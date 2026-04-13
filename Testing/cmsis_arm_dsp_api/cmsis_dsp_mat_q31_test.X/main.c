/* 
 * File:   main.c
 * Author: OpenCode
 *
 * Created on March 23, 2026
 * 
 * Q31 Matrix Functions Test for CMSIS-DSP MCHP Library
 */
#define FCY 8000000
#include <libpic30.h>


#include <stdio.h>
#include <stdlib.h>
#include "main.h"

int main(int argc, char** argv) {

    UARTInit();

    #ifdef MATRIX_LIB_TEST
    MADD_Test();
    MSUB_Test();
    MMUL_Test();
    MTRP_Test();
    MSCL_Test();
    MINV_Test();
    #endif
    while(1);
    return (EXIT_SUCCESS);
}

void __attribute__((interrupt)) _DefaultInterrupt(){
    printf("\r\n IN DEFAULT INTERRUPT....");
    printf("\r\n PCTRAP = 0x%08lX", PCTRAP);
    printf("\r\n INTCON1 = 0x%08lX", INTCON1);
    printf("\r\n INTCON3 = 0x%08lX", INTCON3);
    printf("\r\n INTCON4 = 0x%08lX", INTCON4);
    printf("\r\n INTCON5 = 0x%08lX", INTCON5);
    while(1);
}
