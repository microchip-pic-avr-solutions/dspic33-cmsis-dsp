/**
;*****************************************************************************
;                                                                            *
;                       Software License Agreement                           *
;*****************************************************************************
;*****************************************************************************
;? [2026] Microchip Technology Inc. and its subsidiaries.                    *
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
 * @defgroup MatrixExample Matrix Example
 *
 * \par Description:
 * \par
 * Demonstrates the use of Matrix Transpose, Matrix Multiplication, and Matrix Inverse
 * functions to apply least squares fitting to input data. Least squares fitting is
 * the procedure for finding the best-fitting curve that minimizes the sum of the
 * squares of the offsets (least square error) from a given set of data.
 *
 * \par Algorithm:
 * \par
 * The linear combination of parameters considered is as follows:
 * \par
 * <code>A * X = B</code>, where \c X is the unknown value and can be estimated
 * from \c A & \c B.
 * \par
 * The least squares estimate \c X is given by the following equation:
 * \par
 * <code>X = Inverse(A<sup>T</sup> * A) *  A<sup>T</sup> * B</code>
 *
 * \par Block Diagram:
 * \par
 *
 * \par Variables Description:
 * \par
 * \li \c A_f32 input matrix in the linear combination equation
 * \li \c B_f32 output matrix in the linear combination equation
 * \li \c X_f32 unknown matrix estimated using \c A_f32 & \c B_f32 matrices
 *
 * \par CMSIS DSP Software Library Functions Used:
 * \par
 * - mchp_mat_init_f32()
 * - mchp_mat_trans_f32()
 * - mchp_mat_mult_f32()
 * - mchp_mat_inverse_f32()
 *
 * <b> Refer  </b>
 * \link mchp_matrix_example.c \endlink
 *
 * \example mchp_matrix_example.c
 *
 */


#include "../clock.h"
#include "../uart.h"
#include "mchp_math.h"
#include "../math_helper.h"
#include <stdio.h>


#define SNR_THRESHOLD   77

/* --------------------------------------------------------------------------------
* Test input data(Cycles) taken from FIR Q15 function for different cases of blockSize
* and tapSize
* --------------------------------------------------------------------------------- */

const float32_t B_f32[4] =
{
  782.0, 7577.0, 470.0, 4505.0
};

/* --------------------------------------------------------------------------------
* Formula to fit is  C1 + C2 * numTaps + C3 * blockSize + C4 * numTaps * blockSize
* -------------------------------------------------------------------------------- */

const float32_t A_f32[16] =
{
  /* Const,   numTaps,   blockSize,   numTaps*blockSize */
  1.0f,     32.0f,      4.0f,     128.0f,
  1.0f,     32.0f,     64.0f,    2048.0f,
  1.0f,     16.0f,      4.0f,      64.0f,
  1.0f,     16.0f,     64.0f,    1024.0f,
};


/* ----------------------------------------------------------------------
* Temporary buffers  for storing intermediate values
* ------------------------------------------------------------------- */
/* Transpose of A Buffer */
float32_t AT_f32[16];
/* (Transpose of A * A) Buffer */
float32_t ATMA_f32[16];
/* Inverse(Transpose of A * A)  Buffer */
float32_t ATMAI_f32[16];
/* Test Output Buffer */
float32_t X_f32[4];

/* ----------------------------------------------------------------------
* Reference output buffer C1, C2, C3 and C4 taken from MATLAB
* ------------------------------------------------------------------- */
const float32_t xRef_f32[4] = {73.0f, 8.0f, 21.25f, 2.875f};

float32_t snr;


/* ----------------------------------------------------------------------
* Matrix Least Squares Fitting Example
* ------------------------------------------------------------------- */

int main(int argc, char** argv)
{
    CLOCK_Initialize();
    UART_Initialize();

    mchp_matrix_instance_f32 A;      /* Matrix A Instance */
    mchp_matrix_instance_f32 AT;     /* Matrix AT(A transpose) instance */
    mchp_matrix_instance_f32 ATMA;   /* Matrix ATMA( AT multiply with A) instance */
    mchp_matrix_instance_f32 ATMAI;  /* Matrix ATMAI(Inverse of ATMA) instance */
    mchp_matrix_instance_f32 B;      /* Matrix B instance */
    mchp_matrix_instance_f32 X;      /* Matrix X(Unknown Matrix) instance */

    uint32_t srcRows, srcColumns;  /* Temporary variables */
    mchp_status status;

    /* Initialise A Matrix Instance with numRows, numCols and data array(A_f32) */
    srcRows = 4;
    srcColumns = 4;
    mchp_mat_init_f32(&A, srcRows, srcColumns, (float32_t *)A_f32);

    /* Initialise Matrix Instance AT with numRows, numCols and data array(AT_f32) */
    srcRows = 4;
    srcColumns = 4;
    mchp_mat_init_f32(&AT, srcRows, srcColumns, AT_f32);

    /* calculation of A transpose */
    status = mchp_mat_trans_f32(&A, &AT);


    /* Initialise ATMA Matrix Instance with numRows, numCols and data array(ATMA_f32) */
    srcRows = 4;
    srcColumns = 4;
    mchp_mat_init_f32(&ATMA, srcRows, srcColumns, ATMA_f32);

    /* calculation of AT Multiply with A */
    status = mchp_mat_mult_f32(&AT, &A, &ATMA);

    /* Initialise ATMAI Matrix Instance with numRows, numCols and data array(ATMAI_f32) */
    srcRows = 4;
    srcColumns = 4;
    mchp_mat_init_f32(&ATMAI, srcRows, srcColumns, ATMAI_f32);

    /* calculation of Inverse((Transpose(A) * A) */
    status = mchp_mat_inverse_f32(&ATMA, &ATMAI);

    /* calculation of (Inverse((Transpose(A) * A)) *  Transpose(A)) */
    status = mchp_mat_mult_f32(&ATMAI, &AT, &ATMA);

    /* Initialise B Matrix Instance with numRows, numCols and data array(B_f32) */
    srcRows = 4;
    srcColumns = 1;
    mchp_mat_init_f32(&B, srcRows, srcColumns, (float32_t *)B_f32);

    /* Initialise X Matrix Instance with numRows, numCols and data array(X_f32) */
    srcRows = 4;
    srcColumns = 1;
    mchp_mat_init_f32(&X, srcRows, srcColumns, X_f32);

    /* calculation ((Inverse((Transpose(A) * A)) *  Transpose(A)) * B) */
    status = mchp_mat_mult_f32(&ATMA, &B, &X);

    /* Comparison of reference with test output */
    snr = mchp_snr_f32((float32_t *)xRef_f32, X_f32, 4);

    /*------------------------------------------------------------------------------
    *            Initialise status depending on SNR calculations
    *------------------------------------------------------------------------------*/
    status = (snr < SNR_THRESHOLD) ? MCHP_MATH_TEST_FAILURE : MCHP_MATH_SUCCESS;
    
    if (status != MCHP_MATH_SUCCESS)
    {
      printf("\r\n FAILURE \r\n");
    }
    else
    {
      printf("\r\n SUCCESS \r\n");
    }
    while(1);
}

 /** \endlink */
