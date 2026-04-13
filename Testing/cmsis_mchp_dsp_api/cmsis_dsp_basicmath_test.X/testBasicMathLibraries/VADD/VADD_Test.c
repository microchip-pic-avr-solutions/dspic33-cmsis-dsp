#include <stdio.h>
#include <stdlib.h>
#include "VADD.h"
#include "../Include/mchp_math.h"


/*
 * 
 */

#ifdef VECTOR_LIB_TEST_I
void VADD_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** VADD TEST **************************"RESET_COLOR);
    float VADD_result[150] = {0};
    printf("\r\n EXECUTING TESTS....");
    ENABLE_PMU;
    mchp_add_f32(VADD_src1, VADD_src2, VADD_result,150);
    DISABLE_PMU;
    printf(" COMPLETE...");
    if (FAIL == floatCompare(0, 150, VADD_result, VADD_er)){
        printf(RED"\r\n VADD TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n VADD TEST PASS."RESET_COLOR );
    }
    PRINT_PMU_COUNT(150);
}

#endif