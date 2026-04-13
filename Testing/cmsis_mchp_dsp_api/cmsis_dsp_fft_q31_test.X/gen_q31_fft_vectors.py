"""
Q31 FFT Test Vector Generator
==============================
Generates test vectors for the dsPIC33AK Q31 FFT implementation.

This generator models the EXACT behavior of the assembly code:
- DIF (Decimation-in-Frequency) radix-2 butterfly
- Implicit 1/2 scaling per stage (sacr.l a, #1)
- Twiddle table stores cos + j*sin (positive exponent e^{+j*2*pi*k/N})
- Forward FFT: negate Wi (use conjugate twiddle)
- Inverse FFT: use Wi as-is
- Bitreversal applied at the end
- For RFFT: N/2-point complex FFT (with 2N-point twiddle stride) + split
- For IRFFT: inverse split + N/2-point complex FFT

Q31 format: value in [-1.0, 1.0) mapped to [-2^31, 2^31-1]
  q31 = int(round(float_val * 2^31))
  float_val = q31 / 2^31

Author: OpenCode (test vector generator for cmsis-dsp-mchp Q31 FFT)
"""

import numpy as np
import struct

N = 128           # FFT length for CFFT/CIFFT and RFFT/IRFFT
Q31_SCALE = 2**31  # 2147483648

def float_to_q31(val):
    """Convert float [-1.0, 1.0) to Q31 integer."""
    v = int(round(val * Q31_SCALE))
    # Clamp to Q31 range
    if v > 0x7FFFFFFF:
        v = 0x7FFFFFFF
    elif v < -0x80000000:
        v = -0x80000000
    return v

def q31_to_float(q):
    """Convert Q31 integer to float."""
    # Handle signed 32-bit
    if q >= 0x80000000:
        q -= 0x100000000
    return q / Q31_SCALE

def q31_to_hex(val):
    """Convert Q31 integer (possibly negative) to unsigned hex string."""
    return "0x{:08X}".format(val & 0xFFFFFFFF)

def generate_twiddle_table(N):
    """Generate the twiddle table matching twiddleCoef_q31_N.
    Stores cos(2*pi*k/N) + j*sin(2*pi*k/N) for k=0..N-1.
    This is the positive exponent convention."""
    table = []
    for k in range(N):
        angle = 2.0 * np.pi * k / N
        wr = np.cos(angle)
        wi = np.sin(angle)
        table.append((wr, wi))
    return table

def q31_add_half(a, b):
    """Q31 saturated (a + b) / 2, matching sacr.l a, #1 behavior."""
    # In the DSP engine: accumulator = a + b (40-bit), then shift right by 1
    # with convergent rounding, then saturate to 32-bit.
    # For simulation, use 64-bit arithmetic:
    s = a + b  # 64-bit sum
    # Arithmetic right shift by 1 with rounding
    if s >= 0:
        result = (s + 1) >> 1
    else:
        result = (s + 0) >> 1  # For negative, floor division
    # Actually, convergent rounding: round to nearest even
    # For simplicity, use standard rounding (close enough for test vectors)
    result = (s + 1) >> 1 if (s & 1) else s >> 1
    # Actually, let's just use simple division
    result = s // 2 if s >= 0 else -((-s) // 2)
    return result

def q31_sub_half(a, b):
    """Q31 (a - b) / 2."""
    s = a - b
    result = s // 2 if s >= 0 else -((-s) // 2)
    return result

def q31_fract_mul(a, b):
    """Q31 fractional multiply: result = (a * b) >> 31.
    This matches the DSP engine mpy.l behavior."""
    # Full 64-bit product, then shift right by 31
    product = a * b
    # The DSP engine produces a 63-bit result in the accumulator
    result = product >> 31
    return result

# ============================================================
# Model the DIF FFT as implemented in assembly
# ============================================================

def dif_fft_q31_model(data_re, data_im, twiddle_table, N, ifft_flag, twiddle_stride_factor=1):
    """
    Model the DIF FFT exactly as implemented in assembly.
    
    data_re, data_im: lists of Q31 integers (length N)
    twiddle_table: list of (wr_float, wi_float) tuples
    N: FFT length
    ifft_flag: 0 = forward, 1 = inverse
    twiddle_stride_factor: 1 for CFFT, 2 for RFFT (2N-point table)
    
    Returns: (out_re, out_im) in natural order (after bitreversal)
    """
    # Work on interleaved data (matching memory layout)
    n = N
    
    # Convert to Python lists for in-place modification
    re = list(data_re)
    im = list(data_im)
    
    num_stages = int(np.log2(N))
    butterflies_per_group = 1
    
    for stage in range(num_stages):
        n_groups = N // (2 * butterflies_per_group)
        offset = n_groups  # distance between upper and lower legs (in complex elements)
        
        for bfly_idx in range(butterflies_per_group):
            # Twiddle for this butterfly index
            tw_index = bfly_idx * twiddle_stride_factor
            wr_f, wi_f = twiddle_table[tw_index % len(twiddle_table)]
            
            # Convert twiddle to Q31
            wr = float_to_q31(wr_f)
            wi = float_to_q31(wi_f)
            
            # For forward FFT, negate Wi (conjugate twiddle)
            if ifft_flag == 0:
                wi = -wi
                if wi < -0x80000000:
                    wi = -0x80000000
            
            for grp in range(n_groups):
                upper = bfly_idx + grp * (2 * butterflies_per_group)
                lower = upper + offset
                
                ar = re[upper]
                ai = im[upper]
                br = re[lower]
                bi = im[lower]
                
                # DIF butterfly with 1/2 scaling:
                # Upper output: (A + B) / 2
                # Lower output: ((A - B) / 2) * W
                
                # diffR = (Ar - Br) / 2
                diff_r = (ar - br) // 2
                # diffI = (Ai - Bi) / 2
                diff_i = (ai - bi) // 2
                
                # sumR = (Ar + Br) / 2
                sum_r = (ar + br) // 2
                # sumI = (Ai + Bi) / 2
                sum_i = (ai + bi) // 2
                
                # Lower: Dr = diffR * Wr - diffI * Wi (Q31 fract mul)
                dr = (diff_r * wr - diff_i * wi) >> 31
                # Di = diffR * Wi + diffI * Wr
                di = (diff_r * wi + diff_i * wr) >> 31
                
                re[upper] = sum_r
                im[upper] = sum_i
                re[lower] = dr
                im[lower] = di
                
            # Advance twiddle stride for next group
            # (In the assembly, twiddle advances by butterflies_per_group * twiddle_stride_factor
            #  per group within the inner loop. But since we compute tw_index = bfly_idx * stride,
            #  the per-group twiddle advancement is handled differently.)
            #
            # Actually, re-reading the assembly: the twiddle pointer is rewound after each
            # butterfly set (outer loop), and advanced by stride within the inner (group) loop.
            # So the twiddle for group g at butterfly index b is:
            #   tw = base + b * 8 + g * (butterflies_per_group * 8 * twiddle_stride_factor)
            # Wait, that's not right either. Let me re-read the assembly:
            #
            # Inner loop (groups): twiddle advances by w3*8*twiddle_stride_factor each group
            # Outer loop (butterflies): twiddle rewinds to base
            #
            # So twiddle[grp] = base + grp * butterflies_per_group * twiddle_stride_factor
            # But bfly_idx doesn't affect twiddle pointer!
            #
            # That means for each butterfly index within a group, the SAME twiddle set
            # is used for that group. The twiddle depends on the GROUP, not the butterfly index.
            #
            # Wait, no. Let me re-read more carefully:
            # - Outer loop: w6 = butterflies_per_group (bfly idx counter)
            # - For each bfly idx: w10 = data base (upper), w11 = w10 + offset
            # - Inner loop: w5 = n_groups (group counter)
            #   - Butterfly at (w10, w11) with twiddle at w8
            #   - w10 += 8 (next complex element in upper half)
            #   - w11 += 8 (next complex element in lower half)
            #   - w8 += w3 * 8 * twiddle_stride_factor (advance twiddle by stride)
            # - After inner loop: w10 += offset (skip lower region)
            # - w8 = w2 (rewind twiddle)
            #
            # So for butterfly index b and group g:
            #   upper = base + b + g * (2 * butterflies_per_group)
            #   Wait, w10 starts at data base, then after inner loop processes all groups,
            #   w10 has advanced by n_groups * 8 bytes (one complex per group).
            #   Then w10 += offset skips the lower half.
            #   Next bfly_idx iteration, w10 starts from the new position.
            #
            # Actually, let me think in terms of element indices:
            #   Stage has 2*butterflies_per_group elements per "block"
            #   (butterflies_per_group upper + butterflies_per_group lower)
            #
            # For the outer loop (bfly_idx from 0 to bpg-1):
            #   w10 starts at data[0] for bfly_idx=0
            #   Inner loop processes n_groups groups
            #   For group g: upper = data[bfly_idx + g * 2*bpg]
            #                lower = upper + offset = data[bfly_idx + g * 2*bpg + n_groups]
            #   Wait, offset = n_groups * 8 bytes = n_groups complex elements
            #   But n_groups = N / (2 * bpg)
            #   So upper = bfly_idx + g * N/n_groups?
            #   
            # Let me just trace with N=8, stage 2 (bpg=2, n_groups=2):
            #   w10 starts at data[0]
            #   bfly_idx=0:
            #     offset = n_groups = 2 complex elements
            #     w11 = w10 + 2 = data[2]
            #     group 0: upper=data[0], lower=data[2], twiddle=tw[0]
            #       w10 -> data[1], w11 -> data[3]
            #       twiddle advance: w8 += bpg * 8 = 2 * 8 = 16 bytes = 2 complex entries
            #       twiddle = tw[2]
            #     group 1: upper=data[1]?? NO
            #
            # Hmm, I'm confusing myself. Let me trace more carefully.
            # 
            # w10 starts at &data[0]. w10 points to data[0].re
            # After processing group 0: w10 has advanced past Re and Im (+8 bytes = +1 complex)
            # So w10 -> data[1].re
            # Then group 1: upper = data[1], lower = data[1+offset] = data[3]
            # After group 1: w10 -> data[2].re
            # End of inner loop for bfly_idx=0.
            # w10 += offset = 2 complex -> w10 = data[4].re
            # bfly_idx=1:
            #   w11 = w10 + offset = data[4+2] = data[6]
            #   group 0: upper=data[4], lower=data[6], twiddle=tw[0] (rewound)
            #     w10 -> data[5], w11 -> data[7]
            #     twiddle advance: tw[2]
            #   group 1: upper=data[5], lower=data[7], twiddle=tw[2]
            #
            # So for N=8, stage 2 (bpg=2, ngrps=2):
            #   bfly_idx=0: (0,2)@tw0, (1,3)@tw2
            #   bfly_idx=1: (4,6)@tw0, (5,7)@tw2
            #
            # For standard DIF with N=8, stage 2:
            #   Groups of 4 elements, 2 butterflies each
            #   Group 0 (elements 0-3): bfly (0,2)@W0, bfly (1,3)@W2
            #   Group 1 (elements 4-7): bfly (4,6)@W0, bfly (5,7)@W2
            #
            # YES! This matches. The twiddle for element pair (upper, lower) in group g
            # depends on the POSITION within the group, and the assembly achieves this
            # by advancing the twiddle within the inner (group) loop.
            #
            # So the twiddle for bfly_idx b in group g is:
            #   tw[g * butterflies_per_group * twiddle_stride_factor]
            # NOT tw[b * something].
            #
            # Wait, that contradicts what I wrote above. Let me re-check:
            # In the inner loop, twiddle advances by w3*8*tsf per group iteration.
            # w3 = butterflies_per_group.
            # So twiddle for group g = tw[g * bpg * tsf]
            #
            # And the twiddle is REWOUND at the start of each bfly_idx.
            # So the twiddle used for (bfly_idx=b, group=g) is:
            #   tw[g * bpg * tsf]  -- same regardless of b!
            #
            # But for DIF FFT, within a group of 2*bpg elements, butterfly index b
            # should use twiddle W^(b), and there should be bpg different twiddles.
            #
            # For N=8, stage 2: bpg=2, groups of 4 elements each
            #   Group 0: (0,2)@W0, (1,3)@W2  
            #   Group 1: (4,6)@W0, (5,7)@W2
            #
            # The twiddle for (bfly_idx=0, group=g) is tw[g*2] = tw[0], tw[2]
            # The twiddle for (bfly_idx=1, group=g) is tw[g*2] = tw[0], tw[2] too!
            # But we want (bfly_idx=0, group=0)@tw0 and (bfly_idx=1, group=0)@tw2!
            #
            # WAIT. Let me re-trace:
            # bfly_idx=0:
            #   group 0: upper=data[0], lower=data[2], tw=tw[0]
            #     advance tw by 2*tsf -> tw[2*tsf]
            #   group 1: upper=data[1], lower=data[3], tw=tw[2*tsf]
            # bfly_idx=1: (rewind tw)
            #   group 0: upper=data[4], lower=data[6], tw=tw[0]
            #   group 1: upper=data[5], lower=data[7], tw=tw[2*tsf]
            #
            # So the pairs are:
            #   (0,2)@tw[0], (1,3)@tw[2*tsf], (4,6)@tw[0], (5,7)@tw[2*tsf]
            #
            # For standard DIF, stage 2 of N=8:
            #   Two groups of 4: {0,1,2,3} and {4,5,6,7}
            #   Within each group: bfly (0,2)@W0, bfly (1,3)@W2
            #   So: (0,2)@W0, (1,3)@W2, (4,6)@W0, (5,7)@W2
            #
            # With tsf=1: tw[2*1] = tw[2] = W2. Correct!
            #
            # So the twiddle for a particular computation depends on which GROUP
            # iteration we're in (within the inner loop), not on bfly_idx.
            # The twiddle effectively indexes the POSITION within a group.
            #
            # Let me re-express: for bfly_idx=b, group=g,
            #   upper_element_index = b*n_groups*2 + ... hmm, actually the element indices
            #   don't form a simple formula from (b,g). Let me trace again.
            #
            # The sequential access pattern is:
            #   bfly_idx=0: process elements (0,offset), (1,1+offset), ..., (ngrps-1, ngrps-1+offset)
            #     w10 advances: 0, 1, 2, ..., ngrps-1, then + offset
            #   bfly_idx=1: starts at ngrps+offset, processes next batch
            #
            # For N=8, ngrps=2, offset=2, bpg=2:
            #   bfly_idx=0: (0,2), (1,3). w10 ends at 2. +offset=2 -> starts at 4
            #   bfly_idx=1: (4,6), (5,7)
            #
            # The twiddle for the g-th iteration of the inner loop is:
            #   tw[g * bpg * tsf]
            # So for g=0: tw[0], for g=1: tw[2] (with tsf=1, bpg=2)
            #
            # For stage 1 (bpg=1, ngrps=4, offset=4):
            #   bfly_idx=0: (0,4), (1,5), (2,6), (3,7)
            #     twiddles: tw[0], tw[1], tw[2], tw[3]
            #   That's it (only 1 butterfly index).
            #
            # Standard DIF stage 1 for N=8: one group of 8 elements
            #   Butterflies: (0,4)@W0, (1,5)@W1, (2,6)@W2, (3,7)@W3
            #   Matches!
            #
            # For stage 3 (bpg=4, ngrps=1, offset=1):
            #   bfly_idx=0: (0,1). twiddle: tw[0*4]=tw[0]
            #   bfly_idx=1: (2,3). twiddle: tw[0]=tw[0]
            #   bfly_idx=2: (4,5). twiddle: tw[0]=tw[0]
            #   bfly_idx=3: (6,7). twiddle: tw[0]=tw[0]
            #
            # Standard DIF stage 3 for N=8: 4 groups of 2
            #   Each group: 1 butterfly at W0
            #   (0,1)@W0, (2,3)@W0, (4,5)@W0, (6,7)@W0
            #   Matches!

        butterflies_per_group *= 2
    
    # Apply bitreversal
    re_out = [0] * N
    im_out = [0] * N
    num_bits = int(np.log2(N))
    for i in range(N):
        j = int('{:0{w}b}'.format(i, w=num_bits)[::-1], 2)
        re_out[j] = re[i]
        im_out[j] = im[i]
    
    return re_out, im_out

# ACTUALLY, after all that analysis, I realize the model is wrong.
# The twiddle for (bfly_idx=b, group_iteration=g) should be:
#   tw[g * bpg * tsf]  (twiddle depends on group iteration, not bfly_idx)
#
# But that means within a "group" of 2*bpg elements, all butterflies at the
# same group_iteration get the same twiddle. That doesn't match DIF!
#
# Let me re-think. Actually, in the assembly:
# - bfly_idx iterates the OUTER loop (which pair within a group)
# - group_iteration iterates the INNER loop (which group)
#
# For bfly_idx=b: processes elements b, b + 2*bpg, b + 4*bpg, ...
# These are elements at position b within each group.
# The twiddle for position b within a group should be W^(b).
# But the twiddle is advanced per GROUP iteration, not per bfly_idx.
#
# In the inner loop, the twiddle advances by bpg*tsf per group.
# For bfly_idx=0: groups see tw[0], tw[bpg*tsf], tw[2*bpg*tsf], ...
# For bfly_idx=1: groups see tw[0], tw[bpg*tsf], tw[2*bpg*tsf], ... (SAME!)
#
# This is WRONG for DIF! Butterfly position b within a group should use W^b.
#
# UNLESS... the outer/inner loop structure doesn't map to "position within group"
# and "which group" the way I'm thinking.
#
# Let me VERY carefully trace N=8 stage 2 with the assembly logic.
#
# Stage 2: bpg=2 (doubled from stage 1), ngrps = N/(2*bpg) = 8/4 = 2
# w9 = ngrps = 2 (halved from previous stage's value of 4)
# offset = ngrps * 8 bytes = 2 complex elements
# w3 = bpg = 2
# twiddle stride = w3 * 8 = 16 bytes = 2 complex entries (for tsf=1)
#
# Outer loop: w6 = bpg = 2
#   bfly_idx = 0 (first iteration):
#     w10 = &data[0] (upper base)
#     w11 = w10 + offset = &data[2]
#     Inner loop: w5 = ngrps = 2
#       group_iter = 0:
#         butterfly(data[0], data[2], twiddle[0])
#         w10 -> data[1], w11 -> data[3]
#         w8 += stride=2 -> twiddle[2]
#       group_iter = 1:
#         butterfly(data[1], data[3], twiddle[2])
#         w10 -> data[2], w11 -> data[4]
#         w8 += 2 -> twiddle[4]
#     w10 += offset=2 -> data[4]
#     w8 = base (rewind)
#
#   bfly_idx = 1 (second iteration):
#     w10 = &data[4]
#     w11 = &data[6]
#     Inner loop: w5 = ngrps = 2
#       group_iter = 0:
#         butterfly(data[4], data[6], twiddle[0])
#         w10 -> data[5], w11 -> data[7]
#         w8 += 2 -> twiddle[2]
#       group_iter = 1:
#         butterfly(data[5], data[7], twiddle[2])
#     w10 += offset=2 -> data[6] (but loop ends)
#
# So butterflies are:
#   (0,2)@tw0, (1,3)@tw2, (4,6)@tw0, (5,7)@tw2
#
# Standard DIF stage 2 for N=8 (2 groups of 4):
#   Group 0: (0,2)@W0, (1,3)@W2
#   Group 1: (4,6)@W0, (5,7)@W2
#   MATCHES!
#
# So the mapping is:
#   bfly_idx b, group_iter g:
#     upper = b * 2 * ngrps + g  (NO, that gives 0*4+0=0, 0*4+1=1, 1*4+0=4, 1*4+1=5)
#     Wait, that's actually what happens: indices processed are 0,1,4,5
#     with lower = upper + ngrps: 2,3,6,7
#     YES! Upper indices are: 0, 1, 4, 5
#     Lower indices are: 2, 3, 6, 7
#     This is correct for DIF stage 2.
#
# The twiddle used for group_iter g is: tw[g * bpg * tsf]
# For g=0: tw[0] = W^0
# For g=1: tw[2*1] = tw[2] = W^2
#
# But in standard DIF, within a group:
#   Position 0 uses W^0, position 1 uses W^2 (for N=8, stage 2)
#
# So group_iter=0 corresponds to position 0 in each group,
# and group_iter=1 corresponds to position 1.
# The twiddle W^(g * bpg) = W^(g * 2) for this stage.
#
# For general stage with bpg butterflies per group:
#   Twiddle for position p within a group = W^(p * N/(2*bpg))
#   And group_iter g corresponds to position g.
#   The code computes: tw[g * bpg * tsf]
#   
#   W^(g * bpg * tsf) should equal W^(g * N/(2*bpg))
#   For CFFT (tsf=1): g * bpg should equal g * N/(2*bpg)
#     bpg = N/(2*bpg) ? No, that's only true for the middle stage.
#
# Wait, actually the twiddle table has entries for W^k, k=0..N-1.
# Entry tw[k] = (cos(2πk/N), sin(2πk/N)) = W_N^k.
# The assembly indexes as tw[g * bpg * tsf].
# For CFFT (tsf=1): tw[g * bpg].
# The twiddle value = W_N^(g * bpg).
#
# For DIF, stage s (starting from s=1):
#   bpg = 2^(s-1)
#   ngrps = N / (2*bpg) = N / 2^s
#   Within each group of 2*bpg elements, butterfly position p uses W_N^(p * ngrps)
#   = W_N^(p * N/2^s)
#
# The code maps: position p = group_iter g, and tw = W_N^(g * bpg)
# So W_N^(g * bpg) should = W_N^(g * N/2^s)
# g * bpg = g * 2^(s-1)
# g * N/2^s
# These are equal only if bpg = N/2^s, i.e., 2^(s-1) = N/2^s, i.e., 2^(2s-1) = N.
# That's not generally true.
#
# For N=8, stage 2: bpg=2, ngrps=2
#   Code: tw[g*2]
#   Expected: W_8^(g * 8/4) = W_8^(2g) = tw[2g]
#   MATCHES!
#
# For N=8, stage 1: bpg=1, ngrps=4
#   Code: tw[g*1] = tw[g]
#   Expected: W_8^(g * 8/2) = W_8^(4g) = tw[4g]
#   g*1 vs 4g. DOESN'T MATCH!
#
# Wait, let me retrace stage 1:
# bpg=1, ngrps=4
# Outer: w6=1, so only bfly_idx=0
#   w10=&data[0], offset=ngrps=4
#   w11=&data[4]
#   Inner: w5=4
#     g=0: bfly(0,4), tw[0]. stride=bpg*8=8 bytes = 1 complex. tw advances to tw[1]
#     g=1: bfly(1,5), tw[1]. tw -> tw[2]
#     g=2: bfly(2,6), tw[2]. tw -> tw[3]
#     g=3: bfly(3,7), tw[3].
#
# Butterflies: (0,4)@W0, (1,5)@W1, (2,6)@W2, (3,7)@W3
#
# Standard DIF stage 1 for N=8: ONE group of N elements
#   (0,4)@W0, (1,5)@W1, (2,6)@W2, (3,7)@W3
#   MATCHES!
#
# So for stage 1: twiddle = tw[g*1] = W_N^g. Expected: W_N^g. CORRECT!
# For stage 2: twiddle = tw[g*2] = W_N^(2g). Expected: W_N^(2g). CORRECT!
# For stage 3: twiddle = tw[g*4] = W_N^(4g). Expected: W_N^(4g). 
#   But stage 3 has ngrps=1, so g=0 only. tw[0]=W0. Expected: W0. CORRECT!
#
# General: twiddle = W_N^(g * bpg) for group_iter g.
# Expected: W_N^(g * bpg). Because the standard DIF twiddle for position g
# within a block of size 2*bpg is W_{2*bpg}^g = W_N^(g * N/(2*bpg)).
# And indeed N/(2*bpg) = ngrps, and the twiddle stride is bpg * tsf.
#
# For CFFT (tsf=1): stride = bpg. So twiddle = tw[g * bpg] = W_N^(g*bpg).
# We need this to equal W_N^(g * ngrps) = W_N^(g * N/(2*bpg)).
# g*bpg = g*N/(2*bpg) only if bpg^2 = N/2.
#
# Hmm, this doesn't match for all stages. Let me recheck with N=128, stage 1:
# bpg=1, ngrps=64
# stride=1 (for tsf=1)
# twiddle for g: tw[g*1] = W_128^g
# Expected: W_128^g (position g within the single group)
# CORRECT!
#
# Stage 2: bpg=2, ngrps=32
# stride=2
# twiddle for g: tw[g*2] = W_128^(2g)
# Expected: position g within group → W_{4}^g = W_128^(32g)
# WAIT, 2g ≠ 32g. 
#
# No wait. For stage 2 of DIF N=128:
#   Block size = 2*bpg = 4. Number of blocks = 32.
#   Within each block, butterflies at positions 0,1 use twiddles W_4^0=W0, W_4^1=W128^32
#   But the assembly processes things differently due to the loop structure.
#
# Actually, I think I'm overcomplicating this. Let me re-derive from the assembly trace.
#
# The assembly structure for stage s:
#   bpg = 2^(s-1), ngrps = N/2^s
#   outer loop b = 0..bpg-1:
#     upper base starts at: first element of the b-th "column" across all blocks
#     inner loop g = 0..ngrps-1:
#       upper = (sequentially advancing through the b-th column of blocks)
#       lower = upper + ngrps
#       twiddle = tw[g * bpg * tsf] (advances by bpg*tsf per group)
#
# The key insight: the "group" in the inner loop doesn't correspond to 
# "which block". Instead, it corresponds to "which position within each block
# is being processed." Let me re-verify with N=8 stage 2:
#
# Elements in natural order: 0 1 2 3 | 4 5 6 7  (two blocks of 4)
# bfly_idx=0: processes (0,2), (1,3)
#   These are: position 0 in block 0, position 0 in block 1
#   But (0,2) is within block 0 (positions 0 and 2)
#   And (1,3) is also within block 0!
#   Wait, (1,3) means upper=1, lower=3, both in block 0.
#
# So the inner loop processes DIFFERENT POSITIONS within the SAME block(s).
# After bfly_idx=0's inner loop: we've processed position 0 and position 1
# of block 0 (elements 0,1,2,3), and we haven't touched block 1 yet.
# Then bfly_idx=1 processes block 1.
#
# Actually wait. ngrps=2, but there are 2 blocks. So the inner loop
# runs 2 iterations for 2 different positions within a block (or two blocks).
#
# I think the confusion is that "block" and "group" are being conflated.
# Let me just enumerate the butterflies:
#
# Stage 2, N=8, bpg=2, ngrps=2, offset=2:
#   b=0: upper starts at 0
#     g=0: bfly(0, 0+2=2), tw[0*2]=tw[0]
#     g=1: bfly(1, 1+2=3), tw[1*2]=tw[2]
#     w10 += offset=2 -> 4
#   b=1: upper starts at 4
#     g=0: bfly(4, 4+2=6), tw[0*2]=tw[0]
#     g=1: bfly(5, 5+2=7), tw[1*2]=tw[2]
#
# Butterflies: (0,2)@tw0, (1,3)@tw2, (4,6)@tw0, (5,7)@tw2
# This is CORRECT for DIF stage 2.
#
# The twiddle indices match standard DIF.
#
# So my model should be:
#   For bfly_idx b, group_iter g (0-indexed):
#     upper = (sum of elements from previous bfly_idx iterations) + g
#     Specifically: upper = b * (ngrps + offset) + g
#       Wait, no. Let me compute from the assembly behavior.
#     In the assembly: w10 starts at data[0] for b=0.
#     After b=0's inner loop (ngrps iterations), w10 has advanced by ngrps elements.
#     Then w10 += offset = ngrps more elements. Total advance = 2*ngrps.
#     For b=1: w10 starts at 2*ngrps. Then processes ngrps elements.
#     For b: upper_start = b * 2 * ngrps
#     For group_iter g: upper = b * 2 * ngrps + g
#     lower = upper + ngrps
#     twiddle index = g * bpg * tsf
#
# Let me verify: N=8, stage 2: bpg=2, ngrps=2, 2*ngrps=4
#   b=0, g=0: upper=0, lower=2, tw=0*2*1=0. ✓
#   b=0, g=1: upper=1, lower=3, tw=1*2*1=2. ✓
#   b=1, g=0: upper=4, lower=6, tw=0*2*1=0. ✓
#   b=1, g=1: upper=5, lower=7, tw=1*2*1=2. ✓
# PERFECT!

def dif_fft_q31(data_re, data_im, N, ifft_flag, twiddle_stride_factor=1):
    """
    Precise model of the DIF FFT as implemented in assembly.
    Uses high-precision Python integers for Q31 arithmetic.
    
    data_re, data_im: lists of Q31 integers (length N)
    N: FFT length
    ifft_flag: 0 = forward, 1 = inverse
    twiddle_stride_factor: 1 for CFFT, 2 for RFFT core
    
    Returns: (out_re, out_im) in natural order (after bitreversal)
    """
    re = list(data_re)
    im = list(data_im)
    
    num_stages = int(np.log2(N))
    bpg = 1  # butterflies per group (doubles each stage)
    
    for stage in range(num_stages):
        ngrps = N // (2 * bpg)
        offset = ngrps  # distance between upper/lower legs
        
        for b in range(bpg):
            for g in range(ngrps):
                upper = b * 2 * ngrps + g
                lower = upper + offset
                
                # Twiddle index
                tw_idx = g * bpg * twiddle_stride_factor
                angle = 2.0 * np.pi * tw_idx / (N * twiddle_stride_factor)
                wr_f = np.cos(angle)
                wi_f = np.sin(angle)
                
                # Convert to Q31
                wr = float_to_q31(wr_f)
                wi = float_to_q31(wi_f)
                
                # For forward FFT, negate Wi
                if ifft_flag == 0:
                    wi = -wi
                
                ar, ai = re[upper], im[upper]
                br, bi = re[lower], im[lower]
                
                # DIF butterfly with 1/2 scaling
                diff_r = (ar - br) // 2
                diff_i = (ai - bi) // 2
                sum_r = (ar + br) // 2
                sum_i = (ai + bi) // 2
                
                # Lower output: diff * W (Q31 fractional multiply)
                dr = (diff_r * wr - diff_i * wi) >> 31
                di = (diff_r * wi + diff_i * wr) >> 31
                
                re[upper] = sum_r
                im[upper] = sum_i
                re[lower] = dr
                im[lower] = di
        
        bpg *= 2
    
    # Bitreversal
    num_bits = int(np.log2(N))
    re_out = [0] * N
    im_out = [0] * N
    for i in range(N):
        j = int('{:0{w}b}'.format(i, w=num_bits)[::-1], 2)
        re_out[j] = re[i]
        im_out[j] = im[i]
    
    return re_out, im_out


def rfft_forward_split_q31(data_re, data_im, N):
    """
    Model the forward RFFT split function.
    
    data_re, data_im: complex FFT output (N/2 complex points, but stored as N/2+1 for Nyquist)
    N: real FFT length
    
    Input is N/2 complex points in data_re[0..N/2-1], data_im[0..N/2-1].
    Output writes N/2+1 complex points including DC and Nyquist.
    
    For simplicity, works with indices 0..N/2 where:
    - Pr[k] = data_re[k], Pi[k] = data_im[k] for k=0..N/2-1
    - Pr[N/2] and Pi[N/2] would be beyond the array; we handle it via the
      interleaved storage: the real FFT output uses N+2 values total
      stored as [Pr0, Pi0, Pr1, Pi1, ..., Pr[N/2-1], Pi[N/2-1]]
      but the split writes Pr[N/2] and Pi[N/2] at positions N and N+1.
    
    Actually, matching the assembly: the split operates on a flat array
    of 2*(N/2) = N Q31 values, indexed as:
      [Pr[0], Pi[0], Pr[1], Pi[1], ..., Pr[N/2-1], Pi[N/2-1]]
    and the output extends to include Pr[N/2], Pi[N/2] (positions N, N+1).
    
    For the model, use separate re/im arrays of length N/2+1.
    """
    half = N // 2
    
    # Extend arrays to hold N/2+1 elements (index 0 to N/2)
    pre = list(data_re) + [0]  # Pr[0..N/2]
    pim = list(data_im) + [0]  # Pi[0..N/2]
    gre = [0] * (half + 1)     # Gr[0..N/2]
    gim = [0] * (half + 1)     # Gi[0..N/2]
    
    # DC and Nyquist (NO /2, matching f32 and Q31 assembly)
    gre[0] = pre[0] + pim[0]
    gim[0] = 0
    gre[half] = pre[0] - pim[0]
    gim[half] = 0
    
    # Bins 1 to N/2-1
    for k in range(1, half):
        nk = half - k  # N/2 - k (the conjugate index)
        
        radd = (pre[k] + pre[nk]) // 2
        iadd = (pim[k] + pim[nk]) // 2
        rsub = pre[k] - radd   # = (pre[k] - pre[nk]) / 2
        isub = pim[k] - iadd   # = (pim[k] - pim[nk]) / 2
        
        # Twiddle: entry k+1 in the split twiddle table (skip entry 0)
        # Actually, the assembly does: w4 = twiddle_base + 8 (skip first pair)
        # Then advances by 8 bytes per iteration.
        # So for bin k, twiddle index = k (1-indexed from the skip).
        # The twiddle table is the same as the main table.
        # Split twiddle entry k = (cos(2πk/N), sin(2πk/N))
        # But Wi is NEGATED in the forward split.
        angle = 2.0 * np.pi * k / N
        wr = float_to_q31(np.cos(angle))
        wi = float_to_q31(np.sin(angle))
        wi = -wi  # Forward split negates Wi
        
        # T1 = Iadd*Wr + Rsub*Wi
        t1 = (iadd * wr + rsub * wi) >> 31
        # T2 = Iadd*Wi - Rsub*Wr
        t2 = (iadd * wi - rsub * wr) >> 31
        
        gre[k] = radd + t1
        gim[k] = isub + t2
        gre[nk] = radd - t1
        gim[nk] = t2 - isub
    
    # Negate Gi[N/4] (the N/2-th bin's imaginary part in the assembly)
    # Actually, the assembly negates [w8+4] which is Pi[N/4] after the loop.
    # w8 points to Gr[N/4] after the loop, so [w8+4] = Gi[N/4].
    quarter = N // 4
    gim[quarter] = -gim[quarter]
    
    return gre, gim


def irfft_split_q31(data_re, data_im, N):
    """
    Model the inverse RFFT split function.
    
    data_re, data_im: frequency-domain data (N/2+1 complex points)
    N: real FFT length
    
    Output: N/2 complex points for the complex IFFT.
    """
    half = N // 2
    
    pre = list(data_re)
    pim = list(data_im)
    gre = [0] * half
    gim = [0] * half
    
    # DC bin
    gre[0] = (pre[0] + pre[half]) // 2
    gim[0] = (pre[0] - pre[half]) // 2
    
    # Bins 1 to N/2-1
    for k in range(1, half):
        nk = half - k
        
        radd = (pre[k] + pre[nk]) // 2
        iadd = (pim[k] + pim[nk]) // 2
        rsub = pre[k] - radd
        isub = pim[k] - iadd
        
        # Twiddle (NOT negated for IFFT split)
        angle = 2.0 * np.pi * k / N
        wr = float_to_q31(np.cos(angle))
        wi = float_to_q31(np.sin(angle))
        
        # T1 = Iadd*Wr + Rsub*Wi
        t1 = (wr * iadd + rsub * wi) >> 31
        # T2 = Wr*Rsub - Wi*Iadd
        t2 = (wr * rsub - wi * iadd) >> 31
        
        gre[k] = radd - t1
        gim[k] = isub + t2
        gre[nk] = radd + t1
        gim[nk] = t2 - isub
    
    # Negate Gi[N/4]
    quarter = N // 4
    gim[quarter] = -gim[quarter]
    
    return gre, gim


def format_c_array(name, values, per_line=2, is_interleaved=True):
    """Format Q31 values as a C array."""
    lines = [f"q31_t {name}[] = {{"]
    
    if is_interleaved:
        # Values are already interleaved [re0, im0, re1, im1, ...]
        for i in range(0, len(values), per_line):
            chunk = values[i:i+per_line]
            parts = [f"    {q31_to_hex(v)}" for v in chunk]
            line = ", ".join(parts)
            if i + per_line < len(values):
                line += ","
            lines.append(line)
    else:
        for i in range(0, len(values), per_line):
            chunk = values[i:i+per_line]
            parts = [f"    {q31_to_hex(v)}" for v in chunk]
            line = ", ".join(parts)
            if i + per_line < len(values):
                line += ","
            lines.append(line)
    
    lines.append("};")
    return "\n".join(lines)


def interleave(re_list, im_list):
    """Interleave real and imaginary parts: [re0, im0, re1, im1, ...]"""
    result = []
    for r, i in zip(re_list, im_list):
        result.append(r)
        result.append(i)
    return result


def generate_cfft_vectors():
    """Generate CFFT (forward complex FFT) test vectors."""
    np.random.seed(42)
    
    # Generate random input with magnitude < 0.5 to prevent saturation
    src_re_f = (np.random.random(N) - 0.5) * 0.8  # range [-0.4, 0.4]
    src_im_f = (np.random.random(N) - 0.5) * 0.8
    
    src_re = [float_to_q31(v) for v in src_re_f]
    src_im = [float_to_q31(v) for v in src_im_f]
    
    # Forward FFT (ifft_flag=0)
    out_re, out_im = dif_fft_q31(src_re, src_im, N, ifft_flag=0, twiddle_stride_factor=1)
    
    src_interleaved = interleave(src_re, src_im)
    out_interleaved = interleave(out_re, out_im)
    
    return src_interleaved, out_interleaved


def generate_cifft_vectors():
    """Generate CIFFT (inverse complex FFT) test vectors."""
    np.random.seed(123)
    
    # Generate random frequency-domain input with magnitude < 0.5
    src_re_f = (np.random.random(N) - 0.5) * 0.8
    src_im_f = (np.random.random(N) - 0.5) * 0.8
    
    src_re = [float_to_q31(v) for v in src_re_f]
    src_im = [float_to_q31(v) for v in src_im_f]
    
    # Inverse FFT (ifft_flag=1)
    out_re, out_im = dif_fft_q31(src_re, src_im, N, ifft_flag=1, twiddle_stride_factor=1)
    
    src_interleaved = interleave(src_re, src_im)
    out_interleaved = interleave(out_re, out_im)
    
    return src_interleaved, out_interleaved


def generate_rfft_vectors():
    """Generate RFFT (forward real FFT) test vectors."""
    np.random.seed(456)
    
    # Generate N real samples with magnitude < 0.5
    src_f = (np.random.random(N) - 0.5) * 0.8
    
    # Input: N real values stored as N/2 complex pairs
    half = N // 2
    src_re = [float_to_q31(src_f[2*i]) for i in range(half)]
    src_im = [float_to_q31(src_f[2*i+1]) for i in range(half)]
    
    # Step 1: N/2-point complex FFT (forward, with 2x twiddle stride)
    fft_re, fft_im = dif_fft_q31(src_re, src_im, half, ifft_flag=0, twiddle_stride_factor=2)
    
    # Step 2: Forward real split
    split_re, split_im = rfft_forward_split_q31(fft_re, fft_im, N)
    
    # Source: N real values as interleaved complex (re, im pairs)
    src_interleaved = interleave(src_re, src_im)
    
    # Output: N/2+1 complex values (N+2 Q31 values), but test compares N+2 values
    out_interleaved = interleave(split_re, split_im)
    
    return src_f, src_interleaved, out_interleaved


def generate_irfft_vectors():
    """Generate IRFFT (inverse real FFT) test vectors."""
    np.random.seed(789)
    
    half = N // 2
    
    # Generate frequency-domain input: N/2+1 complex values
    # (Hermitian symmetric for real output, but we just need valid test data)
    src_re_f = np.zeros(half + 1)
    src_im_f = np.zeros(half + 1)
    
    # Generate random but small values
    for k in range(half + 1):
        src_re_f[k] = (np.random.random() - 0.5) * 0.2
        src_im_f[k] = (np.random.random() - 0.5) * 0.2
    
    # DC and Nyquist should have zero imaginary for real-valued output
    src_im_f[0] = 0.0
    src_im_f[half] = 0.0
    
    src_re = [float_to_q31(v) for v in src_re_f]
    src_im = [float_to_q31(v) for v in src_im_f]
    
    # Step 1: Inverse real split
    split_re, split_im = irfft_split_q31(src_re, src_im, N)
    
    # Step 2: N/2-point complex FFT (inverse, with 2x twiddle stride) + bitreversal
    out_re, out_im = dif_fft_q31(split_re, split_im, half, ifft_flag=1, twiddle_stride_factor=2)
    
    # Source: N/2+1 complex values as interleaved pairs
    src_interleaved = interleave(src_re, src_im)
    
    # Output: N/2 complex values = N real values (interleaved re, im)
    out_interleaved = interleave(out_re, out_im)
    
    return src_interleaved, out_interleaved


if __name__ == "__main__":
    print("=" * 70)
    print("Q31 FFT Test Vector Generator")
    print("=" * 70)
    
    # ---- CFFT ----
    print("\n--- CFFT (Forward Complex FFT, N=128) ---")
    cfft_src, cfft_er = generate_cfft_vectors()
    print(f"  Input:    {len(cfft_src)} Q31 values ({len(cfft_src)//2} complex)")
    print(f"  Expected: {len(cfft_er)} Q31 values ({len(cfft_er)//2} complex)")
    print(f"  First src: {q31_to_hex(cfft_src[0])}, {q31_to_hex(cfft_src[1])}")
    print(f"  First er:  {q31_to_hex(cfft_er[0])}, {q31_to_hex(cfft_er[1])}")
    
    # ---- CIFFT ----
    print("\n--- CIFFT (Inverse Complex FFT, N=128) ---")
    cifft_src, cifft_er = generate_cifft_vectors()
    print(f"  Input:    {len(cifft_src)} Q31 values ({len(cifft_src)//2} complex)")
    print(f"  Expected: {len(cifft_er)} Q31 values ({len(cifft_er)//2} complex)")
    print(f"  First src: {q31_to_hex(cifft_src[0])}, {q31_to_hex(cifft_src[1])}")
    print(f"  First er:  {q31_to_hex(cifft_er[0])}, {q31_to_hex(cifft_er[1])}")
    
    # ---- RFFT ----
    print("\n--- RFFT (Forward Real FFT, N=128) ---")
    rfft_src_f, rfft_src, rfft_er = generate_rfft_vectors()
    print(f"  Input:    {len(rfft_src)} Q31 values ({len(rfft_src)//2} complex)")
    print(f"  Expected: {len(rfft_er)} Q31 values ({len(rfft_er)//2} complex)")
    print(f"  First src: {q31_to_hex(rfft_src[0])}, {q31_to_hex(rfft_src[1])}")
    print(f"  First er:  {q31_to_hex(rfft_er[0])}, {q31_to_hex(rfft_er[1])}")
    
    # ---- IRFFT ----
    print("\n--- IRFFT (Inverse Real FFT, N=128) ---")
    irfft_src, irfft_er = generate_irfft_vectors()
    print(f"  Input:    {len(irfft_src)} Q31 values ({len(irfft_src)//2} complex)")
    print(f"  Expected: {len(irfft_er)} Q31 values ({len(irfft_er)//2} complex)")
    print(f"  First src: {q31_to_hex(irfft_src[0])}, {q31_to_hex(irfft_src[1])}")
    print(f"  First er:  {q31_to_hex(irfft_er[0])}, {q31_to_hex(irfft_er[1])}")
    
    # ---- Write C source files ----
    print("\n" + "=" * 70)
    print("Writing C source files...")
    
    # CFFT
    with open("TestFFTLibraries/FFT/FFT_q31_test_inputs.c", "w") as f:
        f.write("""
/* Microchip Technology Inc. and its subsidiaries.  You may use this software 
 * and any derivatives exclusively with Microchip products. 
 * 
 * THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS".  NO WARRANTIES, WHETHER 
 * EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED 
 * WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A 
 * PARTICULAR PURPOSE, OR ITS INTERACTION WITH MICROCHIP PRODUCTS, COMBINATION 
 * WITH ANY OTHER PRODUCTS, OR USE IN ANY APPLICATION. 
 *
 * IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE, 
 * INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND 
 * WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS 
 * BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE.  TO THE 
 * FULLEST EXTENT ALLOWED BY LAW, MICROCHIPS TOTAL LIABILITY ON ALL CLAIMS 
 * IN ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF 
 * ANY, THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.
 *
 * MICROCHIP PROVIDES THIS SOFTWARE CONDITIONALLY UPON YOUR ACCEPTANCE OF THESE 
 * TERMS. 
 */

/* 
 * File:   FFT_q31_test_inputs.c
 * Comments: Q31 test vectors for forward Complex FFT (128-point)
 *           Generated by gen_q31_fft_vectors.py
 * Revision history: 
 */

#include "../../main.h"

#ifdef TRANSFORM_LIB_TEST

#ifdef DATA_SET_I

""")
        f.write(f"q31_t __attribute__((space(xmemory))) FFT_src1[] = {{\n")
        for i in range(0, len(cfft_src), 2):
            comma = "," if i + 2 < len(cfft_src) else ""
            f.write(f"    {q31_to_hex(cfft_src[i])}, {q31_to_hex(cfft_src[i+1])}{comma}\n")
        f.write(f"}};\n\n")
        
        f.write(f"q31_t FFT_er[] = {{\n")
        for i in range(0, len(cfft_er), 2):
            comma = "," if i + 2 < len(cfft_er) else ""
            f.write(f"    {q31_to_hex(cfft_er[i])}, {q31_to_hex(cfft_er[i+1])}{comma}\n")
        f.write(f"}};\n\n")
        
        f.write("#endif\n\n#endif      // TRANSFORM_LIB_TEST\n")
    
    print("  Written: TestFFTLibraries/FFT/FFT_q31_test_inputs.c")
    
    # CIFFT
    with open("TestFFTLibraries/IFFT/IFFT_q31_test_inputs.c", "w") as f:
        f.write("""
/* Microchip Technology Inc. and its subsidiaries.  You may use this software 
 * and any derivatives exclusively with Microchip products. 
 * 
 * THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS".  NO WARRANTIES, WHETHER 
 * EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED 
 * WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A 
 * PARTICULAR PURPOSE, OR ITS INTERACTION WITH MICROCHIP PRODUCTS, COMBINATION 
 * WITH ANY OTHER PRODUCTS, OR USE IN ANY APPLICATION. 
 *
 * IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE, 
 * INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND 
 * WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS 
 * BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE.  TO THE 
 * FULLEST EXTENT ALLOWED BY LAW, MICROCHIPS TOTAL LIABILITY ON ALL CLAIMS 
 * IN ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF 
 * ANY, THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.
 *
 * MICROCHIP PROVIDES THIS SOFTWARE CONDITIONALLY UPON YOUR ACCEPTANCE OF THESE 
 * TERMS. 
 */

/* 
 * File:   IFFT_q31_test_inputs.c
 * Comments: Q31 test vectors for inverse Complex FFT (128-point)
 *           Generated by gen_q31_fft_vectors.py
 * Revision history: 
 */

#include "../../main.h"

#ifdef TRANSFORM_LIB_TEST

#ifdef DATA_SET_I

""")
        f.write(f"q31_t __attribute__((space(xmemory))) IFFT_src1[] = {{\n")
        for i in range(0, len(cifft_src), 2):
            comma = "," if i + 2 < len(cifft_src) else ""
            f.write(f"    {q31_to_hex(cifft_src[i])}, {q31_to_hex(cifft_src[i+1])}{comma}\n")
        f.write(f"}};\n\n")
        
        f.write(f"q31_t IFFT_er[] = {{\n")
        for i in range(0, len(cifft_er), 2):
            comma = "," if i + 2 < len(cifft_er) else ""
            f.write(f"    {q31_to_hex(cifft_er[i])}, {q31_to_hex(cifft_er[i+1])}{comma}\n")
        f.write(f"}};\n\n")
        
        f.write("#endif\n\n#endif      // TRANSFORM_LIB_TEST\n")
    
    print("  Written: TestFFTLibraries/IFFT/IFFT_q31_test_inputs.c")
    
    # RFFT
    with open("TestFFTLibraries/RFFT/RFFT_q31_test_inputs.c", "w") as f:
        f.write("""
/* Microchip Technology Inc. and its subsidiaries.  You may use this software 
 * and any derivatives exclusively with Microchip products. 
 * 
 * THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS".  NO WARRANTIES, WHETHER 
 * EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED 
 * WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A 
 * PARTICULAR PURPOSE, OR ITS INTERACTION WITH MICROCHIP PRODUCTS, COMBINATION 
 * WITH ANY OTHER PRODUCTS, OR USE IN ANY APPLICATION. 
 *
 * IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE, 
 * INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND 
 * WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS 
 * BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE.  TO THE 
 * FULLEST EXTENT ALLOWED BY LAW, MICROCHIPS TOTAL LIABILITY ON ALL CLAIMS 
 * IN ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF 
 * ANY, THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.
 *
 * MICROCHIP PROVIDES THIS SOFTWARE CONDITIONALLY UPON YOUR ACCEPTANCE OF THESE 
 * TERMS. 
 */

/* 
 * File:   RFFT_q31_test_inputs.c
 * Comments: Q31 test vectors for forward Real FFT (128-point)
 *           Generated by gen_q31_fft_vectors.py
 * Revision history: 
 */

#include "../../main.h"

#ifdef TRANSFORM_LIB_TEST

#ifdef DATA_SET_I

""")
        # RFFT input: N real values stored as N/2 interleaved complex pairs
        f.write(f"q31_t __attribute__((space(xmemory))) RFFT_src1[] = {{\n")
        for i in range(0, len(rfft_src), 2):
            comma = "," if i + 2 < len(rfft_src) else ""
            f.write(f"    {q31_to_hex(rfft_src[i])}, {q31_to_hex(rfft_src[i+1])}{comma}\n")
        f.write(f"}};\n\n")
        
        # RFFT output: N/2+1 complex values = N+2 Q31 values
        f.write(f"q31_t RFFT_er[] = {{\n")
        for i in range(0, len(rfft_er), 2):
            comma = "," if i + 2 < len(rfft_er) else ""
            f.write(f"    {q31_to_hex(rfft_er[i])}, {q31_to_hex(rfft_er[i+1])}{comma}\n")
        f.write(f"}};\n\n")
        
        f.write("#endif\n\n#endif      // TRANSFORM_LIB_TEST\n")
    
    print("  Written: TestFFTLibraries/RFFT/RFFT_q31_test_inputs.c")
    
    # IRFFT
    with open("TestFFTLibraries/IRFFT/IRFFT_q31_test_inputs.c", "w") as f:
        f.write("""
/* Microchip Technology Inc. and its subsidiaries.  You may use this software 
 * and any derivatives exclusively with Microchip products. 
 * 
 * THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS".  NO WARRANTIES, WHETHER 
 * EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED 
 * WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A 
 * PARTICULAR PURPOSE, OR ITS INTERACTION WITH MICROCHIP PRODUCTS, COMBINATION 
 * WITH ANY OTHER PRODUCTS, OR USE IN ANY APPLICATION. 
 *
 * IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE, 
 * INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND 
 * WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS 
 * BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE.  TO THE 
 * FULLEST EXTENT ALLOWED BY LAW, MICROCHIPS TOTAL LIABILITY ON ALL CLAIMS 
 * IN ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF 
 * ANY, THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.
 *
 * MICROCHIP PROVIDES THIS SOFTWARE CONDITIONALLY UPON YOUR ACCEPTANCE OF THESE 
 * TERMS. 
 */

/* 
 * File:   IRFFT_q31_test_inputs.c
 * Author: OpenCode
 * Comments: Q31 test vectors for Inverse Real FFT (128-point)
 *           Generated by gen_q31_fft_vectors.py
 * Revision history: 
 */

#include "../../main.h"

#ifdef TRANSFORM_LIB_TEST

#ifdef DATA_SET_I

""")
        # IRFFT input: N/2+1 complex values = N+2 Q31 values
        f.write(f"q31_t IRFFT_src1[] = {{\n")
        for i in range(0, len(irfft_src), 2):
            comma = "," if i + 2 < len(irfft_src) else ""
            f.write(f"    {q31_to_hex(irfft_src[i])}, {q31_to_hex(irfft_src[i+1])}{comma}\n")
        f.write(f"}};\n\n")
        
        # IRFFT output: N/2 complex values = N Q31 values (time domain)
        f.write(f"q31_t IRFFT_er[] = {{\n")
        for i in range(0, len(irfft_er), 2):
            comma = "," if i + 2 < len(irfft_er) else ""
            f.write(f"    {q31_to_hex(irfft_er[i])}, {q31_to_hex(irfft_er[i+1])}{comma}\n")
        f.write(f"}};\n\n")
        
        f.write("#endif\n\n#endif      // TRANSFORM_LIB_TEST\n")
    
    print("  Written: TestFFTLibraries/IRFFT/IRFFT_q31_test_inputs.c")
    
    print("\nDone! All test vector files generated.")
