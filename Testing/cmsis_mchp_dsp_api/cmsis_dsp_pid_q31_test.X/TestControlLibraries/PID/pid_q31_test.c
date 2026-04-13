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
#include "pid_q31_test.h"
  
#ifdef CONTROL_LIB_TEST

mchp_pid_instance_q31 pidQ31Inst[PID_Q31_BLOCK_SIZE];
q31_t pidQ31Output[PID_Q31_BLOCK_SIZE];

void pid_q31_test() {
    printf(CYAN"\r\n\r\n\r\n ************************** PID Q31 TEST **************************"RESET_COLOR);

    // PID INIT TEST - verify A0, A1, A2 computation
    printf(CYAN"\r\n\r\n PID Q31 INIT TEST : "RESET_COLOR);
    BOOL initPass = PASS;
    
    for(int i = 0; i < PID_Q31_BLOCK_SIZE; i++) {
        pidQ31Inst[i].Kp = PID_Q31_KP[i];
        pidQ31Inst[i].Ki = PID_Q31_KI[i];
        pidQ31Inst[i].Kd = PID_Q31_KD[i];
        
        ENABLE_PMU;
        mchp_pid_init_q31(&pidQ31Inst[i], 1);
        DISABLE_PMU;
        
        if(pidQ31Inst[i].A0 != PID_Q31_A0[i]) {
            printf(RED"\r\n PID[%d] A0 mismatch: Expected=0x%08X Got=0x%08X"RESET_COLOR, i, (unsigned int)PID_Q31_A0[i], (unsigned int)pidQ31Inst[i].A0);
            initPass = FAIL;
        }
        if(pidQ31Inst[i].A1 != PID_Q31_A1[i]) {
            printf(RED"\r\n PID[%d] A1 mismatch: Expected=0x%08X Got=0x%08X"RESET_COLOR, i, (unsigned int)PID_Q31_A1[i], (unsigned int)pidQ31Inst[i].A1);
            initPass = FAIL;
        }
        if(pidQ31Inst[i].A2 != PID_Q31_A2[i]) {
            printf(RED"\r\n PID[%d] A2 mismatch: Expected=0x%08X Got=0x%08X"RESET_COLOR, i, (unsigned int)PID_Q31_A2[i], (unsigned int)pidQ31Inst[i].A2);
            initPass = FAIL;
        }
    }
    
    if(initPass == PASS) {
        printf(GREEN"\r\n PID Q31 INIT TEST PASS."RESET_COLOR);
    } else {
        printf(RED"\r\n PID Q31 INIT TEST FAIL."RESET_COLOR);
    }
    
    // PID RUN TEST - process one sample per instance
    printf(CYAN"\r\n\r\n PID Q31 RUN TEST : "RESET_COLOR);
    
    for(int i = 0; i < PID_Q31_BLOCK_SIZE; i++) {
        ENABLE_PMU;
        pidQ31Output[i] = mchp_pid_q31(&pidQ31Inst[i], PID_Q31_INPUT[i]);
        DISABLE_PMU;
    }
    PRINT_PMU_COUNT(1);
    
    if ((FAIL == fractCompare(0, PID_Q31_BLOCK_SIZE,(fractional*)&pidQ31Output[0],(fractional*)&PID_Q31_OUTPUT[0]))){
        printf(RED"\r\n PID Q31 RUN TEST FAIL."RESET_COLOR);
    }
    else{
        printf(GREEN"\r\n PID Q31 RUN TEST PASS."RESET_COLOR);
    }
    
    // PID RESET TEST
    printf(CYAN"\r\n\r\n PID Q31 RESET TEST : "RESET_COLOR);
    BOOL resetPass = PASS;
    
    for(int i = 0; i < PID_Q31_BLOCK_SIZE; i++) {
        mchp_pid_reset_q31(&pidQ31Inst[i]);
        if(pidQ31Inst[i].state[0] != 0 || pidQ31Inst[i].state[1] != 0 || pidQ31Inst[i].state[2] != 0) {
            printf(RED"\r\n PID[%d] reset failed: state[0]=0x%08X state[1]=0x%08X state[2]=0x%08X"RESET_COLOR,
                i, (unsigned int)pidQ31Inst[i].state[0], (unsigned int)pidQ31Inst[i].state[1], (unsigned int)pidQ31Inst[i].state[2]);
            resetPass = FAIL;
        }
    }
    
    if(resetPass == PASS) {
        printf(GREEN"\r\n PID Q31 RESET TEST PASS."RESET_COLOR);
    } else {
        printf(RED"\r\n PID Q31 RESET TEST FAIL."RESET_COLOR);
    }
    
    printf("\r\nCOMPLETE...");
}

#endif
