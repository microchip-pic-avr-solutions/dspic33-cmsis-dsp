#include <stdio.h>
#include <stdlib.h>
#include "VCON_q31.h"

#ifdef VECTOR_LIB_TEST_II

void VCON_q31_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** Vector Convolution Q31 test **************************"RESET_COLOR);
    q31_t VCON_result[150] = {0};
    printf("\r\n EXECUTING TESTS....");
    ENABLE_PMU;
    mchp_conv_q31(VCON_Q31_src1, 50, VCON_Q31_src2, 50, VCON_result);
    DISABLE_PMU;
    PRINT_PMU_COUNT(99);
    printf("\r\n\r\n");
    if (FAIL == fractCompare(0, 99, (fractional*)VCON_result, (fractional*)VCON_Q31_er)){
        printf(RED"\r\n VCON Q31 TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n VCON Q31 TEST PASS."RESET_COLOR );
    }
}

#endif
