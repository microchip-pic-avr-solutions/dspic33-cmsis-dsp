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
; _mchp_std_q31: Q31 vector standard deviation.
;
; Operation:
;    variance = sum((x_i - mean)^2) / (blockSize - 1)
;    stddev   = sqrt(variance)
;
; Input:
;    w0 = pointer to input vector (pSrc)
;    w1 = blockSize
;    w2 = pointer to output stddev (q31_t *pResult)
;
; Return:
;    none (stddev stored at *pResult)
;
; Notes:
;    - If blockSize <= 1, stores 0.
;    - Calls _mchp_var_q31 for variance, then _mchp_sqrt_q31 for sqrt.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .extern _mchp_var_q31
    .extern _mchp_sqrt_q31

    .global _mchp_std_q31
_mchp_std_q31:
    push.l   CORCON
    push.l   w8

    mov.l    w2, w8            ; w8 = pResult (preserve across calls)

    cp.l     w1, #2
    bra      lt, _std_store_zero

    ;--------------------------------------------------------------------
    ; Step 1: Compute variance into *pResult.
    ;   _mchp_var_q31(w0=pSrc, w1=N, w2=pResult)
    ;   After this call, variance is stored at [w8].
    ;--------------------------------------------------------------------
    call     _mchp_var_q31

    ;--------------------------------------------------------------------
    ; Step 2: Compute sqrt of variance.
    ;   _mchp_sqrt_q31(w0=input, w1=pOut)
    ;   Load variance from [w8], pass w8 as output pointer.
    ;--------------------------------------------------------------------
    mov.l    [w8], w0          ; w0 = variance
    mov.l    w8, w1            ; w1 = pResult (output for sqrt)
    call     _mchp_sqrt_q31    ; sqrt stores result at [w1]

    pop.l    w8
    pop.l    CORCON
    return

_std_store_zero:
    mov.l    #0, w0
    mov.l    w0, [w8]
    pop.l    w8
    pop.l    CORCON
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF
