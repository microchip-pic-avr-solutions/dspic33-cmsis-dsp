# Dot Product / Basic Math Example (Q31)

## Description

This example demonstrates **Q31 fixed-point basic math vector operations** using the **dspic33-cmsis-dsp library**. Six tests exercise every Q31 basic math function on a pair of 8-element vectors with known reference results.

All input values are in the range [-1.0, +1.0) represented as Q1.31 fixed-point integers.

---

## Features

- Computes:
  - Vector addition (A + B)
  - Vector subtraction (A - B)
  - Element-wise multiplication (A .* B, Q1.31 output)
  - Dot product (A . B, q63_t output in Q2.62 format)
  - Vector scaling (A * 0.5)
  - Vector negation (-A)
- Demonstrates all Q31 basic math APIs from the dspic33-cmsis-dsp library
- Uses statically allocated Q31 buffers with X/Y memory placement for DSP dual-fetch operations
- Verifies each computed result against known reference values

---

## Variables

| Variable | Description |
|---------|-------------|
| `srcA_q31` | First input vector (8 Q31 elements, placed in X data memory) |
| `srcB_q31` | Second input vector (8 Q31 elements, placed in Y data memory) |
| `dstAdd_q31` | Output buffer for addition result |
| `dstSub_q31` | Output buffer for subtraction result |
| `dstMult_q31` | Output buffer for element-wise multiplication result |
| `dotResult` | Computed dot product value (q63_t, 64-bit) |
| `dstScale_q31` | Output buffer for scaling result |
| `dstNeg_q31` | Output buffer for negation result |

---

## dspic33-cmsis-dsp Functions Used

- `mchp_add_q31()` -- Performs element-wise vector addition
- `mchp_sub_q31()` -- Performs element-wise vector subtraction
- `mchp_mult_q31()` -- Performs element-wise vector multiplication (Q1.31 output)
- `mchp_dot_prod_q31()` -- Computes dot product (q63_t output, Q2.62 format)
- `mchp_scale_q31()` -- Scales a vector by a Q31 fractional value with bit shift
- `mchp_negate_q31()` -- Negates each element of a vector

---

## How It Works

1. **System Initialization**
   - The system clock and UART are initialized using `CLOCK_Initialize()` and `UART_Initialize()`.

2. **Test 1: Vector Addition (A + B)**
   - Adds `srcA_q31` and `srcB_q31` element by element using `mchp_add_q31()`.
   - Compares output against precomputed reference values.

3. **Test 2: Vector Subtraction (A - B)**
   - Subtracts `srcB_q31` from `srcA_q31` using `mchp_sub_q31()`.

4. **Test 3: Element-wise Multiplication (A * B)**
   - Multiplies vectors element by element using `mchp_mult_q31()`.
   - Uses dsPIC DSP engine fractional multiply with implicit left shift, producing Q1.31 output.

5. **Test 4: Dot Product (A . B)**
   - Computes the dot product using `mchp_dot_prod_q31()`.
   - The result is a full 64-bit q63_t value (lower 64 bits of the 72-bit DSP accumulator in Q2.62 format).

6. **Test 5: Vector Scale (A * 0.5)**
   - Scales the input vector by 0.5 (Q31: 0x40000000) using `mchp_scale_q31()`.

7. **Test 6: Vector Negate (-A)**
   - Negates each element using `mchp_negate_q31()`.

8. **Result Validation**
   - Each test compares computed output against reference values within a defined error threshold.
   - A **SUCCESS** or **FAILURE** message is printed to the UART console.

---

## Expected Output

- **SUCCESS** message when all six tests produce results matching their reference values within tolerance
- **FAILURE** message if any test result deviates beyond the allowed limit
- Confirms correct usage of all dspic33-cmsis-dsp Q31 basic math APIs

---
