# dspic33-cmsis-dsp Example Projects

This repository contains example projects demonstrating the use of the **dspic33-cmsis-dsp library**.

Each example is self-contained and focuses on a specific DSP function concept using dspic33-cmsis-dsp APIs except one from each datatype which is CMSIS-DSP based example project (arm_fft_bin_example) for arm based application code.

---

## Contents

- Statistical analysis (class marks)
- Matrix operations (transpose, multiplication, addition, subtraction, inverse)
- FFT frequency bin detection
- Dot product and basic math operations
- FIR lowpass filtering

---

## F32 (Floating-Point) Example Projects

### 1. Class Marks Statistical Analysis (F32)
**Path:** `mchp_class_marks_example_f32.X/`

- Performs statistical analysis on student marks
- Demonstrates use of dspic33-cmsis-dsp statistical and matrix APIs
- Covers max, min, mean, variance, and standard deviation

[View Project README](mchp_class_marks_example_f32.X/README.md)

---

### 2. Matrix Least Squares Fitting (F32)
**Path:** `mchp_matrix_example_f32.X/`

- Implements linear least squares fitting using matrix math
- Uses transpose, multiplication, and inverse operations
- Demonstrates solving overdetermined linear systems

[View Project README](mchp_matrix_example_f32.X/README.md)

---

### 3. FFT Frequency Bin Detection (F32)
**Path:** `arm_fft_bin_example_f32.X/`

- Performs frequency-domain analysis using Complex FFT (CFFT)
- Computes magnitude spectrum to analyze signal energy distribution
- Identifies the frequency bin with maximum energy
- Demonstrates FFT, complex magnitude, and maximum search operations using dspic33-cmsis-dsp APIs
- Validates detected dominant frequency against a known reference bin

[View Project README](arm_fft_bin_example_f32.X/README.md)

---

### 4. Dot Product Example (F32)
**Path:** `mchp_dotproduct_example_f32.X/`

- Demonstrates computation of the dot product between two floating-point vectors
- Uses element-by-element multiplication followed by accumulation of results
- Illustrates basic multiply-and-add signal processing operations
- Operates on two input vectors of length 32 generated using MATLAB `randn()`
- Compares the computed dot product against a reference value with a tolerance check

[View Project README](mchp_dotproduct_example_f32.X/README.md)

---

### 5. FIR Lowpass Filter Example (F32)
**Path:** `mchp_fir_example_f32.X/`

- Demonstrates removal of high-frequency signal components using an FIR lowpass filter
- Uses an input signal composed of two sine waves (1 kHz and 15 kHz) sampled at 48 kHz
- Applies a 29-tap linear-phase FIR lowpass filter with a 6 kHz cutoff frequency
- Shows block-by-block signal processing using dspic33-cmsis-dsp FIR APIs
- Illustrates filter coefficient generation using MATLAB (`fir1`), coefficient time reversal, and linear-phase delay characteristics
- Verifies correct attenuation of the 15 kHz component while preserving the 1 kHz signal

[View Project README](mchp_fir_example_f32.X/README.md)

---

## Q31 (Fixed-Point) Example Projects

### 6. Class Marks Statistical Analysis (Q31)
**Path:** `mchp_class_marks_example_q31.X/`

- Performs statistical analysis on student marks using Q31 fixed-point arithmetic
- Demonstrates matrix initialization, multiplication, and statistical functions (max, min, mean, variance, standard deviation)
- Uses Q31-encoded marks data (marks/100 scaled to fractional range)

[View Project README](mchp_class_marks_example_q31.X/README.md)

---

### 7. Matrix Operations (Q31)
**Path:** `mchp_matrix_example_q31.X/`

- Demonstrates Q31 fixed-point matrix operations: transpose, multiplication, addition, subtraction, and inverse
- Uses a known 3x3 symmetric matrix and 3x1 vector to verify each operation against precomputed references
- Matrix inverse uses internal float conversion with Gauss-Jordan elimination

[View Project README](mchp_matrix_example_q31.X/README.md)

---

### 8. FFT Frequency Bin Detection (Q31)
**Path:** `arm_fft_bin_example_q31.X/`

- Detects the frequency bin with maximum energy from a Q31 input signal (10 kHz tone + white noise)
- Performs 1024-point Complex FFT, magnitude squared computation, and maximum bin search
- Validates detected bin index against a known reference value

[View Project README](arm_fft_bin_example_q31.X/README.md)

---

### 9. Dot Product / Basic Math Example (Q31)
**Path:** `mchp_dotproduct_example_q31.X/`

- Exercises all six Q31 basic math functions: addition, subtraction, multiplication, dot product, scale, and negation
- Dot product returns a full 64-bit q63_t result (Q2.62 format from the 72-bit DSP accumulator)
- Uses X/Y memory placement for DSP dual-fetch operations
- Verifies each result against precomputed reference values

[View Project README](mchp_dotproduct_example_q31.X/README.md)

---

### 10. FIR Lowpass Filter Example (Q31)
**Path:** `mchp_fir_example_q31.X/`

- Demonstrates a 29-tap Q31 FIR lowpass filter with 6 kHz cutoff on a 1 kHz + 15 kHz composite signal (48 kHz sample rate)
- Processes input in blocks of 32 samples using the dsPIC DSP engine
- Input and reference data scaled by 0.75 to fit Q31 range [-1.0, +1.0)
- Verifies output against MATLAB-generated reference with max absolute error check

[View Project README](mchp_fir_example_q31.X/README.md)

---

## References

- [dspic33-cmsis-dsp Library Documentation](https://onlinedocs.microchip.com/oxy/GUID-D4BCF44B-F7E0-42D8-96CB-62B6A03C73BB-en-US-1/index.html "dspic33-cmsis-dsp Library")

