//
///* 
// * File:   main.c
// * Author: C52453
// *
// * Created on October 31, 2023, 3:59 PM
// */
//// DSPIC33AKXXXMPSXXX Configuration Bit Settings
//
//// 'C' source line config statements
//
//// FCP
//#pragma config FCP_CP = 0x1              
//#pragma config FCP_CRC = 0x1          
//#pragma config FCP_WPUCA = 0x3
//
//// FICD
//#pragma config FICD_JTAGEN = 0x0     
//#pragma config FICD_NOBTSWP = 0x1       
//
//// FDEVOPT1  
//#pragma config FDEVOPT1_ALTI2C1 = 0x1    
//#pragma config FDEVOPT1_ALTI2C2 = 0x1    
//#pragma config FDEVOPT1_ALTI2C3 = 0x1    
//#pragma config FDEVOPT1_BISTDIS = 0x1    
//#pragma config FDEVOPT1_SPI2MAPDIS = 0x1 
//
//// FWDT
//#pragma config FWDT_WINEN = 0x1         
//#pragma config FWDT_SWDTMPS = 0x1F       
//#pragma config FWDT_RCLKSEL = 0x3   
//#pragma config FWDT_RWDTPS = 0x1F       
//#pragma config FWDT_WDTWIN = 0x3     
//#pragma config FWDT_FWDTEN = 0x0      
//#pragma config FWDT_WDTRSTEN = 0x1     
//
//// FCPBKUP
//#pragma config FCPBKUP_CP = 0x1              
//#pragma config FCPBKUP_CRC = 0x1          
//#pragma config FCPBKUP_WPUCA = 0x3
//
//// FICDBKUP
//#pragma config FICDBKUP_JTAGEN = 0x0     
//#pragma config FICDBKUP_NOBTSWP = 0x1       
//
//// FDEVOPT1BKUP  
//#pragma config FDEVOPT1BKUP_ALTI2C1 = 0x1    
//#pragma config FDEVOPT1BKUP_ALTI2C2 = 0x1    
//#pragma config FDEVOPT1BKUP_ALTI2C3 = 0x1    
//#pragma config FDEVOPT1BKUP_BISTDIS = 0x1    
//#pragma config FDEVOPT1BKUP_SPI2MAPDIS = 0x1 
//
//// FWDTBKUP
//#pragma config FWDTBKUP_WINEN = 0x0         
//#pragma config FWDTBKUP_SWDTMPS = 0x1F       
//#pragma config FWDTBKUP_RCLKSEL = 0x3   
//#pragma config FWDTBKUP_RWDTPS = 0x1F       
//#pragma config FWDTBKUP_WDTWIN = 0x3     
//#pragma config FWDTBKUP_FWDTEN = 0x1      
//#pragma config FWDTBKUP_WDTRSTEN = 0x1     
//
//// FPR0CTRL
//#pragma config FPR0CTRL_RDIS = 0x1       
//#pragma config FPR0CTRL_ERAO = 0x1       
//#pragma config FPR0CTRL_EX = 0x1         
//#pragma config FPR0CTRL_RD = 0x1         
//#pragma config FPR0CTRL_WR = 0x1         
//#pragma config FPR0CTRL_CRC = 0x1       
//#pragma config FPR0CTRL_RTYPE = 0x3      
//#pragma config FPR0CTRL_PSEL = 0x3 
//
//// FPR0ST
//#pragma config PR0ST_START = 0x7FF       
//
//// FPR0END
//#pragma config PR0END_END = 0x7FF         
//
//// FPR1CTRL
//#pragma config FPR1CTRL_RDIS = 0x1       
//#pragma config FPR1CTRL_ERAO = 0x1       
//#pragma config FPR1CTRL_EX = 0x1         
//#pragma config FPR1CTRL_RD = 0x1         
//#pragma config FPR1CTRL_WR = 0x1         
//#pragma config FPR1CTRL_CRC = 0x1       
//#pragma config FPR1CTRL_RTYPE = 0x3      
//#pragma config FPR1CTRL_PSEL = 0x3 
//
//// FPR1ST
//#pragma config PR1ST_START = 0x7FF       
//
//// FPR1END
//#pragma config PR1END_END = 0x7FF         
//
//// FPR2CTRL
//#pragma config FPR2CTRL_RDIS = 0x1       
//#pragma config FPR2CTRL_ERAO = 0x1       
//#pragma config FPR2CTRL_EX = 0x1         
//#pragma config FPR2CTRL_RD = 0x1         
//#pragma config FPR2CTRL_WR = 0x1         
//#pragma config FPR2CTRL_CRC = 0x1       
//#pragma config FPR2CTRL_RTYPE = 0x3      
//#pragma config FPR2CTRL_PSEL = 0x3 
//
//// FPR2ST
//#pragma config PR2ST_START = 0x7FF       
//
//// FPR2END
//#pragma config PR2END_END = 0x7FF          
//
//// FPR3CTRL
//#pragma config FPR3CTRL_RDIS = 0x1       
//#pragma config FPR3CTRL_ERAO = 0x1       
//#pragma config FPR3CTRL_EX = 0x1         
//#pragma config FPR3CTRL_RD = 0x1         
//#pragma config FPR3CTRL_WR = 0x1         
//#pragma config FPR3CTRL_CRC = 0x1       
//#pragma config FPR3CTRL_RTYPE = 0x3      
//#pragma config FPR3CTRL_PSEL = 0x3 
//
//// FPR3ST
//#pragma config PR3ST_START = 0x7FF       
//
//// FPR3END
//#pragma config PR3END_END = 0x7FF         
//
//// FPR4CTRL
//#pragma config FPR4CTRL_RDIS = 0x1       
//#pragma config FPR4CTRL_ERAO = 0x1       
//#pragma config FPR4CTRL_EX = 0x1         
//#pragma config FPR4CTRL_RD = 0x1         
//#pragma config FPR4CTRL_WR = 0x1         
//#pragma config FPR4CTRL_CRC = 0x1       
//#pragma config FPR4CTRL_RTYPE = 0x3      
//#pragma config FPR4CTRL_PSEL = 0x3 
//
//// FPR4ST
//#pragma config PR4ST_START = 0x7FF       
//
//// FPR4END
//#pragma config PR4END_END = 0x7FF       
//
//// FPR5CTRL
//#pragma config FPR5CTRL_RDIS = 0x1       
//#pragma config FPR5CTRL_ERAO = 0x1       
//#pragma config FPR5CTRL_EX = 0x1         
//#pragma config FPR5CTRL_RD = 0x1         
//#pragma config FPR5CTRL_WR = 0x1         
//#pragma config FPR5CTRL_CRC = 0x1       
//#pragma config FPR5CTRL_RTYPE = 0x3      
//#pragma config FPR5CTRL_PSEL = 0x3 
//
//// FPR5ST
//#pragma config PR5ST_START = 0x7FF       
//
//// FPR5END
//#pragma config PR5END_END = 0x7FF          
//
//// FPR6CTRL
//#pragma config FPR6CTRL_RDIS = 0x1       
//#pragma config FPR6CTRL_ERAO = 0x1       
//#pragma config FPR6CTRL_EX = 0x1         
//#pragma config FPR6CTRL_RD = 0x1         
//#pragma config FPR6CTRL_WR = 0x1         
//#pragma config FPR6CTRL_CRC = 0x1       
//#pragma config FPR6CTRL_RTYPE = 0x3      
//#pragma config FPR6CTRL_PSEL = 0x3 
//
//// FPR6ST
//#pragma config PR6ST_START = 0x7FF       
//
//// FPR6END
//#pragma config PR6END_END = 0x7FF        
//
//// FPR7CTRL
//#pragma config FPR7CTRL_RDIS = 0x1       
//#pragma config FPR7CTRL_ERAO = 0x1       
//#pragma config FPR7CTRL_EX = 0x1         
//#pragma config FPR7CTRL_RD = 0x1         
//#pragma config FPR7CTRL_WR = 0x1         
//#pragma config FPR7CTRL_CRC = 0x1       
//#pragma config FPR7CTRL_RTYPE = 0x3      
//#pragma config FPR7CTRL_PSEL = 0x3 
//
//// FPR7ST
//#pragma config PR7ST_START = 0x7FF       
//
//// FPR7END
//#pragma config PR7END_END = 0x7FF          
//
//// FIRT
//#pragma config FIRT_IRT = 0x1           
//
//// FSECDBG
//#pragma config FSECDBG_SECDBG = 0x1   
//
//// FPED
//#pragma config FTPED_TPED = 0x1      
//
//// FEPUCB
//#pragma config FEPUCB_EPUCB = 0xffffffff
//
//// FWPUCB
//#pragma config FWPUCB_WPUCB = 0xffffffff
//
//// FBOOT
//#pragma config FBOOT_BTMODE = 0x3
//#pragma config FBOOT_PROG = 0x1
//
//// FPR0CTRLBKUP
//#pragma config FPR0CTRLBKUP_RDIS = 0x1       
//#pragma config FPR0CTRLBKUP_ERAO = 0x1       
//#pragma config FPR0CTRLBKUP_EX = 0x1         
//#pragma config FPR0CTRLBKUP_RD = 0x1         
//#pragma config FPR0CTRLBKUP_WR = 0x1         
//#pragma config FPR0CTRLBKUP_CRC = 0x1       
//#pragma config FPR0CTRLBKUP_RTYPE = 0x3      
//#pragma config FPR0CTRLBKUP_PSEL = 0x3 
//
//// FPR0STBKUP
//#pragma config PR0STBKUP_START = 0x7FF       
//
//// FPR0ENDBKUP
//#pragma config PR0ENDBKUP_END = 0x7FF         
//
//// FPR1CTRLBKUP
//#pragma config FPR1CTRLBKUP_RDIS = 0x1       
//#pragma config FPR1CTRLBKUP_ERAO = 0x1       
//#pragma config FPR1CTRLBKUP_EX = 0x1         
//#pragma config FPR1CTRLBKUP_RD = 0x1         
//#pragma config FPR1CTRLBKUP_WR = 0x1         
//#pragma config FPR1CTRLBKUP_CRC = 0x1       
//#pragma config FPR1CTRLBKUP_RTYPE = 0x3      
//#pragma config FPR1CTRLBKUP_PSEL = 0x3 
//
//// FPR1STBKUP
//#pragma config PR1STBKUP_START = 0x7FF       
//
//// FPR1ENDBKUP
//#pragma config PR1ENDBKUP_END = 0x7FF         
//
//// FPR2CTRLBKUP
//#pragma config FPR2CTRLBKUP_RDIS = 0x1       
//#pragma config FPR2CTRLBKUP_ERAO = 0x1       
//#pragma config FPR2CTRLBKUP_EX = 0x1         
//#pragma config FPR2CTRLBKUP_RD = 0x1         
//#pragma config FPR2CTRLBKUP_WR = 0x1         
//#pragma config FPR2CTRLBKUP_CRC = 0x1       
//#pragma config FPR2CTRLBKUP_RTYPE = 0x3      
//#pragma config FPR2CTRLBKUP_PSEL = 0x3 
//
//// FPR2STBKUP
//#pragma config PR2STBKUP_START = 0x7FF       
//
//// FPR2ENDBKUP
//#pragma config PR2ENDBKUP_END = 0x7FF          
//
//// FPR3CTRLBKUP
//#pragma config FPR3CTRLBKUP_RDIS = 0x1       
//#pragma config FPR3CTRLBKUP_ERAO = 0x1       
//#pragma config FPR3CTRLBKUP_EX = 0x1         
//#pragma config FPR3CTRLBKUP_RD = 0x1         
//#pragma config FPR3CTRLBKUP_WR = 0x1         
//#pragma config FPR3CTRLBKUP_CRC = 0x1       
//#pragma config FPR3CTRLBKUP_RTYPE = 0x3      
//#pragma config FPR3CTRLBKUP_PSEL = 0x3 
//
//// FPR3STBKUP
//#pragma config PR3STBKUP_START = 0x7FF       
//
//// FPR3ENDBKUP
//#pragma config PR3ENDBKUP_END = 0x7FF         
//
//// FPR4CTRLBKUP
//#pragma config FPR4CTRLBKUP_RDIS = 0x1       
//#pragma config FPR4CTRLBKUP_ERAO = 0x1       
//#pragma config FPR4CTRLBKUP_EX = 0x1         
//#pragma config FPR4CTRLBKUP_RD = 0x1         
//#pragma config FPR4CTRLBKUP_WR = 0x1         
//#pragma config FPR4CTRLBKUP_CRC = 0x1       
//#pragma config FPR4CTRLBKUP_RTYPE = 0x3      
//#pragma config FPR4CTRLBKUP_PSEL = 0x3 
//
//// FPR4STBKUP
//#pragma config PR4STBKUP_START = 0x7FF       
//
//// FPR4ENDBKUP
//#pragma config PR4ENDBKUP_END = 0x7FF       
//
//// FPR5CTRLBKUP
//#pragma config FPR5CTRLBKUP_RDIS = 0x1       
//#pragma config FPR5CTRLBKUP_ERAO = 0x1       
//#pragma config FPR5CTRLBKUP_EX = 0x1         
//#pragma config FPR5CTRLBKUP_RD = 0x1         
//#pragma config FPR5CTRLBKUP_WR = 0x1         
//#pragma config FPR5CTRLBKUP_CRC = 0x1       
//#pragma config FPR5CTRLBKUP_RTYPE = 0x3      
//#pragma config FPR5CTRLBKUP_PSEL = 0x3 
//
//// FPR5STBKUP
//#pragma config PR5STBKUP_START = 0x7FF       
//
//// FPR5ENDBKUP
//#pragma config PR5ENDBKUP_END = 0x7FF          
//
//// FPR6CTRLBKUP
//#pragma config FPR6CTRLBKUP_RDIS = 0x1       
//#pragma config FPR6CTRLBKUP_ERAO = 0x1       
//#pragma config FPR6CTRLBKUP_EX = 0x1         
//#pragma config FPR6CTRLBKUP_RD = 0x1         
//#pragma config FPR6CTRLBKUP_WR = 0x1         
//#pragma config FPR6CTRLBKUP_CRC = 0x1       
//#pragma config FPR6CTRLBKUP_RTYPE = 0x3      
//#pragma config FPR6CTRLBKUP_PSEL = 0x3 
//
//// FPR6STBKUP
//#pragma config PR6STBKUP_START = 0x7FF       
//
//// FPR6ENDBKUP
//#pragma config PR6ENDBKUP_END = 0x7FF        
//
//// FPR7CTRLBKUP
//#pragma config FPR7CTRLBKUP_RDIS = 0x1       
//#pragma config FPR7CTRLBKUP_ERAO = 0x1       
//#pragma config FPR7CTRLBKUP_EX = 0x1         
//#pragma config FPR7CTRLBKUP_RD = 0x1         
//#pragma config FPR7CTRLBKUP_WR = 0x1         
//#pragma config FPR7CTRLBKUP_CRC = 0x1       
//#pragma config FPR7CTRLBKUP_RTYPE = 0x3      
//#pragma config FPR7CTRLBKUP_PSEL = 0x3 
//
//// FPR7STBKUP
//#pragma config PR7STBKUP_START = 0x7FF       
//
//// FPR7ENDBKUP
//#pragma config PR7ENDBKUP_END = 0x7FF          
//
//// FIRTBKUP
//#pragma config FIRTBKUP_IRT = 0x1           
//
//// FSECDBGBKUP
//#pragma config FSECDBGBKUP_SECDBG = 0x1   
//
//// FPEDBKUP
//#pragma config FTPEDBKUP_TPED = 0x1      
//
//// FEPUCBBKUP
//#pragma config FEPUCBBKUP_EPUCB = 0xffffffff 
//
//// FWPUCBBKUP
//#pragma config FWPUCBBKUP_WPUCB = 0xffffffff 
//
//// FBOOTBKUP
//#pragma config FBOOTBKUP_BTMODE = 0x3
//#pragma config FBOOTBKUP_PROG = 0x1
#include <xc.h>


#ifndef HPCCON
volatile uint32_t HPCCON __attribute__((address(0x1E10)));
typedef struct tagHPCCONBITS {
  uint8_t :8;
  uint8_t :5;
  uint8_t CLR:1;
  uint8_t :1;
  uint8_t ON:1;
  uint8_t :8;
  uint8_t :8;
} HPCCONBITS;
volatile HPCCONBITS HPCCONbits __attribute__((address(0x1E10)));

#define HPSEL0 HPSEL0
volatile uint32_t HPSEL0 __attribute__((address(0x1E14)));
typedef struct tagHPSEL0BITS {
  uint8_t SELECT0:5;
  uint8_t :3;
  uint8_t SELECT1:5;
  uint8_t :3;
  uint8_t SELECT2:5;
  uint8_t :3;
  uint8_t SELECT3:5;
  uint8_t :3;
} HPSEL0BITS;
volatile HPSEL0BITS HPSEL0bits __attribute__((address(0x1E14)));

#define HPSEL1 HPSEL1
volatile uint32_t HPSEL1 __attribute__((address(0x1E14)));
typedef struct tagHPSEL1BITS {
  uint8_t SELECT4:5;
  uint8_t :3;
  uint8_t SELECT5:5;
  uint8_t :3;
  uint8_t SELECT6:5;
  uint8_t :3;
  uint8_t SELECT7:5;
  uint8_t :3;
} HPSEL1BITS;
volatile HPSEL1BITS HPSEL1bits __attribute__((address(0x1E14)));

#define HPCCNTL0 HPCCNTL0
volatile uint32_t HPCCNTL0 __attribute__((address(0x1E20)));
#define HPCCNTH0 HPCCNTH0
volatile uint32_t HPCCNTH0 __attribute__((address(0x1E20)));
#define HPCCNTL1 HPCCNTL1
volatile uint32_t HPCCNTL1 __attribute__((address(0x1E24)));
#define HPCCNTH1 HPCCNTH1
volatile uint32_t HPCCNTH1 __attribute__((address(0x1E24)));
#define HPCCNTL2 HPCCNTL2
volatile uint32_t HPCCNTL2 __attribute__((address(0x1E28)));
#define HPCCNTH2 HPCCNTH2
volatile uint32_t HPCCNTH2 __attribute__((address(0x1E28)));
#define HPCCNTL3 HPCCNTL3
volatile uint32_t HPCCNTL3 __attribute__((address(0x1E2C)));
#define HPCCNTH3 HPCCNTH3
volatile uint32_t HPCCNTH3 __attribute__((address(0x1E2C)));
#define HPCCNTL4 HPCCNTL4
volatile uint32_t HPCCNTL4 __attribute__((address(0x1E30)));
#define HPCCNTH4 HPCCNTH4
volatile uint32_t HPCCNTH4 __attribute__((address(0x1E30)));
#define HPCCNTL5 HPCCNTL5
volatile uint32_t HPCCNTL5 __attribute__((address(0x1E34)));
#define HPCCNTH5 HPCCNTH5
volatile uint32_t HPCCNTH5 __attribute__((address(0x1E34)));
#define HPCCNTL6 HPCCNTL6
volatile uint32_t HPCCNTL6 __attribute__((address(0x1E38)));
#define HPCCNTH6 HPCCNTH6
volatile uint32_t HPCCNTH6 __attribute__((address(0x1E38)));
#define HPCCNTL7 HPCCNTL7
volatile uint32_t HPCCNTL7 __attribute__((address(0x1E3C)));
#define HPCCNTH7 HPCCNTH7
volatile uint32_t HPCCNTH7 __attribute__((address(0x1E3C)));
#endif