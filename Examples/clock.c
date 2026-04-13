/**
;*****************************************************************************
;                                                                            *
;                       Software License Agreement                           *
;*****************************************************************************
;*****************************************************************************
;? [2026] Microchip Technology Inc. and its subsidiaries.                    *
;                                                                            *
;   Subject to your compliance with these terms, you may use Microchip       *
;   software and any derivatives exclusively with Microchip products.        *
;   You are responsible for complying with 3rd party license terms            *
;   applicable to your use of 3rd party software (including open source       *
;   software) that may accompany Microchip software. SOFTWARE IS ?AS IS.?     *
;   NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS       *
;   SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,           *
;   MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT         *
;   WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,             *
;   INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY          *
;   KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF          *
;   MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE          *
;   FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIP?S            *
;   TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT            *
;   EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR         *
;   THIS SOFTWARE.                                                            *
;*****************************************************************************
*/

#include <xc.h>


void CLOCK_Initialize(void)
{
    /*  
        System Clock Source                             :  PLL1 VCO Divider output
        System/Generator 1 frequency (Fosc)             :  200 MHz
        
        Clock Generator 2 frequency                     : 8 MHz
        Clock Generator 3 frequency                     : 8 MHz
        
        PLL 1 frequency                                 : 320 MHz
        PLL 1 VCO Out frequency                         : 800 MHz

    */
    
    // NOSC FRC Oscillator; OE enabled; SIDL disabled; ON enabled; BOSC Serial Test Mode clock (PGC); FSCMEN disabled; DIVSWEN disabled; OSWEN disabled; EXTCFSEL disabled; EXTCFEN disabled; FOUTSWEN disabled; RIS disabled; PLLSWEN disabled; 
    PLL1CON = 0x9100UL;
    // POSTDIV2 1x divide; POSTDIV1 5x divide; PLLFBDIV 200; PLLPRE 1; 
    PLL1DIV = 0x100C829UL;
    //Enable PLL Input and Feedback Divider update
    PLL1CONbits.PLLSWEN = 1U;
#ifndef __MPLAB_DEBUGGER_SIMULATOR
    while (PLL1CONbits.PLLSWEN == 1){};
#endif
    PLL1CONbits.FOUTSWEN = 1U;
#ifndef __MPLAB_DEBUGGER_SIMULATOR
    while (PLL1CONbits.FOUTSWEN == 1U){};
#endif
    //enable clock switching
    PLL1CONbits.OSWEN = 1U; 
#ifndef __MPLAB_DEBUGGER_SIMULATOR 
    //wait for switching
    while(PLL1CONbits.OSWEN == 1U){}; 
    //wait for clock to be ready
    while(OSCCTRLbits.PLL1RDY == 0U){};    
#endif
    
    //Configure VCO Divider
    // INTDIV 1; 
    VCO1DIV = 0x10000UL;
    //enable PLL VCO divider
    PLL1CONbits.DIVSWEN = 1U;
#ifndef __MPLAB_DEBUGGER_SIMULATOR     
    //wait for setup complete
    while(PLL1CONbits.DIVSWEN == 1U){}; 
#endif
    //Clearing ON shuts down oscillator when no downstream clkgen or peripheral is requesting the clock
    PLL1CONbits.ON = 0U;
    
    // NOSC PLL1 VCO Divider output; OE enabled; SIDL disabled; ON enabled; BOSC Backup FRC Oscillator; FSCMEN enabled; DIVSWEN disabled; OSWEN disabled; EXTCFSEL External clock fail detection module #1; EXTCFEN disabled; RIS disabled; 
    CLK1CON = 0x129700UL;
    // FRACDIV 0; INTDIV 2; 
    CLK1DIV = 0x20000UL;
    //enable divide factors
    CLK1CONbits.DIVSWEN = 1U; 
    //wait for divide factors to get updated
#ifndef __MPLAB_DEBUGGER_SIMULATOR 
    while(CLK1CONbits.DIVSWEN == 1U){};
#endif
    //enable clock switching
    CLK1CONbits.OSWEN = 1U;
#ifndef __MPLAB_DEBUGGER_SIMULATOR    
    //wait for clock switching complete
    while(CLK1CONbits.OSWEN == 1U){};
#endif
  
}

