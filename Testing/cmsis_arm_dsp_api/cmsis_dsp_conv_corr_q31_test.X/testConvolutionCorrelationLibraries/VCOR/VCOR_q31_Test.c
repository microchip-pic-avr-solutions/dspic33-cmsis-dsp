#include <stdio.h>
#include <stdlib.h>
#include "VCOR_q31.h"

#ifdef VECTOR_LIB_TEST_II

void VCOR_q31_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** VCOR Q31 TEST **************************"RESET_COLOR);
    q31_t VCOR_result[150] = {0};
    printf("\r\n EXECUTING TESTS....");
    ENABLE_PMU;
    mchp_correlate_q31(VCOR_Q31_src1, 50, VCOR_Q31_src2, 50, VCOR_result);
    DISABLE_PMU;
    PRINT_PMU_COUNT(99);
    printf(" COMPLETE...");
    if (FAIL == fractCompare(0, 99, (fractional*)VCOR_result, (fractional*)VCOR_Q31_er)){
        printf(RED"\r\n VCOR Q31 TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n VCOR Q31 TEST PASS."RESET_COLOR );
    }
}

#endif
