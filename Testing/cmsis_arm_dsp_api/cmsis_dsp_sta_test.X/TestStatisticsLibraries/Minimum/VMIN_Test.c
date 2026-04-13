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
#include "../../main.h"
#include "arm_math.h"
#include "VMIN.h"

#ifdef STATISTICS_LIB_TEST

void VMIN_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** VMIN TEST **************************"RESET_COLOR);
    float VMIN_result[15] = {0};
    fractional VMIN_index[15] = {0};
    printf("\r\n EXECUTING TESTS....");
    for (int index = 0; index < 15; index++){
        uint32_t minIndex = 0xFFFF;
        float minValue = 0.0f;
        float* lsrc1_ptr = (VMIN_src1 + index*10);
        ENABLE_PMU;
        arm_min_f32(lsrc1_ptr, 10, &minValue, &minIndex);
        DISABLE_PMU;
        VMIN_result[index] = minValue;
        VMIN_index[index] = minIndex;
    }    
    PRINT_PMU_COUNT(15);
    printf("\r\n COMPLETE...");
    if (FAIL == floatCompare(0, 15, VMIN_result, VMIN_er) || FAIL == fractCompare(0, 15, VMIN_index, VMIN_er_index)){
        printf(RED"\r\n VMIN TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n VMIN TEST PASS."RESET_COLOR );
    }
}

#endif
