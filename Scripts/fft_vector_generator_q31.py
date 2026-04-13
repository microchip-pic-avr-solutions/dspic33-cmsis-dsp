"""
FFT / IFFT Test Vector Generator for C Code (Q31 Format)
---------------------------------------------------------
This script generates random Q31 fixed-point test data for FFT and IFFT
operations using NumPy and prints them in a C-compatible array format
so they can be copy-pasted directly into embedded C source files.

Generated outputs:
- Input vector (real and imaginary interleaved, Q31)
- Expected FFT output vector (real and imaginary interleaved, Q31)
- Expected IFFT output vector (real and imaginary interleaved, Q31)

Author: Adapted from f32 version (Author: I78279)
"""

import numpy as np
from helper_q31 import *

# ============================================================
# Global scaling — keep values in [-1.0, +1.0) for Q31
# ============================================================
gSCL_VAL = 0.5       # Scale factor (keep small to avoid overflow)
gOFFSET_VAL = 0.25    # Offset to center around zero

# Global lists
FFT_srcG = []
FFT_er = []
IFFT_er = []


def c_array_interleaved_q31(arr):
    """Format interleaved Q31 array for C."""
    parts = []
    for val in arr:
        ival = float_to_q31(val)
        uval = int(ival) & 0xFFFFFFFF
        parts.append(f"0x{uval:08X}")
    return ", ".join(parts)


# ============================================================
# FFT Test Vector Generation (Q31)
# ============================================================
def FFT_Q31():
    print("\n\n FFT Q31 Test : ")
    N = 128  # FFT size

    # Generate random float values in [-1.0, +1.0) range
    FFT_srcG_real = (gSCL_VAL * np.random.random_sample(N) - gOFFSET_VAL)
    FFT_srcG_imag = (gSCL_VAL * np.random.random_sample(N) - gOFFSET_VAL)

    # Clip to Q31 representable range
    FFT_srcG_real = np.clip(FFT_srcG_real, -1.0, 1.0 - 1.0/(2**31))
    FFT_srcG_imag = np.clip(FFT_srcG_imag, -1.0, 1.0 - 1.0/(2**31))

    # Build complex input
    FFT_srcG = FFT_srcG_real + 1j * FFT_srcG_imag

    # Compute FFT (in float domain, then convert)
    FFT_result = np.fft.fft(FFT_srcG)
    # Scale FFT result by 1/N to keep within Q31 range
    FFT_result_scaled = FFT_result / N

    # Compute IFFT
    IFFT_result = np.fft.ifft(FFT_result)

    # Interleave real and imaginary parts for input
    src_interleaved = []
    for i in range(N):
        src_interleaved.append(FFT_srcG_real[i])
        src_interleaved.append(FFT_srcG_imag[i])

    # Interleave FFT result (scaled)
    fft_interleaved = []
    for i in range(N):
        fft_interleaved.append(FFT_result_scaled[i].real)
        fft_interleaved.append(FFT_result_scaled[i].imag)

    # Interleave IFFT result
    ifft_interleaved = []
    for i in range(N):
        ifft_interleaved.append(IFFT_result[i].real)
        ifft_interleaved.append(IFFT_result[i].imag)

    # Convert to Q31
    src_q31 = float_array_to_q31(np.array(src_interleaved))
    fft_q31 = float_array_to_q31(np.array(fft_interleaved))
    ifft_q31 = float_array_to_q31(np.array(ifft_interleaved))

    # Print C arrays
    print(f"\n// FFT Q31 Input ({N} complex samples, {2*N} Q31 values)")
    print(f"#define FFT_Q31_SIZE {N}")
    print(f"const q31_t fft_q31_input[{2*N}] = {{")
    print(f"    {c_array_q31(src_q31)}")
    print("};")

    print(f"\n// FFT Q31 Expected Output ({N} complex samples, {2*N} Q31 values)")
    print(f"const q31_t fft_q31_expected_output[{2*N}] = {{")
    print(f"    {c_array_q31(fft_q31)}")
    print("};")

    print(f"\n// IFFT Q31 Expected Output ({N} complex samples, {2*N} Q31 values)")
    print(f"const q31_t ifft_q31_expected_output[{2*N}] = {{")
    print(f"    {c_array_q31(ifft_q31)}")
    print("};")

    return src_q31, fft_q31, ifft_q31


# ============================================================
if __name__ == "__main__":
    FFT_Q31()