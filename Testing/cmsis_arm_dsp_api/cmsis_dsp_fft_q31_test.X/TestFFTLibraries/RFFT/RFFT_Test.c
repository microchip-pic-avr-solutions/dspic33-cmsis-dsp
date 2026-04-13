/*
 * File:   RFFT_Test.c
 *
 * Q31 real FFT (forward) test.
 */

#include <stdio.h>
#include <stdlib.h>
#include "RFFT.h"
#include "../Include/mchp_math_types.h"
#include "../Include/dsp/transform_functions.h"

#ifdef TRANSFORM_LIB_TEST

mchp_rfft_instance_q31 S2;
mchp_cfft_instance_q31 S2_cfft;  /* internal CFFT instance for RFFT */

q31_t __attribute__((space(xmemory))) RFFT_result[1<<(N_RFFT+1)] = {0};

void RFFT_Test() {
    mchp_status status;
    printf(CYAN"\r\n\r\n\r\n ************************** RFFT Q31 TEST **************************"RESET_COLOR);
    printf("\r\n EXECUTING TESTS....");

    /* Initialize the internal CFFT instance (N/2 = 64) first */
    status = mchp_cfft_init_q31(&S2_cfft, RFFTLEN / 2);
    if (status != MCHP_MATH_SUCCESS) {
        /* 64-pt twiddle not available; fall back to manual setup.
         * The assembly loads fftLen from the pointed-to CFFT instance. */
        S2_cfft.fftLen = RFFTLEN / 2;
        S2_cfft.pTwiddle = 0;  /* will be set by rfft init via pTwiddle */
    }
    S2.pCfft = &S2_cfft;

    ENABLE_PMU;
    status = mchp_rfft_init_q31(&S2, RFFTLEN, 0, 1);  /* ifftFlag=0 (forward), bitRev=1 */
    DISABLE_PMU;
    PRINT_PMU_COUNT((1<<N_RFFT));
    if (status != MCHP_MATH_SUCCESS) {
        printf(RED"\r\n RFFT Q31 INIT FAILED."RESET_COLOR );
        while (1) { /* error trap */ }
    }
    /* Point the internal CFFT's twiddle to the RFFT's pTwiddle (same table) */
    S2_cfft.pTwiddle = S2.pTwiddle;

    printf("COMPLETE...");
    printf("\r\n PERFORMING RFFT Q31....");

    ENABLE_PMU;
    mchp_rfft_q31(&S2, (q31_t*)RFFT_src1, (q31_t*)RFFT_result);
    DISABLE_PMU;

    printf(" COMPLETE...");
    /* RFFT output: N/2+1 complex values = N+2 q31_t values = 130 */
    if (FAIL == fractCompare(0, ((1 << N_RFFT) + 2), (fractional*)RFFT_result, (fractional*)RFFT_er)){
        printf(RED"\r\n RFFT Q31 TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n RFFT Q31 TEST PASS."RESET_COLOR );
    }
    PRINT_PMU_COUNT((1<<N_RFFT));
}

#endif
