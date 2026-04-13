
#include <stdio.h>
#include <stdlib.h>
#include "VNEG.h"
#include "../Include/mchp_math.h"

#ifdef VECTOR_LIB_TEST_I



void VNEG_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** VNEG Q31 TEST **************************"RESET_COLOR);
    q31_t VNEG_result[150] = {0};
    printf("\r\n EXECUTING TESTS....");
    ENABLE_PMU;
    mchp_negate_q31(VNEG_q31_src1, VNEG_result, 150);
    DISABLE_PMU;
    printf(" COMPLETE...");
    if (FAIL == fractCompare(0, 150, (fractional*)VNEG_result, (fractional*)VNEG_q31_er)){
        printf(RED"\r\n VNEG Q31 TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n VNEG Q31 TEST PASS."RESET_COLOR );
    }
    PRINT_PMU_COUNT(150);
}

#endif
