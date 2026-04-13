#include <stdio.h>
#include <stdlib.h>
#include "VSCL.h"
#include "../Include/mchp_math.h"

#ifdef VECTOR_LIB_TEST_I



void VSCL_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** VSCL Q31 TEST **************************"RESET_COLOR);
    q31_t VSCL_result[150] = {0};
    printf("\r\n EXECUTING TESTS....");
    for (int index = 0; index < 10; index++){
        q31_t* lresult_ptr = (VSCL_result + index*15);
        q31_t* lsrc_ptr = (VSCL_q31_src1 + index*15);
        ENABLE_PMU;
        mchp_scale_q31(lsrc_ptr, VSCL_q31_scalars[index], 1, lresult_ptr, 15);
        DISABLE_PMU;
        PRINT_PMU_COUNT(15);
    }    
    printf(" COMPLETE...");
    if (FAIL == fractCompare(0, 150, (fractional*)VSCL_result, (fractional*)VSCL_q31_er)){
        printf(RED"\r\n VSCL Q31 TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n VSCL Q31 TEST PASS."RESET_COLOR );
    }
}

#endif
