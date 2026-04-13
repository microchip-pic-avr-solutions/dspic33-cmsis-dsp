;*****************************************************************************
;                                                                            *
;                       Software License Agreement                           *
;*****************************************************************************
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
; _mchp_power_q31: Fixed-point (Q31) vector power (sum of squares).
;
; Description:
;    Computes the sum of squared elements of a Q31 source vector and
;    stores the saturated result at the location pointed to by the
;    result pointer.
;
;    This is the Q31 equivalent of the "dot product of a vector with
;    itself," commonly used for energy/power estimation.
;
;    Uses the DSP engines sqrac.l instruction for single-cycle
;    square-and-accumulate operations, matching the original
;    _VectorPower implementation.
;
;    dsPIC33AK does NOT have the REPEAT instruction; DTB is used for
;    all loop control.
;
; Operation:
;    *pResult = sum( pSrc[n] * pSrc[n] ), with
;
;    n in {0, 1, ... , blockSize-1}
;
; Input:
;    w0 = ptr to source vector (pSrc)
;    w1 = number of elements in vector (blockSize)
;    w2 = ptr to result (q63_t *pResult, 64-bit little-endian)
;
; Return:
;    no return value (void)
;    *pResult = power value (sum of squares) as q63_t (64-bit)
;
; System resources usage:
;    {w0..w5}    used, not restored
;     AccuA      used, not restored
;     CORCON     saved, used, restored
;
; Notes:
;    - blockSize must be >= 1 (if blockSize == 0, stores 0 to *pResult).
;    - pResult must point to a valid q63_t location (8 bytes).
;    - Accumulator saturation prevents overflow for large vectors.
;    - The sqrac.l instruction computes [src]^2 and accumulates in one cycle.
;    - No REPEAT instruction on dsPIC33AK; DTB loop is used.
;
;............................................................................

    .global    _mchp_power_q31        ; export

_mchp_power_q31:

;............................................................................
; Prepare CORCON for fractional computation.
;............................................................................

    push.l     CORCON                 ; Save 32-bit CORCON (will be restored on exit).
    fractsetup w3                     ; Setup CORCON for fractional/saturating
                                      ; arithmetic; w3 used as scratch by macro.

;............................................................................
; Save result pointer.
;............................................................................

    mov.l      w2, w3                ; w3 = pResult pointer (saved for later store).

;............................................................................
; Check for zero blockSize.
;............................................................................

    cp0.l      w1                     ; blockSize == 0 ? (32-bit compare)
    bra        z, _pow_store_zero     ; Yes => store zero result and exit.

;............................................................................
; Initialize accumulator.
;............................................................................

    clr        a                     ; Clear Accumulator A (a = 0).
                                      ; Starting sum = 0.

;............................................................................
; Power loop: square-and-accumulate each Q31 element.
;
;   w0 = running pSrc pointer (post-incremented by sqrac.l)
;   w1 = loop counter (blockSize, decremented by DTB)
;   AccuA = running sum of squares
;
;   The sqrac.l instruction:
;     a += [w0]^2
;   with post-increment on the source pointer.
;   This performs a fractional square-and-accumulate in a single cycle.
;............................................................................

v_pow_start:
    sqrac.l    [w0]+=4, a           ; a += pSrc[n] * pSrc[n] (saturated).
                                      ; Post-increment pSrc pointer (+4 bytes).

    DTB        w1, v_pow_start       ; Decrement 32-bit blockSize counter (w1);
                                      ; branch to v_pow_start if not zero.

;............................................................................
; Store accumulated power result as q63_t (64-bit).
;
;   q63_t is little-endian: low 32 bits at [w3+0], high 32 bits at [w3+4].
;   slac.l extracts accumulator bits[31:0] (lower 32 bits).
;   sac.l  extracts accumulator bits[63:32] (upper 32 bits, truncation).
;
;   IMPORTANT: Must disable SATDW before extraction. With SATDW_ON,
;   sac.l saturates to 0x7FFFFFFF when guard bits are non-zero (i.e., when
;   the sum exceeds 32-bit range in bits[63:32]). For q63_t output we need
;   the raw unsaturated bits[63:32].
;............................................................................

    bclr       CORCON, #5           ; Clear SATDW_ON to disable write saturation.
    slac.l     a, w4                ; w4 = AccA bits[31:0] (lower word).
    sac.l      a, w5                ; w5 = AccA bits[63:32] (upper word, no saturation).
    mov.l      w4, [w3]             ; Store low 32 bits at pResult+0.
    mov.l      w5, [w3+4]           ; Store high 32 bits at pResult+4.
    bra        _pow_exit             ; Branch to exit.

;............................................................................
; Zero result: blockSize was 0, store zero q63_t to *pResult.
;............................................................................

_pow_store_zero:
    mov.l      #0, w4               ; Zero value.
    mov.l      w4, [w3]             ; Store 0 at pResult+0 (low word).
    mov.l      w4, [w3+4]           ; Store 0 at pResult+4 (high word).

;............................................................................
; Exit: restore saved registers and return.
;............................................................................

_pow_exit:
    pop.l      CORCON                ; Restore 32-bit CORCON to pre-call state.
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF