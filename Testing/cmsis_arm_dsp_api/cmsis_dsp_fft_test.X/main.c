/* 
 * File:   main.c
 * Author: I69791
 *
 * Created on November 25, 2025, 7:03PM
 */

#include <stdio.h>
#include <stdlib.h>
#include "main.h"

int main(int argc, char** argv) {

    UARTInit();

    #ifdef TRANSFORM_LIB_TEST
    FFT_Test();
    IFFT_Test();
    RFFT_Test();
    IRFFT_Test();
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

