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

"iir_lattice_f32_test_inputs": """<<INSERT_DISCLAIMER_HERE>>

#include "../../main.h"
#include "iir_lattice_f32_test.h"

#ifdef FILTER_LIB_TEST
#ifdef DATA_SET_I

float32_t IIR_LATTICE_INPUT[] = <<INSERT_IIR_IS_HERE>>;
float32_t IIR_LATTICE_PK[]    = <<INSERT_IIR_PK_HERE>>;
float32_t IIR_LATTICE_PV[]    = <<INSERT_IIR_PV_HERE>>;
float32_t IIR_LATTICE_OUTPUT[] = <<INSERT_IIR_OS_HERE>>;
float32_t IIR_LATTICE_STATE[IIR_LATTICE_BLOCK_SIZE + IIR_LATTICE_STAGES];

#endif
#endif
""",

"iir_lattice_f32_test_header": """<<INSERT_DISCLAIMER_HERE>>

#include "../../main.h"

#ifdef FILTER_LIB_TEST
#ifdef DATA_SET_I

#define IIR_LATTICE_BLOCK_SIZE <<INSERT_IIR_BLOCK_SIZE_HERE>>
#define IIR_LATTICE_STAGES <<INSERT_IIR_STAGES_HERE>>

extern float32_t IIR_LATTICE_INPUT[];
extern float32_t IIR_LATTICE_OUTPUT[];
extern float32_t IIR_LATTICE_PK[];
extern float32_t IIR_LATTICE_PV[];
extern float32_t IIR_LATTICE_STATE[IIR_LATTICE_BLOCK_SIZE + IIR_LATTICE_STAGES];

#endif
#endif
""",
}


# ================================================================
#   Generate stable IIR test using Butterworth → lattice conversion
# ================================================================

def generate_stable_iir_lattice_test_data(
    order=32,
    cutoff=0.2,
    block_size=128,
    seed=None
):

    if seed is not None:
        np.random.seed(seed)

    # 1) Generate stable low-pass Butterworth
    #b, a = butter(order, cutoff)

    # 2) Convert denominator into reflection coefficients
    pk = list(signal.firwin(32, [0.33]))

    # 3) Ladder coefficients = numerator
    pv = list(signal.firwin(33, [0.36]))
    # 4) Input
    input_signal = np.random.rand(block_size).astype(np.float32)

    # 5) CMSIS processing
    S = dsp.arm_iir_lattice_instance_f32()
    state = np.zeros(block_size + order, dtype=np.float32)

    dsp.arm_iir_lattice_init_f32(S, order, pk, pv, state)
    output = dsp.arm_iir_lattice_f32(S, input_signal)

    return {
        "num_stages": order,
        "block_size": block_size,
        "pk": pk,
        "pv": pv,
        "input_signal": input_signal.tolist(),
        "expected_output": output.tolist(),
    }


# ================================================================
#   File Generation Wrapper
# ================================================================

def iir_lattice_f32():

    print("\nGenerating IIR Lattice Test Data...")

    data = generate_stable_iir_lattice_test_data(
        order=32,
        cutoff=0.2,
        block_size=128,
        seed=123
    )

    input_signal = np.array(data["input_signal"])
    pk = np.array(data["pk"])
    pv = np.array(data["pv"])
    output_signal = np.array(data["expected_output"])
    block_size = data["block_size"]
    num_stages = data["num_stages"]

    # .c file
    output_c = test_to_template["iir_lattice_f32_test_inputs"]
    output_c = output_c.replace("<<INSERT_IIR_IS_HERE>>", c_array(input_signal))
    output_c = output_c.replace("<<INSERT_IIR_PK_HERE>>", c_array(pk))
    output_c = output_c.replace("<<INSERT_IIR_PV_HERE>>", c_array(pv))
    output_c = output_c.replace("<<INSERT_IIR_OS_HERE>>", c_array(output_signal))
    output_c = output_c.replace("<<INSERT_IIR_BLOCK_SIZE_HERE>>", str(block_size))
    output_c = output_c.replace("<<INSERT_IIR_STAGES_HERE>>", str(num_stages))

    replace_test_file("iir_lattice_f32_test_inputs", output_c)

    # .h file
    output_h = test_to_template["iir_lattice_f32_test_header"]
    output_h = output_h.replace("<<INSERT_IIR_BLOCK_SIZE_HERE>>", str(block_size))
    output_h = output_h.replace("<<INSERT_IIR_STAGES_HERE>>", str(num_stages))

    replace_test_file("iir_lattice_f32_test_header", output_h)

    print("IIR lattice test files generated")


# Standalone execution
if __name__ == "__main__":
    iir_lattice_f32()
