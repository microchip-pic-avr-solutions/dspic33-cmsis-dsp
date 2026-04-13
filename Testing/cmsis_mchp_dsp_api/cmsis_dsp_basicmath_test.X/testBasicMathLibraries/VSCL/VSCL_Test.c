#include <stdio.h>
#include <stdlib.h>
#include "VSCL.h"
#include "../Include/mchp_math.h"

#ifdef VECTOR_LIB_TEST_I



void VSCL_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** VSCL TEST **************************"RESET_COLOR);
    float VSCL_result[150] = {0};
    printf("\r\n EXECUTING TESTS....");
    for (int index = 0; index < 10; index++){
        float* lresult_ptr = (VSCL_result + index*15);
        float* lsrc_ptr = (VSCL_src1 + index*15);
        ENABLE_PMU;
        mchp_scale_f32(lsrc_ptr, VSCL_src2[index],lresult_ptr, 15 );
        DISABLE_PMU;
        PRINT_PMU_COUNT(15);
    }    
    printf(" COMPLETE...");
    if (FAIL == floatCompare(0, 150, VSCL_result, VSCL_er)){
        printf(RED"\r\n VSCL TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n VSCL TEST PASS."RESET_COLOR );
    }
}

#endif