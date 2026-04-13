/* 
 * File:   FFT_Test.c
 * Author: I66951
 *
 * Created on June 5, 2023, 3:14 PM
 */

#include <stdio.h>
#include <stdlib.h>
#include "FFT.h"
#include "../Include/mchp_math.h"
/*
 * 
 */

#ifdef TRANSFORM_LIB_TEST

 mchp_cfft_instance_f32 S;

void FFT_Test() {
    mchp_status status;
    printf(CYAN"\r\n\r\n\r\n ************************** CFFT TEST **************************"RESET_COLOR);
    printf("\r\n EXECUTING TESTS....");

    ENABLE_PMU;    
    status = mchp_cfft_init_f32(&S, FFTLEN);
    DISABLE_PMU;
    PRINT_PMU_COUNT((1<<N));
    if (status != MCHP_MATH_SUCCESS) {
        printf(RED"\r\n CFFT INIT TEST FAILED."RESET_COLOR );
        // init failed - likely twiddle/bitrev tables not present or unsupported FFTLEN
        //printf("FFT init failed: %d\n", status);
        while (1) { /* error trap */ }
    }
    printf("COMPLETE...");
    printf("\r\n PERFORMING CFFT....");
    
    ENABLE_PMU; 
    mchp_cfft_f32(&S, (float32_t*)FFT_src1,0,1);
    DISABLE_PMU;
    
    printf(" COMPLETE...");
    if (FAIL == floatCompare(0.05, (1 << (N+1)), FFT_src1, FFT_er)){
        printf(RED"\r\n CFFT TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n CFFT TEST PASS."RESET_COLOR );
    }
    PRINT_PMU_COUNT((1<<N));
}

#endif

