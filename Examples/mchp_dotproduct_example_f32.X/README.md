# Dot Product Example

## Description

This example demonstrates how to **compute the dot product of two floating‑point vectors** using **dspic33-cmsis-dsp library** vector math functions.

The dot product is calculated by performing **element‑by‑element multiplication** of two input vectors followed by **accumulating (summing) the products**. This operation is commonly used in signal processing, filtering, and linear algebra applications.

---

## Features

- Computes:
  - Element-wise multiplication of two vectors
  - Accumulation of multiplied results to form a dot product
- Demonstrates CMSIS-DSP basic math APIs
- Uses statically allocated floating-point buffers
- Verifies computed result against a known reference value

---

## Variables

| Variable | Description |
|---------|-------------|
| `srcA_buf_f32` | First input vector (32 floating-point elements) |
| `srcB_buf_f32` | Second input vector (32 floating-point elements) |
| `multOutput` | Intermediate buffer holding element-wise multiplication results |
| `testOutput` | Final computed dot product value |
| `refDotProdOut` | Reference dot product value used for validation |
| `diff` | Absolute difference between reference and computed results |
| `DELTA` | Allowed tolerance for result comparison |
| `status` | Indicates success or failure of the test |

---

## dspic33-cmsis-dsp Functions Used

- `mchp_mult_f32()` – Performs element-wise multiplication of two float32 vectors  
- `mchp_add_f32()` – Adds two float32 values (used iteratively for accumulation)  

---

## How It Works

1. **System Initialization**  
   - The system clock and UART are initialized using `CLOCK_Initialize()` and `UART_Initialize()`.

2. **Vector Multiplication**  
   - The input vectors `srcA_buf_f32` and `srcB_buf_f32` are multiplied element by element using `mchp_mult_f32()`.
   - The result is stored in the `multOutput` buffer.

3. **Accumulation (Dot Product Calculation)**  
   - Each value in `multOutput` is added to `testOutput` in a loop using `mchp_add_f32()` to obtain the final dot product.

4. **Result Comparison**  
   - The absolute difference between the computed dot product and the reference value `refDotProdOut` is calculated.

5. **Validation**  
   - If the difference is within the defined tolerance (`DELTA`), the test passes.
   - Otherwise, the test fails.

6. **Logging**  
   - A **SUCCESS** or **FAILURE** message is printed to the UART console.

---

## Expected Output

- **SUCCESS** message when the computed dot product matches the reference value within tolerance  
- **FAILURE** message if the computed result deviates beyond the allowed limit  
- Confirms correct usage of dspic33-cmsis-dsp multiplication and addition APIs for dot product computation  

---
