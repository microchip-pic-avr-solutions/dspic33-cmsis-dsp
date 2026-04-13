"""
FIR Filter Test Vector Generator (Q31 Format)
Uses dsPIC33AK DSP engine model for accurate expected values.
Assembly uses: clr a + mac.l (no mpy.l) + sacr.l for output.
"""

import numpy as np
import os
import random
from scipy.signal import firwin
from helper_q31 import *
from dspic_q31_model import DspAccumulator, to_signed32

test_to_template = {
    "fir_q31_test_inputs": """/*
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
#include "fir_q31_test.h"

#ifdef FILTER_LIB_TEST

#ifdef DATA_SET_I

q31_t FIR_Q31_INPUT[] = {
    <<INSERT_IS_HERE>>
};

q31_t FIR_Q31_COEFF[] = {
    <<INSERT_COEFFS_HERE>>
};

q31_t FIR_Q31_OUTPUT[] = {
    <<INSERT_OS_HERE>>
};

q31_t FIR_Q31_STATE[FIR_Q31_BLOCK_SIZE+FIR_Q31_NUM_TAPS-1];

#endif

#endif
""",
    "fir_q31_test_header": """/*
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
#define FIR_Q31_BLOCK_SIZE <<INSERT_BLOCK_SIZE_HERE>>
#define FIR_Q31_NUM_TAPS <<INSERT_NUMTAPS_HERE>>

extern q31_t FIR_Q31_INPUT[];
extern q31_t FIR_Q31_OUTPUT[];
extern q31_t FIR_Q31_COEFF[];
extern q31_t FIR_Q31_STATE[FIR_Q31_BLOCK_SIZE+FIR_Q31_NUM_TAPS-1];

#endif

#endif
"""
}


def dspic_fir_filter_q31(input_q31, coeffs_q31, num_taps):
    """
    dsPIC33AK FIR Q31 model matching mchp_fir_q31.s assembly (fixed version).
    Assembly uses: mpy.l (first product) + mac.l (M-2 middle) + mac.l (last,
    no delay post-inc) + sacr.l for output. Total M multiplies per sample.

    Assembly pointer behavior (modulo addressing, matches fir_aa.s):
      - w7 (delay ptr) starts at d[0].
      - Each sample: write x[n] at [w7], then mpy.l + mac.l loop reads FORWARD
        through delay with [w7]+=4 (modulo wrap) for all M taps.
      - Last MAC uses [w7] without post-increment, so w7 stays at the
        last element read = (write_pos + M - 1) % M = (write_pos - 1) % M.
      - Next sample's write_pos = where w7 was left = write_pos - 1 (mod M).

    Write position sequence: 0, M-1, M-2, M-3, ..., 1, 0, M-1, ...
    Read direction: FORWARD from write_pos with modulo wrap.
    Pairing: h[0]*d[write_pos], h[1]*d[write_pos+1], ..., h[M-1]*d[write_pos+M-1]
    This produces y[n] = h[0]*x[n] + h[1]*x[n-1] + ... + h[M-1]*x[n-M+1].
    """
    block_size = len(input_q31)
    input_signed = [to_signed32(x) for x in input_q31]
    coeff_signed = [to_signed32(c) for c in coeffs_q31]

    # Circular delay buffer
    delay = [0] * num_taps
    write_pos = 0  # w7 initial position

    acc = DspAccumulator()
    output = []

    for n in range(block_size):
        # Write new sample into delay buffer at current w7 position
        delay[write_pos] = input_signed[n]

        # mpy.l [w6]+=4, [w7]+=4, a  (first product, clears acc)
        read_idx = write_pos
        acc.mpy(coeff_signed[0], delay[read_idx])
        read_idx = (read_idx + 1) % num_taps

        # mac.l [w6]+=4, [w7]+=4, a  (middle MACs, M-2 iterations)
        # mac.l [w6]+=4, [w7], a     (last MAC, no delay post-inc)
        for m in range(1, num_taps):
            acc.mac(coeff_signed[m], delay[read_idx])
            read_idx = (read_idx + 1) % num_taps  # FORWARD (post-increment)

        # sacr.l a, [w2++]
        output.append(acc.sacr())

        # w7 ends at last-read position (no post-inc on last MAC).
        # Last read was at (write_pos + M - 1) % M = (write_pos - 1) % M.
        # That becomes the next sample's write position.
        write_pos = (write_pos - 1) % num_taps

    return np.array(output, dtype=np.int32)


def generate_fir_denoising_test_data_q31(fs=200, f_sin=1, f_noise=25,
                                          duration=2, num_taps=15):
    """Generate FIR test data in Q31 format using dsPIC33AK model."""
    block_size = int(fs * duration)
    t = np.arange(block_size) / fs

    # Generate noisy signal in float, normalized to [-1.0, +1.0)
    clean_signal = 0.3 * np.sin(2 * np.pi * f_sin * t)
    noise = 0.1 * np.sin(2 * np.pi * f_noise * t)
    noisy_signal = (clean_signal + noise).astype(np.float32)

    # Clip to Q31 range
    noisy_signal = np.clip(noisy_signal, -1.0, 1.0 - 1e-10)

    # Design FIR filter coefficients
    coeffs = firwin(num_taps, f_noise - 5, fs=fs).astype(np.float32)
    # Normalize coefficients to fit Q31 range
    coeffs = np.clip(coeffs, -1.0, 1.0 - 1e-10).astype(np.float32)

    # Convert to Q31
    noisy_q31 = float_array_to_q31(noisy_signal)
    coeffs_q31 = float_array_to_q31(coeffs)

    # Process with dsPIC33AK model (sacr.l convergent rounding)
    output_q31 = dspic_fir_filter_q31(noisy_q31, coeffs_q31, num_taps)

    return {
        "t": t,
        "sampling_rate": fs,
        "num_taps": num_taps,
        "block_size": block_size,
        "coeffs_q31": coeffs_q31,
        "input_q31": noisy_q31,
        "expected_output_q31": output_q31,
    }


def fir_q31():
    fs = 200
    f_sin = 1
    f_noise = 25
    duration = 2
    num_taps = 15

    print("\n\n Generating FIR Q31 Test Data: ")

    data = generate_fir_denoising_test_data_q31(fs, f_sin, f_noise, duration, num_taps)

    input_q31 = data["input_q31"]
    output_q31 = data["expected_output_q31"]
    coeffs_q31 = data["coeffs_q31"]
    block_size = data["block_size"]
    num_taps = data["num_taps"]

    output_str = test_to_template["fir_q31_test_inputs"]
    output_str = output_str.replace("<<INSERT_IS_HERE>>", c_array_q31(input_q31))
    output_str = output_str.replace("<<INSERT_OS_HERE>>", c_array_q31(output_q31))
    output_str = output_str.replace("<<INSERT_COEFFS_HERE>>", c_array_q31(coeffs_q31))
    output_str = output_str.replace("<<INSERT_BLOCK_SIZE_HERE>>", str(block_size))
    output_str = output_str.replace("<<INSERT_NUMTAPS_HERE>>", str(num_taps))
    replace_test_file("fir_q31_test_inputs", output_str)

    output_str = test_to_template["fir_q31_test_header"]
    output_str = output_str.replace("<<INSERT_BLOCK_SIZE_HERE>>", str(block_size))
    output_str = output_str.replace("<<INSERT_NUMTAPS_HERE>>", str(num_taps))
    replace_test_file("fir_q31_test_header", output_str)

    print("\n\n Done Generating FIR Q31 Test Data")
