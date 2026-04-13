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
;
; _mchp_sqrt_q31: Q31 square root using hardware double-precision FPU.
;
; Algorithm (from proven reference _Q31sqrt in libq):
;   1. Convert Q31 integer to double-precision float
;   2. Scale by 2^-31 to get fractional value in [0, 1)
;   3. Hardware sqrt.d
;   4. Scale by 2^31 to convert back to Q31 integer
;   5. Convert double to integer
;
; Input:
;   w0 = x       (q31_t) input value (must be >= 0)
;   w1 = pOut    (q31_t*) pointer to store result
;
; Return:
;   (void) result stored at *pOut
;
; System resources usage:
;   {w0, w1}       used, not restored
;   {f0..f3, FCR}  used, saved/restored
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Local inclusions.

    .nolist
    .include    "dspcommon.inc"      ; floatsetup macro
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .global _mchp_sqrt_q31
_mchp_sqrt_q31:
    ; Handle zero or negative input
    cp0.l   w0
    bra     le, _sqrt_zero

    ; Save callee context
    push.l  w1                  ; save pOut
    push.l  FCR
    push.l  F0
    push.l  F1
    push.l  F2
    push.l  F3

    ; Setup FPU control register
    floatsetup w2

    ; Convert Q31 integer in w0 to double float in [f0:f1]
    mov.l   w0, f0
    li2f.d  f0, f0              ; [f0:f1] = (double)w0

    ; Scale by 2^-31:  double 2^-31 = 0x3E000000_00000000
    ;   f3 = high word = 0x3E000000
    ;   f2 = low  word = 0x00000000
    mov.l   #0x3E000000, f3
    mov.l   #0, f2
    mul.d   f0, f2, f0          ; [f0:f1] = w0 * 2^-31  (fractional value)

    ; Hardware double-precision square root
    sqrt.d  f0, f0              ; [f0:f1] = sqrt(fractional value)

    ; Scale by 2^31:  double 2^31 = 0x41E00000_00000000
    mov.l   #0x41E00000, f3
    mul.d   f0, f2, f0          ; [f0:f1] = result * 2^31  (Q31 range)

    ; Convert double back to integer
    f2li.d  f0, f2              ; f2 = (int32)result
    mov.l   f2, w0              ; w0 = Q31 result

    ; Restore callee context
    pop.l   F3
    pop.l   F2
    pop.l   F1
    pop.l   F0
    pop.l   FCR
    pop.l   w1                  ; restore pOut

    ; Store result
    mov.l   w0, [w1]
    return

_sqrt_zero:
    mov.l   #0, w0
    mov.l   w0, [w1]
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF
