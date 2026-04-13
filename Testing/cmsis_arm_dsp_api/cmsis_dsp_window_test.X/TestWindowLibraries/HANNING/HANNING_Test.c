#include <stdio.h>
#include <stdlib.h>
#include "HANNING.h"
#include "../Include/arm_math.h"

/*
 * 
 */

#ifdef WINDOW_LIB_TEST
void HANNING_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** HANNING TEST **************************"RESET_COLOR);
    float HANNING_result[128] = {0};
    printf("\r\n EXECUTING TESTS....");
    ENABLE_PMU;
    arm_hanning_f32(HANNING_result, 128);
    DISABLE_PMU;
    printf(" COMPLETE...");
    if (FAIL == floatCompare(0.006, 128, HANNING_result, HANNING_er)){
        printf(RED"\r\n HANNING TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n HANNING TEST PASS."RESET_COLOR );
    }
    PRINT_PMU_COUNT(128);
}

#endif