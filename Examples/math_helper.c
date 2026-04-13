/* Microchip Technology Inc. and its subsidiaries.  You may use this software 
 * and any derivatives exclusively with Microchip products. 
 * 
 * THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS".  NO WARRANTIES, WHETHER 
 * EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED 
 * WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A 
 * PARTICULAR PURPOSE, OR ITS INTERACTION WITH MICROCHIP PRODUCTS, COMBINATION 
 * WITH ANY OTHER PRODUCTS, OR USE IN ANY APPLICATION. 
 *
 * IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE, 
 * INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND 
 * WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS 
 * BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE.  TO THE 
 * FULLEST EXTENT ALLOWED BY LAW, MICROCHIPS TOTAL LIABILITY ON ALL CLAIMS 
 * IN ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF 
 * ANY, THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.
 *
 * MICROCHIP PROVIDES THIS SOFTWARE CONDITIONALLY UPON YOUR ACCEPTANCE OF THESE 
 * TERMS. 
 * 
 * Title:	      math_helper.c
 *
 * Description:	Definition of all helper functions required.
 *
 * Target Processor: dsPIC33A
 */

/* ----------------------------------------------------------------------
*		Include standard header files
* -------------------------------------------------------------------- */
#include <math.h>

/* ----------------------------------------------------------------------
*		Include project header files
* -------------------------------------------------------------------- */
#include "math_helper.h"

/**
 * @brief  Calculation of SNR
 * @param[in]  pRef 	Pointer to the reference buffer
 * @param[in]  pTest	Pointer to the test buffer
 * @param[in]  buffSize	total number of samples
 * @return     SNR
 * The function Calculates signal to noise ratio for the reference output
 * and test output
 */

float mchp_snr_f32(float *pRef, float *pTest, uint32_t buffSize)
{
  float EnergySignal = 0.0, EnergyError = 0.0;
  uint32_t i;
  float SNR;
  int temp;
  int *test;

  for (i = 0; i < buffSize; i++)
    {
 	  /* Checking for a NAN value in pRef array */
	  test =   (int *)(&pRef[i]);
      temp =  *test;

	  if (temp == 0x7FC00000)
	  {
	  		return(0);
	  }

	  /* Checking for a NAN value in pTest array */
	  test =   (int *)(&pTest[i]);
      temp =  *test;

	  if (temp == 0x7FC00000)
	  {
	  		return(0);
	  }
      EnergySignal += pRef[i] * pRef[i];
      EnergyError += (pRef[i] - pTest[i]) * (pRef[i] - pTest[i]);
    }

	/* Checking for a NAN value in EnergyError */
	test =   (int *)(&EnergyError);
    temp =  *test;

    if (temp == 0x7FC00000)
    {
  		return(0);
    }


  SNR = 10 * (float32_t)log10 ((double)EnergySignal / (double)EnergyError);

  return (SNR);

}


/**
 * @brief  Calculates number of guard bits
 * @param[in]  num_adds 	number of additions
 * @return guard bits
 * The function Calculates the number of guard bits
 * depending on the numtaps
 */

uint32_t mchp_calc_guard_bits (uint32_t num_adds)
{
  uint32_t i = 1, j = 0;

  if (num_adds == 1)
    {
      return (0);
    }

  while (i < num_adds)
    {
      i = i * 2;
      j++;
    }

  return (j);
}

/**
 * @brief  Apply guard bits to buffer
 * @param[in,out]  pIn         pointer to input buffer
 * @param[in]      numSamples  number of samples in the input buffer
 * @param[in]      guard_bits  guard bits
 * @return none
 */

void mchp_apply_guard_bits (float32_t *pIn,
						   uint32_t numSamples,
						   uint32_t guard_bits)
{
  uint32_t i;

  for (i = 0; i < numSamples; i++)
    {
      pIn[i] = pIn[i] * mchp_calc_2pow(guard_bits);
    }
}

/**
 * @brief  Calculates pow(2, numShifts)
 * @param[in]  numShifts 	number of shifts
 * @return pow(2, numShifts)
 */
uint32_t mchp_calc_2pow(uint32_t numShifts)
{

  uint32_t i, val = 1;

  for (i = 0; i < numShifts; i++)
    {
      val = val * 2;
    }

  return(val);
}