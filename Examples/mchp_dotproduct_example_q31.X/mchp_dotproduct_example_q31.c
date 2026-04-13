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
 * @defgroup DotProductExampleQ31 Dot Product Example (Q31)
 *
 * \par Description:
 * \par
 * Demonstrates Q31 fixed-point basic math vector operations from the
 * CMSIS-DSP library.  Six tests exercise every Q31 basic math
 * function on a pair of 8-element vectors with known reference results.
 *
 * \par Tests:
 * \par
 *   1. Vector Addition       -- mchp_add_q31()
 *   2. Vector Subtraction    -- mchp_sub_q31()
 *   3. Element-wise Multiply -- mchp_mult_q31()  (output in Q1.31 format)
 *   4. Dot Product           -- mchp_dot_prod_q31() (returns q63_t, Q2.62)
 *   5. Vector Scale          -- mchp_scale_q31()
 *   6. Vector Negate         -- mchp_negate_q31()
 *
 * \par Q31 Fixed-Point Considerations:
 * \par
 * - All input values are in the range [-1.0, +1.0) represented as Q1.31.
 * - mchp_mult_q31 uses the dsPIC DSP engine fractional multiply (mpy.l)
 *   which computes Q1.31 x Q1.31 with an implicit <<1, producing a
 *   Q1.31 result via sacr.l (NOT Q3.29 as in the ARM CMSIS version).
 * - mchp_dot_prod_q31 accumulates Q1.31 x Q1.31 products in the DSP
 *   accumulator and stores the full 64-bit result (lower 64 bits of the
 *   72-bit accumulator in Q2.62 format) via slac.l/sac.l with SATDW off.
 * - mchp_scale_q31 performs fractional multiply (<<1) with saturation,
 *   producing Q1.31 output.
 *
 * \par CMSIS DSP Library Functions Used:
 * \par
 * - mchp_add_q31()
 * - mchp_sub_q31()
 * - mchp_mult_q31()
 * - mchp_dot_prod_q31()
 * - mchp_scale_q31()
 * - mchp_negate_q31()
 *
 */

#include "../clock.h"
#include "../uart.h"
#include "mchp_math.h"
#include "../math_helper.h"
#include <stdio.h>
#include <xc.h>

/* -----------------------------------------------------------------------
 * Error thresholds (in LSBs of the respective output format)
 * ----------------------------------------------------------------------- */
#define ADD_SUB_NEG_THRESHOLD   0           /* add/sub/negate are exact   */
#define MULT_THRESHOLD          0x4L        /* mult rounding tolerance    */
#define SCALE_THRESHOLD         0x4L        /* scale has rounding error   */
#define DOT_THRESHOLD           2LL         /* dot product q63_t result   */

/* -----------------------------------------------------------------------
 * Block size
 * ----------------------------------------------------------------------- */
#define BLOCKSIZE   8

/* -----------------------------------------------------------------------
 * Source vectors (Q1.31)
 *
 *   srcA = { 0.5,  0.25, -0.25,  0.125, -0.125,  0.0625, -0.0625,  0.5  }
 *   srcB = { 0.25, 0.5,   0.125,-0.25,   0.0625,-0.125,   0.5,    -0.25 }
 *
 * Q31 encoding: value * 2^31
 *   0.5     = 0x40000000     -0.5     = 0xC0000000
 *   0.25    = 0x20000000     -0.25    = 0xE0000000
 *   0.125   = 0x10000000     -0.125   = 0xF0000000
 *   0.0625  = 0x08000000     -0.0625  = 0xF8000000
 *
 * NOTE: dsPIC33A dual-fetch MAC instructions (mpy.l [Wx]+=4, [Wy]+=4, Acc)
 * require one operand from X data space and the other from Y data space.
 * Functions that use dual-fetch (mchp_mult_q31, mchp_dot_prod_q31) pass
 * pSrcA via w0 (X-space prefetch) and pSrcB via w1 (Y-space prefetch).
 * Placing both arrays in the same data space or in const/flash causes a
 * MATHERR trap.  The space(xmemory) and space(ymemory) attributes ensure
 * correct placement.  The 'const' qualifier is removed because const data
 * is placed in program flash, which is not accessible via X/Y data buses.
 * ----------------------------------------------------------------------- */
q31_t __attribute__((space(xmemory))) srcA_q31[BLOCKSIZE] =
{
    0x40000000L,    /*  0.5     */
    0x20000000L,    /*  0.25    */
    0xE0000000L,    /* -0.25    */
    0x10000000L,    /*  0.125   */
    0xF0000000L,    /* -0.125   */
    0x08000000L,    /*  0.0625  */
    0xF8000000L,    /* -0.0625  */
    0x40000000L     /*  0.5     */
};

q31_t __attribute__((space(ymemory))) srcB_q31[BLOCKSIZE] =
{
    0x20000000L,    /*  0.25    */
    0x40000000L,    /*  0.5     */
    0x10000000L,    /*  0.125   */
    0xE0000000L,    /* -0.25    */
    0x08000000L,    /*  0.0625  */
    0xF0000000L,    /* -0.125   */
    0x40000000L,    /*  0.5     */
    0xE0000000L     /* -0.25    */
};

/* -----------------------------------------------------------------------
 * Reference: A + B (Q1.31, saturating)
 *
 *   { 0.75, 0.75, -0.125, -0.125, -0.0625, -0.0625, 0.4375, 0.25 }
 * ----------------------------------------------------------------------- */
const q31_t refAdd_q31[BLOCKSIZE] =
{
    0x60000000L,    /*  0.75    */
    0x60000000L,    /*  0.75    */
    0xF0000000L,    /* -0.125   */
    0xF0000000L,    /* -0.125   */
    0xF8000000L,    /* -0.0625  */
    0xF8000000L,    /* -0.0625  */
    0x38000000L,    /*  0.4375  */
    0x20000000L     /*  0.25    */
};

/* -----------------------------------------------------------------------
 * Reference: A - B (Q1.31, saturating)
 *
 *   { 0.25, -0.25, -0.375, 0.375, -0.1875, 0.1875, -0.5625, 0.75 }
 * ----------------------------------------------------------------------- */
const q31_t refSub_q31[BLOCKSIZE] =
{
    0x20000000L,    /*  0.25    */
    0xE0000000L,    /* -0.25    */
    0xD0000000L,    /* -0.375   */
    0x30000000L,    /*  0.375   */
    0xE8000000L,    /* -0.1875  */
    0x18000000L,    /*  0.1875  */
    0xB8000000L,    /* -0.5625  */
    0x60000000L     /*  0.75    */
};

/* -----------------------------------------------------------------------
 * Reference: A * B element-wise (Q1.31 format)
 *
 * The dsPIC DSP engine fractional multiply (mpy.l) computes:
 *   result = (a * b) << 1, with saturation, stored as Q1.31 via sacr.l.
 * This differs from ARM CMSIS which uses (a * b) >> 33 giving Q3.29.
 *
 *   [0]  0.5   *  0.25   =  0.125    -> 0x10000000
 *   [1]  0.25  *  0.5    =  0.125    -> 0x10000000
 *   [2] -0.25  *  0.125  = -0.03125  -> 0xFC000000
 *   [3]  0.125 * -0.25   = -0.03125  -> 0xFC000000
 *   [4] -0.125 *  0.0625 = -0.0078125-> 0xFF000000
 *   [5]  0.0625* -0.125  = -0.0078125-> 0xFF000000
 *   [6] -0.0625*  0.5    = -0.03125  -> 0xFC000000
 *   [7]  0.5   * -0.25   = -0.125    -> 0xF0000000
 * ----------------------------------------------------------------------- */
const q31_t refMult_q31[BLOCKSIZE] =
{
    0x10000000L,    /*  0.125     */
    0x10000000L,    /*  0.125     */
    0xFC000000L,    /* -0.03125   */
    0xFC000000L,    /* -0.03125   */
    0xFF000000L,    /* -0.0078125 */
    0xFF000000L,    /* -0.0078125 */
    0xFC000000L,    /* -0.03125   */
    0xF0000000L     /* -0.125     */
};

/* -----------------------------------------------------------------------
 * Reference: Dot Product  A . B  (q63_t, lower 64 bits of accumulator)
 *
 * The dsPIC DSP engine accumulates fractional products in AccuA
 * (Q2.62 format: each mpy.l/mac.l computes (a*b)<<1), then extracts
 * the full 64-bit result via slac.l/sac.l with SATDW disabled.
 *
 *   Manual sum of float products:
 *     0.125 + 0.125 - 0.03125 - 0.03125
 *     - 0.0078125 - 0.0078125 - 0.03125 - 0.125
 *     = 0.015625
 *
 *   q63_t value = sum( (int64_t)a[i] * b[i] * 2 ) = 0x0200000000000000
 * ----------------------------------------------------------------------- */
#define REF_DOT_Q63   ((q63_t)0x0200000000000000LL)

/* -----------------------------------------------------------------------
 * Reference: Scale A by 0.5 (Q1.31 output)
 *
 * mchp_scale_q31 performs: (q31_t)(((q63_t)a * scaleFract) << 1 >> 32)
 * with scaleFract = 0x40000000 (0.5 in Q31).
 *
 *   { 0.25, 0.125, -0.125, 0.0625, -0.0625, 0.03125, -0.03125, 0.25 }
 * ----------------------------------------------------------------------- */
#define SCALE_FRACT   ((q31_t)0x40000000L)  /* 0.5 in Q1.31 */

const q31_t refScale_q31[BLOCKSIZE] =
{
    0x20000000L,    /*  0.25    */
    0x10000000L,    /*  0.125   */
    0xF0000000L,    /* -0.125   */
    0x08000000L,    /*  0.0625  */
    0xF8000000L,    /* -0.0625  */
    0x04000000L,    /*  0.03125 */
    0xFC000000L,    /* -0.03125 */
    0x20000000L     /*  0.25    */
};

/* -----------------------------------------------------------------------
 * Reference: -A (Q1.31, saturating negate)
 *
 *   { -0.5, -0.25, 0.25, -0.125, 0.125, -0.0625, 0.0625, -0.5 }
 * ----------------------------------------------------------------------- */
const q31_t refNeg_q31[BLOCKSIZE] =
{
    0xC0000000L,    /* -0.5     */
    0xE0000000L,    /* -0.25    */
    0x20000000L,    /*  0.25    */
    0xF0000000L,    /* -0.125   */
    0x10000000L,    /*  0.125   */
    0xF8000000L,    /* -0.0625  */
    0x08000000L,    /*  0.0625  */
    0xC0000000L     /* -0.5     */
};

/* -----------------------------------------------------------------------
 * Working buffers
 * ----------------------------------------------------------------------- */
q31_t dstAdd_q31[BLOCKSIZE];
q31_t dstSub_q31[BLOCKSIZE];
q31_t dstMult_q31[BLOCKSIZE];
q31_t dstScale_q31[BLOCKSIZE];
q31_t dstNeg_q31[BLOCKSIZE];

/* -----------------------------------------------------------------------
 * Helper: check a Q31 array against a reference, return max absolute error.
 * ----------------------------------------------------------------------- */
static int32_t check_q31(const q31_t *computed, const q31_t *reference,
                         uint32_t len, const char *label)
{
    uint32_t i;
    int32_t error, maxErr = 0;

    printf("  %s:\r\n", label);
    for (i = 0; i < len; i++)
    {
        error = computed[i] - reference[i];
        if (error < 0) error = -error;
        if (error > maxErr) maxErr = error;

        printf("    [%lu] = 0x%08lX  (ref 0x%08lX, err %ld)\r\n",
               i, (unsigned long)computed[i],
               (unsigned long)reference[i], (long)error);
    }
    printf("    max error = %ld\r\n", (long)maxErr);
    return maxErr;
}

/* -----------------------------------------------------------------------
 * Main
 * ----------------------------------------------------------------------- */
int main(int argc, char** argv)
{
    CLOCK_Initialize();
    UART_Initialize();

    int pass = 1;   /* assume pass */
    int32_t maxErr;
    q63_t dotResult = 0;
    q63_t dotError;

    printf("\r\n--- Q31 Dot Product / Basic Math Example ---\r\n\r\n");

    /* ===== Test 1: Vector Addition (A + B) ===== */
    printf("Test 1: Vector Addition (A + B)\r\n");
    mchp_add_q31(srcA_q31, srcB_q31, dstAdd_q31, BLOCKSIZE);
    maxErr = check_q31(dstAdd_q31, refAdd_q31, BLOCKSIZE, "A + B");
    if (maxErr > ADD_SUB_NEG_THRESHOLD) {
        pass = 0;
        printf("  >> Test 1 FAIL\r\n");
    } else {
        printf("  >> Test 1 PASS\r\n");
    }

    /* ===== Test 2: Vector Subtraction (A - B) ===== */
    printf("\r\nTest 2: Vector Subtraction (A - B)\r\n");
    mchp_sub_q31(srcA_q31, srcB_q31, dstSub_q31, BLOCKSIZE);
    maxErr = check_q31(dstSub_q31, refSub_q31, BLOCKSIZE, "A - B");
    if (maxErr > ADD_SUB_NEG_THRESHOLD) {
        pass = 0;
        printf("  >> Test 2 FAIL\r\n");
    } else {
        printf("  >> Test 2 PASS\r\n");
    }

    /* ===== Test 3: Element-wise Multiplication (A * B) ===== */
    printf("\r\nTest 3: Element-wise Multiply (A * B) [Q1.31 output]\r\n");
    mchp_mult_q31(srcA_q31, srcB_q31, dstMult_q31, BLOCKSIZE);
    maxErr = check_q31(dstMult_q31, refMult_q31, BLOCKSIZE, "A .* B");
    if (maxErr > (int32_t)MULT_THRESHOLD) {
        pass = 0;
        printf("  >> Test 3 FAIL\r\n");
    } else {
        printf("  >> Test 3 PASS\r\n");
    }

    /* ===== Test 4: Dot Product (A . B) ===== */
    /* The assembly stores a full 64-bit q63_t result (lower 64 bits of
     * the 72-bit accumulator in Q2.62 format). */
    printf("\r\nTest 4: Dot Product (A . B) [q63_t result]\r\n");
    dotResult = 0;
    mchp_dot_prod_q31(srcA_q31, srcB_q31, BLOCKSIZE, &dotResult);

    dotError = dotResult - REF_DOT_Q63;
    if (dotError < 0) dotError = -dotError;

    printf("  result   = 0x%08lX%08lX\r\n",
           (unsigned long)(dotResult >> 32),
           (unsigned long)(dotResult & 0xFFFFFFFF));
    printf("  expected = 0x%08lX%08lX\r\n",
           (unsigned long)(REF_DOT_Q63 >> 32),
           (unsigned long)(REF_DOT_Q63 & 0xFFFFFFFF));
    printf("  error    = %lld\r\n", (long long)dotError);

    if (dotError > (q63_t)DOT_THRESHOLD) {
        pass = 0;
        printf("  >> Test 4 FAIL\r\n");
    } else {
        printf("  >> Test 4 PASS\r\n");
    }

    /* ===== Test 5: Scale (A * 0.5) ===== */
    printf("\r\nTest 5: Vector Scale (A * 0.5)\r\n");
    mchp_scale_q31(srcA_q31, SCALE_FRACT, 1, dstScale_q31, BLOCKSIZE);
    maxErr = check_q31(dstScale_q31, refScale_q31, BLOCKSIZE, "A * 0.5");
    if (maxErr > (int32_t)SCALE_THRESHOLD) {
        pass = 0;
        printf("  >> Test 5 FAIL\r\n");
    } else {
        printf("  >> Test 5 PASS\r\n");
    }

    /* ===== Test 6: Negate (-A) ===== */
    printf("\r\nTest 6: Vector Negate (-A)\r\n");
    mchp_negate_q31(srcA_q31, dstNeg_q31, BLOCKSIZE);
    maxErr = check_q31(dstNeg_q31, refNeg_q31, BLOCKSIZE, "-A");
    if (maxErr > ADD_SUB_NEG_THRESHOLD) {
        pass = 0;
        printf("  >> Test 6 FAIL\r\n");
    } else {
        printf("  >> Test 6 PASS\r\n");
    }

    /* ===== Summary ===== */
    printf("\r\n=========================================\r\n");

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


void __attribute__((interrupt)) _DefaultInterrupt(){
    printf("\r\n IN DEFAULT INTERRUPT....");
    printf("\r\n PCTRAP = 0x%08lX", PCTRAP);
    printf("\r\n INTCON1 = 0x%08lX", INTCON1);
    printf("\r\n INTCON3 = 0x%08lX", INTCON3);
    printf("\r\n INTCON4 = 0x%08lX", INTCON4);
    printf("\r\n INTCON5 = 0x%08lX", INTCON5);
    while(1);
}
