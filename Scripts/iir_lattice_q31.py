"""
IIR Lattice Test Vector Generator (Q31 Format)
Uses dsPIC33AK DSP engine model for accurate expected values.
Assembly follows iirlatt_aa.s reference: lac.l + msc.l + sacr.l + mac.l.
Lattice uses AccuA only; ladder uses AccuA with mpy.l + repeat mac.l.
"""

import numpy as np
import os
from scipy import signal
from helper_q31 import *
from dspic_q31_model import DspAccumulator, to_signed32, sat_q31

test_to_template = {
    "iir_lattice_q31_test_inputs": """/*
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
#include "iir_lattice_q31_test.h"

#ifdef FILTER_LIB_TEST
#ifdef DATA_SET_I

q31_t IIR_LATTICE_Q31_INPUT[] = {
    <<INSERT_IS_HERE>>
};

q31_t IIR_LATTICE_Q31_PK[] = {
    <<INSERT_PK_HERE>>
};

q31_t IIR_LATTICE_Q31_PV[] = {
    <<INSERT_PV_HERE>>
};

q31_t IIR_LATTICE_Q31_OUTPUT[] = {
    <<INSERT_OS_HERE>>
};

q31_t IIR_LATTICE_Q31_STATE[IIR_LATTICE_Q31_NUM_STAGES+1];

#endif
#endif
""",
    "iir_lattice_q31_test_header": """/*
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
#define IIR_LATTICE_Q31_BLOCK_SIZE <<INSERT_BLOCK_SIZE_HERE>>
#define IIR_LATTICE_Q31_NUM_STAGES <<INSERT_NUM_STAGES_HERE>>

extern q31_t IIR_LATTICE_Q31_INPUT[];
extern q31_t IIR_LATTICE_Q31_OUTPUT[];
extern q31_t IIR_LATTICE_Q31_PK[];
extern q31_t IIR_LATTICE_Q31_PV[];
extern q31_t IIR_LATTICE_Q31_STATE[IIR_LATTICE_Q31_NUM_STAGES+1];

#endif
#endif
"""
}


def dspic_iir_lattice_q31(input_q31, pk_q31, pv_q31, num_stages):
    """
    dsPIC33AK IIR Lattice Q31 model matching mchp_iir_lattice_q31.s.

    Follows iirlatt_aa.s reference assembly and iirmodel.c reference C model.

    Lattice phase (m = 0 to M-1, k[] traversed from k[M-1] down to k[0]):
      For each stage:
        a  = current                   -- lac.l: accA = current << 32
        a -= k[M-1-m] * d[m+1]        -- msc.l: a -= k * d (72-bit)
        after = sacr.l a               -- extract with convergent rounding
        a  = d[m+1]                    -- lac.l: a = d[m+1] << 32
        a += k[M-1-m] * after          -- mac.l: a += k * after
        d[m] = sacr.l a               -- store updated state
        current = after
      d[M] = after                     -- mov.l: store last delay

    Ladder phase (computes output):
      a  = g[0] * d[M]                -- mpy.l (first product)
      a += g[1] * d[M-1]              -- repeat mac.l (M-1 products)
      ...
      a += g[M] * d[0]                -- mac.l (last product)
      y[n] = sacr.l a                 -- output with convergent rounding

    This is equivalent to: y[n] = sum_{m=0}^{M} g[M-m] * d[m]
    """
    block_size = len(input_q31)
    M = num_stages
    input_signed = [to_signed32(x) for x in input_q31]
    k = [to_signed32(c) for c in pk_q31]
    g = [to_signed32(c) for c in pv_q31]  # g[0..M] = ladder coeffs

    # State: d[0..M] (M+1 values), initialized to zero
    d = [0] * (M + 1)

    acc = DspAccumulator()
    output = []

    for n in range(block_size):
        current = input_signed[n]
        after = current  # default if M == 0

        # Lattice phase: m = 0 to M-1, reading k[M-1-m] and d[m+1]
        for m in range(M):
            ki = M - 1 - m  # k index, walks from k[M-1] down to k[0]

            # Upper branch: after = current - k[ki] * d[m+1]
            # Assembly: lac.l current -> a; msc.l k, d, a
            acc.value = int(current) << 32
            acc.msc(k[ki], d[m + 1])
            after = acc.sacr()

            # Lower branch: d[m] = d[m+1] + k[ki] * after
            # Assembly: lac.l d[m+1] -> a; mac.l k, after, a
            acc.value = int(d[m + 1]) << 32
            acc.mac(k[ki], after)
            d[m] = acc.sacr()

            current = after

        # Store last delay: d[M] = after
        d[M] = after

        # Ladder phase: y[n] = sum_{m=0}^{M} g[M-m] * d[m]
        # Assembly walks g[] forward (g[0]->g[M]) and d[] backward (d[M]->d[0])
        # First product: mpy.l g[0] * d[M]
        acc.mpy(g[0], d[M])
        # Middle products: mac.l g[1]*d[M-1], g[2]*d[M-2], ..., g[M-1]*d[1]
        for i in range(1, M):
            acc.mac(g[i], d[M - i])
        # Last product: mac.l g[M] * d[0]
        acc.mac(g[M], d[0])

        # sacr.l a -> y[n]
        output.append(acc.sacr())

    return np.array(output, dtype=np.int32)


def generate_stable_iir_lattice_test_data_q31(order=4, block_size=64, seed=42):
    """Generate stable IIR lattice test data in Q31 using dsPIC model."""
    if seed is not None:
        np.random.seed(seed)

    # Design stable filter using Butterworth
    pk_f = list(signal.firwin(order, [0.33]))
    pk_f = np.clip(pk_f, -0.99, 0.99).astype(np.float32)

    pv_f = np.random.uniform(-0.5, 0.5, order + 1).astype(np.float32)

    # Convert to Q31
    pk_q31 = float_array_to_q31(pk_f)
    pv_q31 = float_array_to_q31(pv_f)

    # Random input
    input_f = np.random.uniform(-0.5, 0.5, block_size).astype(np.float32)
    input_q31 = float_array_to_q31(input_f)

    # Process with dsPIC33AK model
    output_q31 = dspic_iir_lattice_q31(input_q31, pk_q31, pv_q31, order)

    return {
        "num_stages": order,
        "block_size": block_size,
        "pk_q31": pk_q31,
        "pv_q31": pv_q31,
        "input_q31": input_q31,
        "expected_output_q31": output_q31,
    }


def iir_lattice_q31():
    print("\nGenerating IIR Lattice Q31 Test Data...")

    data = generate_stable_iir_lattice_test_data_q31()

    output_str = test_to_template["iir_lattice_q31_test_inputs"]
    output_str = output_str.replace("<<INSERT_IS_HERE>>", c_array_q31(data["input_q31"]))
    output_str = output_str.replace("<<INSERT_OS_HERE>>", c_array_q31(data["expected_output_q31"]))
    output_str = output_str.replace("<<INSERT_PK_HERE>>", c_array_q31(data["pk_q31"]))
    output_str = output_str.replace("<<INSERT_PV_HERE>>", c_array_q31(data["pv_q31"]))
    output_str = output_str.replace("<<INSERT_BLOCK_SIZE_HERE>>", str(data["block_size"]))
    output_str = output_str.replace("<<INSERT_NUM_STAGES_HERE>>", str(data["num_stages"]))
    replace_test_file("iir_lattice_q31_test_inputs", output_str)

    output_str = test_to_template["iir_lattice_q31_test_header"]
    output_str = output_str.replace("<<INSERT_BLOCK_SIZE_HERE>>", str(data["block_size"]))
    output_str = output_str.replace("<<INSERT_NUM_STAGES_HERE>>", str(data["num_stages"]))
    replace_test_file("iir_lattice_q31_test_header", output_str)

    print("\nDone Generating IIR Lattice Q31 Test Data")
