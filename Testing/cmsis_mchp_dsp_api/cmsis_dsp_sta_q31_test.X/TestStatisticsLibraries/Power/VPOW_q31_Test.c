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
#include "VPOW_q31.h"

#ifdef STATISTICS_LIB_TEST

void power_q31_test() {
    printf(CYAN"\r\n\r\n POWER Q31 TEST : "RESET_COLOR);
    
    q63_t result;
    
    ENABLE_PMU;
    mchp_power_q31(&VPOW_Q31_INPUT[0], VPOW_Q31_BLOCK_SIZE, &result);
    DISABLE_PMU;
    PRINT_PMU_COUNT(1);
    
    if(result != VPOW_Q31_EXPECTED_VALUE) {
        printf(RED"\r\n POWER Q31 FAIL: Expected=0x%016llX Got=0x%016llX"RESET_COLOR, (unsigned long long)VPOW_Q31_EXPECTED_VALUE, (unsigned long long)result);
    } else {
        printf(GREEN"\r\n POWER Q31 TEST PASS."RESET_COLOR);
    }
}

#endif
