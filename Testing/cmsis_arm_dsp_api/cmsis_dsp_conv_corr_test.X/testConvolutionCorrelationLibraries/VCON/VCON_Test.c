
#include <stdio.h>
#include <stdlib.h>
#include "../Include/arm_math.h"
#include "VCON.h"



#ifdef VECTOR_LIB_TEST_II




void VCON_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** Vector Convolution test **************************"RESET_COLOR);
    float VCON_result[150] = {0};
    float *TempResults = VCON_result+99;
    float *TempSrc1 = VCON_src1+50;
    float *TempSrc2 = VCON_src2+50;
    printf("\r\n EXECUTING TESTS....");
    ENABLE_PMU;
    arm_conv_f32(VCON_src1, 50, VCON_src2, 50, VCON_result);
    DISABLE_PMU;
    PRINT_PMU_COUNT(99);

    ENABLE_PMU;
    arm_conv_f32(TempSrc1, 25, TempSrc2, 10, TempResults);
    DISABLE_PMU;
    PRINT_PMU_COUNT(34);
    printf("\r\n\r\n");
    if (FAIL == floatCompare(0.009, 133, VCON_result, VCON_er)){
        printf(RED"\r\n VCON TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n VCON TEST PASS."RESET_COLOR );
    }
}




#endif
