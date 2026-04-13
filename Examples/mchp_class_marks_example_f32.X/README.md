# Class Marks Statistical Analysis Example

## Description

This example demonstrates how to analyze the marks scored by **20 students across 4 subjects** using statistical and matrix processing functions from the **dspic33-cmsis-dsp library**.

The example illustrates how a single dataset can be used both for **statistical analysis** and **matrix-based computations**, which are commonly used in applications.

---

## Features

- Computes the following statistical parameters:
  - Maximum
  - Minimum
  - Mean
  - Variance
  - Standard deviation
- Demonstrates dspic33-cmsis-dsp library matrix initialization and multiplication
- Uses statically initialized input datasets
- Validates numerical processing using dspic33-cmsis-dsp APIs

---

## Variables

| Variable        | Description |
|-----------------|-------------|
| `testMarks_f32` | Float32 array containing marks of 20 students across 4 subjects |
| `max_marks`    | Maximum mark across all students and subjects |
| `min_marks`    | Minimum mark across all students and subjects |
| `mean`         | Mean (average) of the entire marks dataset |
| `var`          | Variance of the marks dataset |
| `std`          | Standard deviation of the marks dataset |
| `numStudents`  | Total number of students (20) |

---

## dspic33-cmsis-dsp Functions Used

- `mchp_mat_init_f32()` – Initializes CMSIS-DSP matrix structures  
- `mchp_mat_mult_f32()` – Performs matrix multiplication  
- `mchp_max_f32()` – Computes maximum value in the dataset  
- `mchp_min_f32()` – Computes minimum value in the dataset  
- `mchp_mean_f32()` – Computes mean of the dataset  
- `mchp_std_f32()` – Computes standard deviation  
- `mchp_var_f32()` – Computes variance  

---

## How It Works

1. **Data Initialization**  
   - Student marks are statically defined in the `testMarks_f32` array.
   - The dataset represents marks for 20 students, with 4 subjects per student.

2. **Statistical Processing**  
   - CMSIS-DSP statistical functions process the entire dataset to compute:
     - Maximum and minimum values
     - Mean score
     - Variance and standard deviation

3. **Matrix Configuration**  
   - The marks array is reshaped into a 20×4 matrix using `mchp_mat_init_f32()`, enabling matrix-based operations.

4. **Matrix Multiplication**  
   - Matrix multiplication is demonstrated using `mchp_mat_mult_f32()`, showing how multidimensional data can be processed efficiently.

5. **Result Verification**  
   - All computed values can be printed via UART or inspected using a debugger for validation.

---

## Expected Output

- Correct maximum, minimum, mean, variance, and standard deviation values  
- Successful execution of matrix initialization and multiplication operations  
- Verified numerical results using dspic33-cmsis-dsp APIs  

---