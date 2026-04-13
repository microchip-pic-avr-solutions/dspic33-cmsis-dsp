#include <stdio.h>
#include <stdlib.h>
#include "BARTLETT_q31.h"

#ifdef WINDOW_LIB_TEST
void BARTLETT_q31_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** BARTLETT Q31 TEST **************************"RESET_COLOR);
    q31_t BARTLETT_result[128] = {0};
    printf("\r\n EXECUTING TESTS....");
    ENABLE_PMU;
    mchp_bartlett_q31(BARTLETT_result, 128);
    DISABLE_PMU;
    printf(" COMPLETE...");
    if (FAIL == fractCompare(0, 128, (fractional*)BARTLETT_result, (fractional*)BARTLETT_Q31_er)){
        printf(RED"\r\n BARTLETT Q31 TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n BARTLETT Q31 TEST PASS."RESET_COLOR );
    }
    PRINT_PMU_COUNT(128);
}

#endif
