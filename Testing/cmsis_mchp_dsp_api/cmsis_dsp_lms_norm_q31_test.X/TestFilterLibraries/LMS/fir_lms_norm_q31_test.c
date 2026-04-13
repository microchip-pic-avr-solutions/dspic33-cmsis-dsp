/*
  [2026] Microchip Technology Inc. and its subsidiaries.

    Subject to your compliance with these terms, you may use Microchip 
    software and any derivatives exclusively with Microchip products. 
    You are responsible for complying with 3rd party license terms  
    applicable to your use of 3rd party software (including open source  
    software) that may accompany Microchip software. SOFTWARE IS AS IS. 
    NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS 
    SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,  
    MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT 
    WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE, 
    INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY 
    KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF 
    MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE 
    FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIPS 
    TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT 
    EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR 
    THIS SOFTWARE.
*/

#include <stdio.h>
#include <stdlib.h>
#include "../../main.h"
#include "fir_lms_norm_q31_test.h"
  
#ifdef FILTER_LIB_TEST

q31_t firLmsNormQ31Output[FIR_LMS_NORM_Q31_BLOCK_SIZE];
q31_t firLmsNormQ31Error[FIR_LMS_NORM_Q31_BLOCK_SIZE];
mchp_lms_norm_instance_q31 firLmsNormQ31Inst;

void fir_lms_norm_q31_test() {
    printf(CYAN"\r\n\r\n\r\n ************************** LMS NORM Q31 TEST **************************"RESET_COLOR);

    printf(CYAN"\r\n\r\n LMS NORM Q31 INIT TEST : "RESET_COLOR);
    
    ENABLE_PMU;
    mchp_lms_norm_init_q31(&firLmsNormQ31Inst,FIR_LMS_NORM_Q31_NUM_TAPS,&FIR_LMS_NORM_Q31_COEFF_INITIAL[0],&FIR_LMS_NORM_Q31_STATE[0],FIR_LMS_NORM_Q31_MU,FIR_LMS_NORM_Q31_BLOCK_SIZE,FIR_LMS_NORM_Q31_POSTSHIFT);
    DISABLE_PMU;
    PRINT_PMU_COUNT(1);
    
    printf(CYAN"\r\n\r\n LMS NORM Q31 FILTER TEST : "RESET_COLOR);
    
    ENABLE_PMU
    mchp_lms_norm_q31(&firLmsNormQ31Inst,&FIR_LMS_NORM_Q31_INPUT[0],&FIR_LMS_NORM_Q31_DESIRED[0],&firLmsNormQ31Output[0],&firLmsNormQ31Error[0],FIR_LMS_NORM_Q31_BLOCK_SIZE);
    DISABLE_PMU;
    PRINT_PMU_COUNT(2);
   
    printf(CYAN"\r\n\r\n LMS NORM Q31 OUTPUT COMPARE : "RESET_COLOR);
    if ((FAIL == fractCompare(0, FIR_LMS_NORM_Q31_BLOCK_SIZE,(fractional*)&firLmsNormQ31Output[0],(fractional*)&FIR_LMS_NORM_Q31_OUTPUT_REF[0]))){
        printf(RED"\r\n LMS NORM Q31 OUTPUT TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n LMS NORM Q31 OUTPUT TEST PASS."RESET_COLOR );
    }
    
    printf(CYAN"\r\n\r\n LMS NORM Q31 ERROR COMPARE : "RESET_COLOR);
    if ((FAIL == fractCompare(0, FIR_LMS_NORM_Q31_BLOCK_SIZE,(fractional*)&firLmsNormQ31Error[0],(fractional*)&FIR_LMS_NORM_Q31_ERROR_REF[0]))){
        printf(RED"\r\n LMS NORM Q31 ERROR TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n LMS NORM Q31 ERROR TEST PASS."RESET_COLOR );
    }
    
    printf(CYAN"\r\n\r\n LMS NORM Q31 COEFF COMPARE : "RESET_COLOR);
    if ((FAIL == fractCompare(0, FIR_LMS_NORM_Q31_NUM_TAPS,(fractional*)firLmsNormQ31Inst.pCoeffs,(fractional*)&FIR_LMS_NORM_Q31_COEFF_FINAL_REF[0]))){
        printf(RED"\r\n LMS NORM Q31 COEFF TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n LMS NORM Q31 COEFF TEST PASS."RESET_COLOR );
    }
    
    printf("\r\nCOMPLETE...");
}

#endif
