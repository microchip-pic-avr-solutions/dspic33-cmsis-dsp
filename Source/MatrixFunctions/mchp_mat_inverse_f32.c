/**
;*****************************************************************************
;                                                                            *
;                       Software License Agreement                           *
;*****************************************************************************
;*****************************************************************************
; © [2026] Microchip Technology Inc. and its subsidiaries.                    *
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
 * @brief  Single precision floating point Matrix Inversion.
 *
 * This function computes the inverse of a square matrix of type float32 using
 * the full-pivoting Gauss-Jordan elimination algorithm. The implementation
 * transforms the input matrix in-place (or copies if src != dst) and applies
 * row and column swaps to ensure numerical stability. The algorithm is similar
 * to the CMSIS-DSP matrix inversion approach.
 *
 * - The input and output matrices must be square and of the same dimensions.
 * - The function supports in-place inversion (src == dst).
 * - If the matrix is singular (non-invertible), the function returns an error.
 * - No heap memory is used; all bookkeeping arrays are allocated on the stack.
 *
 * @param[in]  src   Pointer to the source matrix instance (matrix to invert).
 * @param[out] dst   Pointer to the destination matrix instance (resulting inverse).
 *
 * @return MCHP_MATH_SUCCESS         Matrix inversion successful.
 * @return MCHP_MATH_SIZE_MISMATCH   Input and output matrix dimensions do not match.
 * @return MCHP_MATH_SINGULAR        Matrix is singular (non-invertible).
 *
 * @note
 * - The function does not check for NaN or Inf values in the input matrix.
 * - The function assumes row-major storage for matrix data.
 * - The function does not support non-square matrices.
 */
#include "mchp_math.h"
#include <math.h>

mchp_status mchp_mat_inverse_f32(const mchp_matrix_instance_f32 *src,
                                 mchp_matrix_instance_f32 *dst)
{
    uint16_t nRows = src->numRows;
    uint16_t nCols = src->numCols;
    mchp_status status = MCHP_MATH_SUCCESS;

    if ((dst->numRows != nRows) || (dst->numCols != nCols)) {
        status = MCHP_MATH_SIZE_MISMATCH;
    }
    else
    {
        int numRowsCols = (int)nRows;
        float absVal;
        float maxVal;
        int cntr = 0;
        int r;
        int c;
        int ir;
        int ic;
        uint32_t pivotMask = 0U; // Bitmask for used pivots

        // Copy src to dst if not in-place
        if (src != dst) {
            for (r = 0; r < numRowsCols; r++) {
                for (c = 0; c < numRowsCols; c++) {
                    dst->pData[(r * numRowsCols) + c] = src->pData[(r * numRowsCols) + c];
                }
            }
        }

        // Gauss-Jordan elimination
        for (cntr = 0; cntr < numRowsCols; cntr++) {
            // Find pivot element
            maxVal = 0.0f;
            ir = -1;
            ic = -1;
            for (r = 0; r < numRowsCols; r++) {
                if ((pivotMask & (1U << (uint32_t)r)) == 0U) {
                    for (c = 0; c < numRowsCols; c++) {
                        if ((pivotMask & (1U << (uint32_t)c)) == 0U) {
                            absVal = fabsf(dst->pData[(r * numRowsCols) + c]);
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
            }
            else
            {
                pivotMask |= (1U << (uint32_t)ic); // mark pivot used

                // Swap rows
                if (ir != ic) {
                    for (c = 0; c < numRowsCols; c++) {
                        absVal = dst->pData[(ir * numRowsCols) + c];
                        dst->pData[(ir * numRowsCols) + c] = dst->pData[(ic * numRowsCols) + c];
                        dst->pData[(ic * numRowsCols) + c] = absVal;
                    }
                }

                // Check for singular matrix
                if (dst->pData[(ic * numRowsCols) + ic] == 0.0f) {
                    status = MCHP_MATH_SINGULAR;
                    break; // Single break to exit the main loop
                }
                // Divide the row by the pivot
                absVal = 1.0f / dst->pData[(ic * numRowsCols) + ic];
                dst->pData[(ic * numRowsCols) + ic] = 1.0f;
                for (c = 0; c < numRowsCols; c++) {
                    dst->pData[(ic * numRowsCols) + c] *= absVal;
                }

                // Fix other rows
                for (r = 0; r < numRowsCols; r++) {
                    if (r != ic) {
                        absVal = dst->pData[(r * numRowsCols) + ic];
                        dst->pData[(r * numRowsCols) + ic] = 0.0f;
                        for (c = 0; c < numRowsCols; c++) {
                            dst->pData[(r * numRowsCols) + c] -= (dst->pData[(ic * numRowsCols) + c] * absVal);
                        }
                    }
                }
            }
        }
    }

    return status;
}
