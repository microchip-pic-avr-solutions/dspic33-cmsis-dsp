"""
FFT / IFFT Test Vector Generator for C Code
-------------------------------------------
This script generates random floating-point test data for FFT and IFFT operations
using NumPy and prints them in a C-compatible array format so they can be
copy-pasted directly into embedded C source files.

Generated outputs:
- Input vector (real and imaginary interleaved)
- Expected output vector (real and imaginary interleaved)
- Output format is suitable for unit tests or regression testing of DSP code.

Author: I78279
"""

import numpy as np

# Global storage for input and expected output vectors (interleaved format)
FFT_srcG = []  # Complex input (Python complex type)
FFT_er = []    # Expected FFT output (flattened real/imag pairs)

IFFT_er = []   # Expected IFFT output (flattened real/imag pairs)

# Constants for test vector generation
gSCL_VAL = 2    
gOFFSET_VAL = 1 


def c_array(python_array):
    array_str = "{"
    array_len = len(list(python_array))

    for i in range(array_len):
        elem = python_array[i]

        # Strings (rarely used here)
        if isinstance(elem, str):
            array_str += elem

        # Floating point values
        elif isinstance(elem, float) or isinstance(elem, np.float32):
            array_str += str(elem)

        # Nested list or NumPy array support
        elif isinstance(elem, list) or isinstance(elem, np.ndarray):
            array_str += "{"
            for j in range(len(elem)):
                elemj = elem[j]
                if isinstance(elemj, str):
                    array_str += elemj
                elif isinstance(elemj, list):
                    pass  # Reserved for nested structures
                elif isinstance(elemj, float) or isinstance(elem, np.float32):
                    array_str += str(elemj)
                else:
                    # Fallback for integer conversion with 32-bit masking
                    array_str += hex(elemj & 0xFFFFFFFF)

                if (j < len(elem) - 1):
                    array_str += ", "
            array_str += "}"

        # Integer values (converted to hex)
        elif isinstance(elem, int):
            array_str += hex(elem & 0xFFFFFFFF)

        # Fallback
        else:
            array_str += hex(elem)

        if (i < array_len - 1):
            array_str += ", "

    array_str += "}"
    return array_str

# ------------------------------------------------------------
# Generate FFT test vector and expected FFT result
# Output is flattened to: [real0, imag0, real1, imag1, ...]
# ------------------------------------------------------------
def FFT():
    print("\n\n FFT Test : ")
    N = 128  # FFT size
    FFT_srcG_real = (gSCL_VAL * np.random.random_sample(N).astype(np.float32) - gOFFSET_VAL)
    FFT_srcG_imag = (gSCL_VAL * np.random.random_sample(N).astype(np.float32) - gOFFSET_VAL)

    # Combine into a complex vector
    for i in range(N):
        FFT_srcG.append(complex(FFT_srcG_real[i], FFT_srcG_imag[i]))

    # Compute expected FFT output via numpy
    FFT_er_1 = np.fft.fft(FFT_srcG)

    # Flatten into C array format (real, imag, real, imag, ...)
    FFT_src = []
    for i in range(N):
        FFT_src.append(FFT_srcG[i].real)
        FFT_er.append(FFT_er_1[i].real)
        FFT_src.append(FFT_srcG[i].imag)
        FFT_er.append(FFT_er_1[i].imag)

    print(c_array(FFT_src), c_array(FFT_er))

# ------------------------------------------------------------
# Generate IFFT test vector and expected IFFT result
# ------------------------------------------------------------
def IFFT():
    print("\n\n IFFT Test : ")
    N = 128
    IFFT_srcG = []

    IFFT_srcG_real = (gSCL_VAL * np.random.random_sample(N).astype(np.float32) - gOFFSET_VAL)
    IFFT_srcG_imag = (gSCL_VAL * np.random.random_sample(N).astype(np.float32) - gOFFSET_VAL)

    # Combine into a complex input vector
    for i in range(N):
        IFFT_srcG.append(complex(IFFT_srcG_real[i], IFFT_srcG_imag[i]))

    # Compute expected IFFT output
    IFFT_er_1 = np.fft.ifft(IFFT_srcG)

    # Flatten into C array format
    IFFT_src = []
    for i in range(N):
        IFFT_src.append(IFFT_srcG[i].real)
        IFFT_er.append(IFFT_er_1[i].real)
        IFFT_src.append(IFFT_srcG[i].imag)
        IFFT_er.append(IFFT_er_1[i].imag)

    print(c_array(IFFT_src), c_array(IFFT_er))


# Execute both tests
FFT()
IFFT()
