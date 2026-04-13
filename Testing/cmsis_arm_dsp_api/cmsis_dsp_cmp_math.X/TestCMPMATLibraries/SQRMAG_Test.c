/**
;*****************************************************************************
;                                                                            *
;                       Software License Agreement                           *
;*****************************************************************************
;*****************************************************************************
;� [2026] Microchip Technology Inc. and its subsidiaries.                    *
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

#include <stdio.h>
#include <stdlib.h>
#include "../main.h"
#include "arm_math.h"
#include "SQRMAG.h"

#ifdef COMPLEX_MATH_LIB_TEST
void SQRMAG_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** CMPLX MAG SQUARED TEST **************************"RESET_COLOR);
    float cmplx_result[N] = {0};
    printf("\r\n EXECUTING TESTS....");

    ENABLE_PMU;
    arm_cmplx_mag_squared_f32(SQRMAG_src1, cmplx_result, N);
    DISABLE_PMU;

    if (FAIL == floatCompare(0, N, cmplx_result, SQRMAG_er)) {
        printf(RED"\r\n CMPLX MAG SQUARED TEST FAIL."RESET_COLOR);
    } else {
        printf(GREEN"\r\n CMPLX MAG SQUARED TEST PASS."RESET_COLOR);
    }
    PRINT_PMU_COUNT(N);

}

#endif

