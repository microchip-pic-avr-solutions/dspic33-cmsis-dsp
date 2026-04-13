import random
from scipy.signal import firwin
import matplotlib.pyplot as plt
from helper import *

try:
    import cmsisdsp as dsp
except:
    os.system("python -m pip install cmsisdsp")

test_to_template = {
    # Control tests
    "fir_inter_f32_test_inputs": """<<INSERT_DISCLAIMER_HERE>>

#include "../../main.h"
#include "fir_inter_f32_test.h"

#ifdef FILTER_LIB_TEST

#ifdef DATA_SET_I

float32_t FIR_INTER_INPUT[] = <<INSERT_INTER_IS_HERE>>;
float32_t FIR_INTER_COEFF[] = <<INSERT_INTER_COEFFS_HERE>>;
float32_t FIR_INTER_OUTPUT[] = <<INSERT_INTER_OS_HERE>>;
float32_t FIR_INTER_STATE[FIR_INTER_BLOCK_SIZE+FIR_INTER_NUMTAPS_SIZE-1];

#endif

#endif
""",
# Fir tests
    "fir_inter_f32_test_header": """<<INSERT_DISCLAIMER_HERE>>

#include "../../main.h"

#ifdef FILTER_LIB_TEST

#ifdef DATA_SET_I
#define FIR_INTER_BLOCK_SIZE <<INSERT_INTER_BLOCK_SIZE_HERE>>
#define FIR_INTER_RATE <<INSERT_INTER_RATE_HERE>>
#define FIR_INTER_NUMTAPS_SIZE <<INSERT_INTER_NUMTAPS_HERE>>

extern float32_t FIR_INTER_INPUT[];
extern float32_t FIR_INTER_OUTPUT[];
extern float32_t FIR_INTER_COEFF[];
extern float32_t FIR_INTER_STATE[FIR_INTER_BLOCK_SIZE+FIR_INTER_NUMTAPS_SIZE-1];

#endif

#endif
""",}

def generate_random_fir_inter_test_data(num_taps=32, inter_rate=4, block_size=128, seed=None):

    # CMSIS requirement
    assert block_size % inter_rate == 0, \
        f"block_size ({block_size}) must be a multiple of inter_rate ({inter_rate})"

    if seed is not None:
        np.random.seed(seed)

    coeffs= np.array([
            -0.0012181676454745339, -0.0017934634668666594, 0.000043543532,
            0.003831382370509822, 0.004445165403381914, -0.0031870292573056057,
            -0.012758068864731267, -0.00776823233257993, 0.015565226638006642,
            0.03074853177681216, 0.0047277812793199035, -0.050605834538322764,
            -0.06481867209410139, 0.028075125002651382, 0.20514782216818284,
            0.3495648900319511, 0.3495648900319511, 0.20514782216818284,
            0.028075125002651382, -0.06481867209410139, -0.05060583453832275,
            0.004727781279319903, 0.03074853177681216, 0.015565226638006639,
            -0.007768232332579928, -0.012758068864731263, -0.0031870292573056057,
            0.004445165403381914, 0.003831382370509822, 0.000043543532,
            -0.0017934634668666594, -0.0012181676454745339
        ], dtype=np.float32)
    input_signal = np.random.uniform(-10.0, 10.0, block_size).astype(np.float32)
    S = dsp.arm_fir_interpolate_instance_f32()
    state = np.zeros(block_size + num_taps - 1, dtype=np.float32)    

    dsp.arm_fir_interpolate_init_f32(S, inter_rate,num_taps, coeffs, state)
    output  = dsp.arm_fir_interpolate_f32(S, input_signal)

    return {
        "num_taps": num_taps,
        "block_size": block_size,
        "coeffs": coeffs.tolist(),
        "inter_rate": inter_rate,
        "input_signal": input_signal.tolist(),
        "expected_output": output.tolist()
    }

def fir_inter_f32():
    
    fs=200                 # Sampling frequency (Hz)
    f_sin=1                # Frequency of sine wave (Hz)
    f_noise=25            # Frequency of high-frequency noise (Hz)
    duration=2           # seconds
    num_taps=15            # Number of FIR taps
    inter_rate= 6
    seed=None
    
    print("\n\n Generating FIR Interpolate Test Data: ")
    
    data = generate_random_fir_inter_test_data()
    
    input_signal = np.array(data["input_signal"])
    output_signal = np.array(data["expected_output"])
    coeffs = np.array(data["coeffs"])
    block_size = np.array(data["block_size"])
    num_taps = np.array(data["num_taps"])
    inter_rate = np.array(data["inter_rate"])
    
    output_str = test_to_template["fir_inter_f32_test_inputs"]
    output_str = output_str.replace("<<INSERT_INTER_IS_HERE>>", c_array(input_signal))
    output_str = output_str.replace("<<INSERT_INTER_OS_HERE>>", c_array(output_signal))
    output_str = output_str.replace("<<INSERT_INTER_COEFFS_HERE>>", c_array(coeffs))
    output_str = output_str.replace("<<INSERT_INTER_BLOCK_SIZE_HERE>>", str(block_size))
    output_str = output_str.replace("<<INSERT_INTER_NUMTAPS_HERE>>", str(num_taps))
    replace_test_file("fir_inter_f32_test_inputs", output_str)
    
    output_str = test_to_template["fir_inter_f32_test_header"]
    output_str = output_str.replace("<<INSERT_INTER_BLOCK_SIZE_HERE>>", str(block_size))
    output_str = output_str.replace("<<INSERT_INTER_NUMTAPS_HERE>>", str(num_taps))
    output_str = output_str.replace("<<INSERT_INTER_RATE_HERE>>", str(inter_rate))
    replace_test_file("fir_inter_f32_test_header", output_str)

    print("\n\n Done Generating FIR Interpolate Test Data") 