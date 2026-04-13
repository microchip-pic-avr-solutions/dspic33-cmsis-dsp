#include <stdio.h>
#include <stdlib.h>
#include "HAMMING.h"
#include "../Include/mchp_math.h"

/*
 * 
 */

#ifdef WINDOW_LIB_TEST
void HAMMING_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** HAMMING TEST **************************"RESET_COLOR);
    float HAMMING_result[128] = {0};
    printf("\r\n EXECUTING TESTS....");
    ENABLE_PMU;
    mchp_hamming_f32(HAMMING_result, 128);
    DISABLE_PMU;
    printf(" COMPLETE...");
    if (FAIL == floatCompare(0, 128, HAMMING_result, HAMMING_er)){
        printf(RED"\r\n HAMMING TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n HAMMING TEST PASS."RESET_COLOR );
    }
    PRINT_PMU_COUNT(128);
}

#endif