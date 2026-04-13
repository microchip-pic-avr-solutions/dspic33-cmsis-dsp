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
#include "pid_f32_test.h"
 
#ifdef CONTROL_LIB_TEST

void pid_f32_test() {
printf(CYAN"\r\n\r\n\r\n ************************** PID TEST **************************"RESET_COLOR);
    BOOL flag = PASS;
    mchp_pid_instance_f32 pidInst[BLOCK_SIZE];
    float32_t pidOut;
    printf(CYAN"\r\n\r\n PID INIT TEST : "RESET_COLOR);
    for (int i=0; i<BLOCK_SIZE ;i++){
        pidInst[i].Kp = PID_KP[i];
        pidInst[i].Ki = PID_KI[i];
        pidInst[i].Kd = PID_KD[i];
        if(i==(BLOCK_SIZE-1))
        {
            ENABLE_PMU;
        }
        mchp_pid_init_f32(&pidInst[i],0);
        if(i==(BLOCK_SIZE-1))
        {
            DISABLE_PMU;
        }
        if ((FAIL == floatCompare(0, 1, &pidInst[i].A0, &PID_A0[i]))||
            (FAIL == floatCompare(0, 1, &pidInst[i].A1, &PID_A1[i]))||
            (FAIL == floatCompare(0, 1, &pidInst[i].A2, &PID_A2[i])))
        {
            flag = FAIL;
        }
    }
    if(flag == PASS)
    {
        printf(GREEN"\r\n PID INIT TEST PASS."RESET_COLOR );
    }
    else
    {
        printf(RED"\r\n PID INIT TEST FAIL."RESET_COLOR );
    }
    PRINT_PMU_COUNT(1);
    
    printf(CYAN"\r\n\r\n PID RUN TEST : "RESET_COLOR);
    
    mchp_pid_init_f32(&pidInst[0],1);
    for (int i=0; i<BLOCK_SIZE ;i++)
    {
        if(i==(BLOCK_SIZE-1))
        {
            ENABLE_PMU;
        }
        pidOut = mchp_pid_f32(&pidInst[0],PID_INPUT[i]);
        if(i==(BLOCK_SIZE-1))
        {
            DISABLE_PMU;
        }
        if (FAIL == floatCompare(0, 1, &pidOut, &PID_OUTPUT[i]))
        {
            flag = FAIL;
        }
    }
    if(flag == PASS)
    {
        printf(GREEN"\r\n PID TEST PASS."RESET_COLOR );
    }
    else
    {
        printf(RED"\r\n PID TEST FAIL."RESET_COLOR );
    }
    PRINT_PMU_COUNT(2);
    
    printf(CYAN"\r\n\r\n PID RESET TEST : "RESET_COLOR);
    float32_t zero = 0.0f;
    ENABLE_PMU;
    mchp_pid_reset_f32(&pidInst[0]);
    DISABLE_PMU;
    PRINT_PMU_COUNT(3);
    if ((FAIL == floatCompare(0, 1, &pidInst[0].state[0], &zero))||
            (FAIL == floatCompare(0, 1, &pidInst[0].state[1], &zero))||
            (FAIL == floatCompare(0, 1, &pidInst[0].state[2], &zero)))
    {
        printf(RED"\r\n PID TEST FAIL."RESET_COLOR );
    }
    else
    {
        printf(GREEN"\r\n PID TEST PASS."RESET_COLOR );
    }
    printf("\r\nCOMPLETE...");
}

#endif