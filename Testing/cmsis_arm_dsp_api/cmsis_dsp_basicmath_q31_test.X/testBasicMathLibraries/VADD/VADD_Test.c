#include <stdio.h>
#include <stdlib.h>
#include "VADD.h"
#include "../Include/mchp_math.h"


/*
 * Q31 Vector Addition Test
 */

#ifdef VECTOR_LIB_TEST_I
void VADD_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** VADD Q31 TEST **************************"RESET_COLOR);
    q31_t VADD_result[150] = {0};
    printf("\r\n EXECUTING TESTS....");
    ENABLE_PMU;
    mchp_add_q31(VADD_q31_src1, VADD_q31_src2, VADD_result, 150);
    DISABLE_PMU;
    printf(" COMPLETE...");
    if (FAIL == fractCompare(0, 150, (fractional*)VADD_result, (fractional*)VADD_q31_er)){
        printf(RED"\r\n VADD Q31 TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n VADD Q31 TEST PASS."RESET_COLOR );
    }
    PRINT_PMU_COUNT(150);
}

#endif
