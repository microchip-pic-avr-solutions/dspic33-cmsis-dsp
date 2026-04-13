"""
IIR Biquad Cascade DF1 Test Vector Generator (Q31 Format)
Uses dsPIC33AK DSP engine model for accurate expected values.
Assembly uses: mpy.l + mac.l + msc.l + sacr.l.

DF1 difference equation per section:
  y[n] = b0*x[n] + b1*x[n-1] + b2*x[n-2] - a1*y[n-1] - a2*y[n-2]

Coefficient layout per section: [b0, b1, b2, a1, a2]
  where a1, a2 are the STANDARD denominator coefficients (NOT negated).
  The assembly uses msc.l to subtract: a -= coeff * state.

State layout per section: [x[n-1], x[n-2], y[n-1], y[n-2]]
"""

import numpy as np
import os
from scipy import signal
from helper_q31 import *
from dspic_q31_model import DspAccumulator, to_signed32

test_to_template = {
    "iir_canonic_q31_test_inputs": """/*
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
#include "biquad_cascade_df1_q31_test.h"

#ifdef FILTER_LIB_TEST
#ifdef DATA_SET_I

q31_t IIR_DF1_Q31_INPUT[] = {
    <<INSERT_IS_HERE>>
};

q31_t IIR_DF1_Q31_COEFF[] = {
    <<INSERT_COEFFS_HERE>>
};

q31_t IIR_DF1_Q31_OUTPUT[] = {
    <<INSERT_OS_HERE>>
};

q31_t IIR_DF1_Q31_STATE[<<INSERT_NUM_STAGES_HERE>> * 4];

#endif
#endif
""",
    "iir_canonic_q31_test_header": """/*
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
#define IIR_DF1_Q31_BLOCK_SIZE <<INSERT_BLOCK_SIZE_HERE>>
#define IIR_DF1_Q31_NUM_STAGES <<INSERT_NUM_STAGES_HERE>>

extern q31_t IIR_DF1_Q31_INPUT[];
extern q31_t IIR_DF1_Q31_COEFF[];
extern q31_t IIR_DF1_Q31_OUTPUT[];
extern q31_t IIR_DF1_Q31_STATE[];

#endif
#endif
"""
}


def generate_stable_iir_biquad_q31(order=2, block_size=32, seed=123):
    """Generate stable IIR biquad cascade DF1 test data in Q31 using dsPIC model.

    The assembly implements DF1:
      y[n] = b0*x[n] + b1*x[n-1] + b2*x[n-2] - a1*y[n-1] - a2*y[n-2]
    using mpy.l/mac.l for b-terms and msc.l for a-terms.

    Coefficients stored as [b0, b1, b2, a1, a2] per stage (standard, NOT negated).
    """
    if seed is not None:
        np.random.seed(seed)

    # Design Butterworth low-pass filter
    sos = signal.butter(order, 0.3, btype='low', output='sos')

    # Coefficient layout: [b0, b1, b2, a1, a2] per stage.
    # a1, a2 are standard denominator coefficients (NOT negated).
    # Assembly uses msc.l to subtract: acc -= a1*y[n-1], acc -= a2*y[n-2].
    num_stages = sos.shape[0]
    coeff_list = []
    for i in range(num_stages):
        b0, b1, b2, a0, a1, a2 = sos[i]
        # Normalize by a0 (should be 1.0 for SOS)
        coeff_list.extend([b0/a0, b1/a0, b2/a0, a1/a0, a2/a0])

    coeff_f = np.array(coeff_list, dtype=np.float64)
    # Clip to Q31 range [-1.0, ~+1.0)
    coeff_f = np.clip(coeff_f, -1.0, 1.0 - 1e-10)
    coeff_q31 = float_array_to_q31(coeff_f)

    # Random input
    input_f = np.random.uniform(-0.5, 0.5, block_size).astype(np.float64)
    input_q31 = float_array_to_q31(input_f)

    # Process with dsPIC33AK model
    coeff_signed = [to_signed32(c) for c in coeff_q31]
    input_signed = [to_signed32(x) for x in input_q31]

    acc = DspAccumulator()
    current_input = input_signed[:]

    for stage_idx in range(num_stages):
        ci = stage_idx * 5
        b0, b1, b2 = coeff_signed[ci], coeff_signed[ci+1], coeff_signed[ci+2]
        a1, a2 = coeff_signed[ci+3], coeff_signed[ci+4]

        xn1, xn2, yn1, yn2 = 0, 0, 0, 0
        stage_output = []

        for n_idx in range(block_size):
            xn = current_input[n_idx]

            # mpy.l b0*xn (clears acc, then multiplies)
            acc.mpy(b0, xn)
            # mac.l b1*xn1
            acc.mac(b1, xn1)
            # mac.l b2*xn2
            acc.mac(b2, xn2)
            # msc.l a1*yn1 (standard coeff, msc subtracts)
            acc.msc(a1, yn1)
            # msc.l a2*yn2
            acc.msc(a2, yn2)

            # sacr.l a, w9
            yn = acc.sacr()
            stage_output.append(yn)

            xn2 = xn1
            xn1 = xn
            yn2 = yn1
            yn1 = yn

        current_input = stage_output

    output_q31 = np.array(current_input, dtype=np.int32)

    return {
        "num_stages": num_stages,
        "block_size": block_size,
        "coeff_q31": coeff_q31,
        "input_q31": input_q31,
        "expected_output_q31": output_q31,
    }


def iir_canonic_q31():
    print("\nGenerating IIR Biquad Cascade DF1 Q31 Test Data...")

    data = generate_stable_iir_biquad_q31()

    output_str = test_to_template["iir_canonic_q31_test_inputs"]
    output_str = output_str.replace("<<INSERT_IS_HERE>>", c_array_q31(data["input_q31"]))
    output_str = output_str.replace("<<INSERT_OS_HERE>>", c_array_q31(data["expected_output_q31"]))
    output_str = output_str.replace("<<INSERT_COEFFS_HERE>>", c_array_q31(data["coeff_q31"]))
    output_str = output_str.replace("<<INSERT_BLOCK_SIZE_HERE>>", str(data["block_size"]))
    output_str = output_str.replace("<<INSERT_NUM_STAGES_HERE>>", str(data["num_stages"]))
    replace_test_file("iir_canonic_q31_test_inputs", output_str)

    output_str = test_to_template["iir_canonic_q31_test_header"]
    output_str = output_str.replace("<<INSERT_BLOCK_SIZE_HERE>>", str(data["block_size"]))
    output_str = output_str.replace("<<INSERT_NUM_STAGES_HERE>>", str(data["num_stages"]))
    replace_test_file("iir_canonic_q31_test_header", output_str)

    print("\nDone Generating IIR Biquad Cascade DF1 Q31 Test Data")