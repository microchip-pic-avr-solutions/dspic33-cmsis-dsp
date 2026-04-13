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
 
#include <stdio.h>
#include <stdlib.h>
#include "../../main.h"
#include "mchp_math.h"
#include "MSCL.h"

#ifdef MATRIX_LIB_TEST
void MSCL_Test() {

    printf(CYAN"\r\n\r\n\r\n ************************** MSCL TEST **************************"RESET_COLOR);
    float MSCL_result[150] = {0};
    printf("\r\n EXECUTING TESTS....");
    printf("\r\n Validating results : Tolerance = 0.00100 %%");
    for (int index = 0; index < 10; index++) {
        float* lresult_ptr = (MSCL_result + index*15);
        float* lsrc_ptr = (MSCL_src1 + index*15);

        mchp_matrix_instance_f32 subMatA, subMatR;
        
        mchp_mat_init_f32(&subMatA, 3, 5, lsrc_ptr);
        mchp_mat_init_f32(&subMatR, 3, 5, lresult_ptr);

        ENABLE_PMU;
        mchp_status status = mchp_mat_scale_f32(&subMatA, MSCL_src2[index], &subMatR);
        DISABLE_PMU;
        if (status == MCHP_MATH_SUCCESS) {
            if (FAIL == floatCompare(0, 15, MSCL_result, MSCL_er)){
                printf(RED"\r\n MSCL TEST FAIL."RESET_COLOR );
            }
        }
        else{
            printf(RED"\r\n MSCL TEST FAILED WITH SIZE MISMATCH."RESET_COLOR);
        }
    }
    printf(GREEN"\r\n MSCL TEST PASS."RESET_COLOR );
    PRINT_PMU_COUNT(150);
}

#endif
