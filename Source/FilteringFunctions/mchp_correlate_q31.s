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

; Local inclusions.

    .nolist
    .include    "dspcommon.inc"      ; fractsetup
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_correlate_q31: Q31 vector correlation (using convolution).
;
; Description:
;    Computes the cross-correlation of two Q31 vectors by time-reversing
;    the second vector (pSrcB) and then calling convolution
;    (_mchp_conv_q31).
;
;    Correlation is defined as:
;      r[n] = sum_{k=0:N-1}{ x[k] * y[k+n] }
;
;    This is equivalent to convolving x[] with the time-reversed y[].
;
;    The time-reversal is performed in-place on pSrcB before calling
;    convolution, matching the vcor_aa.s approach [64].
;
;    IMPORTANT: pSrcB is modified in-place (time-reversed). If the
;    caller needs the original pSrcB data, it must save a copy before
;    calling this function.
;
;    dsPIC33AK: uses DTB (no REPEAT instruction).
;
; Operation:
;    r[n] = sum_{k=0:N-1}{ x[k] * y[k+n] }
;    where:
;      x[n] defined for 0 <= n < N (pSrcA, srcALen)
;      y[n] defined for 0 <= n < M (pSrcB, srcBLen), M <= N
;      r[n] defined for 0 <= n < N+M-1 (pDst)
;
; Input:
;    w0 = pSrcA     (const q31_t*) pointer to first source vector (x)
;    w1 = srcALen   (uint32)       length of first source vector (N)
;    w2 = pSrcB     (q31_t*)       pointer to second source vector (y)
;                                   NOTE: modified in-place (reversed)
;    w3 = srcBLen   (uint32)       length of second source vector (M)
;    w4 = pDst      (q31_t*)       pointer to output vector (N+M-1 elements)
;
; Return:
;    (void)
;
; System resources usage:
;    {w0..w9}    used, not restored
;     AccuA      used, not restored (via _mchp_conv_q31)
;     CORCON     saved, used, restored (via _mchp_conv_q31)
;
; Notes:
;    - Output length = srcALen + srcBLen - 1.
;    - pDst must be pre-allocated for (N+M-1) q31_t elements.
;    - pSrcB is modified in-place by the time-reversal.
;    - Calls _mchp_conv_q31 for the actual convolution.
;    - If either length is 0, function returns immediately.
;
;............................................................................

    .extern    _mchp_conv_q31

    .global    _mchp_correlate_q31    ; export

_mchp_correlate_q31:

;............................................................................
; Save working registers.
;............................................................................

    push.l    w8                     ; Save w8 (used for reversal loop).

;............................................................................
; Early exit if either length is 0.
;............................................................................

    cp0.l     w1
    bra       z, _corr_exit_q31
    cp0.l     w3
    bra       z, _corr_exit_q31

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Step 1: Time-reverse pSrcB in-place [64].
;
;   Swap elements pairwise from both ends towards the center:
;     y[0] <-> y[M-1]
;     y[1] <-> y[M-2]
;     ...
;   Number of swaps = floor(M / 2).
;
;   w7 = pointer to y[0]      (walks forward)
;   w6 = pointer to y[M-1]    (walks backward)
;   w8 = floor(M/2)           (swap count for DTB)
;   w5 = scratch for swap
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Compute pointer to y[M-1].
    mov.l     w2, w7                ; w7 -> y[0] (start pointer).
    sub.l     w3, #1, w5            ; w5 = M - 1.
    sl.l      w5, #2, w5            ; w5 = (M-1) * 4 bytes.
    add.l     w2, w5, w6            ; w6 -> y[M-1] (end pointer).

    ; Compute number of swaps = floor(M/2).
    lsr.l     w3, w8                ; w8 = M / 2 (swap count).

    ; If M < 2, no swaps needed.
    cp0.l     w8
    bra       z, _reversal_done_q31

;............................................................................
; Reversal swap loop [64].
;............................................................................

_startRevert_q31:
    ; Swap y[front] <-> y[back].
    mov.l     [w6], w5              ; w5 = y[back] (save).
    mov.l     [w7], [w6--]          ; y[back] = y[front]; back--.
    mov.l     w5, [w7++]            ; y[front] = saved y[back]; front++.

    DTB       w8, _startRevert_q31  ; Decrement swap counter;
                                     ; branch if not zero.

_reversal_done_q31:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Step 2: Call convolution (_mchp_conv_q31) [65].
;
;   After time-reversal, correlation = conv(x, rev(y)).
;   The convolution function expects:
;     w0 = pSrcA     (x)
;     w1 = srcALen   (N)
;     w2 = pSrcB     (rev(y))
;     w3 = srcBLen   (M)
;     w4 = pDst      (r)
;
;   All registers are already in the correct positions:
;     w0 = pSrcA   (unchanged)
;     w1 = srcALen  (unchanged)
;     w2 = pSrcB    (now reversed in-place)
;     w3 = srcBLen  (unchanged)
;     w4 = pDst     (unchanged)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    call       _mchp_conv_q31       ; Perform convolution on reversed data.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Exit: restore saved registers and return.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_corr_exit_q31:
    pop.l     w8                    ; Restore w8.

    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF