# FFT Frequency Bin Analysis Example (Q31)

## Description

This example demonstrates how to **detect the frequency bin with maximum energy** from an input signal using **dspic33-cmsis-dsp library** Q31 fixed-point FFT and vector processing functions.

The input signal consists of a **10 kHz sinusoidal waveform with uniformly distributed white noise**. By transforming the signal into the frequency domain using a **Complex FFT (CFFT)** and computing the magnitude squared of each frequency bin, the bin corresponding to the dominant frequency is identified.

---

## Features

- Computes:
  - Complex FFT of the Q31 input signal (1024 points)
  - Magnitude squared spectrum of FFT bins
  - Maximum energy bin index
- Demonstrates dspic33-cmsis-dsp Q31 FFT and vector processing APIs
- Uses statically allocated Q31 input and output buffers
- Validates detected frequency bin against a known reference value

---

## Variables

| Variable | Description |
|---------|-------------|
| `testInput_q31_10khz` | Input signal buffer containing a 10 kHz tone with added white noise (complex Q31 data, 2048 elements) |
| `testOutput` | Output buffer containing magnitude squared of FFT bins |
| `fftSize` | Length of FFT (1024 points) |
| `ifftFlag` | Selects FFT (`0`) or IFFT (`1`) operation |
| `doBitReverse` | Enables bit reversal (`1` = normal output order) |
| `varInstCfftQ31` | CMSIS-DSP structure for Q31 Complex FFT configuration |
| `refIndex` | Reference FFT bin index for the 10 kHz signal (213) |
| `testIndex` | Computed FFT bin index with maximum energy |
| `maxValue` | Maximum magnitude squared value across all FFT bins |

---

## dspic33-cmsis-dsp Functions Used

- `arm_cfft_init_q31()` -- Initializes the Q31 Complex FFT instance
- `arm_cfft_q31()` -- Performs the complex FFT operation on Q31 data
- `arm_cmplx_mag_squared_q31()` -- Computes magnitude squared of complex FFT output
- `arm_max_q31()` -- Finds the maximum value and corresponding index

---

## How It Works

1. **Input Signal Preparation**
   - A predefined complex input array (`testInput_q31_10khz`) contains Q31 samples of a 10 kHz sinusoid with added white noise.

2. **FFT Configuration**
   - The FFT instance is initialized for a 1024-point transform using `mchp_cfft_init_q31()`.

3. **FFT Processing**
   - The input signal is transformed from the time domain to the frequency domain using `mchp_cfft_q31()`.

4. **Magnitude Squared Computation**
   - The magnitude squared of each complex FFT bin is calculated using `mchp_cmplx_mag_squared_q31()` and stored in `testOutput`.

5. **Maximum Bin Detection**
   - `mchp_max_q31()` scans the magnitude buffer to identify the bin with the highest energy and stores the index in `testIndex`.

6. **Result Validation**
   - The calculated bin index is compared with the expected reference index (`refIndex = 213`).
   - A **SUCCESS** or **FAILURE** message is printed based on the comparison result.

---

## Expected Output

- **SUCCESS** message when the detected FFT bin matches the reference bin
- **FAILURE** message if the detected bin differs from the expected value
- Correct execution of Q31 FFT, magnitude squared computation, and maximum detection using dspic33-cmsis-dsp APIs

---
