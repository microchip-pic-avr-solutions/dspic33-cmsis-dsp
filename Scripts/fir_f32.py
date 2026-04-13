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
    "fir_f32_test_inputs": """<<INSERT_DISCLAIMER_HERE>>

#include "../../main.h"
#include "fir_f32_test.h"

#ifdef FILTER_LIB_TEST

#ifdef DATA_SET_I

float32_t FIR_INPUT[] = <<INSERT_IS_HERE>>;
float32_t FIR_OUTPUT[] = <<INSERT_OS_HERE>>;
float32_t FIR_COEFF[] = <<INSERT_COEFFS_HERE>>;
float32_t STATE[BLOCK_SIZE+NUMTAPS_SIZE-1];

#endif

#endif
""",
# Control tests
    "fir_f32_test_header": """<<INSERT_DISCLAIMER_HERE>>

#include "../../main.h"

#ifdef FILTER_LIB_TEST

#ifdef DATA_SET_I
#define BLOCK_SIZE <<INSERT_BLOCK_SIZE_HERE>>
#define NUMTAPS_SIZE <<INSERT_NUMTAPS_HERE>>

extern float32_t FIR_INPUT[];
extern float32_t FIR_OUTPUT[];
extern float32_t FIR_COEFF[];
extern float32_t STATE[BLOCK_SIZE+NUMTAPS_SIZE-1];

#endif

#endif
""",}
    
def generate_fir_denoising_test_data(
    fs=1000,                 # Sampling frequency (Hz)
    f_sin=5,                # Frequency of sine wave (Hz)
    f_noise=200,            # Frequency of high-frequency noise (Hz)
    duration=2.0,           # seconds
    num_taps=101,            # Number of FIR taps
    seed=None
):
    """
    Generate test case for FIR denoising: sine wave + noise filtered by low-pass FIR.
    Returns dict with filter coefficients, input, expected output.
    """

    if seed is not None:
        np.random.seed(seed)

    t = np.arange(0, duration, 1/fs)
    block_size = len(t)

    # Clean sine wave
    sine_wave = np.sin(2 * np.pi * f_sin * t)

    # High-frequency noise
    noise = 0.5 * np.sin(2 * np.pi * f_noise * t) + 0.2 * np.random.randn(len(t))

    # Noisy signal = sine + noise
    noisy_signal = sine_wave + noise

    # Design FIR low-pass filter to keep < 10 Hz
    cutoff_hz = 10
    coeffs = firwin(num_taps, cutoff=cutoff_hz, fs=fs, window='hamming').astype(np.float32)

    # FIR instance
    fir = dsp.arm_fir_instance_f32()

    # Init FIR
    state = np.zeros(block_size + num_taps - 1, dtype=np.float32)
    dsp.arm_fir_init_f32(fir, num_taps, coeffs, state)
    
    updated_state = state.copy()

    # Filter signal
    output = dsp.arm_fir_f32(fir, noisy_signal.astype(np.float32))

    return {
        "t": t,
        "sampling_rate": fs,
        "num_taps": num_taps,
        "block_size": block_size,
        "coeffs": coeffs.tolist(),
        "input_signal": noisy_signal.tolist(),
        "expected_output": output.tolist(),
        "duration": duration,
        "f_sin": f_sin,
        "f_noise": f_noise,
    }
        


def fir_f32():
    
    fs=200                 # Sampling frequency (Hz)
    f_sin=1                # Frequency of sine wave (Hz)
    f_noise=25            # Frequency of high-frequency noise (Hz)
    duration=2           # seconds
    num_taps=15            # Number of FIR taps
    seed=None
    
    print("\n\n Generating FIR Test Data: ")
    
    data = generate_fir_denoising_test_data(fs,f_sin,f_noise,duration,num_taps)
    
    input_signal = np.array(data["input_signal"])
    output_signal = np.array(data["expected_output"])
    coeffs = np.array(data["coeffs"])
    block_size = np.array(data["block_size"])
    num_taps = np.array(data["num_taps"])
    
    output_str = test_to_template["fir_f32_test_inputs"]
    output_str = output_str.replace("<<INSERT_IS_HERE>>", c_array(input_signal))
    output_str = output_str.replace("<<INSERT_OS_HERE>>", c_array(output_signal))
    output_str = output_str.replace("<<INSERT_COEFFS_HERE>>", c_array(coeffs))
    output_str = output_str.replace("<<INSERT_BLOCK_SIZE_HERE>>", str(block_size))
    output_str = output_str.replace("<<INSERT_NUMTAPS_HERE>>", str(num_taps))
    replace_test_file("fir_f32_test_inputs", output_str)
    
    output_str = test_to_template["fir_f32_test_header"]
    output_str = output_str.replace("<<INSERT_BLOCK_SIZE_HERE>>", str(block_size))
    output_str = output_str.replace("<<INSERT_NUMTAPS_HERE>>", str(num_taps))
    replace_test_file("fir_f32_test_header", output_str)
    
    print("\n\n Done Generating FIR Test Data")
             