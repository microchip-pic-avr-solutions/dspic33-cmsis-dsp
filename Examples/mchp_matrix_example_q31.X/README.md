# Matrix Operations Example (Q31)

## Description

This example demonstrates **Q31 fixed-point matrix operations** from the **dspic33-cmsis-dsp library**: transpose, multiplication, addition, subtraction, and inverse.

A known 3x3 symmetric matrix and a 3x1 vector are used to verify each operation against precomputed reference values.

---

## Algorithm Overview

Given a known symmetric matrix **A** (3x3) and vector **b** (3x1), the example verifies:

1. **A^T** -- Transpose (should equal A since A is symmetric)
2. **A^T * A** -- Matrix multiply (verified against hand-computed reference)
3. **A * b** -- Matrix-vector multiply (verified against reference)
4. **A + A** -- Matrix addition (should equal 2*A, with Q31 saturation)
5. **A - A** -- Matrix subtraction (should be all zeros)
6. **inv(I)** -- Inverse of the 3x3 identity matrix (should equal identity)

### Q31 Fixed-Point Considerations

- All values must be in the range [-1.0, +1.0) represented as Q31.
- Q31 matrix multiplication is fractional: each element of the dot product is computed using the 72-bit DSP accumulator.
- The matrix inverse function converts Q31 to float internally, performs Gauss-Jordan elimination, then converts back to Q31.

---

## Variables

| Variable | Description |
|---------|-------------|
| `A_q31` | Input matrix (3x3, symmetric: diag=0.5, off-diag=0.25/0.125) |
| `b_q31` | Input vector (3x1: [0.5, 0.25, 0.125]) |
| `I_q31` | Identity matrix (3x3, diagonal = 0x7FFFFFFF) |
| `Ab_ref_q31` | Reference result for A * b |
| `ATA_ref_q31` | Reference result for A^T * A |
| `AT_q31` | Output buffer for transpose |
| `ATA_q31` | Output buffer for A^T * A |
| `SUM_q31` | Output buffer for A + A |
| `DIFF_q31` | Output buffer for A - A |
| `Ab_q31` | Output buffer for A * b |
| `INV_q31` | Output buffer for inverse |

---

## dspic33-cmsis-dsp Functions Used

- `mchp_mat_init_q31()` -- Initializes matrix instance structures
- `mchp_mat_trans_q31()` -- Computes matrix transpose
- `mchp_mat_mult_q31()` -- Performs matrix multiplication
- `mchp_mat_add_q31()` -- Performs matrix addition
- `mchp_mat_sub_q31()` -- Performs matrix subtraction
- `mchp_mat_inverse_q31()` -- Computes matrix inverse

---

## How It Works

1. **System Initialization**
   - The system clock and UART are initialized.

2. **Matrix Initialization**
   - All matrix instances are initialized using `mchp_mat_init_q31()`.

3. **Test 1: Transpose**
   - Computes A^T and verifies it equals A (since A is symmetric).

4. **Test 2: Multiply (A^T * A)**
   - Multiplies transpose by original and compares against reference.

5. **Test 3: Matrix-Vector Multiply (A * b)**
   - Multiplies the matrix by a vector and verifies the result.

6. **Test 4: Addition (A + A)**
   - Adds A to itself and verifies each element equals 2*A (with Q31 saturation for values reaching 1.0).

7. **Test 5: Subtraction (A - A)**
   - Subtracts A from itself and verifies all elements are zero.

8. **Test 6: Inverse (inv(I))**
   - Inverts the identity matrix and verifies the result equals the identity.

9. **Result Validation**
   - Each test reports PASS or FAIL based on the maximum absolute error.
   - A **SUCCESS** or **FAILURE** message is printed to the UART console.

---

## Expected Output

- **SUCCESS** message when all six matrix operation tests pass within tolerance
- **FAILURE** message if any test result deviates beyond the allowed limit
- Confirms correct usage of all dspic33-cmsis-dsp Q31 matrix APIs

---
