

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
 * File:   VDOT_q31_test_inputs.c
 * Author: OpenCode
 * Comments: Q31 test vectors for mchp_dot_prod_q31
 * Revision history: 
 */

#include "../../main.h"
#include "mchp_math_types.h"

#ifdef VECTOR_LIB_TEST_I

/*
 * Q31 test data for dot product.
 * mchp_dot_prod_q31: result = sum(pSrcA[n] * pSrcB[n]) for n=0..blockSize-1
 * Intermediate products accumulated in fractional mode (mpy.l/mac.l with <<1 shift).
 * Full 64-bit result extracted from accumulator via slac.l/sac.l with SATDW disabled.
 * Output is q63_t (lower 64 bits of 72-bit accumulator in Q2.62 format).
 *
 * 150 source elements = 15 groups of 10, each producing one q63_t dot product result.
 */

/* 150 source elements (15 groups of 10) */
q31_t VDOT_q31_src1[] = {
    /* Group 0: All zeros */
    0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
    /* Group 1: src1 all max positive, src2 all max positive */
    0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF,
    0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF,
    /* Group 2: Orthogonal (alternating +/-) */
    0x40000000, (int)0xC0000000, 0x40000000, (int)0xC0000000, 0x40000000,
    (int)0xC0000000, 0x40000000, (int)0xC0000000, 0x40000000, (int)0xC0000000,
    /* Group 3: All max positive * all max negative */
    0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF,
    0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF,
    /* Group 4: Single element non-zero */
    0x40000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
    /* Group 5: Two elements */
    0x40000000, 0x20000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
    /* Group 6: Uniform 0.5 (0x40000000) */
    0x40000000, 0x40000000, 0x40000000, 0x40000000, 0x40000000,
    0x40000000, 0x40000000, 0x40000000, 0x40000000, 0x40000000,
    /* Group 7: Alternating positive */
    0x20000000, 0x40000000, 0x20000000, 0x40000000, 0x20000000,
    0x40000000, 0x20000000, 0x40000000, 0x20000000, 0x40000000,
    /* Group 8: Mixed positive and negative */
    0x7FFFFFFF, (int)0x80000000, 0x40000000, (int)0xC0000000, 0x20000000,
    (int)0xE0000000, 0x10000000, (int)0xF0000000, 0x08000000, (int)0xF8000000,
    /* Group 9: Gradual increase */
    0x08000000, 0x10000000, 0x18000000, 0x20000000, 0x28000000,
    0x30000000, 0x38000000, 0x40000000, 0x48000000, 0x50000000,
    /* Group 10: Random values set 1 */
    0x1A2B3C4D, (int)0xE5D4C3B3, 0x2AAAAAAB, (int)0xD5555555, 0x33333333,
    (int)0xCCCCCCCD, 0x3FFFFFFF, (int)0xC0000001, 0x12345678, (int)0xEDCBA988,
    /* Group 11: Random values set 2 */
    0x45678901, (int)0xBA987700, 0x6789ABCD, (int)0x98765433, 0x23456789,
    (int)0xDCBA9877, 0x56789ABC, (int)0xA9876544, 0x7FFF0000, (int)0x80010000,
    /* Group 12: Uniform negative -0.5 (0xC0000000) */
    (int)0xC0000000, (int)0xC0000000, (int)0xC0000000, (int)0xC0000000, (int)0xC0000000,
    (int)0xC0000000, (int)0xC0000000, (int)0xC0000000, (int)0xC0000000, (int)0xC0000000,
    /* Group 13: Powers of 2 */
    0x40000000, 0x20000000, 0x10000000, 0x08000000, 0x04000000,
    0x02000000, 0x01000000, 0x00800000, 0x00400000, 0x00200000,
    /* Group 14: Negative powers of 2 */
    (int)0xC0000000, (int)0xE0000000, (int)0xF0000000, (int)0xF8000000, (int)0xFC000000,
    (int)0xFE000000, (int)0xFF000000, (int)0xFF800000, (int)0xFFC00000, (int)0xFFE00000
};

q31_t VDOT_q31_src2[] = {
    /* Group 0: All zeros */
    0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
    /* Group 1: All max positive */
    0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF,
    0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF,
    /* Group 2: All same as src1 (should cancel to 0 alternation with itself) */
    0x40000000, (int)0xC0000000, 0x40000000, (int)0xC0000000, 0x40000000,
    (int)0xC0000000, 0x40000000, (int)0xC0000000, 0x40000000, (int)0xC0000000,
    /* Group 3: All max negative */
    (int)0x80000000, (int)0x80000000, (int)0x80000000, (int)0x80000000, (int)0x80000000,
    (int)0x80000000, (int)0x80000000, (int)0x80000000, (int)0x80000000, (int)0x80000000,
    /* Group 4: Single element non-zero */
    0x40000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
    /* Group 5: Two elements */
    0x60000000, 0x40000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
    /* Group 6: Uniform 0.5 (0x40000000) */
    0x40000000, 0x40000000, 0x40000000, 0x40000000, 0x40000000,
    0x40000000, 0x40000000, 0x40000000, 0x40000000, 0x40000000,
    /* Group 7: Uniform 0.5 (0x40000000) */
    0x40000000, 0x40000000, 0x40000000, 0x40000000, 0x40000000,
    0x40000000, 0x40000000, 0x40000000, 0x40000000, 0x40000000,
    /* Group 8: All ones (~0 in Q31) */
    0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001,
    0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001,
    /* Group 9: Self (same as src1) */
    0x08000000, 0x10000000, 0x18000000, 0x20000000, 0x28000000,
    0x30000000, 0x38000000, 0x40000000, 0x48000000, 0x50000000,
    /* Group 10: Negated src1 */
    (int)0xE5D4C3B3, 0x1A2B3C4D, (int)0xD5555555, 0x2AAAAAAB, (int)0xCCCCCCCD,
    0x33333333, (int)0xC0000001, 0x3FFFFFFF, (int)0xEDCBA988, 0x12345678,
    /* Group 11: Negated src2 */
    (int)0xBA987700, 0x45678901, (int)0x98765433, 0x6789ABCD, (int)0xDCBA9877,
    0x23456789, (int)0xA9876544, 0x56789ABC, (int)0x80010000, 0x7FFF0000,
    /* Group 12: Uniform positive 0.5 */
    0x40000000, 0x40000000, 0x40000000, 0x40000000, 0x40000000,
    0x40000000, 0x40000000, 0x40000000, 0x40000000, 0x40000000,
    /* Group 13: Same as src1 (self dot product) */
    0x40000000, 0x20000000, 0x10000000, 0x08000000, 0x04000000,
    0x02000000, 0x01000000, 0x00800000, 0x00400000, 0x00200000,
    /* Group 14: Same as src1 (self dot product) */
    (int)0xC0000000, (int)0xE0000000, (int)0xF0000000, (int)0xF8000000, (int)0xFC000000,
    (int)0xFE000000, (int)0xFF000000, (int)0xFF800000, (int)0xFFC00000, (int)0xFFE00000
};

/*
 * Expected q63_t results for each group of 10.
 * The assembly accumulates fractional products: acc += (a[i] * b[i]) << 1
 * in a 72-bit accumulator (fractsetup + mpy.l/mac.l), then extracts the
 * full 64-bit result via slac.l (bits[31:0]) and sac.l (bits[63:32])
 * with SATDW disabled. The stored value is the lower 64 bits of the
 * 72-bit accumulator in Q2.62 format.
 */
q63_t VDOT_q31_er[] = {
    (q63_t)0x0000000000000000LL,  /* Group 0:  all zeros */
    (q63_t)0xFFFFFFEC00000014LL,  /* Group 1:  10 * (~1.0)^2, exceeds 64-bit */
    (q63_t)0x4000000000000000LL,  /* Group 2:  10 * 0.25 = 2.5 in Q2.62 */
    (q63_t)0x0000000A00000000LL,  /* Group 3:  10 * (~1.0 * -1.0), exceeds 64-bit */
    (q63_t)0x2000000000000000LL,  /* Group 4:  single 0.5*0.5 = 0.25 */
    (q63_t)0x4000000000000000LL,  /* Group 5:  0.5*0.75 + 0.25*0.5 = 0.5 */
    (q63_t)0x4000000000000000LL,  /* Group 6:  10 * 0.25 = 2.5 in Q2.62 */
    (q63_t)0xF000000000000000LL,  /* Group 7:  mixed, sum > 1.0 */
    (q63_t)0xFFFFFFFFFFFFFFFELL,  /* Group 8:  tiny products sum to ~0 */
    (q63_t)0xC080000000000000LL,  /* Group 9:  self dot product */
    (q63_t)0x6AB79CB1CA1838D0LL,  /* Group 10: cross products */
    (q63_t)0x84FA9852EC46CDD8LL,  /* Group 11: cross products */
    (q63_t)0xC000000000000000LL,  /* Group 12: -0.5 * 0.5 * 10 = -2.5 */
    (q63_t)0x2AAAA80000000000LL,  /* Group 13: self dot of powers of 2 */
    (q63_t)0x2AAAA80000000000LL   /* Group 14: self dot of neg powers of 2 */
};

#endif



