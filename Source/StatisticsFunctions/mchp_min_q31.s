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
    .include    "dspcommon.inc"      ; Common DSP definitions
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_min_q31: Fixed-point (Q31) vector minimum value and index.
;
; Description:
;    Finds the minimum value and its index in a Q31 source vector.
;    Returns the minimum value through pResult and the index of the
;    first occurrence of the minimum through pIndex.
;
;    Uses signed 32-bit comparison (cp.l + bra lt) for Q31 values,
;    matching the original _VectorMin implementation.
;
;    dsPIC33AK does NOT have the REPEAT instruction; DTB is used for
;    all loop control.
;
; Operation:
;    *pResult = min( pSrc[n] ), with n in {0, 1, ... , blockSize-1}
;    *pIndex  = index of first occurrence of minimum value.
;
; Input:
;    w0 = ptr to source vector (pSrc)
;    w1 = number of elements in vector (blockSize)
;    w2 = ptr to minimum value result (q31_t *pResult)
;    w3 = ptr to index of minimum value (uint32_t *pIndex)
;
; Return:
;    no return value (void)
;    *pResult = minimum value found in pSrc
;    *pIndex  = index of minimum value (0-based)
;
; System resources usage:
;    {w0..w7}    used, not restored
;
; Notes:
;    - blockSize must be >= 1 (undefined behavior for blockSize == 0).
;    - If multiple elements share the minimum value, the index of the
;      first occurrence is returned.
;    - No CORCON or accumulator setup is needed (pure comparison/data move).
;    - dsPIC33AK has no REPEAT instruction; DTB loop is used.
;
;............................................................................

    .global    _mchp_min_q31        ; export

_mchp_min_q31:

;............................................................................
; Early exit check.
;............................................................................

    cp0.l      w1                     ; blockSize == 0 ? (32-bit compare)
    bra        z, _min_exit           ; Yes => nothing to do, exit.

;............................................................................
; Initialize minimum value and index.
;   w4 = current minimum value (initialized to pSrc[0])
;   w5 = current minimum index (initialized to 0)
;   w6 = running index counter (starts at 0, incremented each iteration)
;   w7 = scratch register for loading current element
;   w0 = running pSrc pointer (post-incremented)
;   w1 = loop counter (blockSize, decremented by DTB)
;............................................................................

    mov.l      [w0++], w4           ; w4 = pSrc[0] = initial minimum value.
                                      ; Post-increment pSrc pointer.
    mov.l      #0, w5               ; w5 = 0 = initial minimum index.
    mov.l      #0, w6               ; w6 = 0 = running index counter.

;............................................................................
; Check if only one element.
;............................................................................

    sub.l      w1, #1, w1           ; w1 = blockSize - 1 (remaining elements).
    bra        z, _min_store         ; If blockSize was 1, skip loop, store result.

;............................................................................
; Min search loop: compare each remaining element against current minimum.
;
;   For each element pSrc[n] (n = 1 to blockSize-1):
;     1. Increment running index counter (w6).
;     2. Load pSrc[n] into w7.
;     3. Compare w7 (signed) against current min w4.
;     4. If w7 < w4, update minimum value (w4) and index (w5).
;
;   Uses signed comparison (cp.l / bra ge) because Q31 values are
;   signed 32-bit fixed-point numbers.
;
;   The comparison uses "branch if greater-or-equal" to skip the update,
;   meaning the update happens only when pSrc[n] is strictly less than
;   the current minimum. This ensures the first occurrence index is kept
;   when multiple elements share the same minimum value.
;............................................................................

v_min_start:

    ; Increment running index.
    add.l      #1, w6               ; w6++ (current element index).

    ; Load next source element.
    mov.l      [w0++], w7           ; w7 = pSrc[n].
                                      ; Post-increment pSrc pointer.

    ; Signed comparison: is pSrc[n] < currentMin ?
    cp.l       w7, w4               ; Compare w7 - w4 (signed).
    bra        ge, _min_skip        ; If pSrc[n] >= currentMin, skip update.

    ; Update minimum value and index.
    mov.l      w7, w4               ; w4 = pSrc[n] (new minimum value).
    mov.l      w6, w5               ; w5 = n (new minimum index).

_min_skip:

    DTB        w1, v_min_start      ; Decrement remaining counter (w1);
                                      ; branch to v_min_start if not zero.

;............................................................................
; Store results: minimum value and index.
;............................................................................

_min_store:
    mov.l      w4, [w2]             ; *pResult = minimum value.
    mov.l      w5, [w3]             ; *pIndex  = index of minimum value.

;............................................................................
; Exit: return to caller.
;............................................................................

_min_exit:
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF