/* 
 * File:   MINV_Test.c
 * Q31 Matrix Inverse Test
 *
 * Note: The mchp_mat_inverse_q31 C implementation performs Gauss-Jordan
 * elimination using float arithmetic on the raw q31_t integer values.
 * This means float->int truncation occurs at each step. For the identity
 * matrix input, the inverse should also be the identity matrix.
 */
 
#include <stdio.h>
#include <stdlib.h>
#include "../../main.h"
#include "mchp_math.h"
#include "MINV.h"

#ifdef MATRIX_LIB_TEST
void MINV_Test() {

    printf(CYAN"\r\n\r\n\r\n ************************** MINV Q31 TEST **************************"RESET_COLOR);
    q31_t MINV_result[100] = {0};
    printf("\r\n EXECUTING TESTS....");
    mchp_matrix_instance_q31 matA, matR;
    
    uint16_t numRows = 10;
    uint16_t numCols = 10;

    ENABLE_PMU;
    mchp_mat_init_q31(&matA, numRows, numCols, MINV_src1);
    mchp_mat_init_q31(&matR, numRows, numCols, MINV_result);
    mchp_status status = mchp_mat_inverse_q31(&matA, &matR);
    DISABLE_PMU;
    if (status == MCHP_MATH_SUCCESS) {
        printf(GREEN"\r\n STATUS -> SUCCESS"RESET_COLOR);
        printf("\r\n COMPLETE...");
        if (FAIL == fractCompare(0, 100, (fractional*)MINV_result, (fractional*)MINV_er)){
            printf(RED"\r\n MINV Q31 TEST FAIL."RESET_COLOR );
        }
        else{
            printf(GREEN"\r\n MINV Q31 TEST PASS."RESET_COLOR );
        }
        PRINT_PMU_COUNT(100);
    }
    else if (status == MCHP_MATH_SINGULAR)
    {
        printf(RED"\r\n MINV Q31 TEST FAILED WITH SINGULAR."RESET_COLOR);
    }
    else
    {
        printf(RED"\r\n MINV Q31 TEST FAILED WITH SIZE MISMATCH."RESET_COLOR);
    }
}

#endif
