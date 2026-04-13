#include <stdio.h>
#include <stdlib.h>
#include "VSUB.h"
#include "../Include/arm_math.h"


#ifdef VECTOR_LIB_TEST_I


void VSUB_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** VSUB TEST **************************"RESET_COLOR);
    float VSUB_result[150] = {0};
    printf("\r\n EXECUTING TESTS....");
    ENABLE_PMU;
    arm_sub_f32(VSUB_src1, VSUB_src2, VSUB_result,150);
    DISABLE_PMU;
    printf(" COMPLETE...");
    if (FAIL == floatCompare(0, 150, VSUB_result, VSUB_er)){
        printf(RED"\r\n VSUB TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n VSUB TEST PASS."RESET_COLOR );
    }
    PRINT_PMU_COUNT(150);
}

#endif