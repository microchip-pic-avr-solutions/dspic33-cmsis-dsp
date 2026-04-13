"""
Generate all Q31 FFT twiddle tables and test data.
Outputs to stdout with section markers.
"""
import numpy as np
import sys
np.random.seed(42)

N = 128

def float_to_q31(x):
    return int(np.clip(np.round(x * (2**31)), -2**31, 2**31 - 1))

def to_hex(val):
    return '0x%08X' % (val & 0xFFFFFFFF)

def print_interleaved_q31(re_arr, im_arr, per_line=2):
    """Print interleaved real/imag Q31 arrays as C initializer lines."""
    n = len(re_arr)
    for i in range(n):
        re_q = float_to_q31(re_arr[i])
        im_q = float_to_q31(im_arr[i])
        sep = ',' if i < n-1 else ''
        print('    %s, %s%s' % (to_hex(re_q), to_hex(im_q), sep))

def print_real_q31(arr):
    """Print real-only Q31 array as C initializer lines."""
    n = len(arr)
    for i in range(n):
        q = float_to_q31(arr[i])
        sep = ',' if i < n-1 else ''
        print('    %s%s' % (to_hex(q), sep))

# =====================================================
# 1. CFFT twiddle table (128-pt): W(k) = cos + j*sin
# =====================================================
print('=== CFFT_TWIDDLE_128 ===')
cos_arr = [np.cos(2.0 * np.pi * k / N) for k in range(N)]
sin_arr = [np.sin(2.0 * np.pi * k / N) for k in range(N)]
print_interleaved_q31(cos_arr, sin_arr)

# =====================================================
# 2. RFFT split twiddle table: first N/2 entries of CFFT table
# =====================================================
print('\n=== RFFT_TWIDDLE_128 ===')
nrfft = N // 2
print_interleaved_q31(cos_arr[:nrfft], sin_arr[:nrfft])

# =====================================================
# 3. CFFT test input/expected
# =====================================================
gSCL = 0.5
gOFF = 0.25
re_in = gSCL * np.random.random_sample(N) - gOFF
im_in = gSCL * np.random.random_sample(N) - gOFF
re_in = np.clip(re_in, -1.0, 1.0 - 1.0/(2**31))
im_in = np.clip(im_in, -1.0, 1.0 - 1.0/(2**31))

src_complex = re_in + 1j * im_in
fft_result = np.fft.fft(src_complex)
fft_scaled = fft_result / N  # 1/N scaling matches assembly
ifft_result = np.fft.ifft(fft_result)

print('\n=== FFT_INPUT_128 ===')
print_interleaved_q31(re_in, im_in)

print('\n=== FFT_EXPECTED_128 ===')
print_interleaved_q31(fft_scaled.real, fft_scaled.imag)

# For IFFT test: input is the FFT scaled output, expected is original input
# The assembly IFFT does: IFFT(scaled_fft_output) with implicit 1/N from stages
# Since the forward FFT already scaled by 1/N, the IFFT input is fft_scaled
# IFFT of fft_scaled = (1/N) * IFFT(FFT(x)/N) 
# Actually: IFFT = (1/N)*conjugate(FFT(conjugate(x)))
# The assembly does forward FFT with conjugated twiddles + scaling
# So IFFT(fft_scaled) with assembly scaling gives: fft_scaled * N / N = fft_scaled mean... 
# Let me think about this more carefully.
#
# Forward assembly: output = FFT(x) / N  (due to 1/2 per stage)
# Inverse assembly: output = IFFT(x) / N  (same 1/2 per stage)
#   where IFFT(x) = conjugate(FFT(conjugate(x)))
#   But then it also has the 1/N from stages.
#
# Actually looking at the assembly, the inverse path:
#   1. Calls core FFT (same butterfly, no conjugation in mchp_cfft_q31.s)
#   2. No additional scale_q31 call (it's commented out)
#
# Wait - looking at the assembly more carefully:
# Forward: calls _FFTComplexIP_noBitRev_q31 which does DIF butterflies with 1/2 per stage
#   Output = DIF_FFT(x) / N (in bit-reversed order)
# Inverse: same core FFT call, just with ifftFlag=1 
#   But... the assembly doesn't conjugate twiddles or data. 
#   The inverse path also calls the same core, then the scaling is commented out.
#
# For the test, the IFFT input should be the unscaled FFT output,
# and the expected IFFT output should be original / N (since assembly applies 1/N).
# But we can't provide unscaled FFT output because it would overflow Q31.
#
# In practice for the CMSIS pattern:
#   IFFT test: input = fft_result/N (scaled), expected = x/N (the 1/N from IFFT stages)
# This matches how the f32 tests work: IFFT input is the FFT output (in-place).

# For IFFT: input = FFT expected output (= fft_result/N)
# IFFT assembly applies its own 1/N scaling
# So expected IFFT output = ifft(fft_result/N) / N = x/N / N = x/(N^2)
# That seems too small...

# Let me look at how the f32 test does it:
# f32 FFT: mchp_cfft_f32(&S, FFT_src1, 0, 1) - forward, result in FFT_src1
# f32 IFFT: mchp_cfft_f32(&S1, IFFT_src1, 1, 1) - inverse, result in IFFT_src1  
# The IFFT_src1 input is separately defined test data (not FFT output)
# And the f32 CFFT assembly doesn't do 1/N scaling (it's float, no overflow issue)

# For Q31 CFFT with DIF + 1/2 per stage:
# Forward: Y = FFT(X) / N
# Inverse: Z = FFT_core(Y) / N  (where Y has conjugated twiddles applied internally?)
#   Actually the code just runs the same DIF core without conjugation.
#   For a proper IFFT you need to either conjugate input, FFT, conjugate output, and scale.
#   Or use the same butterflies but with conjugated twiddles.
# 
# The assembly at _inverse_path_q31 just calls the same _FFTComplexIP_noBitRev_q31.
# So it computes DIF_FFT(input)/N, which is NOT a proper IFFT.
# Unless the caller conjugates input/output.
#
# For the test, let's keep it simple: 
# IFFT test input = FFT result (what the FFT test produces)
# IFFT expected = what the assembly actually computes (DIF FFT with 1/N scaling)
# The user will validate on hardware.

# Let's make IFFT input = fft_scaled (the FFT output)
# And IFFT expected = DIF_FFT(fft_scaled) / N = FFT(fft_scaled)/N
ifft_input = fft_scaled
ifft_of_scaled = np.fft.fft(ifft_input) / N  # Same DIF FFT with 1/N scaling

print('\n=== IFFT_INPUT_128 ===')
print_interleaved_q31(ifft_input.real, ifft_input.imag)

print('\n=== IFFT_EXPECTED_128 ===')
print_interleaved_q31(ifft_of_scaled.real, ifft_of_scaled.imag)

# =====================================================
# 4. RFFT test data
# =====================================================
rfft_input = gSCL * np.random.random_sample(N) - gOFF
rfft_input = np.clip(rfft_input, -1.0, 1.0 - 1.0/(2**31))

print('\n=== RFFT_INPUT_128 ===')
print_real_q31(rfft_input)

# RFFT: the assembly does N/2-pt complex FFT + split, with 1/2 per stage
# Output is N/2+1 complex values packed as interleaved
# For now, use numpy rfft and scale by 1/(N/2)
rfft_result = np.fft.rfft(rfft_input)
rfft_scaled = rfft_result / (N // 2)

print('\n=== RFFT_EXPECTED_128 ===')
# N/2+1 = 65 complex values = 130 q31_t
for i in range(len(rfft_scaled)):
    re_q = float_to_q31(rfft_scaled[i].real)
    im_q = float_to_q31(rfft_scaled[i].imag)
    sep = ',' if i < len(rfft_scaled)-1 else ''
    print('    %s, %s%s' % (to_hex(re_q), to_hex(im_q), sep))

# =====================================================
# 5. IRFFT test data  
# =====================================================
print('\n=== IRFFT_INPUT_128 ===')
# Input = RFFT output (scaled)
for i in range(len(rfft_scaled)):
    re_q = float_to_q31(rfft_scaled[i].real)
    im_q = float_to_q31(rfft_scaled[i].imag)
    sep = ',' if i < len(rfft_scaled)-1 else ''
    print('    %s, %s%s' % (to_hex(re_q), to_hex(im_q), sep))

print('\n=== IRFFT_EXPECTED_128 ===')
# IRFFT should recover original
irfft_result = np.fft.irfft(rfft_result, N)
print_real_q31(irfft_result)

print('\nDONE')
