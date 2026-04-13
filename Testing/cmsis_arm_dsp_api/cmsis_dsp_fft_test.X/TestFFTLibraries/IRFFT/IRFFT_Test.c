/* 
 * File:   RFFT_Test.c
 * Author: I66951
 *
 * Created on June 5, 2023, 3:14 PM
 */

#include <stdio.h>
#include <stdlib.h>
//#include "../../dsp_ak_alone.h"
#include "IRFFT.h"
#include "../Include/arm_math.h"
/*
 * 
 */

#ifdef TRANSFORM_LIB_TEST

arm_rfft_fast_instance_f32 S3;

float __attribute__((space(xmemory))) IRFFT_result[1<<(N+1)] = {0};

void IRFFT_Test() {
    arm_status status;
    printf(CYAN"\r\n\r\n\r\n ************************** IRFFT TEST **************************"RESET_COLOR);
    printf("\r\n EXECUTING TESTS....");
    
    ENABLE_PMU;    
    status = arm_rfft_fast_init_f32(&S3, IRFFTLEN);
    DISABLE_PMU;
    PRINT_PMU_COUNT((1<<N));
    if (status != ARM_MATH_SUCCESS) {
        // init failed - likely twiddle/bitrev tables not present or unsupported FFTLEN
        //printf("FFT init failed: %d\n", status);
        while (1) { /* error trap */ }
    }
    printf("COMPLETE...");
    printf("\r\n PERFORMING IRFFT....");
    
    ENABLE_PMU; 
    arm_rfft_fast_f32(&S3,(float32_t*)IRFFT_src1, (float32_t*)IRFFT_result,1);
    DISABLE_PMU;
    
    printf(" COMPLETE...");
    if (FAIL == floatCompare(0.005, (1 << (N)), IRFFT_result, IRFFT_er)){
        printf(RED"\r\n IRFFT TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n IRFFT TEST PASS."RESET_COLOR );
    }
    PRINT_PMU_COUNT((1<<N));

}

#endif

