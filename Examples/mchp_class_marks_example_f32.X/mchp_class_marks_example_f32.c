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

/** *
 * @defgroup ClassMarks Class Marks Example
 *
 * \par Description:
 * \par
 * Demonstrates the use the Maximum, Minimum, Mean, Standard Deviation, Variance
 * and Matrix functions to calculate statistical values of marks obtained in a class.
 *
 * \note This example also demonstrates the usage of static initialization.
 *
 * \par Variables Description:
 * \par
 * \li \c testMarks_f32 points to the marks scored by 20 students in 4 subjects
 * \li \c max_marks     Maximum of all marks
 * \li \c min_marks     Minimum of all marks
 * \li \c mean          Mean of all marks
 * \li \c var           Variance of the marks
 * \li \c std           Standard deviation of the marks
 * \li \c numStudents   Total number of students in the class
 *
 * \par CMSIS DSP Software Library Functions Used:
 * \par
 * - mchp_mat_init_f32()
 * - mchp_mat_mult_f32()
 * - mchp_max_f32()
 * - mchp_min_f32()
 * - mchp_mean_f32()
 * - mchp_std_f32()
 * - mchp_var_f32()
 *
 * <b> Refer  </b>
 * \link mchp_class_marks_example_f32.c \endlink
 *
 * \example mchp_class_marks_example_f32.c
 *
 */

#include "../clock.h"
#include "../uart.h"
#include "mchp_math.h"

#include <stdio.h>

#define USE_STATIC_INIT

 /* ----------------------------------------------------------------------
** Global defines
** ------------------------------------------------------------------- */

#define TEST_LENGTH_SAMPLES   (20*4)

/* ----------------------------------------------------------------------
** List of Marks scored by 20 students for 4 subjects
** ------------------------------------------------------------------- */
const float32_t testMarks_f32[TEST_LENGTH_SAMPLES] =
{
  42.000000,  37.000000,  81.000000,  28.000000,
  83.000000,  72.000000,  36.000000,  38.000000,
  32.000000,  51.000000,  63.000000,  64.000000,
  97.000000,  82.000000,  95.000000,  90.000000,
  66.000000,  51.000000,  54.000000,  42.000000,
  67.000000,  56.000000,  45.000000,  57.000000,
  67.000000,  69.000000,  35.000000,  52.000000,
  29.000000,  81.000000,  58.000000,  47.000000,
  38.000000,  76.000000, 100.000000,  29.000000,
  33.000000,  47.000000,  29.000000,  50.000000,
  34.000000,  41.000000,  61.000000,  46.000000,
  52.000000,  50.000000,  48.000000,  36.000000,
  47.000000,  55.000000,  44.000000,  40.000000,
 100.000000,  94.000000,  84.000000,  37.000000,
  32.000000,  71.000000,  47.000000,  77.000000,
  31.000000,  50.000000,  49.000000,  35.000000,
  63.000000,  67.000000,  40.000000,  31.000000,
  29.000000,  68.000000,  61.000000,  38.000000,
  31.000000,  28.000000,  28.000000,  76.000000,
  55.000000,  33.000000,  29.000000,  39.000000
};


/* ----------------------------------------------------------------------
* Number of subjects X 1
* ------------------------------------------------------------------- */
const float32_t testUnity_f32[4] =
{
  1.000,  1.000,   1.000,  1.000
};


/* ----------------------------------------------------------------------
** f32 Output buffer
** ------------------------------------------------------------------- */
static float32_t testOutput[TEST_LENGTH_SAMPLES];


/* ------------------------------------------------------------------
* Global defines
*------------------------------------------------------------------- */
#define   NUMSTUDENTS  20
#define     NUMSUBJECTS  4

/* ------------------------------------------------------------------
* Global variables
*------------------------------------------------------------------- */

 uint32_t    numStudents = 20;
 uint32_t    numSubjects = 4;
float32_t    max_marks, min_marks, mean, std, var;
 uint32_t    student_num;

/* ----------------------------------------------------------------------------------
* Main f32 test function.  It returns maximum marks secured and student number
* ------------------------------------------------------------------------------- */

int main(int argc, char** argv)
{
    CLOCK_Initialize();
    UART_Initialize();

  #ifndef  USE_STATIC_INIT

    mchp_matrix_instance_f32 srcA;
    mchp_matrix_instance_f32 srcB;
    mchp_matrix_instance_f32 dstC;

    /* Input and output matrices initializations */
    mchp_mat_init_f32(&srcA, numStudents, numSubjects, (float32_t *)testMarks_f32);
    mchp_mat_init_f32(&srcB, numSubjects, 1, (float32_t *)testUnity_f32);
    mchp_mat_init_f32(&dstC, numStudents, 1, testOutput);

  #else

    /* Static Initializations of Input and output matrix sizes and array */
    mchp_matrix_instance_f32 srcA = {NUMSTUDENTS, NUMSUBJECTS, (float32_t *)testMarks_f32};
    mchp_matrix_instance_f32 srcB = {NUMSUBJECTS, 1, (float32_t *)testUnity_f32};
    mchp_matrix_instance_f32 dstC = {NUMSTUDENTS, 1, testOutput};

  #endif


    /* ----------------------------------------------------------------------
    *Call the Matrix multiplication process function
    * ------------------------------------------------------------------- */
    mchp_mat_mult_f32(&srcA, &srcB, &dstC);

    /* ----------------------------------------------------------------------
    ** Call the Max function to calculate max marks among numStudents
    ** ------------------------------------------------------------------- */
    mchp_max_f32(testOutput, numStudents, &max_marks, &student_num);

    /* ----------------------------------------------------------------------
    ** Call the Min function to calculate min marks among numStudents
    ** ------------------------------------------------------------------- */
    mchp_min_f32(testOutput, numStudents, &min_marks, &student_num);

    /* ----------------------------------------------------------------------
    ** Call the Mean function to calculate mean
    ** ------------------------------------------------------------------- */
    mchp_mean_f32(testOutput, numStudents, &mean);

    /* ----------------------------------------------------------------------
    ** Call the std function to calculate standard deviation
    ** ------------------------------------------------------------------- */
    mchp_std_f32(testOutput, numStudents, &std);

    /* ----------------------------------------------------------------------
    ** Call the var function to calculate variance
    ** ------------------------------------------------------------------- */
    mchp_var_f32(testOutput, numStudents, &var);

    printf("\r\n mean = %f, std = %f\r\n ",(double)mean,(double)std);
    while(1);
}