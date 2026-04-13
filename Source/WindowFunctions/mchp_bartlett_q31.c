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
;******************************************************************************/

#include "../../Include/dsp/window_functions.h"

/**
  @ingroup groupWindow
 */

/**
  @addtogroup WindowNormal
  @{
 */

/**
  @defgroup WindowBARTLETT Bartlett window function (26.5 dB)

 */

/**
  @ingroup WindowBARTLETT
 */

/**
  @brief         Bartlett window generating function (q31).
  @param[out]    pDst       points to the output generated window
  @param[in]     blockSize  number of samples in the window

  @par Parameters of the window

  | Parameter                             | Value              |
  | ------------------------------------: | -----------------: |
  | Peak sidelobe level                   |           26.5 dB  |
  | Normalized equivalent noise bandwidth |       1.3333 bins  |
  | 3 dB bandwidth                        |       1.2736 bins  |
  | Flatness                              |        -1.8242 dB  |
  | Recommended overlap                   |            50.0 %  |

  Computed in floating point, converted to Q31 fractionals.

 */

MCHP_DSP_ATTRIBUTE void mchp_bartlett_q31(
        q31_t * pDst,
        uint32_t blockSize)
{
    float32_t arg = BART_0 / ((float32_t)(blockSize));
    uint32_t cntr = 0;

    /* Rising slope: 0 to 1 */
    for (cntr = 0; cntr <= ((blockSize) / 2U); cntr++)
    {
        float32_t tempVal = (arg * (float32_t)cntr) * 2147483648.0f;
        *(pDst++) = (q31_t)tempVal;
    }

    /* Falling slope: 1 to 0 */
    for (; cntr < blockSize; cntr++)
    {
        float32_t tempVal = (BART_0 - (arg * (float32_t)cntr)) * 2147483648.0f;
        *(pDst++) = (q31_t)tempVal;
    }

    /* No return (CMSIS style) */
}

/**
  @} end of WindowNormal group
 */