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
#include "fir_lms_f32_test.h"

/*
 * 
 */
    
#ifdef FILTER_LIB_TEST
void lms_f32_test() {
    printf(CYAN"\r\n\r\n\r\n ************************** LMS TEST **************************"RESET_COLOR);

    float32_t firLmsOutput[FIR_LMS_BLOCK_SIZE]; 
    float32_t firLmsError[FIR_LMS_BLOCK_SIZE]; 
    mchp_lms_instance_f32 lmsInst;

    printf(CYAN"\r\n\r\n LMS INIT TEST : "RESET_COLOR);
   
    ENABLE_PMU;
    mchp_lms_init_f32(&lmsInst,FIR_LMS_SIZE,&FIR_LMS_COEFF_INITIAL[0],&FIR_LMS_STATE[0],FIR_LMS_MU,FIR_LMS_BLOCK_SIZE);
    DISABLE_PMU;
    PRINT_PMU_COUNT(1);
    
    printf(CYAN"\r\n\r\n LMS FILTER TEST : "RESET_COLOR);
    PRINT_PMU_COUNT(2);
    ENABLE_PMU
    mchp_lms_f32(&lmsInst,&FIR_LMS_INPUT[0],&FIR_LMS_DESIRED[0],&firLmsOutput[0],&firLmsError[0],FIR_LMS_BLOCK_SIZE);
    DISABLE_PMU;
    if ((FAIL == floatCompare(0.01, FIR_LMS_BLOCK_SIZE,&firLmsOutput[0],&FIR_LMS_OUTPUT_REF[0]))||(FAIL == floatCompare(0.01, FIR_LMS_SIZE, &FIR_LMS_COEFF_INITIAL[0], &FIR_LMS_COEFF_FINAL_REF[0]))){
        printf(RED"\r\n LMS TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n LMS TEST PASS."RESET_COLOR );
    }
    
    
    printf("\r\nCOMPLETE...");
}

#endif