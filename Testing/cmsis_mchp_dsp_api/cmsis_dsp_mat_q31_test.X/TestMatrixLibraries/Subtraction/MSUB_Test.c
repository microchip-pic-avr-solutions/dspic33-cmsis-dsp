/* 
 * File:   MSUB_Test.c
 * Q31 Matrix Subtraction Test
 */
 
#include <stdio.h>
#include <stdlib.h>
#include "../../main.h"
#include "mchp_math.h"
#include "MSUB.h"

#ifdef MATRIX_LIB_TEST
void MSUB_Test() {

    printf(CYAN"\r\n\r\n\r\n ************************** MSUB Q31 TEST **************************"RESET_COLOR);
    q31_t MSUB_result[150] = {0};
    printf("\r\n EXECUTING TESTS....");
    mchp_matrix_instance_q31 matA, matB, matR;
    
    uint16_t numRows = 15;
    uint16_t numCols = 10;

    ENABLE_PMU;
    mchp_mat_init_q31(&matA, numRows, numCols, MSUB_src1);
    mchp_mat_init_q31(&matB, numRows, numCols, MSUB_src2);
    mchp_mat_init_q31(&matR, numRows, numCols, MSUB_result);
    mchp_status status = mchp_mat_sub_q31(&matA, &matB, &matR);
    DISABLE_PMU;
    if (status == MCHP_MATH_SUCCESS) {
        printf(GREEN"\r\n STATUS -> SUCCESS"RESET_COLOR);
        printf("\r\n COMPLETE...");
        if (FAIL == fractCompare(0, 150, (fractional*)MSUB_result, (fractional*)MSUB_er)){
            printf(RED"\r\n MSUB Q31 TEST FAIL."RESET_COLOR );
        }
        else{
            printf(GREEN"\r\n MSUB Q31 TEST PASS."RESET_COLOR );
        }
        PRINT_PMU_COUNT(150);
    }
    else{
        printf(RED"\r\n MSUB Q31 TEST FAILED WITH SIZE MISMATCH."RESET_COLOR);
    }
}

#endif
