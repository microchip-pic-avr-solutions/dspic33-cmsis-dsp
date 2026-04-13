//
///* 
// * File:   config.c
// * Author: OpenCode
// *
// * Created on March 23, 2026
// * 
// * Hardware Performance Counter (HPC) register definitions
// */

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
