"""
PID Controller Test Vector Generator (Q31 Format)
Uses dsPIC33AK DSP engine model for accurate expected values.
Assembly uses: lac.l + mac.l (3x) + sacr.l for output.
Single-sample function with resetStateFlag=1 for test.
"""

import numpy as np
import os
from helper_q31 import *
from dspic_q31_model import DspAccumulator, to_signed32, sat_q31

test_to_template = {
    "pid_q31_test_inputs": """/*
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
#include "pid_q31_test.h"

#ifdef CONTROL_LIB_TEST
#ifdef DATA_SET_I

q31_t PID_Q31_INPUT[] = {
    <<INSERT_IS_HERE>>
};

q31_t PID_Q31_OUTPUT[] = {
    <<INSERT_OS_HERE>>
};

q31_t PID_Q31_KP[] = {
    <<INSERT_KP_HERE>>
};

q31_t PID_Q31_KI[] = {
    <<INSERT_KI_HERE>>
};

q31_t PID_Q31_KD[] = {
    <<INSERT_KD_HERE>>
};

q31_t PID_Q31_A0[] = {
    <<INSERT_A0_HERE>>
};

q31_t PID_Q31_A1[] = {
    <<INSERT_A1_HERE>>
};

q31_t PID_Q31_A2[] = {
    <<INSERT_A2_HERE>>
};

#endif
#endif
""",
    "pid_q31_test_header": """/*
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

#ifdef CONTROL_LIB_TEST
#ifdef DATA_SET_I
#define PID_Q31_BLOCK_SIZE <<INSERT_BLOCK_SIZE_HERE>>

extern q31_t PID_Q31_INPUT[];
extern q31_t PID_Q31_OUTPUT[];
extern q31_t PID_Q31_KP[];
extern q31_t PID_Q31_KI[];
extern q31_t PID_Q31_KD[];
extern q31_t PID_Q31_A0[];
extern q31_t PID_Q31_A1[];
extern q31_t PID_Q31_A2[];

#endif
#endif
"""
}


def generate_pid_test_data_q31(seed=42):
    """Generate PID test data in Q31 format.

    Models the assembly exactly:
    - mchp_pid_init_q31: computes A0, A1, A2 using lac.l/add.l/sacr.l
    - mchp_pid_q31: computes output using lac.l/mac.l(3x)/sacr.l
    - Test uses resetStateFlag=1, so e[n-1]=e[n-2]=controlOutput[n-1]=0.
    """
    if seed is not None:
        np.random.seed(seed)

    N = 32  # Number of test samples

    # Random PID gains (small to stay in Q31 range)
    Kp_f = np.random.uniform(0.05, 0.2, N).astype(np.float64)
    Ki_f = np.random.uniform(0.005, 0.02, N).astype(np.float64)
    Kd_f = np.random.uniform(0.0, 0.01, N).astype(np.float64)
    ein_f = np.random.uniform(-0.5, 0.5, N).astype(np.float64)

    # Convert gains to Q31 first (assembly works from Q31 values)
    Kp_q31 = float_array_to_q31(Kp_f)
    Ki_q31 = float_array_to_q31(Ki_f)
    Kd_q31 = float_array_to_q31(Kd_f)
    ein_q31 = float_array_to_q31(ein_f)

    # Compute A0, A1, A2 using DspAccumulator model matching init assembly:
    #   A0: lac.l Kp, a; add.l Ki, a; add.l Kd, a; sacr.l a
    #   A1: lac.l Kd, a; add.l Kd, a; add.l Kp, a; neg a; sacr.l a
    #   A2: mov.l Kd (no rounding, direct copy)
    acc = DspAccumulator()
    A0_q31 = np.zeros(N, dtype=np.int32)
    A1_q31 = np.zeros(N, dtype=np.int32)
    A2_q31 = np.zeros(N, dtype=np.int32)

    for i in range(N):
        kp = to_signed32(Kp_q31[i])
        ki = to_signed32(Ki_q31[i])
        kd = to_signed32(Kd_q31[i])

        # A0 = sacr(Kp + Ki + Kd)
        acc.value = int(kp) << 32   # lac.l Kp, a
        acc.value += int(ki) << 32  # add.l Ki, a
        acc.value += int(kd) << 32  # add.l Kd, a
        A0_q31[i] = np.int32(acc.sacr())

        # A1 = sacr(-(Kp + 2*Kd))
        acc.value = int(kd) << 32   # lac.l Kd, a
        acc.value += int(kd) << 32  # add.l Kd, a (now 2*Kd)
        acc.value += int(kp) << 32  # add.l Kp, a (now Kp + 2*Kd)
        acc.value = -acc.value      # neg a
        A1_q31[i] = np.int32(acc.sacr())

        # A2 = Kd (direct copy, no rounding)
        A2_q31[i] = np.int32(kd)

    # Compute PID output using dsPIC33AK model
    # With resetStateFlag=1: e[n-1]=0, e[n-2]=0, controlOutput[n-1]=0
    # Assembly: lac.l w7(=0), a; mac.l A0*e[n], a; mac.l A1*0, a; mac.l A2*0, a; sacr.l a
    # So output = sacr(0 + A0*e[n] + 0 + 0)
    output = []
    for i in range(N):
        a0 = to_signed32(A0_q31[i])
        e_n = to_signed32(ein_q31[i])

        # lac.l w7(=0), a => a = 0
        acc.value = 0
        # mac.l A0, e[n], a
        acc.mac(a0, e_n)
        # mac.l A1, e[n-1]=0, a => no change
        # mac.l A2, e[n-2]=0, a => no change
        # sacr.l a, w7
        y = acc.sacr()
        output.append(np.int32(y))

    output_q31 = np.array(output, dtype=np.int32)

    return {
        "block_size": N,
        "input_q31": ein_q31,
        "expected_output_q31": output_q31,
        "kp_q31": Kp_q31,
        "ki_q31": Ki_q31,
        "kd_q31": Kd_q31,
        "A0_q31": A0_q31,
        "A1_q31": A1_q31,
        "A2_q31": A2_q31,
    }


def pid_q31():
    print("\n\n Generating PID Q31 Test Data: ")

    data = generate_pid_test_data_q31()
    block_size = data["block_size"]

    output_str = test_to_template["pid_q31_test_inputs"]
    output_str = output_str.replace("<<INSERT_IS_HERE>>", c_array_q31(data["input_q31"]))
    output_str = output_str.replace("<<INSERT_OS_HERE>>", c_array_q31(data["expected_output_q31"]))
    output_str = output_str.replace("<<INSERT_KP_HERE>>", c_array_q31(data["kp_q31"]))
    output_str = output_str.replace("<<INSERT_KI_HERE>>", c_array_q31(data["ki_q31"]))
    output_str = output_str.replace("<<INSERT_KD_HERE>>", c_array_q31(data["kd_q31"]))
    output_str = output_str.replace("<<INSERT_A0_HERE>>", c_array_q31(data["A0_q31"]))
    output_str = output_str.replace("<<INSERT_A1_HERE>>", c_array_q31(data["A1_q31"]))
    output_str = output_str.replace("<<INSERT_A2_HERE>>", c_array_q31(data["A2_q31"]))
    output_str = output_str.replace("<<INSERT_BLOCK_SIZE_HERE>>", str(block_size))
    replace_test_file("pid_q31_test_inputs", output_str)

    output_str = test_to_template["pid_q31_test_header"]
    output_str = output_str.replace("<<INSERT_BLOCK_SIZE_HERE>>", str(block_size))
    replace_test_file("pid_q31_test_header", output_str)

    print("\n\n Done Generating PID Q31 Test Data")
