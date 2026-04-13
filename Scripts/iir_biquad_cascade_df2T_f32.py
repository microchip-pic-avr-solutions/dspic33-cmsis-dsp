import numpy as np
import os
from scipy import signal

try:
    import cmsisdsp as dsp
except:
    os.system("python -m pip install cmsisdsp")

from helper import *

# ================================================================
#  C FILE TEMPLATES
# ================================================================

test_to_template = {

"iir_canonic_f32_test_inputs": """<<INSERT_DISCLAIMER_HERE>>

#include "../../main.h"
#include "biquad_cascade_df2T_f32_test.h"

#ifdef FILTER_LIB_TEST
#ifdef DATA_SET_I

float32_t IIR_CANONIC_INPUT[] = <<INSERT_IIR_IS_HERE>>;
float32_t IIR_CANONIC_COEFF[]    = <<INSERT_IIR_COEFF_HERE>>;
float32_t IIR_CANONIC_OUTPUT[] = <<INSERT_IIR_OS_HERE>>;
float32_t IIR_CANONIC_STATE[2*IIR_CANONIC_STAGES];

#endif
#endif
""",

"iir_canonic_f32_test_header": """<<INSERT_DISCLAIMER_HERE>>

#include "../../main.h"

#ifdef FILTER_LIB_TEST
#ifdef DATA_SET_I

#define IIR_CANONIC_BLOCK_SIZE <<INSERT_IIR_BLOCK_SIZE_HERE>>
#define IIR_CANONIC_STAGES <<INSERT_IIR_STAGES_HERE>>

extern float32_t IIR_CANONIC_INPUT[];
extern float32_t IIR_CANONIC_OUTPUT[];
extern float32_t IIR_CANONIC_COEFF[];
extern float32_t IIR_CANONIC_STATE[2*IIR_CANONIC_STAGES];

#endif
#endif
""",
}


# ================================================================
#   Generate stable IIR test using Butterworth → lattice conversion
# ================================================================

def generate_stable_iir_canonic_test_data(
    order=2,
    block_size=32,
    seed=None
):

    if seed is not None:
        np.random.seed(seed)

    coeff = [
    0.2929, 0.5858, 0.2929, -0.0000, 0.1716,
    0.2066, 0.4131, 0.2066, -0.3695, 0.1958
    ]

    input_signal = np.random.rand(block_size).astype(np.float32)

    # 5) CMSIS processing
    S = dsp.arm_biquad_cascade_df2T_instance_f32()
    state = np.zeros(block_size*2, dtype=np.float32)

    dsp.arm_biquad_cascade_df2T_init_f32(S, order, coeff,state)
    output = dsp.arm_biquad_cascade_df2T_f32(S, input_signal)

    return {
        "num_stages": order,
        "block_size": block_size,
        "coeff": coeff,
        "input_signal": input_signal.tolist(),
        "expected_output": output.tolist(),
    }

def iir_canonic_f32():

    print("\nGenerating IIR Canonic Test Data...")

    data = generate_stable_iir_canonic_test_data(
        order=2,
        block_size=32,
        seed=123
    )

    input_signal = np.array(data["input_signal"])
    coeff = np.array(data["coeff"])
    output_signal = np.array(data["expected_output"])
    block_size = data["block_size"]
    num_stages = data["num_stages"]

    # .c file
    output_c = test_to_template["iir_canonic_f32_test_inputs"]
    output_c = output_c.replace("<<INSERT_IIR_IS_HERE>>", c_array(input_signal))
    output_c = output_c.replace("<<INSERT_IIR_COEFF_HERE>>", c_array(coeff))
    output_c = output_c.replace("<<INSERT_IIR_OS_HERE>>", c_array(output_signal))
    output_c = output_c.replace("<<INSERT_IIR_BLOCK_SIZE_HERE>>", str(block_size))
    output_c = output_c.replace("<<INSERT_IIR_STAGES_HERE>>", str(num_stages))

    replace_test_file("iir_canonic_f32_test_inputs", output_c)

    # .h file
    output_h = test_to_template["iir_canonic_f32_test_header"]
    output_h = output_h.replace("<<INSERT_IIR_BLOCK_SIZE_HERE>>", str(block_size))
    output_h = output_h.replace("<<INSERT_IIR_STAGES_HERE>>", str(num_stages))

    replace_test_file("iir_canonic_f32_test_header", output_h)

    print("IIR Canonic test files generated")


# Standalone execution
if __name__ == "__main__":
    iir_canonic_f32()
