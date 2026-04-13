/* 
 * File:   MTRP_Test.c
 * Q31 Matrix Transpose Test
 */
 
#include <stdio.h>
#include <stdlib.h>
#include "../../main.h"
#include "mchp_math.h"
#include "MTRP.h"

#ifdef MATRIX_LIB_TEST
void MTRP_Test() {

    printf(CYAN"\r\n\r\n\r\n ************************** MTRP Q31 TEST **************************"RESET_COLOR);
    q31_t MTRP_result[150] = {0};
    printf("\r\n EXECUTING TESTS....");
    mchp_matrix_instance_q31 matA, matR;
  
    uint16_t numRows = 15;
    uint16_t numCols = 10;
    ENABLE_PMU;
    mchp_mat_init_q31(&matA, numRows, numCols, MTRP_src1);
    mchp_mat_init_q31(&matR, numCols, numRows, MTRP_result);

    mchp_status status = mchp_mat_trans_q31(&matA, &matR);
    DISABLE_PMU;
    if (status == MCHP_MATH_SUCCESS) {
        printf(GREEN"\r\n STATUS -> SUCCESS"RESET_COLOR);
        printf("\r\n COMPLETE...");
        if (FAIL == fractCompare(0, 150, (fractional*)MTRP_result, (fractional*)MTRP_er)){
            printf(RED"\r\n MTRP Q31 TEST FAIL."RESET_COLOR );
        }
        else{
            printf(GREEN"\r\n MTRP Q31 TEST PASS."RESET_COLOR );
        }
        PRINT_PMU_COUNT(150);
    }
    else{
        printf(RED"\r\n MTRP Q31 TEST FAILED WITH SIZE MISMATCH."RESET_COLOR);
    }
}

#endif
