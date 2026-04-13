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
 * @defgroup MatrixExampleQ31 Matrix Example (Q31)
 *
 * \par Description:
 * \par
 * Demonstrates Q31 fixed-point matrix operations from the CMSIS-DSP
 * library: transpose, multiplication, addition, subtraction, and inverse.
 *
 * \par Algorithm:
 * \par
 * Given a known matrix A (3x3) and vector b (3x1), the example verifies:
 *
 *   1. A^T        (transpose)
 *   2. A^T * A    (multiply: symmetric result since A is symmetric)
 *   3. A + A      (addition, equivalent to 2*A)
 *   4. A - A      (subtraction, should be zero)
 *   5. A * b      (matrix-vector multiply, verified against reference)
 *   6. inv(I)     (inverse of 3x3 identity, should equal identity)
 *
 * \par Q31 Fixed-Point Considerations:
 * \par
 * - All values must be in the range [-1.0, +1.0) represented as Q31.
 * - Q31 matrix multiplication is fractional: each element of the dot
 *   product is computed as (a * b) >> 31 in the 72-bit DSP accumulator.
 *
 * \par CMSIS DSP Library Functions Used:
 * \par
 * - mchp_mat_init_q31()
 * - mchp_mat_trans_q31()
 * - mchp_mat_mult_q31()
 * - mchp_mat_add_q31()
 * - mchp_mat_sub_q31()
 * - mchp_mat_inverse_q31()
 *
 */

#include "../clock.h"
#include "../uart.h"
#include "mchp_math.h"
#include "../math_helper.h"
#include <stdio.h>

/**
 * Maximum allowable absolute deviation (in Q31 LSBs) between computed
 * result and reference.  The DSP accumulator uses sac.l (truncation)
 * so errors of 1 LSB per multiply-accumulate are expected.
 */
#define MAX_ERROR_THRESHOLD_Q31   0x00000004L   /* 4 LSBs */

/* -----------------------------------------------------------------------
 * Test matrix A (3x3, symmetric)
 *
 *   A = [ 0.5    0.25   0.125  ]
 *       [ 0.25   0.5    0.25   ]
 *       [ 0.125  0.25   0.5    ]
 *
 * Q31 encoding: value * 2^31
 *   0.5     = 0x40000000
 *   0.25    = 0x20000000
 *   0.125   = 0x10000000
 * ----------------------------------------------------------------------- */

#define Q31_0p5      ((q31_t)0x40000000L)
#define Q31_0p25     ((q31_t)0x20000000L)
#define Q31_0p125    ((q31_t)0x10000000L)

const q31_t A_q31[9] =
{
    Q31_0p5,   Q31_0p25,  Q31_0p125,
    Q31_0p25,  Q31_0p5,   Q31_0p25,
    Q31_0p125, Q31_0p25,  Q31_0p5
};

/* -----------------------------------------------------------------------
 * Test vector b (3x1)
 *
 *   b = [ 0.5 ]
 *       [ 0.25]
 *       [ 0.125]
 * ----------------------------------------------------------------------- */

const q31_t b_q31[3] =
{
    Q31_0p5,
    Q31_0p25,
    Q31_0p125
};

/* -----------------------------------------------------------------------
 * Reference: A * b  (3x1)
 *
 * Hand computation (exact Q31 fractional multiply with truncation):
 *
 *   (A*b)[0] = 0.5*0.5 + 0.25*0.25 + 0.125*0.125
 *            = 0.25   + 0.0625  + 0.015625
 *            = 0.328125
 *            = 0x2A000000  in Q31
 *
 *   (A*b)[1] = 0.25*0.5 + 0.5*0.25 + 0.25*0.125
 *            = 0.125  + 0.125   + 0.03125
 *            = 0.28125
 *            = 0x24000000  in Q31
 *
 *   (A*b)[2] = 0.125*0.5 + 0.25*0.25 + 0.5*0.125
 *            = 0.0625 + 0.0625  + 0.0625
 *            = 0.1875
 *            = 0x18000000  in Q31
 * ----------------------------------------------------------------------- */

const q31_t Ab_ref_q31[3] =
{
    0x2A000000L,   /* 0.328125 */
    0x24000000L,   /* 0.28125  */
    0x18000000L    /* 0.1875   */
};

/* -----------------------------------------------------------------------
 * Reference: A^T * A  (3x3)
 *
 * Since A is symmetric, A^T = A, so A^T * A = A * A.
 *
 * (A*A)[i][j] = sum_k A[i][k] * A[k][j]   (Q31 fractional)
 *
 * Row 0:
 *   [0][0] = 0.5*0.5 + 0.25*0.25 + 0.125*0.125     = 0.328125    = 0x2A000000
 *   [0][1] = 0.5*0.25 + 0.25*0.5 + 0.125*0.25       = 0.28125     = 0x24000000
 *   [0][2] = 0.5*0.125 + 0.25*0.25 + 0.125*0.5      = 0.1875      = 0x18000000
 * Row 1:
 *   [1][0] = 0.25*0.5 + 0.5*0.25 + 0.25*0.125       = 0.28125     = 0x24000000
 *   [1][1] = 0.25*0.25 + 0.5*0.5 + 0.25*0.25        = 0.375       = 0x30000000
 *   [1][2] = 0.25*0.125 + 0.5*0.25 + 0.25*0.5       = 0.28125     = 0x24000000
 * Row 2:
 *   [2][0] = 0.125*0.5 + 0.25*0.25 + 0.5*0.125      = 0.1875      = 0x18000000
 *   [2][1] = 0.125*0.25 + 0.25*0.5 + 0.5*0.25       = 0.28125     = 0x24000000
 *   [2][2] = 0.125*0.125 + 0.25*0.25 + 0.5*0.5      = 0.328125    = 0x2A000000
 * ----------------------------------------------------------------------- */

const q31_t ATA_ref_q31[9] =
{
    0x2A000000L, 0x24000000L, 0x18000000L,
    0x24000000L, 0x30000000L, 0x24000000L,
    0x18000000L, 0x24000000L, 0x2A000000L
};

/* -----------------------------------------------------------------------
 * Test matrix for inversion: 3x3 identity (I)
 *
 * In Q31, 1.0 is not exactly representable; the closest value is
 * 0x7FFFFFFF (~0.99999999953).  The inverse of I is I itself, so
 * the expected output equals the input (within float round-trip error).
 *
 * The inverse function converts Q31 -> float -> Gauss-Jordan -> Q31.
 * A Q31 value of 0x7FFFFFFF converts to float ~0.99999999953, whose
 * reciprocal is ~1.00000000047, which saturates back to 0x7FFFFFFF.
 * Off-diagonal zeros remain zero through the round-trip.
 * ----------------------------------------------------------------------- */

#define Q31_ONE  ((q31_t)0x7FFFFFFFL)   /* closest Q31 to 1.0 */

const q31_t I_q31[9] =
{
    Q31_ONE,  0,        0,
    0,        Q31_ONE,  0,
    0,        0,        Q31_ONE
};

/* -----------------------------------------------------------------------
 * Working buffers
 * ----------------------------------------------------------------------- */
q31_t AT_q31[9];       /* Transpose of A          (3x3)  */
q31_t ATA_q31[9];      /* A^T * A                 (3x3)  */
q31_t SUM_q31[9];      /* A + A                   (3x3)  */
q31_t DIFF_q31[9];     /* A - A                   (3x3)  */
q31_t Ab_q31[3];       /* A * b                   (3x1)  */
q31_t INV_q31[9];      /* Inverse result           (3x3)  */

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

    mchp_matrix_instance_q31 A;
    mchp_matrix_instance_q31 AT;
    mchp_matrix_instance_q31 ATA;
    mchp_matrix_instance_q31 SUM;
    mchp_matrix_instance_q31 DIFF;
    mchp_matrix_instance_q31 bVec;
    mchp_matrix_instance_q31 AbVec;
    mchp_matrix_instance_q31 Ident;
    mchp_matrix_instance_q31 INV;

    mchp_status status;
    int32_t maxErr;
    int32_t overallMax = 0;
    uint32_t i;
    int pass = 1;  /* assume pass */

    printf("\r\n--- Q31 Matrix Operations Example ---\r\n\r\n");

    /* Initialize matrix instances */
    mchp_mat_init_q31(&A,     3, 3, (q31_t *)A_q31);
    mchp_mat_init_q31(&AT,    3, 3, AT_q31);
    mchp_mat_init_q31(&ATA,   3, 3, ATA_q31);
    mchp_mat_init_q31(&SUM,   3, 3, SUM_q31);
    mchp_mat_init_q31(&DIFF,  3, 3, DIFF_q31);
    mchp_mat_init_q31(&bVec,  3, 1, (q31_t *)b_q31);
    mchp_mat_init_q31(&AbVec, 3, 1, Ab_q31);
    mchp_mat_init_q31(&Ident, 3, 3, (q31_t *)I_q31);
    mchp_mat_init_q31(&INV,   3, 3, INV_q31);

    /* ===== Test 1: Transpose ===== */
    printf("Test 1: Transpose\r\n");
    status = mchp_mat_trans_q31(&A, &AT);
    if (status != MCHP_MATH_SUCCESS) {
        printf("  FAILED (status=%d)\r\n", status);
        pass = 0;
        goto done;
    }
    /* A is symmetric, so AT should equal A */
    maxErr = check_q31(AT_q31, A_q31, 9, "A^T (should equal A)");
    if (maxErr > 0) { pass = 0; }
    overallMax = (maxErr > overallMax) ? maxErr : overallMax;

    /* ===== Test 2: Multiply A^T * A ===== */
    printf("\r\nTest 2: Multiply (A^T * A)\r\n");
    status = mchp_mat_mult_q31(&AT, &A, &ATA);
    if (status != MCHP_MATH_SUCCESS) {
        printf("  FAILED (status=%d)\r\n", status);
        pass = 0;
        goto done;
    }
    maxErr = check_q31(ATA_q31, ATA_ref_q31, 9, "A^T*A");
    if (maxErr > (int32_t)MAX_ERROR_THRESHOLD_Q31) { pass = 0; printf("  >> Test 2 FAIL\r\n"); }
    else { printf("  >> Test 2 PASS\r\n"); }
    overallMax = (maxErr > overallMax) ? maxErr : overallMax;

    /* ===== Test 3: Matrix-vector multiply A * b ===== */
    printf("\r\nTest 3: Matrix-vector multiply (A * b)\r\n");
    status = mchp_mat_mult_q31(&A, &bVec, &AbVec);
    if (status != MCHP_MATH_SUCCESS) {
        printf("  FAILED (status=%d)\r\n", status);
        pass = 0;
        goto done;
    }
    maxErr = check_q31(Ab_q31, Ab_ref_q31, 3, "A*b");
    if (maxErr > (int32_t)MAX_ERROR_THRESHOLD_Q31) { pass = 0; printf("  >> Test 3 FAIL\r\n"); }
    else { printf("  >> Test 3 PASS\r\n"); }
    overallMax = (maxErr > overallMax) ? maxErr : overallMax;

    /* ===== Test 4: Addition A + A ===== */
    printf("\r\nTest 4: Addition (A + A)\r\n");
    status = mchp_mat_add_q31(&A, &A, &SUM);
    if (status != MCHP_MATH_SUCCESS) {
        printf("  FAILED (status=%d)\r\n", status);
        pass = 0;
        goto done;
    }
    /* A + A should be 2*A: each element doubled */
    {
        q31_t sum_ref[9];
        for (i = 0; i < 9; i++) {
            /* Saturating add: 2 * 0.5 = 1.0 which saturates to 0x7FFFFFFF in Q31 */
            int64_t tmp = (int64_t)A_q31[i] + (int64_t)A_q31[i];
            if (tmp > 0x7FFFFFFFL) tmp = 0x7FFFFFFFL;
            if (tmp < (int64_t)(-0x7FFFFFFFL - 1)) tmp = -0x7FFFFFFFL - 1;
            sum_ref[i] = (q31_t)tmp;
        }
        maxErr = check_q31(SUM_q31, sum_ref, 9, "A+A");
        if (maxErr > 0) { pass = 0; printf("  >> Test 4 FAIL\r\n"); }
        else { printf("  >> Test 4 PASS\r\n"); }
        overallMax = (maxErr > overallMax) ? maxErr : overallMax;
    }

    /* ===== Test 5: Subtraction A - A ===== */
    printf("\r\nTest 5: Subtraction (A - A)\r\n");
    status = mchp_mat_sub_q31(&A, &A, &DIFF);
    if (status != MCHP_MATH_SUCCESS) {
        printf("  FAILED (status=%d)\r\n", status);
        pass = 0;
        goto done;
    }
    /* A - A should be all zeros */
    {
        q31_t zero_ref[9] = {0};
        maxErr = check_q31(DIFF_q31, zero_ref, 9, "A-A (should be 0)");
        if (maxErr > 0) { pass = 0; printf("  >> Test 5 FAIL\r\n"); }
        else { printf("  >> Test 5 PASS\r\n"); }
        overallMax = (maxErr > overallMax) ? maxErr : overallMax;
    }

    /* ===== Test 6: Inverse of identity matrix ===== */
    printf("\r\nTest 6: Inverse (inv(I) should equal I)\r\n");
    status = mchp_mat_inverse_q31(&Ident, &INV);
    if (status != MCHP_MATH_SUCCESS) {
        printf("  FAILED (status=%d)\r\n", status);
        pass = 0;
        goto done;
    }
    maxErr = check_q31(INV_q31, I_q31, 9, "inv(I)");
    if (maxErr > (int32_t)MAX_ERROR_THRESHOLD_Q31) { pass = 0; printf("  >> Test 6 FAIL\r\n"); }
    else { printf("  >> Test 6 PASS\r\n"); }
    overallMax = (maxErr > overallMax) ? maxErr : overallMax;

    /* ===== Summary ===== */
    printf("\r\nOverall max error: %ld LSBs (threshold: %ld)\r\n",
           (long)overallMax, (long)MAX_ERROR_THRESHOLD_Q31);
    printf("pass flag = %d\r\n", pass);

done:
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
