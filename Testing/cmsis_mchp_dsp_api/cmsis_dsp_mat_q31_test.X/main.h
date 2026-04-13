/* 
 * File:   main.h
 * Author: OpenCode
 *
 * Created on March 23, 2026
 * 
 * Q31 Matrix Functions Test Header
 */

#ifndef MAIN_H
#define	MAIN_H

#include <builtins.h>
#include <xc.h>
#include "mchp_math_types.h"

#ifdef	__cplusplus
extern "C" {
#endif
    

//Uncomment DATA_SET_I to execute tests.
#define DATA_SET_I
//#define DATA_SET_II
    
// Uncomment one of the below #defines to execute respective tests.
#define MATRIX_LIB_TEST
    

  
#define FLOATING        -1       /* using floating type */
#define FRACTIONAL       1       /* using fractional type */
#ifndef DATA_TYPE        /* [ */
#define DATA_TYPE       FRACTIONAL              /* default */
#endif  /* ] */

  
#if     DATA_TYPE==FLOATING             /* [ */
typedef double          fractional;
#else   /* ] */
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



#define ENABLE_PMU         {setup_PMU();HPCCONbits.ON = 1;}
#define DISABLE_PMU         {HPCCONbits.ON = 0;}
#define PRINT_PMU_COUNT(N)     {printf(MAG"\r\n N = %d  :: Cycles captured = 0x%08X  \r\n         INSTR_FETCHED  = 0x%08X  \r\n         FPU_WR_STALL   = 0x%08X  \r\n         W_STG_WR_STALL  = 0x%08X\r\n         BRA_MISPREDICT   = 0x%08X  \r\n         A_STG_RD_STALL  = 0x%08X  \r\n         A_STG_STALLED   = 0x%08X  \r\n         PMEM_RD_STALL   = 0x%08X  "RESET_COLOR,(int) N, (unsigned int) HPCCNTL0,(unsigned int) HPCCNTL1,(unsigned int) HPCCNTL2,(unsigned int) HPCCNTL3,(unsigned int) HPCCNTL4,(unsigned int) HPCCNTL5,(unsigned int) HPCCNTL6,(unsigned int) HPCCNTL7);}



void UARTInit();
BOOL fractCompare(int tolerance, int numelem, fractional* Observed_result, fractional* Expected_result);
BOOL floatCompare(float tolerance, int numelem, float* Observed_result, float* Expected_result);
uint32_t floatToHex(float floating_Value);
void setup_PMU();



    
#ifdef MATRIX_LIB_TEST
    void MADD_Test(void);
    void MSUB_Test(void);
    void MMUL_Test(void);
    void MTRP_Test(void);
    void MSCL_Test(void);
    void MINV_Test(void);
#endif
   


#ifdef	__cplusplus
}
#endif

#endif	/* MAIN_H */
