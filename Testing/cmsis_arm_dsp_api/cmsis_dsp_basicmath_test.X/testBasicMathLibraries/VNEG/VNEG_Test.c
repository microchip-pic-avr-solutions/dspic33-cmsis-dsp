
#include <stdio.h>
#include <stdlib.h>
#include "VNEG.h"
#include "../Include/arm_math.h"

#ifdef VECTOR_LIB_TEST_I



void VNEG_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** VNEG TEST **************************"RESET_COLOR);
    float VNEG_result[150] = {0};
    printf("\r\n EXECUTING TESTS....");
    ENABLE_PMU;
    arm_negate_f32(VNEG_src1, VNEG_result, 150);
    DISABLE_PMU;
    printf(" COMPLETE...");
    if (FAIL == floatCompare(0, 150, VNEG_result, VNEG_er)){
        printf(RED"\r\n VNEG TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n VNEG TEST PASS."RESET_COLOR );
    }
    PRINT_PMU_COUNT(150);
}

#endif