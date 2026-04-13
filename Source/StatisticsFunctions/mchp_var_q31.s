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
    .include    "dspcommon.inc"      ; fractsetup macro
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_var_q31: Q31 vector variance (sample variance).
;
; Operation (matches CMSIS arm_var_q31):
;    mean = (sum of all elements) / blockSize
;    variance = sum((x_i - mean)^2) / (blockSize - 1)   [sample variance]
;
; Algorithm:
;    1. Call _mchp_mean_q31 to compute mean.
;    2. For each element, compute diff = x[i] - mean (saturating sub).
;    3. Accumulate diff^2 in AccA using mpy.l/add a (fractional).
;    4. Extract via sac.l (with saturation, Q31 output).
;    5. Divide by (N-1) using divsl with repeat #9.
;
; Input:
;    w0 = pointer to input vector (pSrc)    (q31_t*)
;    w1 = blockSize                         (uint32)
;    w2 = pointer to output variance        (q31_t*)
;
; Return:
;    none (variance stored at *pResult)
;
; System resources usage:
;    {w0..w8}      used, not restored
;     AccuA, AccuB  used, not restored
;     CORCON        saved, used, restored
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .extern _mchp_mean_q31

    .global _mchp_var_q31
_mchp_var_q31:
    push.l   CORCON
    push.l   w8

    mov.l    w1, w3            ; w3 = N (preserve)
    mov.l    w2, w8            ; w8 = pResult (preserve)

    cp.l     w1, #2
    bra      lt, _var_store_zero

    ;--------------------------------------------------------------------
    ; Step 1: Compute mean via _mchp_mean_q31.
    ;   mean stores result at [w2]. We pass w2 = pResult as temp storage.
    ;   Must save w0, w1, w3 across the call (mean clobbers them).
    ;--------------------------------------------------------------------
    push.l   w0                ; save pSrc
    push.l   w1                ; save blockSize
    push.l   w3                ; save N (mean clobbers w3)
    call     _mchp_mean_q31    ; mean stored at [w8]
    pop.l    w3                ; restore N
    pop.l    w1                ; restore blockSize
    pop.l    w0                ; restore pSrc

    ;--------------------------------------------------------------------
    ; Step 2: Setup for variance accumulation.
    ;--------------------------------------------------------------------
    fractsetup w4              ; Setup CORCON for fractional (after mean call)

    mov.l    [w8], w4          ; w4 = mean (Q31)
    clr      a                 ; AccA = 0
    mov.l    w0, w5            ; w5 = running pSrc pointer
    mov.l    w3, w6            ; w6 = N (loop count)

    ;--------------------------------------------------------------------
    ; Step 3: Accumulate sum of squared deviations.
    ;   For each element: diff = x[i] - mean; AccA += diff^2 (fractional)
    ;   mpy.l w7, w7, b => AccB = (diff * diff) << 1 (fractional Q62)
    ;   add a            => AccA += AccB
    ;--------------------------------------------------------------------
_var_loop:
    mov.l    [w5++], w7        ; w7 = x[i]
    sub.l    w7, w4, w7        ; w7 = x[i] - mean (saturating with SATDW)

    mpy.l    w7, w7, b         ; AccB = diff^2 << 1 (fractional)
    add      a                 ; AccA += AccB
    DTB      w6, _var_loop

    ;--------------------------------------------------------------------
    ; Step 4: Extract and divide.
    ;   sac.l extracts bits[63:32] with Q31 saturation.
    ;   Divide by (N-1) to get sample variance.
    ;   On dsPIC33AK: divsl Wd, Wn divides {W(d+1):Wd} by Wn.
    ;   For simple 32/32 case, set W(d+1) = sign extension of Wd.
    ;--------------------------------------------------------------------
    sac.l    a, w4             ; w4 = saturated Q31 sum of squares
    sub.l    w3, #1, w6        ; w6 = N-1

    ; Setup 64-bit dividend {w5:w4} for divsl
    asr.l    w4, #31, w5       ; w5 = sign extension of w4
    repeat   #9
    divsl    w4, w6            ; w4 = w4 / (N-1) (quotient in w4)

    mov.l    w4, [w8]          ; *pResult = variance (Q31)

    pop.l    w8
    pop.l    CORCON
    return

_var_store_zero:
    mov.l    #0, w4
    mov.l    w4, [w8]
    pop.l    w8
    pop.l    CORCON
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF
