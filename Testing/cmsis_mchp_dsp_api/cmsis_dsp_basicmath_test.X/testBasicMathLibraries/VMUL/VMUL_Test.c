#include <stdio.h>
#include <stdlib.h>
#include "VMUL.h"
#include "../Include/mchp_math.h"


#ifdef VECTOR_LIB_TEST_I


void VMUL_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** VMUL TEST **************************"RESET_COLOR);
    float VMUL_result[150] = {0};
    printf("\r\n EXECUTING TESTS....");
    ENABLE_PMU;
    mchp_mult_f32(VMUL_src1, VMUL_src2, VMUL_result,150);
    DISABLE_PMU;
    printf(" COMPLETE...");
    if (FAIL == floatCompare(0, 150, VMUL_result, VMUL_er)){
        printf(RED"\r\n VMUL TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n VMUL TEST PASS."RESET_COLOR );
    }
    PRINT_PMU_COUNT(150);
}

#endif