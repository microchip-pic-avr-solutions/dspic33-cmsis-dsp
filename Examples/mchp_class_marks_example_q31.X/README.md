# Class Marks Statistical Analysis Example (Q31)

## Description

This example demonstrates how to analyze the marks scored by **20 students across 4 subjects** using statistical and matrix processing functions from the **dspic33-cmsis-dsp library**. This is the Q31 fixed-point version of the class marks example.

The example illustrates how a single dataset can be used both for **statistical analysis** and **matrix-based computations** using Q31 fractional arithmetic.

---

## Features

- Computes the following statistical parameters in Q31 fixed-point:
  - Maximum
  - Minimum
  - Mean
  - Variance
  - Standard deviation
- Demonstrates dspic33-cmsis-dsp library matrix initialization and multiplication in Q31
- Uses statically initialized input datasets with Q31-encoded marks
- Validates numerical processing using dspic33-cmsis-dsp APIs

---

## Variables

| Variable | Description |
|---------|-------------|
| `testMarks_q31` | Q31 array containing marks of 20 students across 4 subjects (marks/100 encoded as Q31) |
| `testUnity_q31` | Unity vector (4 elements of 0x7FFFFFFF) for matrix summation |
| `max_marks` | Maximum mark across all students and subjects |
| `min_marks` | Minimum mark across all students and subjects |
| `mean` | Mean (average) of the marks dataset |
| `var` | Variance of the marks dataset |
| `std` | Standard deviation of the marks dataset |
| `numStudents` | Total number of students (20) |

---

## dspic33-cmsis-dsp Functions Used

- `mchp_mat_init_q31()` -- Initializes CMSIS-DSP matrix structures
- `mchp_mat_mult_q31()` -- Performs matrix multiplication (Q31 fractional)
- `mchp_max_q31()` -- Computes maximum value in the dataset
- `mchp_min_q31()` -- Computes minimum value in the dataset
- `mchp_mean_q31()` -- Computes mean of the dataset
- `mchp_std_q31()` -- Computes standard deviation
- `mchp_var_q31()` -- Computes variance

---

## How It Works

1. **Data Initialization**
   - Student marks are statically defined in the `testMarks_q31` array.
   - Each mark is encoded as Q31: `mark / 100.0 * 2^31` (e.g., 42 marks = 0x35C28F5C).
   - The dataset represents marks for 20 students, with 4 subjects per student.

2. **Matrix Multiplication**
   - The marks array is shaped as a 20x4 matrix and multiplied by a 4x1 unity vector using `mchp_mat_mult_q31()`.
   - This sums each student's marks across all subjects (fractional multiply with Q31 unity ~1.0).

3. **Statistical Processing**
   - CMSIS-DSP statistical functions process the summed results to compute:
     - Maximum and minimum values
     - Mean score
     - Variance and standard deviation

4. **Result Output**
   - Computed mean and standard deviation are printed via UART for verification.

---

## Expected Output

- Correct maximum, minimum, mean, variance, and standard deviation values in Q31 format
- Successful execution of matrix initialization and multiplication operations
- Verified numerical results printed via UART using dspic33-cmsis-dsp APIs

---
