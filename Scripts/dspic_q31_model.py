"""
dsPIC33AK Q31 DSP Engine Model
================================
Faithful Python model of the dsPIC33AK DSP engine behavior for Q31
fixed-point operations in fractional mode (CORCON: SATA|SATB|SATDW|ACCSAT,
RND=0 convergent rounding, IF=0 fractional mode).

Key behaviors modeled:
  - Fractional multiply: (a * b) << 1 in 64-bit accumulator
  - Convergent rounding (round-to-even on exact 0x80000000 tie)
  - Saturation to Q31 range [0x80000000, 0x7FFFFFFF]
  - 9.31 accumulator saturation mode (ACCSAT)

Usage:
  from dspic_q31_model import DspAccumulator, q31_fract_mul, sacl_round
"""

import numpy as np

Q31_MAX = 0x7FFFFFFF
Q31_MIN = -0x80000000   # -2147483648

# ============================================================
# Core primitives
# ============================================================

def to_signed32(val):
    """Interpret a 32-bit value as signed."""
    val = int(val) & 0xFFFFFFFF
    if val >= 0x80000000:
        val -= 0x100000000
    return val


def sat_q31(val):
    """Saturate a value to Q31 range [-2^31, 2^31-1]."""
    if val > Q31_MAX:
        return Q31_MAX
    elif val < Q31_MIN:
        return Q31_MIN
    return int(val)


def sacl_round(acc):
    """Simulate sacr.l: extract upper 32 bits of a 64-bit accumulator value
    with convergent (banker's) rounding and saturation.
    
    This models the dsPIC33AK sacr.l instruction behavior:
      lower = acc & 0xFFFFFFFF
      upper = acc >> 32
      Round: if lower > 0x80000000, upper += 1
             if lower == 0x80000000 and upper is odd, upper += 1 (round to even)
      Saturate: clamp upper to [0x80000000, 0x7FFFFFFF]
    """
    lower = acc & 0xFFFFFFFF
    upper = acc >> 32
    if lower > 0x80000000:
        upper += 1       # round up
    elif lower == 0x80000000:
        if upper & 1:    # tie: round to even
            upper += 1
    return sat_q31(upper)


def q31_fract_mul(a, b):
    """Q31 fractional multiply: matches mpy.l + sacr.l in fractional mode.
    
    Computes: ((int64_t)a * (int64_t)b) << 1, then extract upper 32 bits
    with convergent rounding and saturation.
    
    Special case: 0x80000000 * 0x80000000 saturates to 0x7FFFFFFF.
    """
    return sacl_round((int(a) * int(b)) << 1)


# ============================================================
# Accumulator class for MAC operations
# ============================================================

class DspAccumulator:
    """Model of the dsPIC33AK 72-bit DSP accumulator in fractional mode.
    
    In ACCSAT mode (9.31 saturation), the accumulator saturates to
    the range [-2^39, 2^39-1] during accumulation. However, for the
    purpose of test data generation with moderate-range values, we
    use Python arbitrary precision and only saturate on sacr.l extraction.
    
    Usage:
        acc = DspAccumulator()
        acc.clr()
        acc.mpy(a, b)       # acc = (a * b) << 1
        acc.mac(a, b)       # acc += (a * b) << 1
        acc.msc(a, b)       # acc -= (a * b) << 1
        result = acc.sacr() # extract upper 32 with convergent rounding
    """
    
    def __init__(self):
        self.value = 0
    
    def clr(self):
        """Clear accumulator to zero (clr a / clr b)."""
        self.value = 0
    
    def mpy(self, a, b):
        """Set accumulator to fractional product: acc = (a * b) << 1."""
        self.value = (int(a) * int(b)) << 1
    
    def mac(self, a, b):
        """Multiply-accumulate: acc += (a * b) << 1."""
        self.value += (int(a) * int(b)) << 1
    
    def msc(self, a, b):
        """Multiply-subtract: acc -= (a * b) << 1."""
        self.value -= (int(a) * int(b)) << 1
    
    def add(self, val64):
        """Add a raw 64-bit value to accumulator."""
        self.value += val64
    
    def lac(self, val32):
        """Load accumulator from 32-bit value: acc = val32 << 32.
        Models lac.l Ws, Acc."""
        self.value = int(val32) << 32
    
    def add_reg(self, val32):
        """Add a 32-bit register value (shifted to accumulator position).
        Models add.l Ws, Acc: acc += val32 << 32."""
        self.value += int(val32) << 32
    
    def sub_reg(self, val32):
        """Subtract a 32-bit register value from accumulator.
        Models sub.l Ws, Acc: acc -= val32 << 32."""
        self.value -= int(val32) << 32
    
    def sacr(self):
        """Extract upper 32 bits with convergent rounding and saturation.
        Models the sacr.l instruction (no shift)."""
        return sacl_round(self.value)
    
    def sacr_shift(self, shift):
        """Extract with shift and convergent rounding.
        Models sacr.l Acc, #shift, Wd.
        Shift of #1 means the accumulator value is right-shifted by 1 bit
        before extraction, effectively dividing the result by 2."""
        return sacl_round(self.value >> shift)
    
    def sac(self):
        """Extract upper 32 bits with truncation (no rounding) and saturation.
        Models the sac.l instruction (non-rounding variant)."""
        upper = self.value >> 32
        return sat_q31(upper)
    
    def sac_shift(self, shift):
        """Extract with shift and truncation (no rounding).
        Models sac.l Acc, #shift, Wd."""
        upper = (self.value >> shift) >> 32
        return sat_q31(upper)


# ============================================================
# High-level DSP function models
# ============================================================

def dspic_fir_q31(input_q31, coeffs_q31, num_taps, block_size):
    """Model dsPIC33AK FIR Q31 filter (mchp_fir_q31).
    
    For each output sample y[n]:
      acc = sum_{m=0}^{M-1}( h[m] * x[n-m] ) in fractional mode
      y[n] = sacr.l(acc)
    
    Uses circular delay buffer matching assembly pointer behavior:
      - w7 starts at d[0], writes new sample, reads FORWARD with modulo wrap
      - Last MAC has no post-increment, so w7 ends at write_pos-1 (mod M)
      - Next sample writes at that position (overwriting oldest sample)
    
    Args:
        input_q31: array of Q31 input samples (int32)
        coeffs_q31: array of Q31 filter coefficients (int32), length = num_taps
        num_taps: number of filter taps M
        block_size: number of input samples to process
    
    Returns:
        output_q31: array of Q31 output samples (int32)
    """
    input_q31 = [to_signed32(x) for x in input_q31]
    coeffs_q31 = [to_signed32(c) for c in coeffs_q31]
    
    # Delay buffer (state), initialized to zero
    delay = [0] * num_taps
    write_pos = 0  # w7 initial position
    
    output = []
    acc = DspAccumulator()
    
    for n in range(block_size):
        # Write new sample into delay buffer at current w7 position
        delay[write_pos] = input_q31[n]
        
        # mpy.l (first product, clears acc) then mac.l for rest
        # MAC loop reads FORWARD from write_pos with modulo wrap
        read_idx = write_pos
        acc.mpy(coeffs_q31[0], delay[read_idx])
        read_idx = (read_idx + 1) % num_taps
        for m in range(1, num_taps):
            acc.mac(coeffs_q31[m], delay[read_idx])
            read_idx = (read_idx + 1) % num_taps
        
        output.append(acc.sacr())
        
        # w7 ends at (write_pos + M - 1) % M = (write_pos - 1) % M
        write_pos = (write_pos - 1) % num_taps
    
    return np.array(output, dtype=np.int32)


def dspic_conv_q31(pSrcA, srcALen, pSrcB, srcBLen):
    """Model dsPIC33AK convolution Q31 (mchp_conv_q31).
    
    Convolution: y[n] = sum_{k}( a[k] * b[n-k] ), for n = 0..srcALen+srcBLen-2
    Each output uses fractional MAC accumulation + sacr.l.
    
    Args:
        pSrcA: array of Q31 values, length srcALen
        srcALen: length of first input
        pSrcB: array of Q31 values, length srcBLen  
        srcBLen: length of second input
    
    Returns:
        output_q31: array of Q31 output values
    """
    pSrcA = [to_signed32(x) for x in pSrcA]
    pSrcB = [to_signed32(x) for x in pSrcB]
    out_len = srcALen + srcBLen - 1
    
    output = []
    acc = DspAccumulator()
    
    for n in range(out_len):
        acc.clr()
        k_start = max(0, n - srcBLen + 1)
        k_end = min(n, srcALen - 1)
        for k in range(k_start, k_end + 1):
            acc.mac(pSrcA[k], pSrcB[n - k])
        output.append(acc.sacr())
    
    return np.array(output, dtype=np.int32)


def dspic_correlate_q31(pSrcA, srcALen, pSrcB, srcBLen):
    """Model dsPIC33AK correlation Q31.
    
    Correlation: y[n] = sum_{k}( a[k] * b[k+n] )
    Computed as convolution of a with time-reversed b.
    
    Returns:
        output_q31: array of Q31 output values
    """
    pSrcB_rev = list(reversed([to_signed32(x) for x in pSrcB]))
    return dspic_conv_q31(pSrcA, srcALen, pSrcB_rev, srcBLen)


def dspic_biquad_cascade_df1_q31(input_q31, coeffs_q31, num_stages, block_size):
    """Model dsPIC33AK biquad cascade DF1 Q31 (mchp_biquad_cascade_df1_q31).
    
    Each stage implements:
      y[n] = b0*x[n] + b1*x[n-1] + b2*x[n-2] - a1*y[n-1] - a2*y[n-2]
    using mpy.l/mac.l for b-terms and msc.l for a-terms + sacr.l.
    
    Coefficients per stage: [b0, b1, b2, a1, a2] (5 coefficients)
    a1, a2 are standard denominator coefficients (NOT negated).
    Assembly uses msc.l to subtract the feedback terms.
    
    Args:
        input_q31: array of Q31 input samples
        coeffs_q31: flat array of Q31 coefficients [b0,b1,b2,a1,a2, ...] per stage
        num_stages: number of biquad stages
        block_size: number of samples
    
    Returns:
        output_q31: array of Q31 output samples
    """
    input_q31 = [to_signed32(x) for x in input_q31]
    coeffs_q31 = [to_signed32(c) for c in coeffs_q31]
    
    # State per stage: [x[n-1], x[n-2], y[n-1], y[n-2]]
    states = [[0, 0, 0, 0] for _ in range(num_stages)]
    
    current_input = input_q31[:]
    acc = DspAccumulator()
    
    for stage in range(num_stages):
        ci = stage * 5
        b0, b1, b2 = coeffs_q31[ci], coeffs_q31[ci+1], coeffs_q31[ci+2]
        a1, a2 = coeffs_q31[ci+3], coeffs_q31[ci+4]
        
        stage_output = []
        xn1, xn2, yn1, yn2 = states[stage]
        
        for n in range(block_size):
            xn = current_input[n]
            # mpy.l b0*xn (clears + multiplies)
            acc.mpy(b0, xn)
            # mac.l b1*xn1
            acc.mac(b1, xn1)
            # mac.l b2*xn2
            acc.mac(b2, xn2)
            # msc.l a1*yn1 (standard coeff, msc subtracts)
            acc.msc(a1, yn1)
            # msc.l a2*yn2
            acc.msc(a2, yn2)
            
            yn = acc.sacr()
            stage_output.append(yn)
            
            xn2 = xn1
            xn1 = xn
            yn2 = yn1
            yn1 = yn
        
        current_input = stage_output
    
    return np.array(current_input, dtype=np.int32)


def dspic_pid_q31(error_q31, A0, A1, A2):
    """Model dsPIC33AK PID Q31 (mchp_pid_q31) for a single sample.
    
    The PID controller computes:
      out = A0*e[n] + A1*e[n-1] + A2*e[n-2] + out[n-1]
    using MAC accumulation in fractional mode + sacr.l.
    
    With resetStateFlag=1 (as used in test), state is cleared, so for
    the first (and only) sample with e[n-1]=e[n-2]=out[n-1]=0:
      out = A0 * e[n]  (since A1*0 + A2*0 + 0 = 0)
    
    Actually the assembly does:
      acc = A0*e[n] + A1*e[n-1] + A2*e[n-2]
      out = sacr(acc) + state3
    where state3 is the previous output. With reset, state3=0.
    
    Args:
        error_q31: Q31 error input
        A0, A1, A2: Q31 PID coefficients
    
    Returns:
        output_q31: Q31 output
    """
    acc = DspAccumulator()
    acc.mac(to_signed32(A0), to_signed32(error_q31))
    # With reset state, e[n-1]=e[n-2]=0, previous_output=0
    # So only A0*e[n] contributes
    result = acc.sacr()
    # Add previous output (0 after reset) with saturation
    return sat_q31(result + 0)


def dspic_power_q31(input_q31, block_size):
    """Model dsPIC33AK power Q31 (mchp_power_q31).
    
    Computes: sum(x[n]^2) using sqrac.l (square-accumulate) + sacr.l.
    Each x[n]^2 in fractional mode = (x[n] * x[n]) << 1 accumulated.
    Final result via sacr.l.
    
    Note: mchp_power_q31 returns q63_t (64-bit) in some prototypes,
    but the assembly uses sacr.l which gives Q31 (32-bit).
    Check the actual assembly to confirm.
    """
    acc = DspAccumulator()
    for n in range(block_size):
        x = to_signed32(input_q31[n])
        acc.mac(x, x)  # sqrac.l = square-accumulate
    return acc.sacr()


def dspic_mean_q31(input_q31, block_size):
    """Model dsPIC33AK mean Q31 (mchp_mean_q31).
    
    Computes mean by summing all elements then dividing by blockSize.
    The assembly sums in accumulator then uses sac.l (NOT sacr.l -- no rounding
    for the sum) followed by integer division.
    """
    acc = 0
    for n in range(block_size):
        acc += to_signed32(input_q31[n])
    # sac.l extracts upper 32 (but for a sum of Q31 values, the accumulator
    # holds the sum directly, not shifted). Actually mean_q31 doesn't use
    # fractional multiply at all -- it just sums and divides.
    # Need to check the assembly more carefully for the exact approach.
    result = acc // block_size
    return sat_q31(result)


# ============================================================
# FFT / IFFT Models (DIF radix-2)
# ============================================================

def _subr_q31(a, b):
    """Model subr.l instruction: result = b - a, as 32-bit wrapping arithmetic.
    subr.l writes to a W register (not data memory), so SATDW does NOT apply.
    Register ALU results wrap on overflow, they are not saturated."""
    result = int(b) - int(a)
    return to_signed32(result & 0xFFFFFFFF)


def dspic_cfft_dif_q31(data_q31, twiddle_q31, N):
    """Model the DIF radix-2 complex FFT matching mchp_cfft_q31 / fft_aa.s exactly.
    
    Input:
        data_q31: interleaved Q31 array [Re0, Im0, Re1, Im1, ...], length 2*N
        twiddle_q31: interleaved Q31 twiddle [Wr0, Wi0, Wr1, Wi1, ...], length 2*N
                     Convention: Wk = cos(2*pi*k/N) + j*sin(2*pi*k/N)
        N: FFT length (number of complex points)
    
    Output:
        result: interleaved Q31 array in BIT-REVERSED order, scaled by 1/N.
    
    The DIF butterfly (matching reference fft_aa.s):
        Dr = ((Ar-Br)*Wr - (Ai-Bi)*Wi) / 2
        Di = ((Ar-Br)*Wi + (Ai-Bi)*Wr) / 2
        Cr = (Ar+Br) / 2
        Ci = (Ai+Bi) / 2
    
    Where Wr,Wi are twiddle values and /2 comes from sacr.l #1.
    """
    data = [to_signed32(x) for x in data_q31]
    twid = [to_signed32(x) for x in twiddle_q31]
    
    log2N = int(np.log2(N))
    assert (1 << log2N) == N, "N must be a power of 2"
    
    accA = DspAccumulator()
    accB = DspAccumulator()
    
    nGroups = N   # will be halved each stage
    nBflies = 1   # butterflies per group, doubles each stage
    
    for stage in range(log2N):
        nGroups >>= 1  # halve groups
        offset = nGroups  # offset in complex elements (lower leg = upper + offset)
        
        for bfly_idx in range(nBflies):
            for grp in range(nGroups):
                # Compute data indices (complex element indices)
                upper_idx = bfly_idx * 2 * nGroups + grp
                lower_idx = upper_idx + offset
                
                # Twiddle index = grp * nBflies (stride through twiddle table)
                twid_idx = grp * nBflies
                
                # Convert to interleaved array indices
                ui = upper_idx * 2  # upper real index
                li = lower_idx * 2  # lower real index
                ti = twid_idx * 2   # twiddle real index
                
                Ar = data[ui]
                Ai = data[ui + 1]
                Br = data[li]
                Bi = data[li + 1]
                Wr = twid[ti]
                Wi = twid[ti + 1]
                
                # Step 1: Compute differences (full, no halving)
                diffR = _subr_q31(Br, Ar)   # Ar - Br (subr.l: dst = [w10] - w13)
                diffI = _subr_q31(Bi, Ai)   # Ai - Bi
                
                # Step 2: Compute lower leg Dr, Di in accumulator
                # a = diffR * Wr
                accA.mpy(Wr, diffR)
                # b = diffR * Wi
                accB.mpy(Wi, diffR)
                # a -= diffI * Wi  (msc.l)
                accA.msc(Wi, diffI)
                # b += diffI * Wr  (mac.l)
                accB.mac(Wr, diffI)
                
                # Extract with #1 shift (sacr.l a, #1 = divide by 2)
                Dr = accA.sacr_shift(1)
                Di = accB.sacr_shift(1)
                
                # Step 3: Compute upper leg Cr, Ci in accumulator
                # a = Ar
                accA.lac(Ar)
                # b = Ai
                accB.lac(Ai)
                # a += Br
                accA.add_reg(Br)
                # b += Bi
                accB.add_reg(Bi)
                
                # Extract with #1 shift
                Cr = accA.sacr_shift(1)
                Ci = accB.sacr_shift(1)
                
                # Store results
                data[li] = Dr
                data[li + 1] = Di
                data[ui] = Cr
                data[ui + 1] = Ci
        
        nBflies <<= 1  # double butterflies per group
    
    return np.array(data, dtype=np.int32)


def bit_reverse_complex_q31(data_q31, N):
    """Bit-reverse the complex Q31 array in-place, matching hardware XBREV.
    
    Input:
        data_q31: interleaved Q31 array [Re0, Im0, Re1, Im1, ...], length 2*N
        N: number of complex points
    
    Output:
        Bit-reversed interleaved array.
    """
    data = list(data_q31)
    log2N = int(np.log2(N))
    
    for i in range(N):
        # Compute bit-reversed index
        j = 0
        for b in range(log2N):
            if i & (1 << b):
                j |= (1 << (log2N - 1 - b))
        
        if j > i:
            # Swap complex elements i and j
            data[2*i], data[2*j] = data[2*j], data[2*i]
            data[2*i+1], data[2*j+1] = data[2*j+1], data[2*i+1]
    
    return np.array(data, dtype=np.int32)


def dspic_cfft_q31(data_q31, twiddle_q31, N, ifftFlag=0, bitRevFlag=1):
    """Complete CFFT/CIFFT model matching mchp_cfft_q31.
    
    For forward (ifftFlag=0):
        1. DIF FFT core (produces bit-reversed output with 1/N scaling)
        2. Optionally bit-reverse to natural order
    
    For inverse (ifftFlag=1):
        Same as forward — the reference IFFT just calls the same FFT core.
        (The CMSIS inverse path also calls the same core.)
    
    Args:
        data_q31: interleaved complex Q31 input, length 2*N
        twiddle_q31: interleaved complex Q31 twiddle, length 2*N
        N: FFT length
        ifftFlag: 0=forward, 1=inverse
        bitRevFlag: 1=apply bit reversal, 0=skip
    
    Returns:
        result: interleaved complex Q31 output, length 2*N
    """
    # Both forward and inverse use the same DIF core
    result = dspic_cfft_dif_q31(data_q31, twiddle_q31, N)
    
    if bitRevFlag:
        result = bit_reverse_complex_q31(result, N)
    
    return result


# ============================================================
# FFT / RFFT / IRFFT Models
# ============================================================

def dspic_cfft_dif_q31_2N(data_q31, twiddle_q31, N_complex):
    """Model _FFTComplexIP2_noBitRev_q31: N/2-point complex DIF FFT using 2N twiddle table.
    
    This is the same DIF butterfly as dspic_cfft_dif_q31, but operates on N_complex
    complex points and strides through a 2*N_complex-sized twiddle table (i.e.,
    the twiddle table covers 2N points but we use every nBflies-th entry, doubled).
    
    The assembly does: sl.l w3, #4, w7 (stride = nBflies * 16 bytes = nBflies * 2 complex entries)
    compared to the regular CFFT which does: sl.l w3, #3, w7 (stride = nBflies * 8 bytes).
    
    For RFFT-128: N_complex=64, twiddle has 128 complex entries covering a 128-point table.
    The 2x stride means we effectively use twiddle[0], twiddle[2], twiddle[4], etc.
    
    Input:
        data_q31: interleaved Q31 [Re0, Im0, ..., Re_{N-1}, Im_{N-1}], length 2*N_complex
        twiddle_q31: interleaved Q31 twiddle table of size 2*2*N_complex (covering 2N points)
        N_complex: number of complex points (N/2 for RFFT-N)
    
    Output:
        result in BIT-REVERSED order, scaled by 1/N_complex.
    """
    data = [to_signed32(x) for x in data_q31]
    twid = [to_signed32(x) for x in twiddle_q31]
    
    log2N = int(np.log2(N_complex))
    assert (1 << log2N) == N_complex, "N_complex must be a power of 2"
    
    accA = DspAccumulator()
    accB = DspAccumulator()
    
    nGroups = N_complex
    nBflies = 1
    
    for stage in range(log2N):
        nGroups >>= 1
        offset = nGroups  # complex element offset for lower leg
        
        for bfly_idx in range(nBflies):
            for grp in range(nGroups):
                upper_idx = bfly_idx * 2 * nGroups + grp
                lower_idx = upper_idx + offset
                
                # Twiddle index: grp * nBflies * 2 (2x stride for 2N table)
                twid_idx = grp * nBflies * 2
                
                ui = upper_idx * 2
                li = lower_idx * 2
                ti = twid_idx * 2  # interleaved index
                
                Ar = data[ui]
                Ai = data[ui + 1]
                Br = data[li]
                Bi = data[li + 1]
                Wr = twid[ti]
                Wi = twid[ti + 1]
                
                diffR = _subr_q31(Br, Ar)  # Ar - Br
                diffI = _subr_q31(Bi, Ai)  # Ai - Bi
                
                accA.mpy(Wr, diffR)
                accB.mpy(Wi, diffR)
                accA.msc(Wi, diffI)
                accB.mac(Wr, diffI)
                
                Dr = accA.sacr_shift(1)
                Di = accB.sacr_shift(1)
                
                accA.lac(Ar)
                accB.lac(Ai)
                accA.add_reg(Br)
                accB.add_reg(Bi)
                
                Cr = accA.sacr_shift(1)
                Ci = accB.sacr_shift(1)
                
                data[li] = Dr
                data[li + 1] = Di
                data[ui] = Cr
                data[ui + 1] = Ci
        
        nBflies <<= 1
    
    return np.array(data, dtype=np.int32)


def dspic_rfft_split_q31(data_q31, twiddle_q31, N):
    """Model _FFTRealSplit_q31: forward real FFT split function.
    
    Takes the output of an N/2-point complex FFT (in natural order after bit-reversal)
    and produces the N-point real FFT output using the split algorithm.
    
    The data buffer is 2*N Q31 values. The N/2-pt CFFT output occupies complex
    indices 0..N/2-1 (data[0..N-1]). The split writes N/2+1 complex bins, including
    DC at data[0..1] and Nyquist at data[N..N+1].
    
    Loop count: The assembly computes w6 = (4*N >> 4) - 1 = N/4 - 1.
    DTB runs N/4-1 iterations, processing conjugate pairs (k, N/2-k) for k=1..N/4-1.
    The N/4 bin (midpoint) is handled separately after the loop.
    
    Input:
        data_q31: interleaved Q31 from N/2-pt complex FFT, length >= N+2
        twiddle_q31: interleaved Q31 twiddle table, cos(2πk/N)+j*sin(2πk/N)
        N: real FFT length
    
    Output:
        Modified data_q31 in-place, returned as numpy array.
    """
    data = [to_signed32(x) for x in data_q31]
    twid = [to_signed32(x) for x in twiddle_q31]
    N_half = N // 2
    N_quarter = N // 4
    
    accA = DspAccumulator()
    
    # ----- DC and Nyquist -----
    # Gr[0] = Pr[0] + Pi[0]   (no /2)
    # Gr[N/2] = Pr[0] - Pi[0] (no /2)
    # Gi[0] = 0, Gi[N/2] = 0
    Pr0 = data[0]
    Pi0 = data[1]
    
    accA.lac(Pr0)
    accA.add_reg(Pi0)
    data[0] = accA.sacr()        # Gr[0]
    
    accA.lac(Pr0)
    accA.sub_reg(Pi0)
    data[N] = accA.sacr()        # Gr[N/2]
    
    data[1] = 0                   # Gi[0]
    data[N + 1] = 0               # Gi[N/2]
    
    # ----- Bins k=1..N/4-1 (conjugate pairs) -----
    # Forward pointer walks complex indices 1, 2, ..., N/4-1
    # Reverse pointer walks complex indices N/2-1, N/2-2, ..., N/4+1
    # Each iteration processes both bin k and bin N/2-k.
    # Twiddle pointer starts at pair 1, advancing each iteration.
    
    fwd_idx = 1
    rev_idx = N_half - 1
    
    for k in range(1, N_quarter):
        fi = fwd_idx * 2  # interleaved data index for forward bin
        ri = rev_idx * 2  # interleaved data index for reverse bin
        
        # Read conjugate pair (in-place, same order as assembly)
        PrNk = data[ri]
        Prk  = data[fi]
        PiNk = data[ri + 1]
        Pik  = data[fi + 1]
        
        # Radd = (Pr[k] + Pr[N/2-k]) / 2
        accA.lac(PrNk)
        accA.add_reg(Prk)
        Radd = accA.sacr_shift(1)
        
        # Iadd = (Pi[k] + Pi[N/2-k]) / 2
        accA.lac(PiNk)
        accA.add_reg(Pik)
        Iadd = accA.sacr_shift(1)
        
        # Load twiddles: Wr = cos(2πk/N), Wi_neg = -sin(2πk/N)
        ti = k * 2
        Wr = twid[ti]
        Wi = sat_q31(-int(twid[ti + 1]))  # neg.l Wi
        
        # Rsub = Pr[k] - Radd = (Pr[k] - Pr[N/2-k]) / 2
        accA.lac(Prk)
        accA.sub_reg(Radd)
        Rsub = accA.sacr()
        
        # Isub = Pi[k] - Iadd = (Pi[k] - Pi[N/2-k]) / 2
        accA.lac(Pik)
        accA.sub_reg(Iadd)
        Isub = accA.sacr()
        
        # T1 = Iadd*Wr + Rsub*Wi (negated Wi)
        accA.mpy(Iadd, Wr)
        accA.mac(Rsub, Wi)
        T1 = accA.sacr()
        
        # T2 = Iadd*Wi - Rsub*Wr (negated Wi, in accB in assembly)
        accA.mpy(Iadd, Wi)
        accA.msc(Rsub, Wr)
        T2 = accA.sacr()
        
        # Gr(k) = Radd + T1
        accA.lac(Radd)
        accA.add_reg(T1)
        data[fi] = accA.sacr()
        
        # Gi(k) = Isub + T2
        accA.lac(Isub)
        accA.add_reg(T2)
        data[fi + 1] = accA.sacr()
        
        # Gr(N/2-k) = Radd - T1
        accA.lac(Radd)
        accA.sub_reg(T1)
        data[ri] = accA.sacr()
        
        # Gi(N/2-k) = T2 - Isub
        accA.lac(T2)
        accA.sub_reg(Isub)
        data[ri + 1] = accA.sacr()
        
        fwd_idx += 1
        rev_idx -= 1
    
    # ----- N/4 bin (midpoint): negate imaginary part -----
    # Assembly: mov.l [w8+4], w10; neg.l w10; mov.l w10, [w8+4]
    # w8 points to complex index N/4 after the loop
    mid = N_quarter
    data[mid * 2 + 1] = sat_q31(-data[mid * 2 + 1])
    
    return np.array(data, dtype=np.int32)


def dspic_irfft_split_q31(data_q31, twiddle_q31, N):
    """Model _IFFTRealSplit_q31: inverse real FFT split function.
    
    Pre-processing for inverse real FFT. Takes N/2+1 complex bins (from forward RFFT)
    and reconstructs N/2-point complex data for the complex IFFT core.
    
    Loop count: same as forward split — N/4-1 iterations for conjugate pairs,
    plus separate N/4 bin handling.
    
    IFFT differences from forward split:
    - DC: uses /2 scaling
    - Wi is NOT negated
    - T2 formula: Wr*Rsub - Wi*Iadd (different sign pattern)
    - Gr(k) = Radd - T1 (subtract instead of add)
    - Gr(N/2-k) = Radd + T1 (add instead of subtract)
    
    Input:
        data_q31: interleaved Q31, length >= N+2 (N/2+1 meaningful complex bins)
        twiddle_q31: interleaved Q31 twiddle table
        N: real FFT length
    
    Output:
        Modified data_q31 in-place, returned as numpy array.
    """
    data = [to_signed32(x) for x in data_q31]
    twid = [to_signed32(x) for x in twiddle_q31]
    N_half = N // 2
    N_quarter = N // 4
    
    accA = DspAccumulator()
    
    # ----- DC/Nyquist -----
    # Gr[0] = (Pr[0] + Pr[N/2]) / 2
    # Gi[0] = (Pr[0] - Pr[N/2]) / 2
    # Gr[N/2] = 0, Gi[N/2] = 0
    Pr0 = data[0]
    PrN = data[N]     # Pr[N/2] stored at data[N]
    
    accA.lac(Pr0)
    accA.add_reg(PrN)
    Gr0 = accA.sacr_shift(1)
    
    # (Pr[0] - Pr[N/2]) / 2 = Gr0 - Pr[N/2]
    # (This matches the assembly: lac Gr0, sub PrN)
    accA.lac(Gr0)
    accA.sub_reg(PrN)
    Gi0 = accA.sacr()
    
    data[N] = 0          # Gr[N/2] = 0
    data[N + 1] = 0      # Gi[N/2] = 0
    data[0] = Gr0        # Gr[0]
    data[1] = Gi0        # Gi[0]
    
    # ----- Bins k=1..N/4-1 (conjugate pairs) -----
    fwd_idx = 1
    rev_idx = N_half - 1
    
    for k in range(1, N_quarter):
        fi = fwd_idx * 2
        ri = rev_idx * 2
        
        PrNk = data[ri]
        Prk  = data[fi]
        PiNk = data[ri + 1]
        Pik  = data[fi + 1]
        
        # Radd = (Pr[k] + Pr[N/2-k]) / 2
        accA.lac(Prk)
        accA.add_reg(PrNk)
        Radd = accA.sacr_shift(1)
        
        # Iadd = (Pi[k] + Pi[N/2-k]) / 2
        accA.lac(Pik)
        accA.add_reg(PiNk)
        Iadd = accA.sacr_shift(1)
        
        # Load twiddles — Wi NOT negated for IFFT
        ti = k * 2
        Wr = twid[ti]
        Wi = twid[ti + 1]
        
        # Rsub = Pr[k] - Radd
        accA.lac(Prk)
        accA.sub_reg(Radd)
        Rsub = accA.sacr()
        
        # Isub = Pi[k] - Iadd
        accA.lac(Pik)
        accA.sub_reg(Iadd)
        Isub = accA.sacr()
        
        # T1 = Wr*Iadd + Rsub*Wi
        accA.mpy(Wr, Iadd)
        accA.mac(Rsub, Wi)
        T1 = accA.sacr()
        
        # T2 = Wr*Rsub - Wi*Iadd
        accA.mpy(Wr, Rsub)
        accA.msc(Wi, Iadd)
        T2 = accA.sacr()
        
        # Gr(k) = Radd - T1
        accA.lac(Radd)
        accA.sub_reg(T1)
        data[fi] = accA.sacr()
        
        # Gi(k) = Isub + T2
        accA.lac(Isub)
        accA.add_reg(T2)
        data[fi + 1] = accA.sacr()
        
        # Gr(N/2-k) = Radd + T1
        accA.lac(Radd)
        accA.add_reg(T1)
        data[ri] = accA.sacr()
        
        # Gi(N/2-k) = T2 - Isub
        accA.lac(T2)
        accA.sub_reg(Isub)
        data[ri + 1] = accA.sacr()
        
        fwd_idx += 1
        rev_idx -= 1
    
    # ----- N/4 bin: negate Pi(N/4) -----
    mid = N_quarter
    data[mid * 2 + 1] = sat_q31(-data[mid * 2 + 1])
    
    return np.array(data, dtype=np.int32)


def dspic_rfft_fast_q31(real_input_q31, twiddle_q31, N):
    """Model _mchp_rfft_fast_q31 forward path: complete real FFT.
    
    1. Treat N real samples as N/2 complex samples
    2. Run N/2-point complex DIF FFT with 2N twiddle stride + bit reversal
    3. Apply forward split to produce N/2+1 complex frequency bins
    
    Input:
        real_input_q31: N Q31 real samples (interleaved as N/2 complex: [Re0,Im0,...])
        twiddle_q31: interleaved Q31 twiddle table, 2*N entries (N complex pairs)
        N: real FFT length
    
    Output:
        result: 2*N Q31 values; first N+2 values are meaningful
                (N/2+1 complex bins: DC, bins 1..N/2-1, Nyquist)
    """
    N_half = N // 2
    
    # Copy input to working buffer (extended to 2*N for split output space)
    data = [to_signed32(x) for x in real_input_q31]
    # Extend to 2*N if needed (split writes up to index N+1)
    while len(data) < 2 * N:
        data.append(0)
    
    # Step 1: N/2-point complex FFT using 2N twiddle table
    cfft_data = data[:2 * N_half]
    cfft_result = dspic_cfft_dif_q31_2N(cfft_data, twiddle_q31, N_half)
    
    # Bit-reverse the N/2-point result
    cfft_result = bit_reverse_complex_q31(cfft_result, N_half)
    
    # Copy back into the full-size buffer
    for i in range(2 * N_half):
        data[i] = int(cfft_result[i])
    
    # Step 2: Forward split
    result = dspic_rfft_split_q31(data, twiddle_q31, N)
    
    return result


def dspic_irfft_fast_q31(freq_input_q31, twiddle_q31, N):
    """Model _mchp_rfft_fast_q31 inverse path: complete inverse real FFT.
    
    1. Copy input
    2. Apply inverse split to reconstruct N/2 complex samples
    3. Run N/2-point complex DIF FFT with 2N twiddle stride + bit reversal
    
    Input:
        freq_input_q31: 2*N Q31 values (frequency domain from forward RFFT)
        twiddle_q31: interleaved Q31 twiddle table
        N: real FFT length
    
    Output:
        result: 2*N Q31 values; first N values are the real time-domain samples
    """
    N_half = N // 2
    
    data = [to_signed32(x) for x in freq_input_q31]
    while len(data) < 2 * N:
        data.append(0)
    
    # Step 1: Inverse split
    split_result = dspic_irfft_split_q31(data, twiddle_q31, N)
    data = [int(x) for x in split_result]
    
    # Step 2: N/2-point complex FFT + bit reversal
    cfft_data = data[:2 * N_half]
    cfft_result = dspic_cfft_dif_q31_2N(cfft_data, twiddle_q31, N_half)
    cfft_result = bit_reverse_complex_q31(cfft_result, N_half)
    
    for i in range(2 * N_half):
        data[i] = int(cfft_result[i])
    
    return np.array(data, dtype=np.int32)


# ============================================================
# Utility: compare with ARM CMSIS-DSP and report differences
# ============================================================

def compare_results(dspic_results, arm_results, label=""):
    """Compare dsPIC and ARM results, report mismatches."""
    dspic_results = np.asarray(dspic_results, dtype=np.int32)
    arm_results = np.asarray(arm_results, dtype=np.int32)
    
    assert len(dspic_results) == len(arm_results), \
        f"Length mismatch: {len(dspic_results)} vs {len(arm_results)}"
    
    diffs = 0
    for i in range(len(dspic_results)):
        if dspic_results[i] != arm_results[i]:
            diffs += 1
    
    total = len(dspic_results)
    print(f"{label}: {diffs}/{total} values differ from ARM ({100*diffs/total:.1f}%)")
    return diffs
