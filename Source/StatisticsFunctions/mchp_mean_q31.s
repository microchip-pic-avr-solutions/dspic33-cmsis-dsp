;*****************************************************************************
;© [2026] Microchip Technology Inc. and its subsidiaries.                    *
;                                                                            *
;   Subject to your compliance with these terms, you may use Microchip       *
;   software and any derivatives exclusively with Microchip products.        *
;    You are responsible for complying with 3rd party license terms          *
;    applicable to your use of 3rd party software (including open source     *
;    software) that may accompany Microchip software. SOFTWARE IS "AS IS."   *
;    NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS     *
;    SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,         *
;    MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT       *
;    WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,           *
;    INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY        *
;    KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF        *
;    MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE        *
;    FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIPS           *
;    TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT          *
;    EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR       *
;   THIS SOFTWARE.                                                           *
;*****************************************************************************

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Local inclusions.

    .nolist
    .include    "dspcommon.inc"      ; fractsetup, floatsetup macros
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_mean_q31: Q31 vector mean.
;
; Operation:
;    mean = (sum of all elements) / blockSize
;
; Algorithm:
;    Accumulates sum in single-precision float using hardware FPU add.s,
;    then divides by N using div.s (both proven in reference vmean_aa_f32).
;
;    Single-precision float has ~23 bits of mantissa, which is less than
;    Q31's 31 bits. However, since the mean of Q31 values is also Q31,
;    the division reduces the magnitude, and the dominant error is at most
;    ~8 bits in the LSBs. For exact Q31 precision we would need double,
;    but add.s/div.s are proven on this hardware.
;
;    UPDATE: Actually we need full Q31 precision. Use double-precision:
;    Accumulate 64-bit sum in integer registers, then convert to double
;    for the division step. Uses add.d and div.d (double-precision FPU).
;
; Input:
;    w0 = pointer to input vector (pSrc)      (q31_t*)
;    w1 = blockSize (number of elements)      (uint32)
;    w2 = pointer to output mean (pResult)    (q31_t*)
;
; Return:
;    none (mean stored at *pResult)
;
; System resources usage:
;    {w0..w8}     used, not restored
;     FCR, F0..F3  saved, used, restored
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .global _mchp_mean_q31
_mchp_mean_q31:
    push.l   CORCON
    push.l   w8

    mov.l    w1, w3            ; w3 = N (preserve blockSize)
    mov.l    w2, w8            ; w8 = pResult (preserve)

    cp0.l    w1
    bra      z, _mean_store_zero

    ;--------------------------------------------------------------------
    ; Step 1: Accumulate 64-bit sum in w5:w4 (w5=high, w4=low).
    ;--------------------------------------------------------------------
    clr.l    w4                ; sum_lo = 0
    clr.l    w5                ; sum_hi = 0

_mean_sum_loop:
    mov.l    [w0++], w6        ; w6 = x[i] (signed 32-bit)
    asr.l    w6, #31, w7       ; w7 = sign extension of x[i]
    add.l    w6, w4, w4        ; sum_lo += x[i]
    addc.l   w7, w5, w5        ; sum_hi += sign_ext + carry
    DTB      w1, _mean_sum_loop

    ;--------------------------------------------------------------------
    ; Step 2: Convert 64-bit sum to double and divide by N.
    ;
    ; Decompose: sum = w5 * 2^32 + unsigned(w4)
    ;
    ; Convert each part to double separately using li2f.d and mul.d,
    ; then combine with add.d and divide with div.d.
    ;--------------------------------------------------------------------
    push.l   FCR
    push.l   F0
    push.l   F1
    push.l   F2
    push.l   F3

    floatsetup w7

    ; --- High part: (double)w5 * 2^32 ---
    mov.l    w5, f0
    li2f.d   f0, f0            ; [f0:f1] = (double)(signed)w5
    mov.l    #0x41F00000, f3   ; high word of double 2^32
    mov.l    #0, f2            ; low word of double 2^32
    mul.d    f0, f2, f0        ; [f0:f1] = w5 * 2^32

    ; --- Low part: (double)(unsigned)w4 ---
    ; Save high part on stack temporarily
    push.l   f0
    push.l   f1

    mov.l    w4, f0
    li2f.d   f0, f0            ; [f0:f1] = (double)(signed)w4

    ; If w4 < 0, li2f.d gave negative. Add 2^32 to make unsigned.
    ; 2^32 is still in [f2:f3] from above.
    cp0.l    w4
    bra      ge, _mean_low_pos
    add.d    f0, f2, f0        ; [f0:f1] += 2^32

_mean_low_pos:
    ; [f0:f1] = (double)(unsigned)w4
    ; Retrieve high part from stack into [f2:f3]
    pop.l    f3                ; f3 = saved f1 (high part high word)
    pop.l    f2                ; f2 = saved f0 (high part low word)

    ; --- Combine: sum_double = high_part + low_part ---
    add.d    f2, f0, f0        ; [f0:f1] = w5*2^32 + unsigned(w4)

    ; --- Divide by N ---
    mov.l    w3, f2
    li2f.d   f2, f2            ; [f2:f3] = (double)N
    div.d    f0, f2, f0        ; [f0:f1] = sum / N

    ; --- Convert to integer (truncation toward zero) ---
    f2li.d   f0, f2            ; f2 = (int32)(sum / N)
    mov.l    f2, w0

    pop.l    F3
    pop.l    F2
    pop.l    F1
    pop.l    F0
    pop.l    FCR

    mov.l    w0, [w8]          ; *pResult = mean

    pop.l    w8
    pop.l    CORCON
    return

_mean_store_zero:
    mov.l    #0, w0
    mov.l    w0, [w8]
    pop.l    w8
    pop.l    CORCON
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF
