/* 
 * File:   IFFT_Test.c
 * Author: I66951
 *
 * Created on June 5, 2023, 3:14 PM
 */

#include <stdio.h>
#include <stdlib.h>
//#include "../../dsp_ak_alone.h"
#include "IFFT.h"
#include "../Include/mchp_math_types.h"
#include "../Include/dsp/transform_functions.h"
/*
 * 
 */

#ifdef TRANSFORM_LIB_TEST

 mchp_cfft_instance_f32 S1;

void IFFT_Test() {
    mchp_status status;
    printf(CYAN"\r\n\r\n\r\n ************************** CIFFT TEST **************************"RESET_COLOR);
    printf("\r\n EXECUTING TESTS....");

    ENABLE_PMU;    
    status = mchp_cfft_init_f32(&S1, IFFTLEN);
    DISABLE_PMU;
    PRINT_PMU_COUNT((1<<N));
    if (status != MCHP_MATH_SUCCESS) {
        // init failed - likely twiddle/bitrev tables not present or unsupported FFTLEN
        //printf("FFT init failed: %d\n", status);
        while (1) { /* error trap */ }
    }
    printf("COMPLETE...");
    printf("\r\n PERFORMING CIFFT....");
    
    ENABLE_PMU; 
    mchp_cfft_f32(&S1, (float32_t*)IFFT_src1,1,1);
    DISABLE_PMU;
    
    printf(" COMPLETE...");
    if (FAIL == floatCompare(0.005, (1 << (N+1)), IFFT_src1, IFFT_er)){
        printf(RED"\r\n CIFFT TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n CIFFT TEST PASS."RESET_COLOR );
    }
    PRINT_PMU_COUNT((1<<N));
}

#endif

