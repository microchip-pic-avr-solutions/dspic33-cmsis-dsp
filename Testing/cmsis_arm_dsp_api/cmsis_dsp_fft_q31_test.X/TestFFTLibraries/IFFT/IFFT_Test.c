/*
 * File:   IFFT_Test.c
 *
 * Q31 complex IFFT (inverse) test.
 */

#include <stdio.h>
#include <stdlib.h>
#include "IFFT.h"
#include "../Include/mchp_math_types.h"
#include "../Include/dsp/transform_functions.h"

#ifdef TRANSFORM_LIB_TEST

mchp_cfft_instance_q31 S1;

void IFFT_Test() {
    mchp_status status;
    printf(CYAN"\r\n\r\n\r\n ************************** CIFFT Q31 TEST **************************"RESET_COLOR);
    printf("\r\n EXECUTING TESTS....");

    ENABLE_PMU;
    status = mchp_cfft_init_q31(&S1, IFFTLEN);
    DISABLE_PMU;
    PRINT_PMU_COUNT((1<<N_IFFT));
    if (status != MCHP_MATH_SUCCESS) {
        printf(RED"\r\n CIFFT Q31 INIT FAILED."RESET_COLOR );
        while (1) { /* error trap */ }
    }
    printf("COMPLETE...");
    printf("\r\n PERFORMING CIFFT Q31....");

    ENABLE_PMU;
    mchp_cfft_q31(&S1, (q31_t*)IFFT_src1, 1, 1);
    DISABLE_PMU;

    printf(" COMPLETE...");
    if (FAIL == fractCompare(0, (1 << (N_IFFT+1)), (fractional*)IFFT_src1, (fractional*)IFFT_er)){
        printf(RED"\r\n CIFFT Q31 TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n CIFFT Q31 TEST PASS."RESET_COLOR );
    }
    PRINT_PMU_COUNT((1<<N_IFFT));
}

#endif
