

/* Microchip Technology Inc. and its subsidiaries.  You may use this software 
 * and any derivatives exclusively with Microchip products. 
 * 
 * THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS".  NO WARRANTIES, WHETHER 
 * EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED 
 * WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A 
 * PARTICULAR PURPOSE, OR ITS INTERACTION WITH MICROCHIP PRODUCTS, COMBINATION 
 * WITH ANY OTHER PRODUCTS, OR USE IN ANY APPLICATION. 
 *
 * IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE, 
 * INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND 
 * WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS 
 * BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE.  TO THE 
 * FULLEST EXTENT ALLOWED BY LAW, MICROCHIPS TOTAL LIABILITY ON ALL CLAIMS 
 * IN ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF 
 * ANY, THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.
 *
 * MICROCHIP PROVIDES THIS SOFTWARE CONDITIONALLY UPON YOUR ACCEPTANCE OF THESE 
 * TERMS. 
 */

/* 
 * File:   VADD_q31_test_inputs.c
 * Author: OpenCode
 * Comments: Q31 test vectors for mchp_add_q31
 * Revision history: 
 */

#include "../../main.h"
#include "mchp_math_types.h"

#ifdef VECTOR_LIB_TEST_I

/*
 * Q31 test data for vector addition.
 * Q31 range: -1.0 = 0x80000000, +max = 0x7FFFFFFF
 * Addition saturates to 0x7FFFFFFF / 0x80000000 on overflow.
 *
 * 150 element test vectors covering:
 *   - Normal positive + positive
 *   - Normal negative + negative
 *   - Mixed sign values
 *   - Near-zero values
 *   - Saturation cases (positive overflow -> 0x7FFFFFFF)
 *   - Saturation cases (negative overflow -> 0x80000000)
 *   - Boundary values (0x7FFFFFFF, 0x80000000)
 */

q31_t VADD_q31_src1[] = {
    /* 0-9: Normal positive + positive */
    0x10000000, 0x20000000, 0x30000000, 0x05000000, 0x12345678,
    0x0A0B0C0D, 0x3FFFFFFF, 0x01000000, 0x00100000, 0x00010000,
    /* 10-19: Normal negative + negative */
    (int)0xF0000000, (int)0xE0000000, (int)0xD0000000, (int)0xFB000000, (int)0xEDCBA988,
    (int)0xF5F4F3F3, (int)0xC0000001, (int)0xFF000000, (int)0xFFF00000, (int)0xFFFF0000,
    /* 20-29: Mixed sign (positive + negative) */
    0x40000000, (int)0xC0000000, 0x7FFFFFFF, (int)0x80000001, 0x10000000,
    (int)0xF0000000, 0x20000000, (int)0xE0000000, 0x55555555, (int)0xAAAAAAAA,
    /* 30-39: Near-zero values */
    0x00000001, (int)0xFFFFFFFF, 0x00000002, (int)0xFFFFFFFE, 0x00000100,
    (int)0xFFFFFF00, 0x00008000, (int)0xFFFF8000, 0x00000000, 0x00000000,
    /* 40-49: Positive saturation cases */
    0x7FFFFFFF, 0x00000001, 0x7FFFFFFF, 0x7FFFFFFF, 0x60000000,
    0x60000000, 0x50000000, 0x40000000, 0x7FFFFFF0, 0x00000020,
    /* 50-59: Negative saturation cases */
    (int)0x80000000, (int)0xFFFFFFFF, (int)0x80000000, (int)0x80000000, (int)0xA0000000,
    (int)0xA0000000, (int)0xB0000000, (int)0xC0000000, (int)0x80000010, (int)0xFFFFFFE0,
    /* 60-69: Large magnitude mixed */
    0x7FFFFFFF, (int)0x80000000, 0x7FFFFFFF, (int)0xFFFFFFFF, 0x40000000,
    (int)0xC0000000, 0x60000000, (int)0xA0000000, 0x3FFFFFFF, (int)0xC0000001,
    /* 70-79: Random Q31 values set 1 */
    0x1A2B3C4D, (int)0xE5D4C3B3, 0x2AAAAAAB, (int)0xD5555555, 0x33333333,
    (int)0xCCCCCCCD, 0x19999999, (int)0xE6666667, 0x0CCCCCCD, (int)0xF3333333,
    /* 80-89: Random Q31 values set 2 */
    0x45678901, (int)0xBA987700, 0x12345678, (int)0xEDCBA988, 0x6789ABCD,
    (int)0x98765433, 0x23456789, (int)0xDCBA9877, 0x56789ABC, (int)0xA9876544,
    /* 90-99: Alternating large/small */
    0x7FFF0000, 0x00010000, (int)0x8001FFFF, (int)0xFFFF0000, 0x7FFE0000,
    0x00020000, (int)0x80020000, (int)0xFFFE0000, 0x70000000, 0x10000000,
    /* 100-109: Gradual increase */
    0x08000000, 0x10000000, 0x18000000, 0x20000000, 0x28000000,
    0x30000000, 0x38000000, 0x40000000, 0x48000000, 0x50000000,
    /* 110-119: Gradual decrease */
    (int)0xF8000000, (int)0xF0000000, (int)0xE8000000, (int)0xE0000000, (int)0xD8000000,
    (int)0xD0000000, (int)0xC8000000, (int)0xC0000000, (int)0xB8000000, (int)0xB0000000,
    /* 120-129: Powers of 2 */
    0x40000000, 0x20000000, 0x10000000, 0x08000000, 0x04000000,
    0x02000000, 0x01000000, 0x00800000, 0x00400000, 0x00200000,
    /* 130-139: Negative powers of 2 */
    (int)0xC0000000, (int)0xE0000000, (int)0xF0000000, (int)0xF8000000, (int)0xFC000000,
    (int)0xFE000000, (int)0xFF000000, (int)0xFF800000, (int)0xFFC00000, (int)0xFFE00000,
    /* 140-149: Edge and misc cases */
    0x7FFFFFFF, (int)0x80000000, 0x00000000, 0x7FFFFFFF, (int)0x80000000,
    0x55555555, (int)0xAAAAAAAA, 0x12345678, (int)0xEDCBA988, 0x00000000
};

q31_t VADD_q31_src2[] = {
    /* 0-9: Normal positive + positive */
    0x10000000, 0x10000000, 0x10000000, 0x0A000000, 0x0EDCBA98,
    0x15F4F3F3, 0x00000001, 0x02000000, 0x00200000, 0x00020000,
    /* 10-19: Normal negative + negative */
    (int)0xF0000000, (int)0xF0000000, (int)0xF0000000, (int)0xF6000000, (int)0xF2345678,
    (int)0xEA0B0C0D, (int)0xFFFFFFFF, (int)0xFE000000, (int)0xFFE00000, (int)0xFFFE0000,
    /* 20-29: Mixed sign (positive + negative) */
    (int)0xC0000000, 0x40000000, (int)0x80000001, 0x7FFFFFFF, (int)0xF0000000,
    0x10000000, (int)0xE0000000, 0x20000000, (int)0xAAAAAAAA, 0x55555555,
    /* 30-39: Near-zero values */
    (int)0xFFFFFFFF, 0x00000001, (int)0xFFFFFFFE, 0x00000002, (int)0xFFFFFF00,
    0x00000100, (int)0xFFFF8000, 0x00008000, 0x00000000, 0x00000000,
    /* 40-49: Positive saturation cases */
    0x00000001, 0x7FFFFFFF, 0x7FFFFFFF, 0x00000001, 0x60000000,
    0x20000001, 0x30000001, 0x40000000, 0x00000010, 0x7FFFFFF0,
    /* 50-59: Negative saturation cases */
    (int)0xFFFFFFFF, (int)0x80000000, (int)0x80000000, (int)0xFFFFFFFF, (int)0xA0000000,
    (int)0xDFFFFFFF, (int)0xCFFFFFFF, (int)0xC0000000, (int)0xFFFFFFEF, (int)0x80000010,
    /* 60-69: Large magnitude mixed */
    (int)0x80000000, 0x7FFFFFFF, (int)0xFFFFFFFF, 0x7FFFFFFF, (int)0xC0000000,
    0x40000000, (int)0xA0000000, 0x60000000, (int)0xC0000001, 0x3FFFFFFF,
    /* 70-79: Random Q31 values set 1 */
    (int)0xE5D4C3B3, 0x1A2B3C4D, (int)0xD5555555, 0x2AAAAAAB, (int)0xCCCCCCCD,
    0x33333333, (int)0xE6666667, 0x19999999, (int)0xF3333333, 0x0CCCCCCD,
    /* 80-89: Random Q31 values set 2 */
    (int)0xBA987700, 0x45678901, (int)0xEDCBA988, 0x12345678, (int)0x98765433,
    0x6789ABCD, (int)0xDCBA9877, 0x23456789, (int)0xA9876544, 0x56789ABC,
    /* 90-99: Alternating large/small */
    0x00010000, 0x7FFF0000, (int)0xFFFF0000, (int)0x8001FFFF, 0x00020000,
    0x7FFE0000, (int)0xFFFE0000, (int)0x80020000, 0x10000000, 0x70000000,
    /* 100-109: Gradual increase */
    0x08000000, 0x10000000, 0x18000000, 0x20000000, 0x28000000,
    0x30000000, 0x38000000, 0x40000000, 0x48000000, 0x50000000,
    /* 110-119: Gradual decrease */
    (int)0xF8000000, (int)0xF0000000, (int)0xE8000000, (int)0xE0000000, (int)0xD8000000,
    (int)0xD0000000, (int)0xC8000000, (int)0xC0000000, (int)0xB8000000, (int)0xB0000000,
    /* 120-129: Powers of 2 */
    0x40000000, 0x20000000, 0x10000000, 0x08000000, 0x04000000,
    0x02000000, 0x01000000, 0x00800000, 0x00400000, 0x00200000,
    /* 130-139: Negative powers of 2 */
    (int)0xC0000000, (int)0xE0000000, (int)0xF0000000, (int)0xF8000000, (int)0xFC000000,
    (int)0xFE000000, (int)0xFF000000, (int)0xFF800000, (int)0xFFC00000, (int)0xFFE00000,
    /* 140-149: Edge and misc cases */
    (int)0x80000000, 0x7FFFFFFF, 0x00000000, (int)0x80000000, 0x7FFFFFFF,
    (int)0xAAAAAAAA, 0x55555555, (int)0xEDCBA988, 0x12345678, 0x00000000
};

/*
 * Expected results for saturating Q31 addition.
 * sat_add(a, b): if result overflows positive -> 0x7FFFFFFF
 *                if result overflows negative -> 0x80000000
 *                otherwise -> a + b
 */
q31_t VADD_q31_er[] = {
    0x20000000, 0x30000000, 0x40000000, 0x0F000000, 0x21111110,  /* 0-9: Normal positive + positive */
    0x20000000, 0x40000000, 0x03000000, 0x00300000, 0x00030000,
    (int)0xE0000000, (int)0xD0000000, (int)0xC0000000, (int)0xF1000000, (int)0xE0000000,  /* 10-19: Normal negative + negative */
    (int)0xE0000000, (int)0xC0000000, (int)0xFD000000, (int)0xFFD00000, (int)0xFFFD0000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,  /* 20-29: Mixed sign = cancellation */
    0x00000000, 0x00000000, 0x00000000, (int)0xFFFFFFFF, (int)0xFFFFFFFF,
    0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,  /* 30-39: Near-zero values */
    0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF,  /* 40-49: Positive saturation cases */
    0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF,
    (int)0x80000000, (int)0x80000000, (int)0x80000000, (int)0x80000000, (int)0x80000000,  /* 50-59: Negative saturation cases */
    (int)0x80000000, (int)0x80000000, (int)0x80000000, (int)0x80000000, (int)0x80000000,
    (int)0xFFFFFFFF, (int)0xFFFFFFFF, 0x7FFFFFFE, 0x7FFFFFFE, 0x00000000,  /* 60-69: Large magnitude mixed */
    0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,  /* 70-79: Random Q31 values set 1 (cancel to ~0) */
    0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000001, 0x00000001, 0x00000000, 0x00000000, 0x00000000,  /* 80-89: Random Q31 values set 2 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x7FFFFFFF, 0x7FFFFFFF, (int)0x8000FFFF, (int)0x8000FFFF, 0x7FFFFFFF,  /* 90-99: Alternating large/small */
    0x7FFFFFFF, (int)0x80000000, (int)0x80000000, 0x7FFFFFFF, 0x7FFFFFFF,
    0x10000000, 0x20000000, 0x30000000, 0x40000000, 0x50000000,  /* 100-109: Gradual increase (doubled) */
    0x60000000, 0x70000000, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF,
    (int)0xF0000000, (int)0xE0000000, (int)0xD0000000, (int)0xC0000000, (int)0xB0000000,  /* 110-119: Gradual decrease (doubled) */
    (int)0xA0000000, (int)0x90000000, (int)0x80000000, (int)0x80000000, (int)0x80000000,
    0x7FFFFFFF, 0x40000000, 0x20000000, 0x10000000, 0x08000000,  /* 120-129: Powers of 2 (doubled) */
    0x04000000, 0x02000000, 0x01000000, 0x00800000, 0x00400000,
    (int)0x80000000, (int)0xC0000000, (int)0xE0000000, (int)0xF0000000, (int)0xF8000000,  /* 130-139: Negative powers of 2 (doubled) */
    (int)0xFC000000, (int)0xFE000000, (int)0xFF000000, (int)0xFF800000, (int)0xFFC00000,
    (int)0xFFFFFFFF, (int)0xFFFFFFFF, 0x00000000, (int)0xFFFFFFFF, (int)0xFFFFFFFF,  /* 140-149: Edge and misc cases */
    (int)0xFFFFFFFF, (int)0xFFFFFFFF, 0x00000000, 0x00000000, 0x00000000
};

#endif



