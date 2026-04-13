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

#include <xc.h>


#define UART_BAUD             ((unsigned long)115200UL) // UART baud rate
#ifdef MIPS_200
#define FCY                   ((unsigned long)200000000UL) // FCY frequency in Hz
#else
#define FCY                   ((unsigned long)8000000UL) // FCY frequency in Hz
#endif


void UART_Initialize()
{
unsigned long brg;

#if defined __dsPIC33AK128MC106__
    ANSELD = 0;
    TRISDbits.TRISD1 = 0U;
    LATDbits.LATD1 = 1;
    _RP50R = _RPOUT_U1TX; // RP4/RA3
#elif defined __dsPIC33AK512MPS512__
    ANSELH = 0;
    TRISHbits.TRISH1 = 0U;
    LATHbits.LATH1 = 1;
    _RP114R = _RPOUT_U1TX; 
    
#endif
        
    brg = (((FCY/8 + UART_BAUD/2) / UART_BAUD) - 1);
    U1BRG = (unsigned short)brg;    

    U1CON = 0;
    U1STAT = 0;
    U1CONbits.BRGS = 1;   
    U1CONbits.TXEN = 1;
    U1CONbits.ON = 1;   
}

unsigned char UARTIsCharReady()
{
	return (U1STATbits.RXBE == 0);	
}

void UARTWrite(unsigned char txData){
    while(U1STATbits.TXBE == 0);
    U1TXB = (unsigned long)txData;
}

unsigned char UARTRead(){
	while(U1STATbits.RXBE != 0);	
    return U1RXB;
}

int __attribute__((__section__(".libc.write"))) write(int handle, void *buffer, unsigned int len){
    unsigned char *pData = (unsigned char*)buffer;
    unsigned short count;
    for(count=0; count<len; count++)
    {
        UARTWrite(*pData++);
    }
    
    return count;
}

