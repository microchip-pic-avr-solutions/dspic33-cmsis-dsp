
#include <stdio.h>
#include <stdlib.h>
#include "../Include/mchp_math.h"
#include "VCOR.h"

#ifdef VECTOR_LIB_TEST_II


void VCOR_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** VCOR TEST **************************"RESET_COLOR);
    float VCOR_result[150] = {0};
    printf("\r\n EXECUTING TESTS....");
    ENABLE_PMU;
    mchp_correlate_f32(VCOR_src1, 50, VCOR_src2, 50, VCOR_result);
    DISABLE_PMU;
    PRINT_PMU_COUNT(99);

    ENABLE_PMU;
    mchp_correlate_f32(VCOR_src1+50, 25,  VCOR_src2+50, 10, VCOR_result+99);
    DISABLE_PMU;
    PRINT_PMU_COUNT(34);
    printf(" COMPLETE...");
    if (FAIL == floatCompare(0.009, 133, VCOR_result, VCOR_er)){
        printf(RED"\r\n VCOR TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n VCOR TEST PASS."RESET_COLOR );
    }
}


#endif
