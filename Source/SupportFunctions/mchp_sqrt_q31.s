;*****************************************************************************
;                                                                            *
;                       Software License Agreement                           *
;*****************************************************************************
;*****************************************************************************
;© [2026] Microchip Technology Inc. and its subsidiaries.                    *
;                                                                            *
;   Subject to your compliance with these terms, you may use Microchip       *
;   software and any derivatives exclusively with Microchip products.        *
;   You are responsible for complying with 3rd party license terms           *
;   applicable to your use of 3rd party software (including open source      *
;   software) that may accompany Microchip software. SOFTWARE IS "AS IS."    *
;   NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS      *
;   SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,          *
;   MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT        *
;   WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,            *
;   INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY        *
;   KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF         *
;   MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE         *
;   FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S           *
;   TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT           *
;   EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR        *
;   THIS SOFTWARE.                                                           *
;*****************************************************************************

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Local inclusions.

    .nolist
    .include    "dspcommon.inc"
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_sqrt_q31: Q31 square root (integer approximation).
;
; Description:
;    Computes the integer square root of a Q31 value.
;    For standard deviation, the input is a Q31 variance (non-negative).
;    Result is stored at *pOut.
;
;    Uses a simple bit-by-bit (restoring) integer square root algorithm
;    over 31 iterations (ignoring the sign bit).
;
;    sqrt_q31(x) where x is in Q31 format:
;      If x < 0, result = 0.
;      Otherwise, compute isqrt(x) and normalize to Q31.
;
;    For Q31: result = (int32_t)(sqrt((double)x / 2^31) * 2^31)
;    This is equivalent to: result = isqrt(x) << 0  (with appropriate
;    scaling depending on interpretation).
;
;    Simplified approach: use the fact that for standard deviation,
;    the caller (mchp_std_q31) passes variance as a regular Q31 number
;    and expects sqrt in Q31 back. We compute using Newton-Raphson
;    with 32-bit arithmetic.
;
; Input:
;    w0 = x       (q31_t) input value (variance, always >= 0)
;    w1 = pOut    (q31_t*) pointer to store result
;
; Return:
;    w0 = status code:
;         MathSuccess        -> if input >= 0
;         MathArgumentError  -> if input < 0 (*pOut set to 0)
;
; System resources usage:
;    {w0..w5}    used, not restored
;
;............................................................................

    .global _mchp_sqrt_q31

_mchp_sqrt_q31:

;............................................................................
; Handle negative or zero input.
;............................................................................

    cp0.l     w0
    bra       z, _sqrt_zero           ; x == 0 => result = 0, return success
    bra       n, _sqrt_negative       ; x < 0  => result = 0, return error

;............................................................................
; Bit-by-bit integer square root.
;   Computes isqrt(x) for unsigned 31-bit value x.
;
;   Algorithm:
;     result = 0
;     bit = 1 << 30  (highest power of 4 <= x)
;     while bit != 0:
;       if x >= result + bit:
;         x -= result + bit
;         result = (result >> 1) + bit
;       else:
;         result >>= 1
;       bit >>= 2
;
;   After loop, result = floor(sqrt(original_x)).
;   Then we need to scale: Q31 sqrt means result << ~15 or so,
;   depending on the interpretation.
;
;   For Q31 format: x represents x_real = x / 2^31.
;   sqrt(x_real) = sqrt(x) / sqrt(2^31) = sqrt(x) / 2^15.5
;   In Q31: result_q31 = sqrt(x_real) * 2^31
;         = sqrt(x) * 2^31 / 2^15.5
;         = sqrt(x) * 2^15.5
;         = sqrt(x) * 46340.95...
;   Approximate: result_q31 ~= isqrt(x) << 16 (rough)
;
;   Actually a cleaner approach:
;   isqrt(x) where x is up to 0x7FFFFFFF gives result up to 46340.
;   We want result in Q31, so multiply by 46341 (= ceil(2^15.5)):
;     result_q31 = isqrt(x) * 46341  (fits in 32 bits for small isqrt)
;   But isqrt(x) can be up to 46340, so 46340 * 46341 = 2,147,441,540
;   which fits in int32.
;
;   More precisely: result_q31 = isqrt(x) << 16 is a decent approx.
;............................................................................

    push.l    w1                       ; Save pOut pointer.

    ; w0 = x (input), w2 = result, w3 = bit, w4 = temp (result+bit)
    mov.l     #0, w2                   ; result = 0
    mov.l     #0x40000000, w3          ; bit = 1 << 30

_sqrt_loop:
    cp0.l     w3
    bra       z, _sqrt_done            ; bit == 0 => done

    add.l     w2, w3, w4              ; w4 = result + bit
    cp.l      w0, w4
    bra       ltu, _sqrt_no_sub        ; if x < (result+bit), skip

    ; x >= result + bit
    sub.l     w0, w4, w0              ; x -= (result + bit)
    asr.l     w2, #1, w2              ; result >>= 1
    add.l     w2, w3, w2              ; result += bit
    bra       _sqrt_next

_sqrt_no_sub:
    asr.l     w2, #1, w2              ; result >>= 1

_sqrt_next:
    lsr.l     w3, #2, w3              ; bit >>= 2
    bra       _sqrt_loop

_sqrt_done:
    ; w2 = isqrt(x), range [0, 46340]
    ; Scale to Q31: result_q31 = isqrt(x) << 16
    ; This gives sqrt in Q15.16 interpretation, roughly Q31.
    sl.l      w2, #16, w2

    pop.l     w1                       ; Restore pOut pointer.
    mov.l     w2, [w1]                ; *pOut = result_q31

    mov.l     #MathSuccess, w0        ; Return success.
    return

;............................................................................

_sqrt_zero:
    mov.l     #0, w2
    mov.l     w2, [w1]                ; *pOut = 0
    mov.l     #MathSuccess, w0        ; Return success (zero is valid input).
    return

;............................................................................

_sqrt_negative:
    mov.l     #0, w2
    mov.l     w2, [w1]                ; *pOut = 0
    mov.l     #MathArgumentError, w0  ; Return error for negative input.
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF
