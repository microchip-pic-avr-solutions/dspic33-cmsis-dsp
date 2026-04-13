#include <stdio.h>
#include <stdlib.h>
#include "VDOT.h"
#include "../Include/mchp_math.h"

#ifdef VECTOR_LIB_TEST_I


void VDOT_Test() {
    printf(CYAN"\r\n\r\n\r\n ************************** DOT PRODUCT Q31 TEST **************************"RESET_COLOR);
    /*
     * The assembly stores a full 64-bit q63_t result (lower 64 bits of
     * the 72-bit accumulator, extracted via slac.l/sac.l with SATDW off).
     */
    q63_t VDOT_result[16] = {0};
    BOOL FailureFlag = PASS;
    printf("\r\n EXECUTING TESTS....");
    for (int index = 0; index < 15; index++){
        q31_t* lsrc1_ptr = (VDOT_q31_src1 + index*10);
        q31_t* lsrc2_ptr = (VDOT_q31_src2 + index*10);
        ENABLE_PMU;
        mchp_dot_prod_q31(lsrc1_ptr, lsrc2_ptr, 10, &VDOT_result[index]);
        DISABLE_PMU;
        PRINT_PMU_COUNT(10);
    }    
    printf(" COMPLETE...");
    /* Compare 64-bit results */
    for (int index = 0; index < 15; index++){
        if (VDOT_result[index] != VDOT_q31_er[index]){
            printf(RED"\r\n index = %d :: Expected = 0x%08X%08X :: Observed = 0x%08X%08X"RESET_COLOR,
                   index,
                   (unsigned int)(VDOT_q31_er[index] >> 32),
                   (unsigned int)(VDOT_q31_er[index] & 0xFFFFFFFF),
                   (unsigned int)(VDOT_result[index] >> 32),
                   (unsigned int)(VDOT_result[index] & 0xFFFFFFFF));
            FailureFlag = FAIL;
        }
    }
    if (FAIL == FailureFlag){
        printf(RED"\r\n VDOT Q31 TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n VDOT Q31 TEST PASS."RESET_COLOR );
    }
}

#endif
