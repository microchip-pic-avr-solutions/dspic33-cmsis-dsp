#include <stdio.h>
#include <stdlib.h>
#include "VDOT.h"
#include "../Include/arm_math.h"

#ifdef VECTOR_LIB_TEST_I


void VDOT_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** DOT PRODUCT TEST **************************"RESET_COLOR);
    float VDOT_result[16] = {0};
    printf("\r\n EXECUTING TESTS....");
    for (int index = 0; index < 15; index++){
        float* lsrc1_ptr = (VDOT_src1 + index*10);
        float* lsrc2_ptr = (VDOT_src2 + index*10);
        ENABLE_PMU;
        arm_dot_prod_f32(lsrc1_ptr, lsrc2_ptr, 10,  &VDOT_result[index]);
        DISABLE_PMU;
        PRINT_PMU_COUNT(10);
    }    
    printf(" COMPLETE...");
    if (FAIL == floatCompare(0, 15, VDOT_result, VDOT_er)){
        printf(RED"\r\n VDOT TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n VDOT TEST PASS."RESET_COLOR );
    }
}

#endif