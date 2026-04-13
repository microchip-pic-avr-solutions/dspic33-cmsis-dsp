"""
LMS Filter Test Vector Generator (Q31 Format)
Uses dsPIC33AK DSP engine model for accurate expected values.
Assembly uses: clr a + mac.l for FIR, sub b for error,
sacr.l throughout (y[n], e[n], attErr, coefficient updates).
"""

import numpy as np
import os
from helper_q31 import *
from dspic_q31_model import DspAccumulator, to_signed32

test_to_template = {
    "fir_lms_q31_test_inputs": """/*
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
#include "fir_lms_q31_test.h"

#ifdef FILTER_LIB_TEST
#ifdef DATA_SET_I

q31_t FIR_LMS_Q31_INPUT[] = {
    <<INSERT_IS_HERE>>
};

q31_t FIR_LMS_Q31_DESIRED[] = {
    <<INSERT_DS_HERE>>
};

q31_t FIR_LMS_Q31_COEFF_INITIAL[] = {
    <<INSERT_COEFFS_INIT_HERE>>
};

q31_t FIR_LMS_Q31_OUTPUT_REF[] = {
    <<INSERT_OS_HERE>>
};

q31_t FIR_LMS_Q31_ERROR_REF[] = {
    <<INSERT_ES_HERE>>
};

q31_t FIR_LMS_Q31_COEFF_FINAL_REF[] = {
    <<INSERT_COEFFS_FINAL_HERE>>
};

q31_t FIR_LMS_Q31_STATE[FIR_LMS_Q31_BLOCK_SIZE+FIR_LMS_Q31_NUM_TAPS-1];

#endif
#endif
""",
    "fir_lms_q31_test_header": """/*
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
#define FIR_LMS_Q31_BLOCK_SIZE <<INSERT_BLOCK_SIZE_HERE>>
#define FIR_LMS_Q31_NUM_TAPS <<INSERT_NUMTAPS_HERE>>
#define FIR_LMS_Q31_MU <<INSERT_MU_HERE>>
#define FIR_LMS_Q31_POSTSHIFT 0

extern q31_t FIR_LMS_Q31_INPUT[];
extern q31_t FIR_LMS_Q31_DESIRED[];
extern q31_t FIR_LMS_Q31_COEFF_INITIAL[];
extern q31_t FIR_LMS_Q31_OUTPUT_REF[];
extern q31_t FIR_LMS_Q31_ERROR_REF[];
extern q31_t FIR_LMS_Q31_COEFF_FINAL_REF[];
extern q31_t FIR_LMS_Q31_STATE[FIR_LMS_Q31_BLOCK_SIZE+FIR_LMS_Q31_NUM_TAPS-1];

#endif
#endif
"""
}


def lms_q31_python(input_q31, desired_q31, coeffs_initial_q31, mu_q31):
    """
    dsPIC33AK LMS Q31 model matching mchp_lms_q31.s assembly.

    Matches firlms_aa.s reference:
    - FIR: mpy.l first product + mac.l for remaining taps (forward walk)
    - Error: lac.l r[n], b; sub b (b = r[n] - y[n])
    - Attenuated error: mpy.l mu, e[n]; sacr.l
    - Adaptation: lac.l h[m] + mac.l attErr*delay[m] + sacr.l h[m]
    - All extractions via sacr.l (convergent rounding)

    Circular delay buffer walks FORWARD via modulo addressing in assembly.
    Write pointer effectively decrements each sample (newest at current,
    oldest at current+1 via modulo wrapping).
    """
    num_taps = len(coeffs_initial_q31)
    block_size = len(input_q31)
    mu_signed = to_signed32(mu_q31)

    # Working copy of coefficients
    h = [to_signed32(c) for c in coeffs_initial_q31]
    input_signed = [to_signed32(x) for x in input_q31]
    desired_signed = [to_signed32(x) for x in desired_q31]

    # Circular delay buffer
    delay = [0] * num_taps
    delay_idx = 0

    acc_a = DspAccumulator()
    acc_b = DspAccumulator()
    output = np.zeros(block_size, dtype=np.int32)
    error = np.zeros(block_size, dtype=np.int32)

    for n in range(block_size):
        # Write x[n] into delay at current position (assembly: mov.l w13, [w10])
        delay[delay_idx] = input_signed[n]

        # FIR filter: mpy.l first product, then mac.l for remaining taps.
        # Assembly walks FORWARD through circular buffer via modulo:
        #   h[0]*delay[p], h[1]*delay[p+1], ..., h[M-1]*delay[p+M-1]
        # where p = delay_idx (just-written position).
        read_idx = delay_idx
        acc_a.mpy(h[0], delay[read_idx])
        read_idx = (read_idx + 1) % num_taps
        for m in range(1, num_taps):
            acc_a.mac(h[m], delay[read_idx])
            read_idx = (read_idx + 1) % num_taps
        # After FIR, read_idx has wrapped back to delay_idx (advanced M times).

        # Error: lac.l r[n], b; sub b (b = b - a)
        acc_b.value = int(desired_signed[n]) << 32
        acc_b.value -= acc_a.value  # sub b

        # sacr.l b => e[n]; sacr.l a => y[n]
        e_n = acc_b.sacr()
        y_n = acc_a.sacr()
        error[n] = np.int32(e_n)
        output[n] = np.int32(y_n)

        # Attenuated error: mpy.l mu, e[n]; sacr.l a => attErr
        acc_a.mpy(mu_signed, e_n)
        att_err = acc_a.sacr()

        # Coefficient update: lac.l h[m] + mac.l attErr*delay[m] + sacr.l h[m]
        # Assembly walks delay FORWARD from delay[current] (same as FIR).
        read_idx = delay_idx
        for m in range(num_taps):
            acc_a.value = int(h[m]) << 32
            acc_a.mac(att_err, delay[read_idx])
            h[m] = acc_a.sacr()
            read_idx = (read_idx + 1) % num_taps

        # Advance delay write pointer (moves backward: next write at p-1 via modulo)
        # Reference: after adaptation, w10 ends at delay[p+M-1] = delay[p-1].
        # Next iteration writes x[n+1] there, so effective pointer decrements.
        delay_idx = (delay_idx - 1) % num_taps

    coeffs_final = np.array(h[:num_taps], dtype=np.int32)
    return output, error, coeffs_final


def generate_random_fir_lms_test_data_q31(seed=42):
    block_size = 64
    num_taps = 8
    mu_f = 0.01  # Small step size

    if seed is not None:
        np.random.seed(seed)

    mu_q31 = float_to_q31(mu_f)

    coeffs_initial_f = np.zeros(num_taps, dtype=np.float32)
    coeffs_initial_q31 = float_array_to_q31(coeffs_initial_f)

    input_f = np.random.uniform(-0.5, 0.5, block_size).astype(np.float32)
    input_q31 = float_array_to_q31(input_f)

    desired_f = np.random.uniform(-0.5, 0.5, block_size).astype(np.float32)
    desired_q31 = float_array_to_q31(desired_f)

    output_q31, error_q31, coeffs_final_q31 = lms_q31_python(
        input_q31, desired_q31, coeffs_initial_q31, mu_q31
    )

    return {
        "block_size": block_size,
        "num_stage": num_taps,
        "mu_q31": int(mu_q31),
        "input_q31": input_q31,
        "desired_q31": desired_q31,
        "output_q31": output_q31,
        "error_q31": error_q31,
        "coeffs_initial_q31": coeffs_initial_q31,
        "coeffs_final_q31": coeffs_final_q31,
    }


def lms_q31():
    print("\n Generating LMS Q31 Test Data")

    data = generate_random_fir_lms_test_data_q31()

    output_str = test_to_template["fir_lms_q31_test_inputs"]
    output_str = output_str.replace("<<INSERT_IS_HERE>>", c_array_q31(data["input_q31"]))
    output_str = output_str.replace("<<INSERT_DS_HERE>>", c_array_q31(data["desired_q31"]))
    output_str = output_str.replace("<<INSERT_OS_HERE>>", c_array_q31(data["output_q31"]))
    output_str = output_str.replace("<<INSERT_ES_HERE>>", c_array_q31(data["error_q31"]))
    output_str = output_str.replace("<<INSERT_COEFFS_INIT_HERE>>", c_array_q31(data["coeffs_initial_q31"]))
    output_str = output_str.replace("<<INSERT_COEFFS_FINAL_HERE>>", c_array_q31(data["coeffs_final_q31"]))
    output_str = output_str.replace("<<INSERT_BLOCK_SIZE_HERE>>", str(data["block_size"]))
    output_str = output_str.replace("<<INSERT_NUMTAPS_HERE>>", str(data["num_stage"]))
    output_str = output_str.replace("<<INSERT_MU_HERE>>", f"0x{data['mu_q31'] & 0xFFFFFFFF:08X}")
    replace_test_file("fir_lms_q31_test_inputs", output_str)

    output_str = test_to_template["fir_lms_q31_test_header"]
    output_str = output_str.replace("<<INSERT_BLOCK_SIZE_HERE>>", str(data["block_size"]))
    output_str = output_str.replace("<<INSERT_NUMTAPS_HERE>>", str(data["num_stage"]))
    output_str = output_str.replace("<<INSERT_MU_HERE>>", f"0x{data['mu_q31'] & 0xFFFFFFFF:08X}")
    replace_test_file("fir_lms_q31_test_header", output_str)

    print("\n Done Generating LMS Q31 Test Data")
