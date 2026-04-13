#include <stdio.h>
#include <stdlib.h>
#include "HAMMING_q31.h"

#ifdef WINDOW_LIB_TEST
void HAMMING_q31_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** HAMMING Q31 TEST **************************"RESET_COLOR);
    q31_t HAMMING_result[128] = {0};
    printf("\r\n EXECUTING TESTS....");
    ENABLE_PMU;
    mchp_hamming_q31(HAMMING_result, 128);
    DISABLE_PMU;
    printf(" COMPLETE...");
    /* Tolerance 0x200: accounts for float32 cos() implementation difference
     * between dsPIC33AK C library and Python/numpy. Max observed diff ~0x184. */
    if (FAIL == fractCompare(0x200, 128, (fractional*)HAMMING_result, (fractional*)HAMMING_Q31_er)){
        printf(RED"\r\n HAMMING Q31 TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n HAMMING Q31 TEST PASS."RESET_COLOR );
    }
    PRINT_PMU_COUNT(128);
}

#endif
