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
#include "MSUB.h"

#ifdef MATRIX_LIB_TEST
void MSUB_Test() {

    printf(CYAN"\r\n\r\n\r\n ************************** MSUB TEST **************************"RESET_COLOR);
    float MSUB_result[150] = {0};
    printf("\r\n EXECUTING TESTS....");
    printf("\r\n Validating results : Tolerance = 0.00100 %%");
    arm_matrix_instance_f32 matA, matB, matR;
    
    uint16_t numRows = 15;
    uint16_t numCols = 10;

    ENABLE_PMU;
    arm_mat_init_f32(&matA, numRows, numCols, MSUB_src1);
    arm_mat_init_f32(&matB, numRows, numCols, MSUB_src2);
    arm_mat_init_f32(&matR, numRows, numCols, MSUB_result);
    arm_status status = arm_mat_sub_f32(&matA, &matB, &matR);
    DISABLE_PMU;
    if (status == ARM_MATH_SUCCESS) {
        printf(GREEN"\r\n STATUS -> SUCCESS"RESET_COLOR);
        printf("\r\n COMPLETE...");
        if (FAIL == floatCompare(0, 150, MSUB_result, MSUB_er)){
            printf(RED"\r\n MSUB TEST FAIL."RESET_COLOR );
        }
        else{
            printf(GREEN"\r\n MSUB TEST PASS."RESET_COLOR );
        }
        PRINT_PMU_COUNT(150);
    }
    else{
        printf(RED"\r\n MSUB TEST FAILED WITH SIZE MISMATCH."RESET_COLOR);
    }
}

#endif
