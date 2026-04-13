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
    "fir_lattice_f32_test_inputs": """<<INSERT_DISCLAIMER_HERE>>

#include "../../main.h"
#include "fir_lattice_f32_test.h"

#ifdef FILTER_LIB_TEST

#ifdef DATA_SET_I

float32_t FIR_LATTICE_INPUT[] = <<INSERT_LATTICE_IS_HERE>>;
float32_t FIR_LATTICE_COEFF[] = <<INSERT_LATTICE_COEFFS_HERE>>;
float32_t FIR_LATTICE_OUTPUT[] = <<INSERT_LATTICE_OS_HERE>>;
float32_t FIR_LATTICE_STATE[FIR_LATTICE_BLOCK_SIZE+FIR_LATTICE_SIZE];

#endif

#endif
""",
# Fir tests
    "fir_lattice_f32_test_header": """<<INSERT_DISCLAIMER_HERE>>

#include "../../main.h"

#ifdef FILTER_LIB_TEST

#ifdef DATA_SET_I
#define FIR_LATTICE_BLOCK_SIZE <<INSERT_LATTICE_BLOCK_SIZE_HERE>>
#define FIR_LATTICE_SIZE <<INSERT_LATTICE_SIZE_HERE>>

extern float32_t FIR_LATTICE_INPUT[];
extern float32_t FIR_LATTICE_OUTPUT[];
extern float32_t FIR_LATTICE_COEFF[];
extern float32_t FIR_LATTICE_STATE[FIR_LATTICE_BLOCK_SIZE+FIR_LATTICE_SIZE];

#endif

#endif
""",}

def FIRLatt(FIR_src, FIR_Coeff):
    x = (FIR_src)
    k = (FIR_Coeff)
    # x = [0.1, 0.2, 0.3, 0.4, 0.5, 0.1, 0.3, 0.5, 0.7, 0.9, 0.0, 0.2, 0.4, 0.6, 0.8, 0.1]
    # k = [0.7, 0.3, 0.1, 0.9]
    y = [0 for y1 in range(0, len(x))]
    g_1 = [0 for x in range(0, len(k) + 1)]
    for n in range(0, len(x)):
        f = [0 for x in range(0, len(k) + 1)]
        g = [0 for x in range(0, len(k) + 1)]
        f[0] = x[n]
        g[0] = x[n]
        # print(n, "::", iQ31(f[0]), " -- ", iQ31(g[0]))
        for m in range(1, len(k) + 1):
            f[m] = (f[m - 1] + k[m - 1] * g_1[m - 1])
            f_temp = (f[m-1])
            g[m] = (1 * k[m - 1] * f_temp + g_1[m - 1])
        # print(128 - n, "-", "::", iQ31(f[-1]), " -- ", iQ31(g[-2]))
        g_1 = g
        y[n] = (f[-1])
        # print (n, ">>>>>>>>>>>>", (y[n]))
    # print(y, len(x))
    return (y)

def generate_random_fir_lattice_test_data(num_stage=32, inter_rate=4, block_size=128, seed=None):

    # CMSIS requirement
    assert block_size % inter_rate == 0, \
        f"block_size ({block_size}) must be a multiple of inter_rate ({inter_rate})"

    if seed is not None:
        np.random.seed(seed)

    # NOTE: arm_fir_lattice_f32 is not implemented in CMSIS DSP python wrapper
    
    input_signal = np.random.uniform(-10.0, 10.0, block_size).astype(np.float32)
    """input_signal = [0.25549027,    0.33254063,    -0.70138478,    0.71484441,    0.67267936,    -0.73346007,    0.78578085,    0.82640511,    0.84823108,    -0.37101674,    0.01686247,    0.84398937,    0.61645669,    0.74602890,    0.41136882,    0.95229298,    -0.33228844,    0.09375271,    0.84477258,    0.22117847,    -0.58348513,    -0.39411038,    -0.73583996,    -0.12458315,    0.87256277,    0.91037303,    0.57313269,    0.29592603,    -0.87579703,    -0.57968843,    -0.91152793,    -0.79070216,    -0.12471542,    -0.33514634,    0.02536419,    0.66924906,    0.87733674,    0.00675976,    -0.60761362,    0.46965262,    -0.65084904,    0.45150959,    0.73732907,    -0.77367860,    0.46235132,    -0.67809576,    -0.65511465,    -0.75916475,    -0.47912067,    -0.33860880,    0.93509865,    0.91440606,    -0.58462155,    0.28784847,    0.13947897,    0.96354789,    0.33716846,    -0.09458271,    0.70023674,    0.21519479,    -0.94080448,    -0.24932039,    -0.73639488,    0.39880410,    -0.19373143,    0.62778312,    0.41420189,    -0.29694766,    0.53641176,    0.06092300,    -0.86123401,    0.44792774,    0.68697256,    -0.65807837,    -0.45078176,    -0.11929630,    -0.52155668,    -0.60114449,    0.05113611,    0.88161367,    0.50708288,    -0.84197646,    0.10798544,    0.97519767,    -0.25080231,    0.17308724,    -0.01484505,    -0.37761927,    0.31332710,    -0.72982329,    0.20308284,    -0.93926519,    0.34684068,    -0.85620910,    -0.30337420,    0.74651545,    -0.87058365,    -0.08040143,    -0.01482545,    -0.59326422,    -0.43690750,    0.16126141,    0.01604269,    -0.47675592,    -0.83212841,    -0.22630881,    -0.60515451,    -0.42185193,    0.95291990,    0.92682755,    0.52349842,    -0.81055886,    -0.50124025,    -0.26863164,    -0.75411075,    -0.52074295,    -0.97019547,    -0.18354173,    0.91842711,    -0.91592371,    0.80522770,    0.42899817,    -0.58712053,    -0.43615463,    0.32622176,    -0.78931636,    -0.36749011,    -0.93230700,    -0.94045252,    0.38271055,    0.83676112,    0.90510893,    0.97635025,    0.28921911,    -0.11914003,    0.71583593,    -0.07877538,    0.33645961,    0.72784585,    -0.22857234,    -0.20778568,    0.57441735,    0.57671702,    -0.32178116,    -0.78920007,    -0.90348315,    0.71176761,    0.07187980,    0.27958429,    -0.15288319,    -0.63632828,    -0.58365709,    0.90717614,    -0.83245772,    0.97564209,    0.35436401,    0.63626301,    0.11107622,    0.20437004,    0.10232344,    0.06645992,    0.46728054,    0.68588686,    -0.38447919,    0.95456702,    -0.14205579,    0.04634613,    -0.82185757,    -0.85213530,    -0.00262285,    0.30984369,    -0.99787372,    -0.12259679,    -0.76116550,    -0.94066298,    0.72108656,    -0.24387717,    0.86139476,    0.38931802,    0.26911375,    0.99939525,    0.24830167,    -0.33773515,    -0.21332948,    0.44814155,    0.60257435,    -0.59433413,    -0.29481947,    0.45511800,    -0.72083795,    -0.95218927,    0.24609113,    -0.30713949,    -0.61250669,    0.39523751,    0.95457965,    -0.04187274,    -0.24561235,    0.25198409,    0.85293835
    ]"""
    coeffs= np.array([0.30281848,    -0.33142170,    0.42152798,    0.18245520,    -0.36194089,    0.28815892,    0.78341085,    0.26519230,    0.77807599,    0.63708133,    -0.22247593,    -0.06654276,    0.22399838,    -0.55964404,    -0.54128945,    0.71280932,    0.64135003,    -0.73716402,    0.27858496,    0.70602489,    -0.12974493,    0.42718256,    0.15106802,    0.50269300,    -0.77118373,    -0.31521198,    0.30265576,    -0.77255827,    -0.77220041,    -0.77631831,    0.15218103,    0.26875457
    ], dtype=np.float32)
    
    output  = FIRLatt(input_signal.tolist(),coeffs.tolist())

    return {
        "num_stage": num_stage,
        "block_size": block_size,
        "coeffs": coeffs.tolist(),
        "inter_rate": inter_rate,
        "input_signal": input_signal.tolist(),
        "expected_output": output
    } 

def fir_lattice_f32():
    
    fs=200                 # Sampling frequency (Hz)
    f_sin=1                # Frequency of sine wave (Hz)
    f_noise=25            # Frequency of high-frequency noise (Hz)
    duration=2           # seconds
    num_stage=15            # Number of FIR taps
    inter_rate= 6
    seed=None
    
    print("\n\n Generating FIR Lattice Test Data: ")
    
    data = generate_random_fir_lattice_test_data()
    
    input_signal = np.array(data["input_signal"])
    output_signal = np.array(data["expected_output"])
    coeffs = np.array(data["coeffs"])
    block_size = np.array(data["block_size"])
    num_stage = np.array(data["num_stage"])
    inter_rate = np.array(data["inter_rate"])
    
    output_str = test_to_template["fir_lattice_f32_test_inputs"]
    output_str = output_str.replace("<<INSERT_LATTICE_IS_HERE>>", c_array(input_signal))
    output_str = output_str.replace("<<INSERT_LATTICE_OS_HERE>>", c_array(output_signal))
    output_str = output_str.replace("<<INSERT_LATTICE_COEFFS_HERE>>", c_array(coeffs))
    output_str = output_str.replace("<<INSERT_LATTICE_BLOCK_SIZE_HERE>>", str(block_size))
    output_str = output_str.replace("<<INSERT_LATTICE_SIZE_HERE>>", str(num_stage))
    replace_test_file("fir_lattice_f32_test_inputs", output_str)
    
    output_str = test_to_template["fir_lattice_f32_test_header"]
    output_str = output_str.replace("<<INSERT_LATTICE_BLOCK_SIZE_HERE>>", str(block_size))
    output_str = output_str.replace("<<INSERT_LATTICE_SIZE_HERE>>", str(num_stage))
    replace_test_file("fir_lattice_f32_test_header", output_str)
        
    print("\n\n Done Generating FIR Lattice Test Data") 