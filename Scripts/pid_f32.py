import numpy as np
import random
import matplotlib.pyplot as plt
import os

try:
    import cmsisdsp as dsp
except:
    os.system("python -m pip install cmsisdsp")
    import cmsisdsp as dsp

from helper import *   # contains c_array(), replace_test_file(), DISCLAIMER


# ---------------------------------------------------------------------------
#  TEMPLATES
# ---------------------------------------------------------------------------

test_to_template_pid = {

"pid_f32_test_inputs": """<<INSERT_DISCLAIMER_HERE>>

#include "../../MAIN.h"
#include "pid_f32_test.h"

#ifdef CONTROL_LIB_TEST
#ifdef DATA_SET_I

float32_t PID_KP[] = <<INSERT_KP_HERE>>;
float32_t PID_KI[] = <<INSERT_KI_HERE>>;
float32_t PID_KD[] = <<INSERT_KD_HERE>>;

float32_t PID_A0[] = <<INSERT_A0_HERE>>;
float32_t PID_A1[] = <<INSERT_A1_HERE>>;
float32_t PID_A2[] = <<INSERT_A2_HERE>>;

//following values are for Kp[0], Ki[0] and Kd[0]
float32_t PID_INPUT[] = <<INSERT_IS_HERE>>;
float32_t PID_OUTPUT[] = <<INSERT_OS_HERE>>;

float32_t STATE[3];

#endif
#endif
""",

"pid_f32_test_header": """<<INSERT_DISCLAIMER_HERE>>

#include "../../MAIN.h"

#ifdef CONTROL_LIB_TEST
#ifdef DATA_SET_I

#define BLOCK_SIZE <<INSERT_BLOCK_SIZE_HERE>>

extern float32_t PID_KP[];
extern float32_t PID_KI[];
extern float32_t PID_KD[];

extern float32_t PID_A0[];
extern float32_t PID_A1[];
extern float32_t PID_A2[];

extern float32_t PID_INPUT[];
extern float32_t PID_OUTPUT[];

extern float32_t STATE[3];

#endif
#endif
""",
}



# ---------------------------------------------------------------------------
#  PID SIGNAL GENERATION (Correct per-sample gains with state preserved)
# ---------------------------------------------------------------------------

def generate_pid_test_data():
    N = 10

    # Random arrays (keep ranges small to avoid huge values)
    Kp = np.random.uniform(0.1, 0.5, N).astype(np.float32)
    Ki = np.random.uniform(0.01, 0.05, N).astype(np.float32)
    Kd = np.random.uniform(0.0, 0.02, N).astype(np.float32)
    ein = np.random.uniform(-1.0, 1.0, N).astype(np.float32)

    
    A0 = np.zeros(N, dtype=np.float32)
    A1 = np.zeros(N, dtype=np.float32)
    A2 = np.zeros(N, dtype=np.float32)


    # Output array
    output = []

    # ------------------------------------------------------------
    # Initialize ONE PID instance (correct behavior)
    # ------------------------------------------------------------
    pid = dsp.arm_pid_instance_f32(Kp= float(Kp[0]), Ki = float(Ki[0]), Kd = float(Kd[0]))

    dsp.arm_pid_init_f32(pid, True)  # clears state once

    # ------------------------------------------------------------
    # Process each sample (modify gains but keep internal state)
    # ------------------------------------------------------------
    last_input = 0.0

    for i in range(N):
        
        # Compute A0/A1/A2 (Direct Form)
        A0[i] = Kp[i] + Ki[i] + Kd[i]
        A1[i] = -(Kp[i] + 2.0 * Kd[i])
        A2[i] = Kd[i]

        # Compute CMSIS PID output
        y = dsp.arm_pid_f32(pid, float(ein[i]))
        print("y: "+str(y))
        print("y+A2: "+str(y+A2[i]))
        print("y-A2: "+str(y-A2[i]))
        output.append(y)

    # Convert to python lists
    return {
        "block_size": N,
        "input_signal": ein.tolist(),
        "expected_output": output,

        "kp": Kp.tolist(),
        "ki": Ki.tolist(),
        "kd": Kd.tolist(),

        "A0": A0.tolist(),
        "A1": A1.tolist(),
        "A2": A2.tolist(),
    }



# ---------------------------------------------------------------------------
#  WRAPPER
# ---------------------------------------------------------------------------

def pid_f32():

    print("\n\n Generating PID Test Data: ")

    data = generate_pid_test_data()

    input_signal = np.array(data["input_signal"], dtype=float)
    output_signal = np.array(data["expected_output"], dtype=float)

    kp = np.array(data["kp"], dtype=float)
    ki = np.array(data["ki"], dtype=float)
    kd = np.array(data["kd"], dtype=float)
    A0 = np.array(data["A0"], dtype=float)
    A1 = np.array(data["A1"], dtype=float)
    A2 = np.array(data["A2"], dtype=float)

    block_size = data["block_size"]

    # --- .c file generation ---
    output_str = test_to_template_pid["pid_f32_test_inputs"]

    output_str = output_str.replace("<<INSERT_IS_HERE>>", c_array(input_signal))
    output_str = output_str.replace("<<INSERT_OS_HERE>>", c_array(output_signal))

    output_str = output_str.replace("<<INSERT_KP_HERE>>", c_array(kp))
    output_str = output_str.replace("<<INSERT_KI_HERE>>", c_array(ki))
    output_str = output_str.replace("<<INSERT_KD_HERE>>", c_array(kd))

    output_str = output_str.replace("<<INSERT_A0_HERE>>", c_array(A0))
    output_str = output_str.replace("<<INSERT_A1_HERE>>", c_array(A1))
    output_str = output_str.replace("<<INSERT_A2_HERE>>", c_array(A2))

    replace_test_file("pid_f32_test_inputs", output_str)

    # --- header file ---
    output_str = test_to_template_pid["pid_f32_test_header"]
    output_str = output_str.replace("<<INSERT_BLOCK_SIZE_HERE>>", str(block_size))

    replace_test_file("pid_f32_test_header", output_str)

    print("\n\n Done Generating PID Test Data")
