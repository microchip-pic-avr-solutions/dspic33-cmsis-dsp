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
#include "VMIN_q31.h"

#ifdef STATISTICS_LIB_TEST

void min_q31_test() {
    printf(CYAN"\r\n\r\n MIN Q31 TEST : "RESET_COLOR);
    
    q31_t result;
    uint32_t index;
    
    ENABLE_PMU;
    mchp_min_q31(&VMIN_Q31_INPUT[0], VMIN_Q31_BLOCK_SIZE, &result, &index);
    DISABLE_PMU;
    PRINT_PMU_COUNT(1);
    
    if(result != VMIN_Q31_EXPECTED_VALUE) {
        printf(RED"\r\n MIN Q31 VALUE FAIL: Expected=0x%08X Got=0x%08X"RESET_COLOR, (unsigned int)VMIN_Q31_EXPECTED_VALUE, (unsigned int)result);
    } else if(index != VMIN_Q31_EXPECTED_INDEX) {
        printf(RED"\r\n MIN Q31 INDEX FAIL: Expected=%lu Got=%lu"RESET_COLOR, (unsigned long)VMIN_Q31_EXPECTED_INDEX, (unsigned long)index);
    } else {
        printf(GREEN"\r\n MIN Q31 TEST PASS."RESET_COLOR);
    }
}

#endif
