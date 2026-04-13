"""
FIR Lattice Test Vector Generator (Q31 Format)
NOTE: arm_fir_lattice_q31 may not be in the CMSIS-DSP Python wrapper,
so we implement it in Python (same approach as the f32 version).
"""

import numpy as np
import os
from scipy.signal import firwin
from helper_q31 import *
from dspic_q31_model import DspAccumulator, to_signed32, sat_q31

try:
    import cmsisdsp as dsp
except:
    os.system("python -m pip install cmsisdsp")

test_to_template = {
    "fir_lattice_q31_test_inputs": """/*
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
#include "fir_lattice_q31_test.h"

#ifdef FILTER_LIB_TEST
#ifdef DATA_SET_I

q31_t FIR_LATTICE_Q31_INPUT[] = {
    <<INSERT_IS_HERE>>
};

q31_t FIR_LATTICE_Q31_COEFF[] = {
    <<INSERT_COEFFS_HERE>>
};

q31_t FIR_LATTICE_Q31_OUTPUT[] = {
    <<INSERT_OS_HERE>>
};

q31_t FIR_LATTICE_Q31_STATE[FIR_LATTICE_Q31_BLOCK_SIZE+FIR_LATTICE_Q31_NUM_STAGES];

#endif
#endif
""",
    "fir_lattice_q31_test_header": """/*
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
#define FIR_LATTICE_Q31_BLOCK_SIZE <<INSERT_BLOCK_SIZE_HERE>>
#define FIR_LATTICE_Q31_NUM_STAGES <<INSERT_NUMTAPS_HERE>>

extern q31_t FIR_LATTICE_Q31_INPUT[];
extern q31_t FIR_LATTICE_Q31_OUTPUT[];
extern q31_t FIR_LATTICE_Q31_COEFF[];
extern q31_t FIR_LATTICE_Q31_STATE[FIR_LATTICE_Q31_BLOCK_SIZE+FIR_LATTICE_Q31_NUM_STAGES];

#endif
#endif
"""
}


def fir_lattice_filter_q31(input_signal_q31, reflection_coeffs_q31, num_stages):
    """
    Python model of dsPIC33AK mchp_fir_lattice_q31 assembly.
    Uses DspAccumulator (full 72-bit precision) to exactly match hardware.

    The dsPIC33AK accumulator is 72 bits (8 guard + 32 upper + 32 lower).
    mac.l adds the full 64-bit shifted product ((a*b)<<1) to the accumulator.
    sac.l extracts the upper 32 bits (bits [63:32]) with truncation and
    saturation (if guard bits indicate overflow).
    lac.l loads a 32-bit value into the upper 32 bits of the accumulator
    (lower 32 bits cleared).

    ASM flow per sample:
      lac.l [w1++], a        -> AccA = x[n] << 32
      sac.l a, w3            -> w3 = sac(AccA) = x[n]  (f_prev scratch)
      mov.l [w9], w6         -> w6 = g(0)[n-1]
      sac.l a, [w9++]        -> state[0] = x[n] = g(0)[n]

      For each stage m = 1..M-1:
        mac.l [w8], w6, a    -> AccA += (k[m-1] * g_prev) << 1
        lac.l w6, b          -> AccB = g_prev << 32
        mac.l [w8], w3, b    -> AccB += (k[m-1] * f_prev) << 1
        sac.l a, w3          -> w3 = sac(AccA) = f(m)[n]
        add.l #4, w8         -> advance coeff pointer
        mov.l [w9], w6       -> w6 = g(m)[n-1]
        sac.l b, [w9++]      -> state[m] = sac(AccB) = g(m)[n]

      Final stage M:
        mac.l [w8], w6, a    -> AccA += (k[M-1] * g_prev) << 1
        sac.l a, [w2++]      -> output[n] = sac(AccA)
    """
    block_size = len(input_signal_q31)
    state = [0] * num_stages  # 32-bit signed values
    output = np.zeros(block_size, dtype=np.int32)

    accA = DspAccumulator()
    accB = DspAccumulator()

    for n in range(block_size):
        x_n = to_signed32(input_signal_q31[n])

        # Stage 0 setup: lac.l [w1++], a  (load x[n] into upper 32 of acc)
        accA.value = int(x_n) << 32
        w3 = accA.sac()          # sac.l a, w3  (f_prev = x[n])
        w6 = state[0]            # mov.l [w9], w6  (g(0)[n-1])
        state[0] = accA.sac()    # sac.l a, [w9++] (state[0] = x[n])

        # Stages 1..M-1 inner loop
        for m in range(num_stages - 1):
            k_val = to_signed32(reflection_coeffs_q31[m])

            # Upper branch: mac.l [w8], w6, a
            accA.mac(k_val, w6)

            # Lower branch: lac.l w6, b; mac.l [w8], w3, b
            accB.value = int(w6) << 32
            accB.mac(k_val, w3)

            # sac.l a, w3 (new f_prev)
            w3 = accA.sac()

            # mov.l [w9], w6 (next g_prev); sac.l b, [w9++] (store g(m)[n])
            w6 = state[m + 1]
            state[m + 1] = accB.sac()

        # Final stage M: mac.l [w8], w6, a
        k_val = to_signed32(reflection_coeffs_q31[num_stages - 1])
        accA.mac(k_val, w6)

        # sac.l a, [w2++] (output)
        output[n] = np.int32(accA.sac())

    return output


def fir_lattice_q31():
    print("\n\n Generating FIR Lattice Q31 Test Data: ")

    block_size = 128
    num_stages = 12

    # Generate reflection coefficients (small to avoid Q31 overflow in lattice).
    # With 12 stages, CMSIS recommends scaling input by 2*log2(numStages) ≈ 7 bits.
    # Using small coefficients and inputs to avoid saturation differences
    # between ARM C (wrapping) and dsPIC hardware (saturation).
    np.random.seed(42)  # Fixed seed for reproducible test vectors
    reflection_f = np.random.uniform(-0.3, 0.3, num_stages).astype(np.float32)
    reflection_q31 = float_array_to_q31(reflection_f)

    # Random input scaled down to avoid overflow through 12 lattice stages
    input_f = np.random.uniform(-0.05, 0.05, block_size).astype(np.float32)
    input_q31 = float_array_to_q31(input_f)

    # Python-based Q31 lattice filter
    output_q31 = fir_lattice_filter_q31(input_q31, reflection_q31, num_stages)

    output_str = test_to_template["fir_lattice_q31_test_inputs"]
    output_str = output_str.replace("<<INSERT_IS_HERE>>", c_array_q31(input_q31))
    output_str = output_str.replace("<<INSERT_OS_HERE>>", c_array_q31(output_q31))
    output_str = output_str.replace("<<INSERT_COEFFS_HERE>>", c_array_q31(reflection_q31))
    output_str = output_str.replace("<<INSERT_BLOCK_SIZE_HERE>>", str(block_size))
    output_str = output_str.replace("<<INSERT_NUMTAPS_HERE>>", str(num_stages))
    replace_test_file("fir_lattice_q31_test_inputs", output_str)

    output_str = test_to_template["fir_lattice_q31_test_header"]
    output_str = output_str.replace("<<INSERT_BLOCK_SIZE_HERE>>", str(block_size))
    output_str = output_str.replace("<<INSERT_NUMTAPS_HERE>>", str(num_stages))
    replace_test_file("fir_lattice_q31_test_header", output_str)

    print("\n\n Done Generating FIR Lattice Q31 Test Data")
