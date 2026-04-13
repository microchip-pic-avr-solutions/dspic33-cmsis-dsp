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

#ifndef MAIN_H
#define	MAIN_H

#include <builtins.h>
#include <xc.h>

#include "mchp_math.h"
#ifdef	__cplusplus
extern "C" {
#endif
    

#define DATA_SET_I

#define FILTER_LIB_TEST
    
#define FLOATING        -1
#define FRACTIONAL       1
#ifndef DATA_TYPE
#define DATA_TYPE       FRACTIONAL
#endif

#if     DATA_TYPE==FLOATING
typedef double          fractional;
#else
typedef long int        fractional;
#endif 
    
#define RESET_COLOR "\033[0m"
#define RED "\033[1;31m"
#define GREEN "\033[1;32m"
#define YELLOW "\033[1;33m"
#define BLUE "\033[1;34m"
#define MAG "\033[1;35m"
#define CYAN "\033[1;36m"
  
typedef enum{
    FAIL = 0,
    PASS = 1,
}BOOL;

#define COEFFS_PAGE            , 0xFF00

#define ENABLE_PMU         {PMU_Initialize();HPCCONbits.ON = 1;}
#define DISABLE_PMU         {HPCCONbits.ON = 0;}
#define PRINT_PMU_COUNT(N)     {printf(MAG"\r\n N = %d  :: Cycles captured = 0x%08X  \r\n         INSTR_FETCHED  = 0x%08X  \r\n         FPU_WR_STALL   = 0x%08X  \r\n         W_STG_WR_STALL  = 0x%08X\r\n         BRA_MISPREDICT   = 0x%08X  \r\n         A_STG_RD_STALL  = 0x%08X  \r\n         A_STG_STALLED   = 0x%08X  \r\n         PMEM_RD_STALL   = 0x%08X  "RESET_COLOR,(int) N, (unsigned int) HPCCNTL0,(unsigned int) HPCCNTL1,(unsigned int) HPCCNTL2,(unsigned int) HPCCNTL3,(unsigned int) HPCCNTL4,(unsigned int) HPCCNTL5,(unsigned int) HPCCNTL6,(unsigned int) HPCCNTL7);}

void UART_Initialize();
BOOL fractCompare(int tolerance, int numelem, fractional* Observed_result, fractional* Expected_result);
BOOL floatCompare(float tolerance, int numelem, float* Observed_result, float* Expected_result);
uint32_t floatToHex(float floating_Value);
void PMU_Initialize();

#ifdef FILTER_LIB_TEST
    void fir_inter_q31_test();
#endif

#ifdef	__cplusplus
}
#endif

#endif	/* MAIN_H */
