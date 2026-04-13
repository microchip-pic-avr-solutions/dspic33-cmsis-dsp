
//#define __dsPIC33AK512MPS512__
#include <xc.h>


#define UART_BAUD             ((unsigned long)115200UL) // UART baud rate
#ifdef MIPS_200
#define FCY                   ((unsigned long)200000000UL) // FCY frequency in Hz
#else
#define FCY                   ((unsigned long)8000000UL) // FCY frequency in Hz
#endif


void UARTInit()
{
unsigned long brg;

    ANSELA = 0;
    RPOR28bits.RP114R = 0x0013UL;  //RH1->UART1:U1TX;
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
