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
; _mchp_max_q31: Fixed-point (Q31) vector maximum value and index.
;
; Description:
;    Finds the maximum value and its index in a Q31 source vector.
;    Returns the maximum value through pResult and the index of the
;    first occurrence of the maximum through pIndex.
;
;    Uses signed 32-bit comparison (cp.l + bra gt) for Q31 values,
;    matching the original _VectorMax implementation.
;
;    dsPIC33AK does NOT have the REPEAT instruction; DTB is used for
;    all loop control.
;
; Operation:
;    *pResult = max( pSrc[n] ), with n in {0, 1, ... , blockSize-1}
;    *pIndex  = index of first occurrence of maximum value.
;
; Input:
;    w0 = ptr to source vector (pSrc)
;    w1 = number of elements in vector (blockSize)
;    w2 = ptr to maximum value result (q31_t *pResult)
;    w3 = ptr to index of maximum value (uint32_t *pIndex)
;
; Return:
;    no return value (void)
;    *pResult = maximum value found in pSrc
;    *pIndex  = index of maximum value (0-based)
;
; System resources usage:
;    {w0..w7}    used, not restored
;
; Notes:
;    - blockSize must be >= 1 (undefined behavior for blockSize == 0).
;    - If multiple elements share the maximum value, the index of the
;      first occurrence is returned.
;    - No CORCON or accumulator setup is needed (pure comparison/data move).
;    - dsPIC33AK has no REPEAT instruction; DTB loop is used.
;
;............................................................................

    .global    _mchp_max_q31        ; export

_mchp_max_q31:

;............................................................................
; Early exit check.
;............................................................................

    cp0.l      w1                     ; blockSize == 0 ? (32-bit compare)
    bra        z, _max_exit           ; Yes => nothing to do, exit.

;............................................................................
; Initialize maximum value and index.
;   w4 = current maximum value (initialized to pSrc[0])
;   w5 = current maximum index (initialized to 0)
;   w6 = running index counter (starts at 0, incremented each iteration)
;   w7 = scratch register for loading current element
;   w0 = running pSrc pointer (post-incremented)
;   w1 = loop counter (blockSize, decremented by DTB)
;............................................................................

    mov.l      [w0++], w4           ; w4 = pSrc[0] = initial maximum value.
                                      ; Post-increment pSrc pointer.
    mov.l      #0, w5               ; w5 = 0 = initial maximum index.
    mov.l      #0, w6               ; w6 = 0 = running index counter.

;............................................................................
; Check if only one element.
;............................................................................

    sub.l      w1, #1, w1           ; w1 = blockSize - 1 (remaining elements).
    bra        z, _max_store         ; If blockSize was 1, skip loop, store result.

;............................................................................
; Max search loop: compare each remaining element against current maximum.
;
;   For each element pSrc[n] (n = 1 to blockSize-1):
;     1. Load pSrc[n] into w7.
;     2. Compare w7 (signed) against current max w4.
;     3. If w7 > w4, update maximum value (w4) and index (w5).
;     4. Increment running index counter (w6).
;
;   Uses signed comparison (cp.l / bra gt) because Q31 values are
;   signed 32-bit fixed-point numbers.
;............................................................................

v_max_start:

    ; Increment running index.
    add.l      #1, w6               ; w6++ (current element index).

    ; Load next source element.
    mov.l      [w0++], w7           ; w7 = pSrc[n].
                                      ; Post-increment pSrc pointer.

    ; Signed comparison: is pSrc[n] > currentMax ?
    cp.l       w7, w4               ; Compare w7 - w4 (signed).
    bra        le, _max_skip        ; If pSrc[n] <= currentMax, skip update.

    ; Update maximum value and index.
    mov.l      w7, w4               ; w4 = pSrc[n] (new maximum value).
    mov.l      w6, w5               ; w5 = n (new maximum index).

_max_skip:

    DTB        w1, v_max_start      ; Decrement remaining counter (w1);
                                      ; branch to v_max_start if not zero.

;............................................................................
; Store results: maximum value and index.
;............................................................................

_max_store:
    mov.l      w4, [w2]             ; *pResult = maximum value.
    mov.l      w5, [w3]             ; *pIndex  = index of maximum value.

;............................................................................
; Exit: return to caller.
;............................................................................

_max_exit:
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF