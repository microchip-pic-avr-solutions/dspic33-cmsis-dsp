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
#include "mchp_math.h"
#include "VPOW.h"

#ifdef STATISTICS_LIB_TEST

void VPOW_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** VPOW TEST **************************"RESET_COLOR);
    float VPOW_result[15] = {0};
    printf("\r\n EXECUTING TESTS....");
    for (int index = 0; index < 15; index++){
        float* lsrc1_ptr = (VPOW_src1 + index*10);
        ENABLE_PMU;
        mchp_power_f32(lsrc1_ptr, 10, &VPOW_result[index]);
        DISABLE_PMU;
    }    
    PRINT_PMU_COUNT(10);
    printf("\r\n COMPLETE...");
    if (FAIL == floatCompare(0, 15, VPOW_result, VPOW_er)){
        printf(RED"\r\n VPOW TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n VPOW TEST PASS."RESET_COLOR );
    }
}

#endif