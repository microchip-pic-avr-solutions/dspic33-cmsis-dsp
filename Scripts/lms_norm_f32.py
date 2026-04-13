import os
import numpy as np
from helper import *

try:
    import cmsisdsp as dsp
except:
    os.system("python -m pip install cmsisdsp")
try:
    from scipy import signal
except:
    os.system("python -m pip install scipy")

gSCL_VAL = 2
gOFFSET_VAL = 1

# ---------------------------------------------------------
# Templates for C code generation
# ---------------------------------------------------------
test_to_template = {
    "fir_lms_norm_f32_test_inputs": """<<INSERT_DISCLAIMER_HERE>>

#include "../../main.h"
#include "fir_lms_norm_f32_test.h"

#ifdef FILTER_LIB_TEST
#ifdef DATA_SET_I

float32_t FIR_LMS_NORM_INPUT[]          = <<INSERT_LMS_NORM_INPUT_HERE>>;
float32_t FIR_LMS_NORM_DESIRED[]        = <<INSERT_LMS_NORM_DESIRED_HERE>>;
float32_t FIR_LMS_NORM_COEFF_INITIAL[]  = <<INSERT_LMS_NORM_COEFFS_HERE>>;

// Reference expected results
float32_t FIR_LMS_NORM_OUTPUT_REF[]     = <<INSERT_LMS_NORM_OUTPUT_REF_HERE>>;
float32_t FIR_LMS_NORM_ERROR_REF[]      = <<INSERT_LMS_NORM_ERROR_REF_HERE>>;
float32_t FIR_LMS_NORM_COEFF_FINAL_REF[]= <<INSERT_LMS_NORM_COEFF_FINAL_HERE>>;

float32_t FIR_LMS_NORM_STATE[FIR_LMS_NORM_BLOCK_SIZE + FIR_LMS_NORM_SIZE];

#endif
#endif
""",

    "fir_lms_norm_f32_test_header": """<<INSERT_DISCLAIMER_HERE>>

#include "../../main.h"

#ifdef FILTER_LIB_TEST
#ifdef DATA_SET_I

#define FIR_LMS_NORM_BLOCK_SIZE    <<INSERT_LMS_NORM_BLOCK_SIZE_HERE>>
#define FIR_LMS_NORM_SIZE          <<INSERT_LMS_NORM_SIZE_HERE>>
#define FIR_LMS_NORM_MU            <<INSERT_LMS_NORM_MU_HERE>>
#define FIR_LMS_ENERGY_EXPECTED    <<INSERT_LMS_NORM_ENERGY_HERE>>

extern float32_t FIR_LMS_NORM_INPUT[];
extern float32_t FIR_LMS_NORM_DESIRED[];
extern float32_t FIR_LMS_NORM_COEFF_INITIAL[];

extern float32_t FIR_LMS_NORM_OUTPUT_REF[];
extern float32_t FIR_LMS_NORM_ERROR_REF[];
extern float32_t FIR_LMS_NORM_COEFF_FINAL_REF[];

extern float32_t FIR_LMS_NORM_STATE[FIR_LMS_NORM_BLOCK_SIZE + FIR_LMS_NORM_SIZE];

#endif
#endif
""",
}


def FIRLMSN():
    N = 128
    print("\n\n FIR LMS Norm Test : ")
    mu = 0.125
    FIR_src = []
    x = FIR_src = gSCL_VAL*np.random.rand(N).astype(np.float32) - gOFFSET_VAL
    CoEffs = signal.firwin(32, [0.33])
    CoEffs_actual = signal.firwin(32, [0.41])
    r = list(signal.lfilter(b=CoEffs_actual, a=[1], x=x))
    y = [0 for i in range(0, len(FIR_src))]  # (0,N)
    e = [0 for i in range(0, len(FIR_src))]  # (0,N)
    error = [0 for i in range(0, len(FIR_src))]  # (0,N)
    h = list(CoEffs)  # (0,M)
    M = len(CoEffs)
    h_init = list(CoEffs)
    print("h : ", iQ31(h))
    for n in range(0, len(FIR_src)):
        
        for m in range(0, len(CoEffs)):
            if n < m:
                break
            y[n] += (x[n - m] * h[m])
        if n - M + 1 >= 0:
            e[n] = ((e[n - 1] + (x[n] * x[n])) - (x[n - M + 1] * x[n - M + 1]))
        else:
            e[n] = (e[n - 1] + (x[n] * x[n]))
        if (e[n] < 0 or e[n] >= 1):
            print(n, "INVALID ENERGY FACTOR..................", e[n])
        nu = (mu / ((mu + e[n])))
        error[n] = (r[n] - y[n])
        a = ((nu * (r[n] - y[n])))
        for m in range(0, len(CoEffs)):
            if n < m:
                break
            b = (a * x[n - m])
            h[m] = ((h[m] + b))
        
    return {
        "num_stage": 32,
        "block_size": N,
        "mu": mu,
        "input_signal": x.tolist(),
        "desired_signal": r,
        "output_signal": y,
        "error_signal": error,
        "coeffs_initial": h_init,
        "coeffs_final": h,
        "energy": e[-1]
    }

# ---------------------------------------------------------
# Main function to generate C test files
# ---------------------------------------------------------
def lms_norm_f32():
    print("\nGenerating CMSIS-style LMS-Norm Test Data...")

    data = FIRLMSN()

    input_signal = data["input_signal"]
    desired_signal = data["desired_signal"]
    output_signal = data["output_signal"]
    error_signal = data["error_signal"]
    coeffs_initial = data["coeffs_initial"]
    coeffs_final = data["coeffs_final"]

    block_size = data["block_size"]
    num_stage = data["num_stage"]
    mu = data["mu"]
    energy = data["energy"]

    # -----------------------------------------------------
    # Generate fir_lms_norm_f32_test_inputs.c
    # -----------------------------------------------------
    input_c = test_to_template["fir_lms_norm_f32_test_inputs"]
    input_c = input_c.replace("<<INSERT_LMS_NORM_INPUT_HERE>>", c_array(input_signal))
    input_c = input_c.replace("<<INSERT_LMS_NORM_DESIRED_HERE>>", c_array(desired_signal))
    input_c = input_c.replace("<<INSERT_LMS_NORM_COEFFS_HERE>>", c_array(coeffs_initial))
    input_c = input_c.replace("<<INSERT_LMS_NORM_OUTPUT_REF_HERE>>", c_array(output_signal))
    input_c = input_c.replace("<<INSERT_LMS_NORM_ERROR_REF_HERE>>", c_array(error_signal))
    input_c = input_c.replace("<<INSERT_LMS_NORM_COEFF_FINAL_HERE>>", c_array(coeffs_final))
    input_c = input_c.replace("<<INSERT_LMS_NORM_BLOCK_SIZE_HERE>>", str(block_size))
    input_c = input_c.replace("<<INSERT_LMS_NORM_SIZE_HERE>>", str(num_stage))

    replace_test_file("fir_lms_norm_f32_test_inputs", input_c)

    # -----------------------------------------------------
    # Generate fir_lms_norm_f32_test_header.h
    # -----------------------------------------------------
    header_h = test_to_template["fir_lms_norm_f32_test_header"]
    header_h = header_h.replace("<<INSERT_LMS_NORM_BLOCK_SIZE_HERE>>", str(block_size))
    header_h = header_h.replace("<<INSERT_LMS_NORM_SIZE_HERE>>", str(num_stage))
    header_h = header_h.replace("<<INSERT_LMS_NORM_MU_HERE>>", str(mu))
    header_h = header_h.replace("<<INSERT_LMS_NORM_ENERGY_HERE>>",str(energy))

    replace_test_file("fir_lms_norm_f32_test_header", header_h)

    print("Done Generating CMSIS-style LMS-Norm Test Data.\n")


if __name__ == "__main__":
    lms_norm_f32()
