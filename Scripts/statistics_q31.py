"""
Statistics Test Vector Generator (Q31 Format)
Generates test vectors for all 6 statistics functions:
max, min, mean, power, variance, standard deviation.
Uses dsPIC33AK DSP engine model where relevant.
Power uses sacr.l; Mean/Variance use sac.l (truncation).
Min/Max are pure integer comparisons (no DSP).
"""

import numpy as np
import os
from helper_q31 import *
from dspic_q31_model import DspAccumulator, to_signed32, sat_q31

try:
    import cmsisdsp as dsp
except:
    dsp = None

MCHP_LICENSE = """/*
Copyright 2026 Microchip Technology Inc. and its subsidiaries.

    Subject to your compliance with these terms, you may use Microchip 
    software and any derivatives exclusively with Microchip products. 
    You are responsible for complying with 3rd party license terms  
    applicable to your use of 3rd party software (including open source  
    software) that may accompany Microchip software. SOFTWARE IS AS IS. 
    NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS 
    SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,  
    MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT 
    WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE, 
    INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY 
    KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF 
    MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE 
    FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIPS 
    TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT 
    EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR 
    THIS SOFTWARE.
*/
"""

test_to_template = {
    "vmax_q31_test_inputs": MCHP_LICENSE + """
#include "../../main.h"
#include "VMAX_q31.h"

#ifdef STATISTICS_LIB_TEST

q31_t VMAX_Q31_INPUT[] = {
    <<INSERT_IS_HERE>>
};

q31_t VMAX_Q31_EXPECTED_VALUE = <<INSERT_EXPECTED_VALUE_HERE>>;

uint32_t VMAX_Q31_EXPECTED_INDEX = <<INSERT_EXPECTED_INDEX_HERE>>;

#endif
""",
    "vmin_q31_test_inputs": MCHP_LICENSE + """
#include "../../main.h"
#include "VMIN_q31.h"

#ifdef STATISTICS_LIB_TEST

q31_t VMIN_Q31_INPUT[] = {
    <<INSERT_IS_HERE>>
};

q31_t VMIN_Q31_EXPECTED_VALUE = <<INSERT_EXPECTED_VALUE_HERE>>;

uint32_t VMIN_Q31_EXPECTED_INDEX = <<INSERT_EXPECTED_INDEX_HERE>>;

#endif
""",
    "vmean_q31_test_inputs": MCHP_LICENSE + """
#include "../../main.h"
#include "VMEAN_q31.h"

#ifdef STATISTICS_LIB_TEST

q31_t VMEAN_Q31_INPUT[] = {
    <<INSERT_IS_HERE>>
};

q31_t VMEAN_Q31_EXPECTED_VALUE = <<INSERT_EXPECTED_VALUE_HERE>>;

#endif
""",
    "vpow_q31_test_inputs": MCHP_LICENSE + """
#include "../../main.h"
#include "VPOW_q31.h"

#ifdef STATISTICS_LIB_TEST

q31_t VPOW_Q31_INPUT[] = {
    <<INSERT_IS_HERE>>
};

q63_t VPOW_Q31_EXPECTED_VALUE = <<INSERT_EXPECTED_VALUE_HERE>>;

#endif
""",
    "vvar_q31_test_inputs": MCHP_LICENSE + """
#include "../../main.h"
#include "VVAR_q31.h"

#ifdef STATISTICS_LIB_TEST

q31_t VVAR_Q31_INPUT[] = {
    <<INSERT_IS_HERE>>
};

q31_t VVAR_Q31_EXPECTED_VALUE = <<INSERT_EXPECTED_VALUE_HERE>>;

#endif
""",
    "vstd_q31_test_inputs": MCHP_LICENSE + """
#include "../../main.h"
#include "VSTD_q31.h"

#ifdef STATISTICS_LIB_TEST

q31_t VSTD_Q31_INPUT[] = {
    <<INSERT_IS_HERE>>
};

q31_t VSTD_Q31_EXPECTED_VALUE = <<INSERT_EXPECTED_VALUE_HERE>>;

#endif
""",
}


def format_q31_hex(val):
    """Format a single Q31 value as 0xHHHHHHHH hex literal."""
    uval = int(val) & 0xFFFFFFFF
    return f"0x{uval:08X}"


def format_q63_hex(val):
    """Format a Q63 (64-bit) value as 0xHHHHHHHHHHHHHHHHLL hex literal."""
    uval = int(val) & 0xFFFFFFFFFFFFFFFF
    return f"0x{uval:016X}LL"


def dspic_max_q31(input_q31):
    """Find max value and index (pure integer comparison, matches ARM)."""
    max_val = to_signed32(input_q31[0])
    max_idx = 0
    for i in range(1, len(input_q31)):
        val = to_signed32(input_q31[i])
        if val > max_val:
            max_val = val
            max_idx = i
    return max_val, max_idx


def dspic_min_q31(input_q31):
    """Find min value and index (pure integer comparison, matches ARM)."""
    min_val = to_signed32(input_q31[0])
    min_idx = 0
    for i in range(1, len(input_q31)):
        val = to_signed32(input_q31[i])
        if val < min_val:
            min_val = val
            min_idx = i
    return min_val, min_idx


def dspic_mean_q31(input_q31):
    """Mean: sum all values then divide by N.
    Assembly accumulates 64-bit sum in register pair, then converts to
    double-precision float via hardware FPU, divides by N (div.d), and
    converts back to int32 via f2li.d (round-to-nearest-even per FCR)."""
    acc = 0
    for x in input_q31:
        acc += to_signed32(x)
    N = len(input_q31)
    # FPU division: sum converted to double, divided by N, f2li.d rounds to nearest even
    result = int(np.round(float(acc) / N))
    return sat_q31(result)


def dspic_power_q31(input_q31):
    """Power: sum of squares. Assembly uses clr a + sqrac.l loop.
    Returns q63_t (64-bit): full accumulator bits[63:0] via ACCAL + sac.l.
    sqrac.l is equivalent to mac(x,x) = acc += (x*x)<<1 in fractional mode."""
    acc = DspAccumulator()
    for x in input_q31:
        xs = to_signed32(x)
        acc.mac(xs, xs)
    # Return raw accumulator bits[63:0] as q63_t
    return acc.value


def dspic_var_q31(input_q31):
    """Variance: uses sac.l (truncation) for mean, then mpy.l/add a for sum of sq diffs.
    Assembly: sub.l for diff, mpy.l w7,w7,b + add a to accumulate, sac.l + divsl."""
    N = len(input_q31)
    # Step 1: compute mean (sac.l + divide)
    mean = dspic_mean_q31(input_q31)

    # Step 2: sum of (x[i] - mean)^2 using mpy into accB, add a (accA += accB)
    acc = DspAccumulator()
    for x in input_q31:
        diff = to_signed32(x) - mean
        diff = sat_q31(diff)  # sub.l saturates to 32-bit
        acc.mac(diff, diff)   # mpy.l + add a equivalent

    # Step 3: divide by (N-1) — extract via sac.l (truncation, not rounding)
    # divsl truncates toward zero
    sum_sq = acc.sac()
    result = int(sum_sq / (N - 1)) if N > 1 else 0  # truncation toward zero
    return sat_q31(result)


def dspic_std_q31(input_q31):
    """Standard deviation: sqrt(variance). Uses integer sqrt on Q31."""
    var_val = dspic_var_q31(input_q31)
    if var_val <= 0:
        return 0
    # Q31 sqrt: convert to float, sqrt, convert back
    var_float = float(var_val) / (2**31)
    std_float = np.sqrt(var_float)
    return sat_q31(int(np.round(std_float * (2**31))))


def statistics_q31(seed=42):
    """Generate test vectors for all 6 statistics functions."""
    print("\n\n Generating Statistics Q31 Test Data: ")

    np.random.seed(seed)
    block_size = 128

    # Generate random input in Q31 range
    input_f = np.random.uniform(-0.9, 0.9, block_size).astype(np.float32)
    input_q31 = float_array_to_q31(input_f)

    input_c_array = c_array_q31(input_q31)

    # ---- Max ----
    max_val, max_idx = dspic_max_q31(input_q31)
    output_str = test_to_template["vmax_q31_test_inputs"]
    output_str = output_str.replace("<<INSERT_IS_HERE>>", input_c_array)
    output_str = output_str.replace("<<INSERT_EXPECTED_VALUE_HERE>>", format_q31_hex(max_val))
    output_str = output_str.replace("<<INSERT_EXPECTED_INDEX_HERE>>", str(int(max_idx)))
    replace_test_file("vmax_q31_test_inputs", output_str)
    print("  Generated VMAX Q31 test inputs")

    # ---- Min ----
    min_val, min_idx = dspic_min_q31(input_q31)
    output_str = test_to_template["vmin_q31_test_inputs"]
    output_str = output_str.replace("<<INSERT_IS_HERE>>", input_c_array)
    output_str = output_str.replace("<<INSERT_EXPECTED_VALUE_HERE>>", format_q31_hex(min_val))
    output_str = output_str.replace("<<INSERT_EXPECTED_INDEX_HERE>>", str(int(min_idx)))
    replace_test_file("vmin_q31_test_inputs", output_str)
    print("  Generated VMIN Q31 test inputs")

    # ---- Mean ----
    mean_val = dspic_mean_q31(input_q31)
    output_str = test_to_template["vmean_q31_test_inputs"]
    output_str = output_str.replace("<<INSERT_IS_HERE>>", input_c_array)
    output_str = output_str.replace("<<INSERT_EXPECTED_VALUE_HERE>>", format_q31_hex(mean_val))
    replace_test_file("vmean_q31_test_inputs", output_str)
    print("  Generated VMEAN Q31 test inputs")

    # ---- Power (returns q63_t) ----
    power_val = dspic_power_q31(input_q31)
    output_str = test_to_template["vpow_q31_test_inputs"]
    output_str = output_str.replace("<<INSERT_IS_HERE>>", input_c_array)
    output_str = output_str.replace("<<INSERT_EXPECTED_VALUE_HERE>>", format_q63_hex(power_val))
    replace_test_file("vpow_q31_test_inputs", output_str)
    print("  Generated VPOW Q31 test inputs")

    # ---- Variance ----
    var_val = dspic_var_q31(input_q31)
    output_str = test_to_template["vvar_q31_test_inputs"]
    output_str = output_str.replace("<<INSERT_IS_HERE>>", input_c_array)
    output_str = output_str.replace("<<INSERT_EXPECTED_VALUE_HERE>>", format_q31_hex(var_val))
    replace_test_file("vvar_q31_test_inputs", output_str)
    print("  Generated VVAR Q31 test inputs")

    # ---- Standard Deviation ----
    std_val = dspic_std_q31(input_q31)
    output_str = test_to_template["vstd_q31_test_inputs"]
    output_str = output_str.replace("<<INSERT_IS_HERE>>", input_c_array)
    output_str = output_str.replace("<<INSERT_EXPECTED_VALUE_HERE>>", format_q31_hex(std_val))
    replace_test_file("vstd_q31_test_inputs", output_str)
    print("  Generated VSTD Q31 test inputs")

    print("\n\n Done Generating Statistics Q31 Test Data")


if __name__ == "__main__":
    statistics_q31()
