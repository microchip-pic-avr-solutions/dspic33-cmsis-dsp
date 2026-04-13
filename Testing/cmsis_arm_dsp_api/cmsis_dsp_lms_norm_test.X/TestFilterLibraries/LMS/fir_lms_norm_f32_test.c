/*
© [2025] Microchip Technology Inc. and its subsidiaries.

    Subject to your compliance with these terms, you may use Microchip 
    software and any derivatives exclusively with Microchip products. 
    You are responsible for complying with 3rd party license terms  
    applicable to your use of 3rd party software (including open source  
    software) that may accompany Microchip software. SOFTWARE IS ?AS IS.? 
    NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS 
    SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,  
    MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT 
    WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE, 
    INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY 
    KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF 
    MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE 
    FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIP?S 
    TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT 
    EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR 
    THIS SOFTWARE.
*/

#include <stdio.h>
#include <stdlib.h>
#include "../../main.h"
#include "fir_lms_norm_f32_test.h"

/*
 * 
 */
    
#ifdef FILTER_LIB_TEST
void lms_norm_f32_test() {
    printf(CYAN"\r\n\r\n\r\n ********************** LMS NORM TEST **************************"RESET_COLOR);

    float32_t firLmsNormOutput[FIR_LMS_NORM_BLOCK_SIZE]; 
    float32_t firLmsNormError[FIR_LMS_NORM_BLOCK_SIZE]; 
    float32_t FIR_LMS_NORM_STATE[FIR_LMS_NORM_BLOCK_SIZE + FIR_LMS_NORM_SIZE] = {0};
    arm_lms_norm_instance_f32 lmsNormInst;
    lmsNormInst.energy = 0;
    
    printf(CYAN"\r\n\r\n LMS NORM INIT TEST : "RESET_COLOR);
    ENABLE_PMU;
    arm_lms_norm_init_f32(&lmsNormInst,FIR_LMS_NORM_SIZE,&FIR_LMS_NORM_COEFF_INITIAL[0],&FIR_LMS_NORM_STATE[0],FIR_LMS_NORM_MU,FIR_LMS_NORM_BLOCK_SIZE);
    DISABLE_PMU;
    PRINT_PMU_COUNT(1);
    
    printf(CYAN"\r\n\r\n LMS NORM FILTER TEST : "RESET_COLOR);
    PRINT_PMU_COUNT(2);
    ENABLE_PMU
    arm_lms_norm_f32(&lmsNormInst,&FIR_LMS_NORM_INPUT[0],&FIR_LMS_NORM_DESIRED[0],&firLmsNormOutput[0],&firLmsNormError[0],FIR_LMS_NORM_BLOCK_SIZE);
    DISABLE_PMU;
    
    if ((FAIL == floatCompare(0.01, FIR_LMS_NORM_BLOCK_SIZE,&firLmsNormOutput[0],&FIR_LMS_NORM_OUTPUT_REF[0]))){
        printf(RED"\r\n LMS NORM TEST FAIL."RESET_COLOR );
    }
    else if(FAIL == floatCompare(0.01, FIR_LMS_NORM_SIZE, FIR_LMS_NORM_COEFF_INITIAL, FIR_LMS_NORM_COEFF_FINAL_REF))
    {
        printf(RED"\r\n LMS NORM TEST FAIL - UNEXPETED RETURN COEFFICIENTS"RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n LMS TEST PASS."RESET_COLOR );
    }
    
    
    printf("\r\nCOMPLETE...");
}

#endif