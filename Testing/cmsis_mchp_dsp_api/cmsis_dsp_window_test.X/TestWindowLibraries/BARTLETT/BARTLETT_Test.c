#include <stdio.h>
#include <stdlib.h>
#include "BARTLETT.h"
#include "../Include/mchp_math.h"

/*
 * 
 */

#ifdef WINDOW_LIB_TEST
void BARTLETT_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** BARTLETT TEST **************************"RESET_COLOR);
    float BARTLETT_result[128] = {0};
    printf("\r\n EXECUTING TESTS....");
    ENABLE_PMU;
    mchp_bartlett_f32(BARTLETT_result, 128);
    DISABLE_PMU;
    printf(" COMPLETE...");
    if (FAIL == floatCompare(0, 128, BARTLETT_result, BARTLETT_er)){
        printf(RED"\r\n BARTLETT TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n BARTLETT TEST PASS."RESET_COLOR );
    }
    PRINT_PMU_COUNT(128);
}

#endif