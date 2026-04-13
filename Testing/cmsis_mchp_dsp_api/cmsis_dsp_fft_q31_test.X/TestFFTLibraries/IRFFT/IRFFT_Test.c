/*
 * File:   IRFFT_Test.c
 *
 * Q31 real IFFT (inverse) test.
 */

#include <stdio.h>
#include <stdlib.h>
#include "IRFFT.h"
#include "../Include/mchp_math_types.h"
#include "../Include/dsp/transform_functions.h"

#ifdef TRANSFORM_LIB_TEST

mchp_rfft_instance_q31 S3;
mchp_cfft_instance_q31 S3_cfft;  /* internal CFFT instance for IRFFT */

q31_t __attribute__((space(xmemory))) IRFFT_result[1<<(N_IRFFT+1)] = {0};

void IRFFT_Test() {
    mchp_status status;
    printf(CYAN"\r\n\r\n\r\n ************************** IRFFT Q31 TEST **************************"RESET_COLOR);
    printf("\r\n EXECUTING TESTS....");

    /* Initialize the internal CFFT instance (N/2 = 64) first */
    status = mchp_cfft_init_q31(&S3_cfft, IRFFTLEN / 2);
    if (status != MCHP_MATH_SUCCESS) {
        S3_cfft.fftLen = IRFFTLEN / 2;
        S3_cfft.pTwiddle = 0;
    }
    S3.pCfft = &S3_cfft;

    ENABLE_PMU;
    status = mchp_rfft_init_q31(&S3, IRFFTLEN, 1, 1);  /* ifftFlag=1 (inverse), bitRev=1 */
    DISABLE_PMU;
    PRINT_PMU_COUNT((1<<N_IRFFT));
    if (status != MCHP_MATH_SUCCESS) {
        printf(RED"\r\n IRFFT Q31 INIT FAILED."RESET_COLOR );
        while (1) { /* error trap */ }
    }
    S3_cfft.pTwiddle = S3.pTwiddle;

    printf("COMPLETE...");
    printf("\r\n PERFORMING IRFFT Q31....");

    ENABLE_PMU;
    mchp_rfft_q31(&S3, (q31_t*)IRFFT_src1, (q31_t*)IRFFT_result);
    DISABLE_PMU;

    printf(" COMPLETE...");
    /* IRFFT output: N real values */
    if (FAIL == fractCompare(0, (1 << N_IRFFT), (fractional*)IRFFT_result, (fractional*)IRFFT_er)){
        printf(RED"\r\n IRFFT Q31 TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n IRFFT Q31 TEST PASS."RESET_COLOR );
    }
    PRINT_PMU_COUNT((1<<N_IRFFT));
}

#endif
