/**
;*****************************************************************************
;                                                                            *
;                       Software License Agreement                           *
;*****************************************************************************
;*****************************************************************************
;  [2026] Microchip Technology Inc. and its subsidiaries.                    *
;                                                                            *
;   Subject to your compliance with these terms, you may use Microchip       *
;   software and any derivatives exclusively with Microchip products.        *
;   You are responsible for complying with 3rd party license terms            *
;   applicable to your use of 3rd party software (including open source       *
;   software) that may accompany Microchip software. SOFTWARE IS AS IS.       *
;   NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS       *
;   SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,           *
;   MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT         *
;   WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,             *
;   INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY          *
;   KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF          *
;   MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE          *
;   FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S            *
;   TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT            *
;   EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR         *
;   THIS SOFTWARE.                                                            *
;*****************************************************************************
*/

/**
 * @defgroup FIRExampleQ31 FIR Lowpass Filter Example (Q31)
 *
 * \par Description:
 * \par
 * Demonstrates a Q31 fixed-point FIR lowpass filter using the CMSIS-DSP
 * library.  A composite test signal (1 kHz + 15 kHz, sampled at 48 kHz) is
 * filtered through a 29-tap FIR lowpass filter (cutoff ~6 kHz).  The output
 * is verified against a MATLAB-generated reference using a max absolute
 * error check.
 *
 * \par Algorithm:
 * \par
 * The FIR filter coefficients were designed in MATLAB:
 *   h = fir1(28, 6/24);   %% 29 taps, cutoff 6 kHz at 48 kHz sample rate
 * The coefficients are stored in time-reversed order (as required by the
 * direct-form FIR implementation).
 *
 * \par Q31 Fixed-Point Considerations:
 * \par
 * - Q31 represents fractional values in [-1.0, +1.0) as 32-bit integers.
 * - The original f32 test data has values up to ~1.32, which exceeds the Q31
 *   range.  Both input and reference are scaled by 0.75 before conversion.
 * - Coefficients are already in [-1, 1] and convert directly to Q31.
 * - Conversion formula: q31_val = (q31_t)(float_val * 2147483648.0)
 *
 * \par CMSIS DSP Library Functions Used:
 * \par
 * - mchp_fir_init_q31()
 * - mchp_fir_q31()
 *
 */

#include "../clock.h"
#include "../uart.h"
#include "mchp_math.h"
#include <stdio.h>

/* -----------------------------------------------------------------------
 * Test configuration
 * ----------------------------------------------------------------------- */
#define TEST_LENGTH_SAMPLES  64
#define BLOCK_SIZE           32
#define NUM_TAPS             29

/**
 * Maximum allowable absolute deviation (in Q31 LSBs) between computed
 * result and reference.  Q31 FIR uses truncation (sac.l) in the DSP
 * accumulator, so small rounding errors accumulate over 29 taps.
 * 2048 LSBs (~0.000001 in fractional terms) provides comfortable margin.
 */
#define MAX_ERROR_THRESHOLD_Q31   0x00000800L   /* 2048 LSBs */

/* -----------------------------------------------------------------------
 * FIR filter coefficients in Q31 (29 taps)
 *
 * Designed in MATLAB: h = fir1(28, 6/24); stored as fliplr(h).
 * Conversion: q31 = (q31_t)(coeff * 2147483648.0)
 *
 * Float coefficients:
 *  -0.0018225230, -0.0015879294,  0.0000000000, +0.0036977508,
 *  +0.0080754303, +0.0085302217,  0.0000000000, -0.0173976984,
 *  -0.0341458607, -0.0333591565,  0.0000000000, +0.0676308395,
 *  +0.1522061835, +0.2229246956, +0.2504960933, +0.2229246956,
 *  +0.1522061835, +0.0676308395,  0.0000000000, -0.0333591565,
 *  -0.0341458607, -0.0173976984,  0.0000000000, +0.0085302217,
 *  +0.0080754303, +0.0036977508,  0.0000000000, -0.0015879294,
 *  -0.0018225230
 * ----------------------------------------------------------------------- */
const q31_t firCoeffs_q31[NUM_TAPS] =
{
    0xFFC44792L, 0xFFCBF77CL, 0x00000000L, 0x00792AFBL,
    0x01089D9FL, 0x011784B0L, 0x00000000L, 0xFDC5E987L,
    0xFBA11BC2L, 0xFBBAE31DL, 0x00000000L, 0x08A8209AL,
    0x137B7E02L, 0x1C88CBE3L, 0x20104188L, 0x1C88CBE3L,
    0x137B7E02L, 0x08A8209AL, 0x00000000L, 0xFBBAE31DL,
    0xFBA11BC2L, 0xFDC5E987L, 0x00000000L, 0x011784B0L,
    0x01089D9FL, 0x00792AFBL, 0x00000000L, 0xFFCBF77CL,
    0xFFC44792L
};

/* -----------------------------------------------------------------------
 * Test input signal in Q31 (64 samples)
 *
 * Original f32 test signal (1 kHz + 15 kHz at 48 kHz) scaled by 0.75
 * to fit within Q31 range [-1.0, +1.0).
 * Conversion: q31 = (q31_t)(f32_val * 0.75 * 2147483648.0)
 * ----------------------------------------------------------------------- */
q31_t testInput_q31[TEST_LENGTH_SAMPLES] __attribute__((space(xmemory))) =
{
    0x00000000L, 0x38E07182L, 0xF6E7CF09L, 0x125E69FDL,
    0x60000000L, 0x281281C2L, 0x21F0ED9AL, 0x78821559L,
    0x532370B9L, 0x2C58A1B7L, 0x7EAB8570L, 0x718C29B6L,
    0x30000000L, 0x718C29B6L, 0x7EAB8570L, 0x2C58A1B7L,
    0x532370B9L, 0x78821559L, 0x21F0ED9AL, 0x281281C2L,
    0x60000000L, 0x125E69FDL, 0xF6E7CF09L, 0x38E07182L,
    0x00000000L, 0xC71F8E7EL, 0x091830F7L, 0xEDA19603L,
    0xA0000000L, 0xD7ED7E3EL, 0xDE0F1266L, 0x877DEAA7L,
    0xACDC8F47L, 0xD3A75E49L, 0x81547A90L, 0x8E73D64AL,
    0xD0000000L, 0x8E73D64AL, 0x81547A90L, 0xD3A75E49L,
    0xACDC8F47L, 0x877DEAA7L, 0xDE0F1266L, 0xD7ED7E3EL,
    0xA0000000L, 0xEDA19603L, 0x091830F7L, 0xC71F8E7EL,
    0x00000000L, 0x38E07182L, 0xF6E7CF09L, 0x125E69FDL,
    0x60000000L, 0x281281C2L, 0x21F0ED9AL, 0x78821559L,
    0x532370B9L, 0x2C58A1B7L, 0x7EAB8570L, 0x718C29B6L,
    0x30000000L, 0x718C29B6L, 0x7EAB8570L, 0x2C58A1B7L
};

/* -----------------------------------------------------------------------
 * Reference output in Q31 (64 samples)
 *
 * MATLAB-generated reference output of the FIR filter, scaled by 0.75.
 * Conversion: q31 = (q31_t)(ref_f32 * 0.75 * 2147483648.0)
 * ----------------------------------------------------------------------- */
const q31_t refOutput_q31[TEST_LENGTH_SAMPLES] =
{
    0x00000000L, 0xFFE57698L, 0xFFED1F4AL, 0xFFFB2072L,
    0x0001955EL, 0x0033405FL, 0x005AAA5CL, 0x0026F7B2L,
    0xFFBF698CL, 0xFF457308L, 0xFEDA95F8L, 0xFF2B027DL,
    0x00DAAE22L, 0x042217E5L, 0x095ADAB9L, 0x10B53887L,
    0x19BDD975L, 0x23FA659BL, 0x2EF9ED51L, 0x39D4F668L,
    0x43C38FB6L, 0x4C7F03B4L, 0x53AC335BL, 0x59115211L,
    0x5CF2EE9FL, 0x5F5F749AL, 0x601D9E9EL, 0x5F49CAC0L,
    0x5CF15941L, 0x58DE11B2L, 0x535188FFL, 0x4C580C02L,
    0x4404262AL, 0x3A8F8360L, 0x301F5759L, 0x24CF631EL,
    0x18E32B53L, 0x0C9320A2L, 0x00000000L, 0xF36CDF5EL,
    0xE71CD4ADL, 0xDB309CE2L, 0xCFE0A8A7L, 0xC5707CA0L,
    0xBBFBD9D6L, 0xB3A7F3FEL, 0xACAE7701L, 0xA721EE4EL,
    0xA30EA6BFL, 0xA09BABD8L, 0x9FCF80ACL, 0xA09BABD8L,
    0xA30EA6BFL, 0xA721EE4EL, 0xACAE7701L, 0xB3A7F3FEL,
    0xBBFBD9D6L, 0xC5707CA0L, 0xCFE0A8A7L, 0xDB309CE2L,
    0xE71CD4ADL, 0xF36CDF5EL, 0x00000000L, 0x0C9320A2L
};

/* -----------------------------------------------------------------------
 * FIR state buffer: numTaps + blockSize - 1 = 29 + 32 - 1 = 60 elements
 * ----------------------------------------------------------------------- */
static q31_t firState_q31[NUM_TAPS + BLOCK_SIZE - 1];

/* -----------------------------------------------------------------------
 * Output buffer
 * ----------------------------------------------------------------------- */
static q31_t testOutput_q31[TEST_LENGTH_SAMPLES];

/* -----------------------------------------------------------------------
 * Main
 * ----------------------------------------------------------------------- */
int main(int argc, char** argv)
{
    CLOCK_Initialize();
    UART_Initialize();

    mchp_fir_instance_q31 S;
    uint32_t i;
    uint32_t numBlocks = TEST_LENGTH_SAMPLES / BLOCK_SIZE;
    int32_t error, maxErr = 0;
    int pass = 1;

    printf("\r\n--- Q31 FIR Lowpass Filter Example ---\r\n\r\n");
    printf("Config: %d samples, block size %d, %d taps\r\n",
           TEST_LENGTH_SAMPLES, BLOCK_SIZE, NUM_TAPS);
    printf("Input/reference scaled by 0.75 to fit Q31 range\r\n\r\n");

    /* Initialize the FIR filter instance */
    mchp_fir_init_q31(&S, NUM_TAPS, (q31_t *)firCoeffs_q31,
                       firState_q31, BLOCK_SIZE);

    /* Process input data block by block */
    for (i = 0; i < numBlocks; i++)
    {
        mchp_fir_q31(&S,
                      testInput_q31  + (i * BLOCK_SIZE),
                      testOutput_q31 + (i * BLOCK_SIZE),
                      BLOCK_SIZE);
    }

    /* ===== Verify output against reference ===== */
    printf("Output vs Reference:\r\n");
    for (i = 0; i < TEST_LENGTH_SAMPLES; i++)
    {
        error = testOutput_q31[i] - refOutput_q31[i];
        if (error < 0) error = -error;
        if (error > maxErr) maxErr = error;

        printf("  [%2lu] out=0x%08lX  ref=0x%08lX  err=%ld\r\n",
               (unsigned long)i,
               (unsigned long)testOutput_q31[i],
               (unsigned long)refOutput_q31[i],
               (long)error);
    }

    /* ===== Report results ===== */
    printf("\r\nMax absolute error: %ld LSBs (threshold: %ld)\r\n",
           (long)maxErr, (long)MAX_ERROR_THRESHOLD_Q31);

    if (maxErr > (int32_t)MAX_ERROR_THRESHOLD_Q31)
    {
        pass = 0;
        printf("Error check: FAIL\r\n");
    }
    else
    {
        printf("Error check: PASS\r\n");
    }

    if (pass)
    {
        printf("\r\n SUCCESS \r\n");
    }
    else
    {
        printf("\r\n FAILURE \r\n");
    }

    while(1);
}
