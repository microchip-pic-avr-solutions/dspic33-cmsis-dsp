import os
import numpy as np
from helper import *

try:
    import cmsisdsp as dsp
except:
    os.system("python -m pip install cmsisdsp")

# ---------------------------------------------------------
# Templates for C code generation
# ---------------------------------------------------------
test_to_template = {

    "fir_lms_f32_test_inputs": """<<INSERT_DISCLAIMER_HERE>>

#include "../../main.h"
#include "fir_lms_f32_test.h"

#ifdef FILTER_LIB_TEST
#ifdef DATA_SET_I

float32_t FIR_LMS_INPUT[]          = <<INSERT_LMS_INPUT_HERE>>;
float32_t FIR_LMS_DESIRED[]        = <<INSERT_LMS_DESIRED_HERE>>;
float32_t FIR_LMS_COEFF_INITIAL[]  = <<INSERT_LMS_COEFFS_HERE>>;

// Reference expected results
float32_t FIR_LMS_OUTPUT_REF[]     = <<INSERT_LMS_OUTPUT_REF_HERE>>;
float32_t FIR_LMS_ERROR_REF[]      = <<INSERT_LMS_ERROR_REF_HERE>>;
float32_t FIR_LMS_COEFF_FINAL_REF[]= <<INSERT_LMS_COEFF_FINAL_HERE>>;

float32_t FIR_LMS_STATE[FIR_LMS_BLOCK_SIZE + FIR_LMS_SIZE];

#endif
#endif
""",

    "fir_lms_f32_test_header": """<<INSERT_DISCLAIMER_HERE>>

#include "../../main.h"

#ifdef FILTER_LIB_TEST
#ifdef DATA_SET_I

#define FIR_LMS_BLOCK_SIZE    <<INSERT_LMS_BLOCK_SIZE_HERE>>
#define FIR_LMS_SIZE          <<INSERT_LMS_SIZE_HERE>>
#define FIR_LMS_MU            <<INSERT_LMS_MU_HERE>>

extern float32_t FIR_LMS_INPUT[];
extern float32_t FIR_LMS_DESIRED[];
extern float32_t FIR_LMS_COEFF_INITIAL[];

extern float32_t FIR_LMS_OUTPUT_REF[];
extern float32_t FIR_LMS_ERROR_REF[];
extern float32_t FIR_LMS_COEFF_FINAL_REF[];

extern float32_t FIR_LMS_STATE[FIR_LMS_BLOCK_SIZE + FIR_LMS_SIZE];

#endif
#endif
""",
}



# ---------------------------------------------------------
# Python implementation of CMSIS arm_lms_f32
# ---------------------------------------------------------
def lms_f32_python(input_signal, desired_signal, coeffs_initial, mu):
    num_taps = len(coeffs_initial)
    block_size = len(input_signal)

    # CMSIS state length
    state = np.zeros(num_taps + block_size - 1, dtype=np.float32)

    coeffs = coeffs_initial.copy().astype(np.float32)

    output = np.zeros(block_size, dtype=np.float32)
    error = np.zeros(block_size, dtype=np.float32)

    for n in range(block_size):

        state[1:] = state[:-1]
        state[0] = input_signal[n]

        # FIR output
        y = np.dot(coeffs, state[:num_taps])
        output[n] = y

        # LMS error
        e = desired_signal[n] - y
        error[n] = e

        # Coefficient update
        coeffs += mu * e * state[:num_taps]

    return output, error, coeffs



# ---------------------------------------------------------
# Generate FIR LMS reference dataset
# ---------------------------------------------------------
def generate_random_fir_lms_test_data(num_stage=4, block_size=20, mu=0.05, seed=None):

    if seed is not None:
        np.random.seed(seed)

    input_signal = np.random.uniform(-1.0, 1.0, block_size).astype(np.float32)
    desired_signal = np.random.uniform(-1.0, 1.0, block_size).astype(np.float32)
    coeffs_initial = np.random.uniform(-0.5, 0.5, num_stage).astype(np.float32)

    # Get reference output, error, and final coefficients
    output_signal, error_signal, coeffs_final = lms_f32_python(
        input_signal, desired_signal, coeffs_initial, mu
    )

    return {
        "num_stage": num_stage,
        "block_size": block_size,
        "mu": mu,
        "input_signal": input_signal.tolist(),
        "desired_signal": desired_signal.tolist(),
        "output_signal": output_signal.tolist(),
        "error_signal": error_signal.tolist(),
        "coeffs_initial": coeffs_initial.tolist(),
        "coeffs_final": coeffs_final.tolist()
    }
    
# ---------------------------------------------------------
# Main function to write files
# ---------------------------------------------------------
def lms_f32():

    print("\n Generating LMS Test Data")
    
    #Need error updated coefficients and new output to be comapred which is not available in CMSIS API
    data = generate_random_fir_lms_test_data()

    input_signal = data["input_signal"]
    desired_signal = data["desired_signal"]
    output_signal = data["output_signal"]
    error_signal = data["error_signal"]
    coeffs_initial = data["coeffs_initial"]
    coeffs_final = data["coeffs_final"]

    block_size = data["block_size"]
    num_stage = data["num_stage"]
    mu = data["mu"]

    # -----------------------------------------------------
    # Generate fir_lms_f32_test_inputs.c
    # -----------------------------------------------------
    input_c = test_to_template["fir_lms_f32_test_inputs"]
    input_c = input_c.replace("<<INSERT_LMS_INPUT_HERE>>", c_array(input_signal))
    input_c = input_c.replace("<<INSERT_LMS_DESIRED_HERE>>", c_array(desired_signal))
    input_c = input_c.replace("<<INSERT_LMS_COEFFS_HERE>>", c_array(coeffs_initial))

    input_c = input_c.replace("<<INSERT_LMS_OUTPUT_REF_HERE>>", c_array(output_signal))
    input_c = input_c.replace("<<INSERT_LMS_ERROR_REF_HERE>>", c_array(error_signal))
    input_c = input_c.replace("<<INSERT_LMS_COEFF_FINAL_HERE>>", c_array(coeffs_final))

    input_c = input_c.replace("<<INSERT_LMS_BLOCK_SIZE_HERE>>", str(block_size))
    input_c = input_c.replace("<<INSERT_LMS_SIZE_HERE>>", str(num_stage))

    replace_test_file("fir_lms_f32_test_inputs", input_c)


    # -----------------------------------------------------
    # Generate fir_lms_f32_test_header.h
    # -----------------------------------------------------
    header_h = test_to_template["fir_lms_f32_test_header"]
    header_h = header_h.replace("<<INSERT_LMS_BLOCK_SIZE_HERE>>", str(block_size))
    header_h = header_h.replace("<<INSERT_LMS_SIZE_HERE>>", str(num_stage))
    header_h = header_h.replace("<<INSERT_LMS_MU_HERE>>", str(mu))

    replace_test_file("fir_lms_f32_test_header", header_h)

    print("Done Generating LMS Test Data\n")



if __name__ == "__main__":
    lms_f32()
