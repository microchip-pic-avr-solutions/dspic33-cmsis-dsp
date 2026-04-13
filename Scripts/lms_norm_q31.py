"""
LMS Normalized Test Vector Generator (Q31 Format)
Uses dsPIC33AK DSP engine model for accurate expected values.
Assembly uses: sacr.l throughout for all extractions.
"""

import numpy as np
import os
from helper_q31 import *
from dspic_q31_model import DspAccumulator, to_signed32, sat_q31

test_to_template = {
    "fir_lms_norm_q31_test_inputs": """/*
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

#include "../../main.h"
#include "fir_lms_norm_q31_test.h"

#ifdef FILTER_LIB_TEST
#ifdef DATA_SET_I

q31_t FIR_LMS_NORM_Q31_INPUT[] = {
    <<INSERT_IS_HERE>>
};

q31_t FIR_LMS_NORM_Q31_DESIRED[] = {
    <<INSERT_DS_HERE>>
};

q31_t FIR_LMS_NORM_Q31_COEFF_INITIAL[] = {
    <<INSERT_COEFFS_INIT_HERE>>
};

q31_t FIR_LMS_NORM_Q31_OUTPUT_REF[] = {
    <<INSERT_OS_HERE>>
};

q31_t FIR_LMS_NORM_Q31_ERROR_REF[] = {
    <<INSERT_ES_HERE>>
};

q31_t FIR_LMS_NORM_Q31_COEFF_FINAL_REF[] = {
    <<INSERT_COEFFS_FINAL_HERE>>
};

q31_t FIR_LMS_NORM_Q31_STATE[FIR_LMS_NORM_Q31_BLOCK_SIZE+FIR_LMS_NORM_Q31_NUM_TAPS-1];

#endif
#endif
""",
    "fir_lms_norm_q31_test_header": """/*
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

#include "../../main.h"

#ifdef FILTER_LIB_TEST
#ifdef DATA_SET_I
#define FIR_LMS_NORM_Q31_BLOCK_SIZE <<INSERT_BLOCK_SIZE_HERE>>
#define FIR_LMS_NORM_Q31_NUM_TAPS <<INSERT_NUMTAPS_HERE>>
#define FIR_LMS_NORM_Q31_MU <<INSERT_MU_HERE>>
#define FIR_LMS_NORM_Q31_POSTSHIFT 0

extern q31_t FIR_LMS_NORM_Q31_INPUT[];
extern q31_t FIR_LMS_NORM_Q31_DESIRED[];
extern q31_t FIR_LMS_NORM_Q31_COEFF_INITIAL[];
extern q31_t FIR_LMS_NORM_Q31_OUTPUT_REF[];
extern q31_t FIR_LMS_NORM_Q31_ERROR_REF[];
extern q31_t FIR_LMS_NORM_Q31_COEFF_FINAL_REF[];
extern q31_t FIR_LMS_NORM_Q31_STATE[FIR_LMS_NORM_Q31_BLOCK_SIZE+FIR_LMS_NORM_Q31_NUM_TAPS-1];

#endif
#endif
"""
}


def dspic_divfl(num, den):
    """
    Model the dsPIC33AK divfl instruction (signed fractional divide).
    divfl Ws, Wt: divides Ws by Wt as signed 32-bit fractional values.
    Result is a Q31 fractional quotient.
    repeat #9 + divfl performs 10 iterations for 32-bit result.
    """
    if den == 0:
        return 0x7FFFFFFF if num >= 0 else -0x80000000
    # Fractional divide: result = (num / den) in Q31
    # Since both are Q31, result = num / den (same as integer divide with shift)
    result = (int(num) << 31) // int(den)
    result = max(-0x80000000, min(0x7FFFFFFF, result))
    return result


def lms_norm_q31_python(input_q31, desired_q31, coeffs_initial_q31, mu_q31):
    """
    dsPIC33AK LMS Normalized Q31 model matching mchp_lms_norm_q31.s.

    Follows firlmsn_aa.s reference exactly:
    - Energy: E[n] = E[n-1] + x[n]^2 - x[n-M+1]^2
      Computed via sqrac.l (pre-add x[n]^2), then sqr.l + sub (remove oldest)
    - FIR: mpy.l first + mac.l (forward walk through circular buffer)
    - Error: lac.l y[n]; lac.l r[n]; sub b → e[n]
    - nu = mu / (mu + E[n]) via divfl
    - attErr = nu * e[n] via mpy.l + sacr.l
    - Adaptation: lac.l h[m] + mac.l attErr*x[n-m] + sacr.l (forward walk)
    """
    num_taps = len(coeffs_initial_q31)
    M = num_taps
    block_size = len(input_q31)
    mu_signed = to_signed32(mu_q31)

    h = [to_signed32(c) for c in coeffs_initial_q31]
    input_signed = [to_signed32(x) for x in input_q31]
    desired_signed = [to_signed32(x) for x in desired_q31]

    # Circular delay buffer (forward-walking modulo, like firlms_aa.s)
    delay = [0] * M
    delay_idx = 0  # Current write position

    acc_a = DspAccumulator()
    acc_b = DspAccumulator()
    output = np.zeros(block_size, dtype=np.int32)
    error = np.zeros(block_size, dtype=np.int32)
    energy_q31 = 0  # Running energy estimate E[n], in Q31

    for n in range(block_size):
        # Step 1: Pre-add energy: b = E[n-1] + x[n]^2
        # Assembly: lac.l E[n-1], b; sqrac.l [w1], b
        acc_b.value = int(energy_q31) << 32
        x_n = input_signed[n]
        # sqrac.l: b += x[n]^2 (square-accumulate)
        acc_b.value += (int(x_n) * int(x_n)) << 1  # fractional multiply shift
        intermediate_energy = acc_b.sacr()

        # Step 2: Store x[n] in delay, first FIR product (forward walk)
        delay[delay_idx] = x_n
        read_idx = delay_idx

        # mpy.l h[0]*d[p]: first product
        acc_a.mpy(h[0], delay[read_idx])
        read_idx = (read_idx + 1) % M

        # Step 3: FIR middle MACs
        for m in range(1, M - 1):
            acc_a.mac(h[m], delay[read_idx])
            read_idx = (read_idx + 1) % M

        # Step 4: Capture oldest sample, last MAC
        # read_idx now at delay[p+M-1] = x[n-M+1]
        if M > 1:
            oldest = delay[read_idx]
            acc_a.mac(h[M - 1], delay[read_idx])
            read_idx = (read_idx + 1) % M  # wraps back to delay[p]
        else:
            oldest = delay[delay_idx]  # M==1: oldest is current

        # Step 5: y[n] = sacr.l a
        y_n = acc_a.sacr()
        output[n] = np.int32(y_n)

        # Step 6: Complete energy: E[n] = intermediate - x[n-M+1]^2
        # Assembly: sqr.l w5, b; lac.l intermediate, a; sub a; sacr.l a
        acc_b.mpy(oldest, oldest)  # b = oldest^2
        acc_a.value = int(intermediate_energy) << 32  # a = intermediate
        acc_a.value -= acc_b.value  # a -= b
        energy_q31 = acc_a.sacr()  # E[n]

        # Step 7: nu = mu / (mu + E[n])
        # Assembly: add.l w6, a; sacr.l a, w5 → w5 = mu+E[n]
        # NOTE: acc_a still holds full-precision E[n] from sub above.
        # sacr.l does NOT modify the accumulator, so add.l w6,a adds mu
        # to the full-precision value, not the rounded one.
        acc_a.value += int(mu_signed) << 32  # a += mu (full precision)
        denom = acc_a.sacr()  # mu + E[n]
        nu = dspic_divfl(mu_signed, denom)

        # Step 8: Error and attenuated error
        # e[n] = r[n] - y[n]
        acc_a.value = int(y_n) << 32
        acc_b.value = int(desired_signed[n]) << 32
        acc_b.value -= acc_a.value  # b = r[n] - y[n]
        e_n = acc_b.sacr()
        error[n] = np.int32(e_n)

        # attErr = nu * e[n]
        acc_a.mpy(e_n, nu)
        att_err = acc_a.sacr()

        # Step 9: Coefficient adaptation (forward walk, same as FIR)
        read_idx = delay_idx  # back to delay[p] (wrapped after FIR)
        for m in range(M):
            acc_a.value = int(h[m]) << 32
            acc_a.mac(att_err, delay[read_idx])
            h[m] = acc_a.sacr()
            read_idx = (read_idx + 1) % M

        # Advance write pointer (decrements, same as LMS)
        delay_idx = (delay_idx - 1) % M

    coeffs_final = np.array(h[:M], dtype=np.int32)
    return output, error, coeffs_final, energy_q31


def generate_lms_norm_test_data_q31(seed=42):
    block_size = 64
    num_taps = 8
    mu_f = 0.01

    if seed is not None:
        np.random.seed(seed)

    mu_q31 = float_to_q31(mu_f)
    coeffs_initial_q31 = float_array_to_q31(np.zeros(num_taps, dtype=np.float32))

    input_f = np.random.uniform(-0.5, 0.5, block_size).astype(np.float32)
    input_q31 = float_array_to_q31(input_f)

    desired_f = np.random.uniform(-0.5, 0.5, block_size).astype(np.float32)
    desired_q31 = float_array_to_q31(desired_f)

    output_q31, error_q31, coeffs_final_q31, energy = lms_norm_q31_python(
        input_q31, desired_q31, coeffs_initial_q31, mu_q31
    )

    return {
        "block_size": block_size,
        "num_stage": num_taps,
        "mu_q31": int(mu_q31),
        "energy": int(energy),
        "input_q31": input_q31,
        "desired_q31": desired_q31,
        "output_q31": output_q31,
        "error_q31": error_q31,
        "coeffs_initial_q31": coeffs_initial_q31,
        "coeffs_final_q31": coeffs_final_q31,
    }


def lms_norm_q31():
    print("\nGenerating CMSIS-style LMS-Norm Q31 Test Data...")

    data = generate_lms_norm_test_data_q31()

    output_str = test_to_template["fir_lms_norm_q31_test_inputs"]
    output_str = output_str.replace("<<INSERT_IS_HERE>>", c_array_q31(data["input_q31"]))
    output_str = output_str.replace("<<INSERT_DS_HERE>>", c_array_q31(data["desired_q31"]))
    output_str = output_str.replace("<<INSERT_OS_HERE>>", c_array_q31(data["output_q31"]))
    output_str = output_str.replace("<<INSERT_ES_HERE>>", c_array_q31(data["error_q31"]))
    output_str = output_str.replace("<<INSERT_COEFFS_INIT_HERE>>", c_array_q31(data["coeffs_initial_q31"]))
    output_str = output_str.replace("<<INSERT_COEFFS_FINAL_HERE>>", c_array_q31(data["coeffs_final_q31"]))
    output_str = output_str.replace("<<INSERT_BLOCK_SIZE_HERE>>", str(data["block_size"]))
    output_str = output_str.replace("<<INSERT_NUMTAPS_HERE>>", str(data["num_stage"]))
    output_str = output_str.replace("<<INSERT_MU_HERE>>", f"0x{data['mu_q31'] & 0xFFFFFFFF:08X}")
    replace_test_file("fir_lms_norm_q31_test_inputs", output_str)

    output_str = test_to_template["fir_lms_norm_q31_test_header"]
    output_str = output_str.replace("<<INSERT_BLOCK_SIZE_HERE>>", str(data["block_size"]))
    output_str = output_str.replace("<<INSERT_NUMTAPS_HERE>>", str(data["num_stage"]))
    output_str = output_str.replace("<<INSERT_MU_HERE>>", f"0x{data['mu_q31'] & 0xFFFFFFFF:08X}")
    replace_test_file("fir_lms_norm_q31_test_header", output_str)

    print("\nDone Generating LMS Norm Q31 Test Data")
