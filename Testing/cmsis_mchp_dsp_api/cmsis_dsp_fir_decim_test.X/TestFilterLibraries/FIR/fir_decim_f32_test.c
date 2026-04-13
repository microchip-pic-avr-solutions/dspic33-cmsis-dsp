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
#include "fir_decim_f32_test.h"
  
#ifdef FILTER_LIB_TEST

float32_t firDecimOutput[FIR_DECIM_BLOCK_SIZE/FIR_DECIM_RATE]; 
mchp_fir_decimate_instance_f32 firDecimInst;
mchp_status initDecimStatus;

void fir_decim_f32_test() {
    printf(CYAN"\r\n\r\n\r\n ************************** FIR DECIMATE TEST **************************"RESET_COLOR);


    printf(CYAN"\r\n\r\n FIR DECIMATE ERROR INIT TEST : "RESET_COLOR);
    
    ENABLE_PMU;
    initDecimStatus = mchp_fir_decimate_init_f32(&firDecimInst,FIR_DECIM_NUMTAPS_SIZE,FIR_DECIM_RATE,&FIR_DECIM_COEFF[0],&FIR_DECIM_STATE[0],FIR_DECIM_BLOCK_SIZE+1);
    DISABLE_PMU;
    PRINT_PMU_COUNT(1);
    if(initDecimStatus == MCHP_MATH_LENGTH_ERROR)
    {
        printf(GREEN"\r\n FIR DECIMATE ERROR INIT TEST PASS.\r\n"RESET_COLOR );
    }
    else
    {
        printf(RED"\r\n FIR DECIMATE ERROR INIT TEST FAIL.\r\n"RESET_COLOR );
    }
    
    
    printf(CYAN"\r\n\r\n FIR DECIMATE INIT TEST : "RESET_COLOR);
    
    ENABLE_PMU;
    initDecimStatus = mchp_fir_decimate_init_f32(&firDecimInst,FIR_DECIM_NUMTAPS_SIZE,FIR_DECIM_RATE,&FIR_DECIM_COEFF[0],&FIR_DECIM_STATE[0],FIR_DECIM_BLOCK_SIZE);
    DISABLE_PMU;
    PRINT_PMU_COUNT(2);
    
    printf(CYAN"\r\n\r\n FIR DECIMATE FILTER TEST : "RESET_COLOR);
    
    ENABLE_PMU
    mchp_fir_decimate_f32(&firDecimInst,&FIR_DECIM_INPUT[0],&firDecimOutput[0],FIR_DECIM_BLOCK_SIZE);
    DISABLE_PMU;
    PRINT_PMU_COUNT(3);
   
    if ((FAIL == floatCompare(0.01, FIR_DECIM_BLOCK_SIZE/FIR_DECIM_RATE,&firDecimOutput[0],&FIR_DECIM_OUTPUT[0]))){
        printf(RED"\r\n FIR DECIMATE TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n FIR DECIMATE TEST PASS."RESET_COLOR );
    }
    
    
    printf("\r\nCOMPLETE...");
}

#endif