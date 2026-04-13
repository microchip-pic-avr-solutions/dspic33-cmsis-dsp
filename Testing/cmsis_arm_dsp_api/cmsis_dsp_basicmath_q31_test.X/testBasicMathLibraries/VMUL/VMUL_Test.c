#include <stdio.h>
#include <stdlib.h>
#include "VMUL.h"
#include "../Include/mchp_math.h"


#ifdef VECTOR_LIB_TEST_I


void VMUL_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** VMUL Q31 TEST **************************"RESET_COLOR);
    q31_t VMUL_result[150] = {0};
    printf("\r\n EXECUTING TESTS....");
    ENABLE_PMU;
    mchp_mult_q31(VMUL_q31_src1, VMUL_q31_src2, VMUL_result, 150);
    DISABLE_PMU;
    printf(" COMPLETE...");
    if (FAIL == fractCompare(0, 150, (fractional*)VMUL_result, (fractional*)VMUL_q31_er)){
        printf(RED"\r\n VMUL Q31 TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n VMUL Q31 TEST PASS."RESET_COLOR );
    }
    PRINT_PMU_COUNT(150);
}

#endif
