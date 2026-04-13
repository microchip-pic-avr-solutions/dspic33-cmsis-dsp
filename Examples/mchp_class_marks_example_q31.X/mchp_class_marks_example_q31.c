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

/** *
 * @defgroup ClassMarksQ31 Class Marks Example (Q31)
 *
 * \par Description:
 * \par
 * Demonstrates the use the Maximum, Minimum, Mean, Standard Deviation, Variance
 * and Matrix functions to calculate statistical values of marks obtained in a class.
 * This is the Q31 fixed-point version of the mchp_class_marks_example.
 *
 * \note This example also demonstrates the usage of static initialization.
 *
 * \par Variables Description:
 * \par
 * \li \c testMarks_q31 points to the marks scored by 20 students in 4 subjects (Q31)
 * \li \c max_marks     Maximum of all marks
 * \li \c min_marks     Minimum of all marks
 * \li \c mean          Mean of all marks
 * \li \c var           Variance of the marks
 * \li \c std           Standard deviation of the marks
 * \li \c numStudents   Total number of students in the class
 *
 * \par CMSIS DSP Software Library Functions Used:
 * \par
 * - mchp_mat_init_q31()
 * - mchp_mat_mult_q31()
 * - mchp_max_q31()
 * - mchp_min_q31()
 * - mchp_mean_q31()
 * - mchp_std_q31()
 * - mchp_var_q31()
 *
 * <b> Refer  </b>
 * \link mchp_class_marks_example_q31.c \endlink
 *
 * \example mchp_class_marks_example_q31.c
 *
 */

#include "../clock.h"
#include "../uart.h"
#include "mchp_math.h"
#include "../math_helper.h"

#include <stdio.h>

#define USE_STATIC_INIT

 /* ----------------------------------------------------------------------
** Global defines
** ------------------------------------------------------------------- */

#define TEST_LENGTH_SAMPLES   (20*4)

/* ----------------------------------------------------------------------
** List of Marks scored by 20 students for 4 subjects
**
** Q31 encoding: mark / 100.0 * 2^31
** e.g. 42 marks => 42/100 * 2147483648 = 0x35C28F5C
** ------------------------------------------------------------------- */
const q31_t testMarks_q31[TEST_LENGTH_SAMPLES] =
{
  0x35C28F5C,  0x2F5C28F6,  0x67AE147B,  0x23D70A3D,
  0x6A3D70A4,  0x5C28F5C3,  0x2E147AE1,  0x30A3D70A,
  0x28F5C28F,  0x4147AE14,  0x50A3D70A,  0x51EB851F,
  0x7C28F5C3,  0x6999999A,  0x7999999A,  0x73333333,
  0x547AE148,  0x4147AE14,  0x45C28F5C,  0x35C28F5C,
  0x55C28F5C,  0x47AE147B,  0x39999999,  0x48F5C28F,
  0x55C28F5C,  0x5851EB85,  0x2CCCCCCD,  0x428F5C29,
  0x2547AE14,  0x67AE147B,  0x4A3D70A4,  0x3C28F5C3,
  0x30A3D70A,  0x6147AE14,  0x7FFFFFFF,  0x2547AE14,
  0x2A3D70A4,  0x3C28F5C3,  0x2547AE14,  0x40000000,
  0x2B851EB8,  0x347AE148,  0x4E147AE1,  0x3AE147AE,
  0x428F5C29,  0x40000000,  0x3D70A3D7,  0x2E147AE1,
  0x3C28F5C3,  0x46666666,  0x3851EB85,  0x33333333,
  0x7FFFFFFF,  0x7851EB85,  0x6B851EB8,  0x2F5C28F6,
  0x28F5C28F,  0x5AE147AE,  0x3C28F5C3,  0x6333333A,
  0x27AE147B,  0x40000000,  0x3E147AE1,  0x2CCCCCCD,
  0x50A3D70A,  0x55C28F5C,  0x33333333,  0x27AE147B,
  0x2547AE14,  0x570A3D71,  0x4E147AE1,  0x30A3D70A,
  0x27AE147B,  0x23D70A3D,  0x23D70A3D,  0x6147AE14,
  0x46666666,  0x2A3D70A4,  0x2547AE14,  0x31EB851F
};


/* ----------------------------------------------------------------------
* Number of subjects X 1 — unity vector (Q31: 1.0 ≈ 0x7FFFFFFF)
*
* NOTE: On dsPIC33A, Q31 fractional multiply gives (a*b)<<1 >> 32.
* Multiplying by 0x7FFFFFFF (≈1.0) preserves the value.
* ------------------------------------------------------------------- */
const q31_t testUnity_q31[4] =
{
  0x7FFFFFFF,  0x7FFFFFFF,  0x7FFFFFFF,  0x7FFFFFFF
};


/* ----------------------------------------------------------------------
** Q31 Output buffer
** ------------------------------------------------------------------- */
static q31_t testOutput[TEST_LENGTH_SAMPLES];


/* ------------------------------------------------------------------
* Global defines
*------------------------------------------------------------------- */
#define   NUMSTUDENTS  20
#define   NUMSUBJECTS  4

/* ------------------------------------------------------------------
* Global variables
*------------------------------------------------------------------- */

 uint32_t    numStudents = 20;
 uint32_t    numSubjects = 4;
 q31_t       max_marks, min_marks, mean, std, var;
 uint32_t    student_num;

/* ----------------------------------------------------------------------------------
* Main Q31 test function.  It returns maximum marks secured and student number
* ------------------------------------------------------------------------------- */

int main(int argc, char** argv)
{
    CLOCK_Initialize();
    UART_Initialize();

  #ifndef  USE_STATIC_INIT

    mchp_matrix_instance_q31 srcA;
    mchp_matrix_instance_q31 srcB;
    mchp_matrix_instance_q31 dstC;

    /* Input and output matrices initializations */
    mchp_mat_init_q31(&srcA, numStudents, numSubjects, (q31_t *)testMarks_q31);
    mchp_mat_init_q31(&srcB, numSubjects, 1, (q31_t *)testUnity_q31);
    mchp_mat_init_q31(&dstC, numStudents, 1, testOutput);

  #else

    /* Static Initializations of Input and output matrix sizes and array */
    mchp_matrix_instance_q31 srcA = {NUMSTUDENTS, NUMSUBJECTS, (q31_t *)testMarks_q31};
    mchp_matrix_instance_q31 srcB = {NUMSUBJECTS, 1, (q31_t *)testUnity_q31};
    mchp_matrix_instance_q31 dstC = {NUMSTUDENTS, 1, testOutput};

  #endif


    /* ----------------------------------------------------------------------
    *Call the Matrix multiplication process function
    * ------------------------------------------------------------------- */
    mchp_mat_mult_q31(&srcA, &srcB, &dstC);

    /* ----------------------------------------------------------------------
    ** Call the Max function to calculate max marks among numStudents
    ** ------------------------------------------------------------------- */
    mchp_max_q31(testOutput, numStudents, &max_marks, &student_num);

    /* ----------------------------------------------------------------------
    ** Call the Min function to calculate min marks among numStudents
    ** ------------------------------------------------------------------- */
    mchp_min_q31(testOutput, numStudents, &min_marks, &student_num);

    /* ----------------------------------------------------------------------
    ** Call the Mean function to calculate mean
    ** ------------------------------------------------------------------- */
    mchp_mean_q31(testOutput, numStudents, &mean);

    /* ----------------------------------------------------------------------
    ** Call the std function to calculate standard deviation
    ** ------------------------------------------------------------------- */
    mchp_std_q31(testOutput, numStudents, &std);

    /* ----------------------------------------------------------------------
    ** Call the var function to calculate variance
    ** ------------------------------------------------------------------- */
    mchp_var_q31(testOutput, numStudents, &var);

    printf("\r\n mean = 0x%08lX, std = 0x%08lX\r\n ",
           (unsigned long)mean, (unsigned long)std);
    while(1);
}
