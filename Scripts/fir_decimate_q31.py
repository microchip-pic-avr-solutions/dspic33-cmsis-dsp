"""
FIR Decimate Test Vector Generator (Q31 Format)
Uses dsPIC33AK DSP engine model for accurate expected values.
Assembly uses: mpy.l (first product) + mac.l + sacr.l for output.
"""

import numpy as np
import os
import random
from scipy.signal import firwin
from helper_q31 import *
from dspic_q31_model import DspAccumulator, to_signed32

test_to_template = {
    "fir_decim_q31_test_inputs": """/*
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
#include "fir_decim_q31_test.h"

#ifdef FILTER_LIB_TEST

#ifdef DATA_SET_I

q31_t FIR_DECIM_Q31_INPUT[] = {
    <<INSERT_IS_HERE>>
};

q31_t FIR_DECIM_Q31_COEFF[] = {
    <<INSERT_COEFFS_HERE>>
};

q31_t FIR_DECIM_Q31_OUTPUT[] = {
    <<INSERT_OS_HERE>>
};

q31_t FIR_DECIM_Q31_STATE[FIR_DECIM_Q31_BLOCK_SIZE+FIR_DECIM_Q31_NUMTAPS_SIZE-1];

#endif

#endif
""",
    "fir_decim_q31_test_header": """/*
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
#define FIR_DECIM_Q31_BLOCK_SIZE <<INSERT_BLOCK_SIZE_HERE>>
#define FIR_DECIM_Q31_RATE <<INSERT_DECIM_RATE_HERE>>
#define FIR_DECIM_Q31_NUMTAPS_SIZE <<INSERT_NUMTAPS_HERE>>

extern q31_t FIR_DECIM_Q31_INPUT[];
extern q31_t FIR_DECIM_Q31_OUTPUT[];
extern q31_t FIR_DECIM_Q31_COEFF[];
extern q31_t FIR_DECIM_Q31_STATE[FIR_DECIM_Q31_BLOCK_SIZE+FIR_DECIM_Q31_NUMTAPS_SIZE-1];

#endif

#endif
"""
}


def dspic_fir_decimate_q31(input_q31, coeffs_q31, num_taps, decim_rate):
    """
    dsPIC33AK FIR Decimation Q31 model matching mchp_fir_decimate_q31.s.
    Assembly uses: mpy.l (first product) + repeat mac.l + sacr.l.
    Linear delay line, output every R-th sample.
    """
    block_size = len(input_q31)
    input_signed = [to_signed32(x) for x in input_q31]
    coeff_signed = [to_signed32(c) for c in coeffs_q31]

    # Linear delay buffer (newest at end)
    delay = [0] * num_taps
    acc = DspAccumulator()
    output = []

    for n in range(block_size):
        # Shift delay line and insert new sample
        delay.pop(0)
        delay.append(input_signed[n])

        # Only compute output every decim_rate samples
        if (n + 1) % decim_rate == 0:
            # mpy.l (first product, clears acc) + mac.l for rest
            acc.mpy(coeff_signed[0], delay[num_taps - 1])
            for m in range(1, num_taps):
                acc.mac(coeff_signed[m], delay[num_taps - 1 - m])

            # sacr.l a, [w2++]
            output.append(acc.sacr())

    return np.array(output, dtype=np.int32)


def generate_random_fir_decim_test_data_q31():
    """Generate random FIR decimation test data in Q31 using dsPIC model."""
    block_size = 128
    num_taps = 24
    decim_rate = 4  # block_size must be divisible by decim_rate

    # Random coefficients in Q31 range
    coeffs_f = np.random.uniform(-0.5, 0.5, num_taps).astype(np.float32)
    coeffs_q31 = float_array_to_q31(coeffs_f)

    # Random input in Q31 range
    input_f = np.random.uniform(-0.9, 0.9, block_size).astype(np.float32)
    input_q31 = float_array_to_q31(input_f)

    # Process with dsPIC33AK model
    output_q31 = dspic_fir_decimate_q31(input_q31, coeffs_q31, num_taps, decim_rate)

    return {
        "num_taps": num_taps,
        "block_size": block_size,
        "coeffs_q31": coeffs_q31,
        "decim_rate": decim_rate,
        "input_q31": input_q31,
        "expected_output_q31": output_q31,
    }


def fir_decim_q31():
    print("\n\n Generating FIR Decimate Q31 Test Data: ")

    data = generate_random_fir_decim_test_data_q31()

    input_q31 = data["input_q31"]
    output_q31 = data["expected_output_q31"]
    coeffs_q31 = data["coeffs_q31"]
    block_size = data["block_size"]
    num_taps = data["num_taps"]
    decim_rate = data["decim_rate"]

    output_str = test_to_template["fir_decim_q31_test_inputs"]
    output_str = output_str.replace("<<INSERT_IS_HERE>>", c_array_q31(input_q31))
    output_str = output_str.replace("<<INSERT_OS_HERE>>", c_array_q31(output_q31))
    output_str = output_str.replace("<<INSERT_COEFFS_HERE>>", c_array_q31(coeffs_q31))
    output_str = output_str.replace("<<INSERT_BLOCK_SIZE_HERE>>", str(block_size))
    output_str = output_str.replace("<<INSERT_NUMTAPS_HERE>>", str(num_taps))
    output_str = output_str.replace("<<INSERT_DECIM_RATE_HERE>>", str(decim_rate))
    replace_test_file("fir_decim_q31_test_inputs", output_str)

    output_str = test_to_template["fir_decim_q31_test_header"]
    output_str = output_str.replace("<<INSERT_BLOCK_SIZE_HERE>>", str(block_size))
    output_str = output_str.replace("<<INSERT_NUMTAPS_HERE>>", str(num_taps))
    output_str = output_str.replace("<<INSERT_DECIM_RATE_HERE>>", str(decim_rate))
    replace_test_file("fir_decim_q31_test_header", output_str)

    print("\n\n Done Generating FIR Decimate Q31 Test Data")
