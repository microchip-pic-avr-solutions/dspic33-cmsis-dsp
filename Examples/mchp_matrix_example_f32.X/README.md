# Matrix Least Squares Fitting Example

## Description

This example demonstrates how to perform **least squares fitting** using matrix operations from the **dspic33-cmsis-dspdsp library**.

The example shows how an **overdetermined system of linear equations** can be solved by applying matrix transpose, multiplication, and inversion to estimate unknown parameters that minimize the least squares error.

---

## Algorithm Overview

The linear system is represented as:
`A * X = B`
Where:
- `A` – Input matrix (known coefficients)
- `X` – Unknown matrix (parameters to be estimated)
- `B` – Output matrix (measured data)

For an overdetermined system, the least squares solution is computed as:
`X = (Aᵀ · A)⁻¹ · Aᵀ · B`
---

## Variables

| Variable | Description |
|---------|-------------|
| `A_f32` | Input matrix containing known coefficients |
| `B_f32` | Output matrix containing measured values |
| `X_f32` | Estimated matrix of unknown parameters |

---

## dspic33-cmsis-dsp Functions Used

- `mchp_mat_init_f32()` – Initializes dspic33-cmsis-dsp matrix structures  
- `mchp_mat_trans_f32()` – Computes matrix transpose  
- `mchp_mat_mult_f32()` – Performs matrix multiplication  
- `mchp_mat_inverse_f32()` – Computes matrix inverse  

---

## Processing Steps

1. **Matrix Initialization**  
   - Initialize matrices `A` and `B` with known input and output data using `mchp_mat_init_f32()`.

2. **Transpose Calculation**  
   - Compute the transpose of matrix `A` using `mchp_mat_trans_f32()`.

3. **Matrix Multiplication (AᵀA)**  
   - Multiply `Aᵀ` and `A` to form the intermediate matrix `(Aᵀ · A)`.

4. **Matrix Inversion**  
   - Compute the inverse of `(Aᵀ · A)` using `mchp_mat_inverse_f32()`.

5. **Least Squares Solution**  
   - Multiply `(Aᵀ · A)⁻¹`, `Aᵀ`, and `B` to obtain the least squares estimate `X`.

6. **Result Verification**  
   - Inspect the resulting matrix `X_f32` using a debugger or console output to verify correctness.
   - Compare computed `X` with reference values using SNR

7. **Logging**
   - Report **SUCCESS** or **FAILURE** via UART

---

## Expected Output

- Estimated matrix `X_f32` that minimizes the least squares error  
- Successful execution of transpose, multiplication, and inversion operations  
- Verified results using dspic33-cmsis-dsp matrix APIs  

---