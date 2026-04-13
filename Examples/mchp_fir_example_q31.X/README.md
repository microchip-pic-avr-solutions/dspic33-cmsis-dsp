# FIR Lowpass Filter Example (Q31)

## Description

This example demonstrates a **Q31 fixed-point FIR lowpass filter** using the **dspic33-cmsis-dsp library**. A composite test signal (1 kHz + 15 kHz, sampled at 48 kHz) is filtered through a 29-tap FIR lowpass filter with cutoff frequency ~6 kHz. The output is verified against a MATLAB-generated reference using a max absolute error check.

---

## Algorithm

The input signal is a sum of two sine waves: 1 kHz and 15 kHz. This is processed by an FIR lowpass filter with cutoff frequency 6 kHz. The lowpass filter eliminates the 15 kHz signal leaving only the 1 kHz sine wave at the output.

The lowpass filter was designed using MATLAB with a sample rate of 48 kHz and a length of 29 points:

```
h = fir1(28, 6/24);
```

The first argument is the "order" of the filter and is always one less than the desired length. The second argument is the normalized cutoff frequency (0 to 1.0, where 1.0 = Nyquist). A 6 kHz cutoff with a Nyquist frequency of 24 kHz lies at a normalized frequency of 6/24 = 0.25. The CMSIS FIR filter function requires the coefficients to be in time-reversed order: `fliplr(h)`.

### Q31 Fixed-Point Considerations

- Q31 represents fractional values in [-1.0, +1.0) as 32-bit integers.
- The original f32 test data has values up to ~1.32, which exceeds the Q31 range. Both input and reference are scaled by 0.75 before conversion.
- Coefficients are already in [-1, 1] and convert directly to Q31.
- Conversion formula: `q31_val = (q31_t)(float_val * 2147483648.0)`

---

## Variables

| Variable | Description |
|---------|-------------|
| `testInput_q31` | Input signal buffer (64 Q31 samples: 1 kHz + 15 kHz, scaled by 0.75) |
| `refOutput_q31` | MATLAB-generated reference output (64 Q31 samples) |
| `testOutput_q31` | Computed FIR filter output buffer |
| `firCoeffs_q31` | FIR filter coefficients in Q31 (29 taps) |
| `firState_q31` | FIR state buffer (numTaps + blockSize - 1 = 60 elements) |
| `BLOCK_SIZE` | Number of samples processed per block (32) |
| `NUM_TAPS` | Number of FIR filter taps (29) |

---

## dspic33-cmsis-dsp Functions Used

- `mchp_fir_init_q31()` -- Initializes the FIR filter instance structure
- `mchp_fir_q31()` -- Performs the FIR filter operation on a block of samples

---

## How It Works

1. **System Initialization**
   - The system clock and UART are initialized.

2. **FIR Filter Initialization**
   - The FIR filter instance is initialized with 29-tap coefficients, state buffer, and block size using `mchp_fir_init_q31()`.

3. **Block-by-Block Processing**
   - The 64-sample input is processed in two blocks of 32 samples each through the FIR filter using `mchp_fir_q31()`.

4. **Result Verification**
   - Each output sample is compared against the MATLAB-generated reference.
   - The maximum absolute error across all samples is computed.

5. **Validation**
   - If the maximum error is within the allowed threshold (2048 LSBs), the test passes.
   - A **SUCCESS** or **FAILURE** message is printed to the UART console.

---

## Expected Output

- **SUCCESS** message when the FIR filter output matches the reference within tolerance
- **FAILURE** message if the computed output deviates beyond the allowed limit
- Confirms correct usage of dspic33-cmsis-dsp Q31 FIR filter APIs

---
