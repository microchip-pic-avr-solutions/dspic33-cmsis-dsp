# FFT Frequency Bin Analysis Example

## Description

This example demonstrates how to **detect the frequency bin with maximum energy** from an input signal using **dspic33-cmsis-dsp library** FFT and vector processing functions.

The input signal consists of a **10 kHz sinusoidal waveform with uniformly distributed white noise**. By transforming the signal into the frequency domain using a **Complex FFT (CFFT)** and computing the magnitude of each frequency bin, the bin corresponding to the dominant frequency is identified.

---

## Features

- Computes:
  - Complex FFT of the input signal
  - Magnitude spectrum of FFT bins
  - Maximum energy bin index
- Demonstrates CMSIS-DSP FFT and vector processing APIs
- Uses statically allocated input and output buffers
- Validates detected frequency bin against a known reference value

---

## Variables

| Variable | Description |
|---------|-------------|
| `testInput_f32_10khz` | Input signal buffer containing a 10 kHz tone with added white noise (complex float32 data) |
| `testOutput` | Output buffer containing magnitude of FFT bins |
| `fftSize` | Length of FFT (1024 points) |
| `ifftFlag` | Selects FFT (`0`) or IFFT (`1`) operation |
| `doBitReverse` | Enables bit reversal (`1` = normal output order) |
| `varInstCfftF32` | CMSIS-DSP structure for Complex FFT configuration |
| `refIndex` | Reference FFT bin index for the 10 kHz signal |
| `testIndex` | Computed FFT bin index with maximum energy |
| `maxValue` | Maximum magnitude value across all FFT bins |

---

## dspic33-cmsis-dsp Functions Used

- `arm_cfft_init_f32()` – Initializes the Complex FFT instance  
- `arm_cfft_f32()` – Performs the complex FFT operation  
- `arm_cmplx_mag_f32()` – Computes magnitude of complex FFT output  
- `arm_max_f32()` – Finds the maximum value and corresponding index  

---

## How It Works

1. **Input Signal Preparation**  
   - A predefined complex input array (`testInput_f32_10khz`) contains samples of a 10 kHz sinusoid with added white noise.

2. **FFT Configuration**  
   - The FFT instance is initialized for a 1024-point transform using `arm_cfft_init_f32()`.

3. **FFT Processing**  
   - The input signal is transformed from the time domain to the frequency domain using `arm_cfft_f32()`.

4. **Magnitude Computation**  
   - The magnitude of each complex FFT bin is calculated using `arm_cmplx_mag_f32()` and stored in `testOutput`.

5. **Maximum Bin Detection**  
   - `arm_max_f32()` scans the magnitude buffer to identify the bin with the highest energy and stores the index in `testIndex`.

6. **Result Validation**  
   - The calculated bin index is compared with the expected reference index (`refIndex`).
   - A **SUCCESS** or **FAILURE** message is printed based on the comparison result.

---

## Expected Output

- **SUCCESS** message when the detected FFT bin matches the reference bin  
- **FAILURE** message if the detected bin differs from the expected value  
- Correct execution of FFT, magnitude computation, and maximum detection using dspic33-cmsis-dsp APIs  

---
