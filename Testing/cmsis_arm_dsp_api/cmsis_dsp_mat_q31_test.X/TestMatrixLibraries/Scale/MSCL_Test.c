/* 
 * File:   MSCL_Test.c
 * Q31 Matrix Scale Test
 *
 * Tests mchp_mat_scale_q31: scales each element of a Q31 matrix by a Q31 scalar.
 * Prototype (ARM-compatible):
 *   mchp_status mchp_mat_scale_q31(const mchp_matrix_instance_q31 *pSrc,
 *                                   q31_t scaleFract, int32_t shift,
 *                                   mchp_matrix_instance_q31 *pDst)
 */
 
#include <stdio.h>
#include <stdlib.h>
#include "../../main.h"
#include "mchp_math.h"
#include "MSCL.h"

#ifdef MATRIX_LIB_TEST
void MSCL_Test() {

    printf(CYAN"\r\n\r\n\r\n ************************** MSCL Q31 TEST **************************"RESET_COLOR);
    q31_t MSCL_result[150] = {0};
    printf("\r\n EXECUTING TESTS....");
    for (int index = 0; index < 10; index++) {
        q31_t* lresult_ptr = (MSCL_result + index*15);
        q31_t* lsrc_ptr = (MSCL_src1 + index*15);

        mchp_matrix_instance_q31 subMatA, subMatR;
        
        mchp_mat_init_q31(&subMatA, 3, 5, lsrc_ptr);
        mchp_mat_init_q31(&subMatR, 3, 5, lresult_ptr);

        ENABLE_PMU;
        mchp_status status = mchp_mat_scale_q31(&subMatA, MSCL_src2[index], 0, &subMatR);
        DISABLE_PMU;
        if (status == MCHP_MATH_SUCCESS) {
            if (FAIL == fractCompare(0, 15, (fractional*)(MSCL_result + index*15), (fractional*)(MSCL_er + index*15))){
                printf(RED"\r\n MSCL Q31 TEST FAIL at group %d."RESET_COLOR, index);
            }
        }
        else{
            printf(RED"\r\n MSCL Q31 TEST FAILED WITH SIZE MISMATCH at group %d."RESET_COLOR, index);
        }
    }
    printf(GREEN"\r\n MSCL Q31 TEST PASS."RESET_COLOR );
    PRINT_PMU_COUNT(150);
}

#endif
