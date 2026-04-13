"""
Window Q31 Test Vector Generator
=================================
Generates Q31 expected values for Hanning, Hamming, and Bartlett windows,
matching the single-precision float computation in the C implementations.

The C code uses float32_t (32-bit float) for all intermediate computations,
so we must use numpy.float32 to reproduce the exact same rounding.
"""

import numpy as np
import struct
import os

N = 128  # blockSize

# Constants from mchp_math_types.h
HANN_0 = np.float32(0.50)
HANN_1 = np.float32(-0.50)
HAMM_0 = np.float32(0.54)
HAMM_1 = np.float32(-0.46)
BART_0 = np.float32(2.0)
PI = np.float32(np.pi)
SCALE = np.float32(2147483648.0)


def float32_to_q31_c(fval):
    """Convert a float32 value to Q31 integer, matching C (q31_t) cast.
    
    C cast: (q31_t)(fval * 2147483648.0f)
    On dsPIC33AK, this is a truncation toward zero, with saturation
    at 0x7FFFFFFF for values >= 1.0.
    """
    product = float(np.float32(fval) * SCALE)
    # Clamp to int32 range (C behavior: overflow wraps, but the values
    # produced by window functions are in [0, 1.0] so the only overflow
    # case is exactly 1.0 which maps to 0x7FFFFFFF on the hardware).
    if product >= 2147483647.0:
        return 0x7FFFFFFF
    elif product <= -2147483648.0:
        return -2147483648
    else:
        return int(product)


def generate_hanning_q31(n):
    """Match mchp_hanning_q31.c exactly using float32 arithmetic."""
    # C code:
    #   float32_t arg = 2.0*PI/((float)blockSize);
    #   val = (HANN_0 + HANN_1*cos((arg*(float32_t)cntr))) * 2147483648.0f;
    arg = np.float32(np.float32(2.0) * PI / np.float32(float(n)))
    result = []
    for i in range(n):
        cos_val = np.float32(np.cos(np.float32(arg * np.float32(float(i)))))
        val = np.float32(HANN_0 + np.float32(HANN_1 * cos_val))
        result.append(float32_to_q31_c(val))
    return result


def generate_hamming_q31(n):
    """Match mchp_hamming_q31.c exactly using float32 arithmetic."""
    # C code:
    #   float32_t arg = 2.0f * PI/((double)blockSize);
    #   val = (HAMM_0 + HAMM_1*cos((float32_t)arg*cntr)) * 2147483648.0f;
    #
    # Note: the C code has a subtle mix:
    #   arg = 2.0f * PI / ((double)blockSize)
    # The (double) cast means the division is done in double precision,
    # but the result is stored in float32_t arg. Let's match that.
    arg_double = 2.0 * float(PI) / float(n)  # double precision division
    arg = np.float32(arg_double)              # truncated to float32
    result = []
    for i in range(n):
        cos_arg = np.float32(np.float32(arg) * np.float32(float(i)))
        cos_val = np.float32(np.cos(cos_arg))
        val = np.float32(HAMM_0 + np.float32(HAMM_1 * cos_val))
        result.append(float32_to_q31_c(val))
    return result


def generate_bartlett_q31(n):
    """Match mchp_bartlett_q31.c exactly using float32 arithmetic."""
    # C code:
    #   float32_t arg = BART_0 / ((float32_t)(blockSize));
    #   Rising: val = (arg * (float32_t)cntr) * 2147483648.0f
    #   Falling: val = (BART_0 - arg * (float32_t)cntr) * 2147483648.0f
    arg = np.float32(BART_0 / np.float32(float(n)))
    result = []
    # Rising slope: 0 to n/2 (inclusive)
    for i in range(n // 2 + 1):
        val = np.float32(arg * np.float32(float(i)))
        result.append(float32_to_q31_c(val))
    # Falling slope: n/2+1 to n-1
    for i in range(n // 2 + 1, n):
        val = np.float32(BART_0 - np.float32(arg * np.float32(float(i))))
        result.append(float32_to_q31_c(val))
    return result


def format_q31_array(name, data):
    """Format as a C array."""
    hex_vals = []
    for v in data:
        hex_vals.append("0x%08X" % (v & 0xFFFFFFFF))
    return "q31_t %s[] = {%s};" % (name, ", ".join(hex_vals))


def write_test_file(filepath, guard, array_name, data):
    """Write a complete test inputs C file."""
    lines = []
    lines.append("/*")
    lines.append("  [2026] Microchip Technology Inc. and its subsidiaries.")
    lines.append("")
    lines.append("    Subject to your compliance with these terms, you may use Microchip ")
    lines.append("    software and any derivatives exclusively with Microchip products. ")
    lines.append("    You are responsible for complying with 3rd party license terms  ")
    lines.append("    applicable to your use of 3rd party software (including open source  ")
    lines.append("    software) that may accompany Microchip software. SOFTWARE IS AS IS. ")
    lines.append("    NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS ")
    lines.append("    SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,  ")
    lines.append("    MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT ")
    lines.append("    WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE, ")
    lines.append("    INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY ")
    lines.append("    KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF ")
    lines.append("    MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE ")
    lines.append("    FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIPS ")
    lines.append("    TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT ")
    lines.append("    EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR ")
    lines.append("    THIS SOFTWARE.")
    lines.append("*/")
    lines.append("")
    lines.append('#include "../../main.h"')
    lines.append("")
    lines.append("#ifdef WINDOW_LIB_TEST")
    lines.append("")
    lines.append(format_q31_array(array_name, data))
    lines.append("")
    lines.append("#endif")
    
    content = "\n".join(lines) + "\n"
    with open(filepath, "w") as f:
        f.write(content)
    print("  Written: %s" % filepath)


if __name__ == "__main__":
    print("Generating Window Q31 test vectors (N=%d)..." % N)
    
    # Generate all three windows
    hanning = generate_hanning_q31(N)
    hamming = generate_hamming_q31(N)
    bartlett = generate_bartlett_q31(N)
    
    print("  Hanning[0]  = 0x%08X, [64] = 0x%08X" % (hanning[0] & 0xFFFFFFFF, hanning[64] & 0xFFFFFFFF))
    print("  Hamming[0]  = 0x%08X, [64] = 0x%08X" % (hamming[0] & 0xFFFFFFFF, hamming[64] & 0xFFFFFFFF))
    print("  Bartlett[0] = 0x%08X, [64] = 0x%08X" % (bartlett[0] & 0xFFFFFFFF, bartlett[64] & 0xFFFFFFFF))
    
    # Paths
    base = os.path.join(os.getcwd(), "..", "Testing", "cmsis_mchp_dsp_api",
                        "cmsis_dsp_window_q31_test.X", "TestWindowLibraries")
    
    write_test_file(
        os.path.join(base, "HANNING", "HANNING_q31_test_inputs.c"),
        "WINDOW_LIB_TEST", "HANNING_Q31_er", hanning)
    
    write_test_file(
        os.path.join(base, "HAMMING", "HAMMING_q31_test_inputs.c"),
        "WINDOW_LIB_TEST", "HAMMING_Q31_er", hamming)
    
    write_test_file(
        os.path.join(base, "BARTLETT", "BARTLETT_q31_test_inputs.c"),
        "WINDOW_LIB_TEST", "BARTLETT_Q31_er", bartlett)
    
    print("\nDone! All window test vectors written.")
    print("\nRemember to copy files to C:\\CMSIS\\my_branch\\Testing\\...")
