#include <stdio.h>
#include <stdlib.h>
#include "VSUB.h"
#include "../Include/mchp_math.h"


#ifdef VECTOR_LIB_TEST_I


void VSUB_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** VSUB Q31 TEST **************************"RESET_COLOR);
    q31_t VSUB_result[150] = {0};
    printf("\r\n EXECUTING TESTS....");
    ENABLE_PMU;
    mchp_sub_q31(VSUB_q31_src1, VSUB_q31_src2, VSUB_result, 150);
    DISABLE_PMU;
    printf(" COMPLETE...");
    if (FAIL == fractCompare(0, 150, (fractional*)VSUB_result, (fractional*)VSUB_q31_er)){
        printf(RED"\r\n VSUB Q31 TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n VSUB Q31 TEST PASS."RESET_COLOR );
    }
    PRINT_PMU_COUNT(150);
}

#endif
