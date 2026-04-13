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
#include "fir_f32_test.h"
 
#ifdef FILTER_LIB_TEST

void fir_f32_test() {
printf(CYAN"\r\n\r\n\r\n ************************** FIR TEST **************************"RESET_COLOR);

    float32_t firOutput[BLOCK_SIZE];
    mchp_fir_instance_f32 firInst;

    printf(CYAN"\r\n\r\n FIR INIT TEST : "RESET_COLOR);
   
    ENABLE_PMU;
    mchp_fir_init_f32(&firInst,NUMTAPS_SIZE,&FIR_COEFF[0],&STATE[0],BLOCK_SIZE);
    DISABLE_PMU;
    PRINT_PMU_COUNT(1);
    
    printf(CYAN"\r\n\r\n FIR FILTER TEST : "RESET_COLOR);
    
    ENABLE_PMU
    mchp_fir_f32(&firInst,&FIR_INPUT[0],&firOutput[0],BLOCK_SIZE);
    DISABLE_PMU;
    PRINT_PMU_COUNT(2);
   
    if ((FAIL == floatCompare(0.01, BLOCK_SIZE,&firOutput[0],&FIR_OUTPUT[0]))){
        printf(RED"\r\n FIR TEST FAIL."RESET_COLOR );
    }
    else{
        printf(GREEN"\r\n FIR TEST PASS."RESET_COLOR );
    }
    
    
    printf("\r\nCOMPLETE...");
}

#endif