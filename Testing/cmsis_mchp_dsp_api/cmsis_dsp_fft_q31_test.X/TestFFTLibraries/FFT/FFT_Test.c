/*
 * File:   FFT_Test.c
 *
 * Q31 complex FFT (forward) test.
 */

#include <stdio.h>
#include <stdlib.h>
#include "FFT.h"
#include "../Include/mchp_math.h"

#ifdef TRANSFORM_LIB_TEST

mchp_cfft_instance_q31 S;

void FFT_Test() {
    mchp_status status;
    printf(CYAN"\r\n\r\n\r\n ************************** CFFT Q31 TEST **************************"RESET_COLOR);
    printf("\r\n EXECUTING TESTS....");

    ENABLE_PMU;
    status = mchp_cfft_init_q31(&S, FFTLEN);
    DISABLE_PMU;
    PRINT_PMU_COUNT((1<<N));
    if (status != MCHP_MATH_SUCCESS) {
        printf(RED"\r\n CFFT Q31 INIT FAILED."RESET_COLOR );
        while (1) { /* error trap */ }
    }
    printf("COMPLETE...");

    /* Struct check */
    printf("\r\nS.fftLen=%lu, S.pTwiddle=0x%08lX",
           (unsigned long)S.fftLen, (unsigned long)S.pTwiddle);

    /* ---- TEST A: Call with bitReverseFlag=1 (normal) ---- */
    printf("\r\n PERFORMING CFFT Q31 (bitRev=1)....");

    ENABLE_PMU;
    mchp_cfft_q31(&S, (q31_t*)FFT_src1, 0, 1);
    DISABLE_PMU;

    printf(" COMPLETE...");

    if (FAIL == fractCompare(0, (1 << (N+1)), (fractional*)FFT_src1, (fractional*)FFT_er)){
        printf(RED"\r\n CFFT Q31 TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n CFFT Q31 TEST PASS."RESET_COLOR );
    }

    /* Bit-reversal uses pure software implementation (XBREV movr.l
     * does not work on dsPIC33AK for Q31). */
    PRINT_PMU_COUNT((1<<N));
}

#endif
