/* 
 * File:   MADD_Test.c
 * Q31 Matrix Addition Test
 */

#include <stdio.h>
#include <stdlib.h>
#include "../../main.h"
#include "mchp_math.h"
#include "MADD.h"

#ifdef MATRIX_LIB_TEST
void MADD_Test() {
   
    printf(CYAN"\r\n\r\n\r\n ************************** MADD Q31 TEST **************************"RESET_COLOR);
    q31_t MADD_result[150] = {0};
    printf("\r\n EXECUTING TESTS....");
    mchp_matrix_instance_q31 matA, matB, matR;

    uint16_t numRows = 15;
    uint16_t numCols = 10;
    
    ENABLE_PMU;
    mchp_mat_init_q31(&matA, numRows, numCols, MADD_src1);
    mchp_mat_init_q31(&matB, numRows, numCols, MADD_src2);
    mchp_mat_init_q31(&matR, numRows, numCols, MADD_result);
    mchp_status status = mchp_mat_add_q31(&matA, &matB, &matR);
    DISABLE_PMU;
    if (status == MCHP_MATH_SUCCESS) {
        printf(GREEN"\r\n STATUS -> SUCCESS"RESET_COLOR);
        printf("\r\n COMPLETE...");
        if (FAIL == fractCompare(0, 150, (fractional*)MADD_result, (fractional*)MADD_er)){
            printf(RED"\r\n MADD Q31 TEST FAIL."RESET_COLOR );
        }
        else{
            printf(GREEN"\r\n MADD Q31 TEST PASS."RESET_COLOR );
        }
        PRINT_PMU_COUNT(150);
    }
    else{
        printf(RED"\r\n MADD Q31 TEST FAILED WITH SIZE MISMATCH."RESET_COLOR);
    }
}

#endif
