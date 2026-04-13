/* 
 * File:   MMUL_Test.c
 * Q31 Matrix Multiplication Test
 */

#include <stdio.h>
#include <stdlib.h>
#include "../../main.h"
#include "mchp_math.h"
#include "MMUL.h"

#ifdef MATRIX_LIB_TEST
void MMUL_Test() {

    printf(CYAN"\r\n\r\n\r\n ************************** MMUL Q31 TEST **************************"RESET_COLOR);
    q31_t MMUL_result[100] = {0};
    printf("\r\n EXECUTING TESTS....");
    mchp_matrix_instance_q31 matA, matB, matR;
      
    uint16_t numRows = 10;
    uint16_t numCols = 15;
    ENABLE_PMU;
    mchp_mat_init_q31(&matA, numRows, numCols, MMUL_src1);
    mchp_mat_init_q31(&matB, numCols, numRows, MMUL_src2);
    mchp_mat_init_q31(&matR, numRows, numRows, MMUL_result);
    
    mchp_status status = mchp_mat_mult_q31(&matA, &matB, &matR);
    DISABLE_PMU;
    if (status == MCHP_MATH_SUCCESS) {
        printf(GREEN"\r\n STATUS -> SUCCESS"RESET_COLOR);
        printf("\r\n COMPLETE...");
        if (FAIL == fractCompare(1, 100, (fractional*)MMUL_result, (fractional*)MMUL_er)){
            printf(RED"\r\n MMUL Q31 TEST FAIL."RESET_COLOR );
        }
        else{
            printf(GREEN"\r\n MMUL Q31 TEST PASS."RESET_COLOR );
        }
        PRINT_PMU_COUNT(100);
    }
    else{
        printf(RED"\r\n MMUL Q31 TEST FAILED WITH SIZE MISMATCH."RESET_COLOR);
    }
}

#endif
