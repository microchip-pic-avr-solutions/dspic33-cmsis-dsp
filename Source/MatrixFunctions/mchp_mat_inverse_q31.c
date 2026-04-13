/**
;*****************************************************************************
;                                                                            *
;                       Software License Agreement                           *
;*****************************************************************************
;*****************************************************************************
;© [2026] Microchip Technology Inc. and its subsidiaries.                    *
;                                                                            *
;   Subject to your compliance with these terms, you may use Microchip       *
;   software and any derivatives exclusively with Microchip products.        *
;   You are responsible for complying with 3rd party license terms            *
;   applicable to your use of 3rd party software (including open source       *
;   software) that may accompany Microchip software. SOFTWARE IS ?AS IS.?     *
;   NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS       *
;   SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,           *
;   MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT         *
;   WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,             *
;   INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY          *
;   KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF          *
;   MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE          *
;   FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIP?S            *
;   TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT            *
;   EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR         *
;   THIS SOFTWARE.                                                            *
;*****************************************************************************
*/

/**
 * @brief  Q31 fixed-point Matrix Inversion.
 *
 * This function computes the inverse of a square Q31 matrix using the
 * full-pivoting Gauss-Jordan elimination algorithm.  Because Gauss-Jordan
 * requires division (which has no efficient pure-Q31 implementation), the
 * input Q31 data is converted to float for the elimination, and the result
 * is converted back to Q31.  This is the standard approach used by the
 * ARM CMSIS-DSP library for arm_mat_inverse_q31.
 *
 * - The input and output matrices must be square and of the same dimensions.
 * - The function supports in-place inversion (src == dst).
 * - If the matrix is singular (non-invertible), the function returns an error.
 * - No heap memory is used; all bookkeeping arrays are allocated on the stack.
 * - Maximum supported matrix size is 32x32 (limited by pivot bitmask width).
 *
 * @param[in]  src   Pointer to the source matrix instance (matrix to invert).
 * @param[out] dst   Pointer to the destination matrix instance (resulting inverse).
 *
 * @return MCHP_MATH_SUCCESS         Matrix inversion successful.
 * @return MCHP_MATH_SIZE_MISMATCH   Input and output matrix dimensions do not match.
 * @return MCHP_MATH_SINGULAR        Matrix is singular (non-invertible).
 *
 * @note
 * - The function assumes row-major storage for matrix data.
 * - The function does not support non-square matrices.
 * - Q31-to-float conversion: float_val = (float)q31_val / 2147483648.0f
 * - Float-to-Q31 conversion: q31_val  = (q31_t)(float_val * 2147483648.0f)
 *   with saturation to [0x80000000, 0x7FFFFFFF].
 */
#include "mchp_math.h"
#include <math.h>

#define Q31_SCALE 2147483648.0f   /* 2^31 */

/**
 * @brief Convert a Q31 fractional value to float.
 *
 * Q31 represents the range [-1.0, +1.0) as [0x80000000, 0x7FFFFFFF].
 * This divides by 2^31 to recover the fractional value.
 */
static inline float q31_to_float(q31_t x)
{
    return (float)x / Q31_SCALE;
}

/**
 * @brief Convert a float value back to Q31 with saturation.
 *
 * Multiplies by 2^31 and saturates to the Q31 range.
 */
static inline q31_t float_to_q31(float x)
{
    x = x * Q31_SCALE;
    if (x >= (float)0x7FFFFFFF) {
        return (q31_t)0x7FFFFFFF;
    }
    if (x < (float)((q31_t)0x80000000U)) {
        return (q31_t)0x80000000U;
    }
    return (q31_t)x;
}

mchp_status mchp_mat_inverse_q31(const mchp_matrix_instance_q31 *src,
                                 mchp_matrix_instance_q31 *dst)
{
    uint16_t nRows = src->numRows;
    uint16_t nCols = src->numCols;
    mchp_status status = MCHP_MATH_SUCCESS;

    /* Dimension checks: src and dst must match, and matrix must be square. */
    if ((dst->numRows != nRows) || (dst->numCols != nCols) || (nRows != nCols)) {
        status = MCHP_MATH_SIZE_MISMATCH;
    }
    else
    {
        int n = (int)nRows;
        int totalElements = n * n;
        float absVal;
        float maxVal;
        int cntr;
        int r, c, ir, ic;
        uint32_t pivotMask = 0U;

        /*
         * Allocate a temporary float working buffer on the stack.
         * Convert Q31 source data to float for the Gauss-Jordan elimination.
         */
        float work[totalElements];

        for (r = 0; r < totalElements; r++) {
            work[r] = q31_to_float(src->pData[r]);
        }

        /* ---- Gauss-Jordan elimination (in float) ---- */
        for (cntr = 0; cntr < n; cntr++) {
            /* Find pivot element (full pivoting). */
            maxVal = 0.0f;
            ir = -1;
            ic = -1;
            for (r = 0; r < n; r++) {
                if ((pivotMask & (1U << (uint32_t)r)) == 0U) {
                    for (c = 0; c < n; c++) {
                        if ((pivotMask & (1U << (uint32_t)c)) == 0U) {
                            absVal = fabsf(work[(r * n) + c]);
                            if (absVal >= maxVal) {
                                maxVal = absVal;
                                ir = r;
                                ic = c;
                            }
                        }
                    }
                }
            }

            if ((ir == -1) || (ic == -1)) {
                status = MCHP_MATH_SINGULAR;
                break;
            }

            pivotMask |= (1U << (uint32_t)ic);

            /* Swap rows ir and ic. */
            if (ir != ic) {
                for (c = 0; c < n; c++) {
                    float tmp = work[(ir * n) + c];
                    work[(ir * n) + c] = work[(ic * n) + c];
                    work[(ic * n) + c] = tmp;
                }
            }

            /* Check for singular matrix (zero pivot). */
            if (work[(ic * n) + ic] == 0.0f) {
                status = MCHP_MATH_SINGULAR;
                break;
            }

            /* Divide pivot row by the pivot element. */
            absVal = 1.0f / work[(ic * n) + ic];
            work[(ic * n) + ic] = 1.0f;
            for (c = 0; c < n; c++) {
                work[(ic * n) + c] *= absVal;
            }

            /* Eliminate column ic from all other rows. */
            for (r = 0; r < n; r++) {
                if (r != ic) {
                    float factor = work[(r * n) + ic];
                    work[(r * n) + ic] = 0.0f;
                    for (c = 0; c < n; c++) {
                        work[(r * n) + c] -= work[(ic * n) + c] * factor;
                    }
                }
            }
        }

        /* Convert float result back to Q31 and store in dst. */
        if (status == MCHP_MATH_SUCCESS) {
            for (r = 0; r < totalElements; r++) {
                dst->pData[r] = float_to_q31(work[r]);
            }
        }
    }

    return status;
}
