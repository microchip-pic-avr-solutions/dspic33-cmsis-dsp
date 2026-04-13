/*
 [2025] Microchip Technology Inc. and its subsidiaries.

    Subject to your compliance with these terms, you may use Microchip 
    software and any derivatives exclusively with Microchip products. 
    You are responsible for complying with 3rd party license terms  
    applicable to your use of 3rd party software (including open source  
    software) that may accompany Microchip software. SOFTWARE IS "AS IS." 
    NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS 
    SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,  
    MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT 
    WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE, 
    INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY 
    KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF 
    MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE 
    FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S 
    TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT 
    EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR 
    THIS SOFTWARE.
*/

// Section: Included Files
#include <xc.h>
#include "traps.h"

#define ERROR_HANDLER __attribute__((weak,interrupt,no_auto_psv))
#define FAILSAFE_STACK_GUARDSIZE 8
#define FAILSAFE_STACK_SIZE 32

static uint16_t TRAPS_error_code = -1;

void __attribute__((weak)) TRAPS_halt_on_error(uint16_t code)
{
    TRAPS_error_code = code;
#ifdef __DEBUG
    __builtin_software_breakpoint();
    while(1)
    {

    }
#else
    __asm__ volatile ("reset");
#endif
}

inline static void use_failsafe_stack(void)
{
    static uint8_t failsafe_stack[FAILSAFE_STACK_SIZE];
    asm volatile (
        "   mov    %[pstack], W15\n"
        :
        : [pstack]"r"(failsafe_stack)
    );
    SPLIM = (uint32_t)(((uint8_t *)failsafe_stack) + sizeof(failsafe_stack) - (uint32_t) FAILSAFE_STACK_GUARDSIZE);
}

void ERROR_HANDLER _AddressErrorTrap(void)
{
    INTCON1bits.ADDRERR = 0;
    TRAPS_halt_on_error(TRAPS_ADDRESS_ERR);
}

void ERROR_HANDLER _GeneralTrap(void)
{
    if(INTCON5bits.DMTE == 1)
    {
      INTCON5bits.DMTE = 0;
      TRAPS_halt_on_error(TRAPS_DMT_ERR);
    }

    if(INTCON5bits.SOFT == 1)
    {
      INTCON5bits.SOFT = 0;
      TRAPS_halt_on_error(TRAPS_GEN_ERR);
    }

    if(INTCON5bits.WDTE == 1)
    {
      INTCON5bits.WDTE = 0;
      TRAPS_halt_on_error(TRAPS_WDT_ERR);
    }

    while(1)
    {
    }
}

void ERROR_HANDLER _MathErrorTrap(void)
{
    INTCON4bits.DIV0ERR = 0;
    TRAPS_halt_on_error(TRAPS_DIV0_ERR);
}

void ERROR_HANDLER _StackErrorTrap(void)
{
    use_failsafe_stack();
    INTCON1bits.STKERR = 0;
    TRAPS_halt_on_error(TRAPS_STACK_ERR);
}

void ERROR_HANDLER _BusErrorTrap(void)
{
    INTCON3bits.DMABET = 0;
    TRAPS_halt_on_error(TRAPS_DMA_BUS_ERR);
}

void ERROR_HANDLER _IllegalInstructionTrap(void)
{
    INTCON1bits.BADOPERR = 0;
    TRAPS_halt_on_error(TRAPS_ILLEGALINSTRUCTION);
}
