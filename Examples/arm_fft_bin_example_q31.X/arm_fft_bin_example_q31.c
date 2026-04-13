/* ----------------------------------------------------------------------
* Copyright (C) 2010-2012 ARM Limited. All rights reserved.
*
* Project:       dspic33-cmsis-dsp Library
* Title:	     arm_fft_bin_example_q31.c
*
* Description:   Example code demonstrating calculation of Max energy bin of
*                frequency domain of input signal.
*
* Target Processor: dsPIC33A
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*   - Redistributions of source code must retain the above copyright
*     notice, this list of conditions and the following disclaimer.
*   - Redistributions in binary form must reproduce the above copyright
*     notice, this list of conditions and the following disclaimer in
*     the documentation and/or other materials provided with the
*     distribution.
*   - Neither the name of ARM LIMITED nor the names of its contributors
*     may be used to endorse or promote products derived from this
*     software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
* BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
* CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
* LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
* ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
* -------------------------------------------------------------------- */

/**
 * @addtogroup groupExamples
 * @{
 *
 * @defgroup FrequencyBinQ31 Frequency Bin Example (Q31)
 *
 * \par Description
 * \par
 * Demonstrates the calculation of the maximum energy bin in the frequency
 * domain of the input signal with the use of Complex FFT, Complex
 * Magnitude Squared, and Maximum functions.
 *
 * \par Algorithm:
 * \par
 * The input test signal contains a 10 kHz signal with uniformly distributed white noise.
 * Calculating the FFT of the input signal will give us the maximum energy of the
 * bin corresponding to the input frequency of 10 kHz.
 *
 * \par Variables Description:
 * \par
 * \li \c testInput_q31_10khz points to the input data
 * \li \c testOutput points to the output data
 * \li \c fftSize length of FFT
 * \li \c ifftFlag flag for the selection of CFFT/CIFFT
 * \li \c doBitReverse Flag for selection of normal order or bit reversed order
 * \li \c refIndex reference index value at which maximum energy of bin ocuurs
 * \li \c testIndex calculated index value at which maximum energy of bin ocuurs
 *
 * \par CMSIS DSP Software Library Functions Used:
 * \par
 * - mchp_cfft_q31()
 * - mchp_cmplx_mag_squared_q31()
 * - mchp_max_q31()
 *
 * <b> Refer  </b>
 * \link mchp_fft_bin_example_q31.c \endlink
 *
 * \example mchp_fft_bin_example_q31.c
 *
 * @}*/

#include "../clock.h"
#include "../uart.h"
#include "arm_math.h"
#include <stdio.h>

#define TEST_LENGTH_SAMPLES 2048


/* -------------------------------------------------------------------
* External Input and Output buffer Declarations for FFT Bin Example
* ------------------------------------------------------------------- */
extern q31_t testInput_q31_10khz[TEST_LENGTH_SAMPLES];
static q31_t testOutput[TEST_LENGTH_SAMPLES/2];

/* ------------------------------------------------------------------
* Global variables for FFT Bin Example
* ------------------------------------------------------------------- */
uint32_t fftSize = 1024;
uint32_t ifftFlag = 0;
uint32_t doBitReverse = 1;
mchp_cfft_instance_q31 varInstCfftQ31;

/* Reference index at which max energy of bin ocuurs */
uint32_t refIndex = 213, testIndex = 0;

/* ----------------------------------------------------------------------
* Max magnitude FFT Bin test
* ------------------------------------------------------------------- */

int main(int argc, char** argv)
{

    mchp_status status;
    q31_t maxValue;

    /* CLOCK Initialize */
    CLOCK_Initialize();
    /* UART Initialize */
    UART_Initialize();

    status = ARM_MATH_SUCCESS;

    status=arm_cfft_init_q31(&varInstCfftQ31, 1024);

    /* Process the data through the CFFT/CIFFT function */
    arm_cfft_q31(&varInstCfftQ31, testInput_q31_10khz, ifftFlag, doBitReverse);

    /* Process the data through the Complex Magnitude Squared function for
    calculating the magnitude at each bin */
    arm_cmplx_mag_squared_q31(testInput_q31_10khz, testOutput, fftSize);

    /* Calculates maxValue and returns corresponding BIN value */
    arm_max_q31(testOutput, fftSize, &maxValue, &testIndex);

    status = (testIndex != refIndex) ? ARM_MATH_TEST_FAILURE : ARM_MATH_SUCCESS;

    if (status != ARM_MATH_SUCCESS)
    {
        printf("\r\n FAILURE \r\n");
    }
    else
    {
        printf("\r\n SUCCESS \r\n");
    }

    while(1);        /* main function does not return */
}
