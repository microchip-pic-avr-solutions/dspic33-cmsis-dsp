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
#include "fir_inter_q31_test.h"
  
#ifdef FILTER_LIB_TEST

q31_t firInterQ31Output[FIR_INTER_Q31_BLOCK_SIZE * FIR_INTER_Q31_RATE]; 
mchp_fir_interpolate_instance_q31 firInterQ31Inst;
mchp_status initInterQ31Status;

void fir_inter_q31_test() {
    printf(CYAN"\r\n\r\n\r\n ************************** FIR INTERPOLATE Q31 TEST **************************"RESET_COLOR);

    printf(CYAN"\r\n\r\n FIR INTERPOLATE Q31 ERROR INIT TEST : "RESET_COLOR);
    
    ENABLE_PMU;
    initInterQ31Status = mchp_fir_interpolate_init_q31(&firInterQ31Inst,FIR_INTER_Q31_RATE,FIR_INTER_Q31_NUMTAPS_SIZE+1,&FIR_INTER_Q31_COEFF[0],&FIR_INTER_Q31_STATE[0],FIR_INTER_Q31_BLOCK_SIZE);
    DISABLE_PMU;
    PRINT_PMU_COUNT(1);
    if(initInterQ31Status == MCHP_MATH_LENGTH_ERROR)
    {
        printf(GREEN"\r\n FIR INTERPOLATE Q31 ERROR INIT TEST PASS.\r\n"RESET_COLOR );
    }
    else
    {
        printf(RED"\r\n FIR INTERPOLATE Q31 ERROR INIT TEST FAIL.\r\n"RESET_COLOR );
    }
    
    printf(CYAN"\r\n\r\n FIR INTERPOLATE Q31 INIT TEST : "RESET_COLOR);
    
    ENABLE_PMU;
    initInterQ31Status = mchp_fir_interpolate_init_q31(&firInterQ31Inst,FIR_INTER_Q31_RATE,FIR_INTER_Q31_NUMTAPS_SIZE,&FIR_INTER_Q31_COEFF[0],&FIR_INTER_Q31_STATE[0],FIR_INTER_Q31_BLOCK_SIZE);
    DISABLE_PMU;
    PRINT_PMU_COUNT(2);
    
    printf(CYAN"\r\n\r\n FIR INTERPOLATE Q31 FILTER TEST : "RESET_COLOR);
    
    ENABLE_PMU
    mchp_fir_interpolate_q31(&firInterQ31Inst,&FIR_INTER_Q31_INPUT[0],&firInterQ31Output[0],FIR_INTER_Q31_BLOCK_SIZE);
    DISABLE_PMU;
    PRINT_PMU_COUNT(3);
   
    if ((FAIL == fractCompare(0, FIR_INTER_Q31_BLOCK_SIZE * FIR_INTER_Q31_RATE,(fractional*)&firInterQ31Output[0],(fractional*)&FIR_INTER_Q31_OUTPUT[0]))){
        printf(RED"\r\n FIR INTERPOLATE Q31 TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n FIR INTERPOLATE Q31 TEST PASS."RESET_COLOR );
    }
    
    printf("\r\nCOMPLETE...");
}

#endif
