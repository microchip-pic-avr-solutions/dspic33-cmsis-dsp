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
;   INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY         *
;   KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF         *
;   MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE         *
;   FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIPS            *
;   TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT           *
;   EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR        *
;   THIS SOFTWARE.                                                           *
;*****************************************************************************

; Local inclusions.

    .nolist
    .include    "dspcommon.inc"
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_fir_q31: Q31 FIR block filtering.
;
; Description:
;    Performs FIR filtering on a block of Q31 input samples using modulo
;    (circular) addressing for both coefficient and delay buffers.
;
;    Inner loop is kept identical to the fir_aa.s MAC sequence [42]:
;      - All but last MAC: mac.l [w6]+=4, [w7]+=4, a  (DTB loop)
;      - Last MAC:         mac.l [w6]+=4, [w7], a     (no post-inc on delay)
;      - Store:            sacr.l a, [w1++]
;
;    Modulo setup mirrors mchp_fir_f32.s [43]:
;      - X modulo for coefficients (w6 = XWM register)
;      - Y modulo for delay/state  (w7 = YWM register)
;
;    dsPIC33AK: uses DTB (no REPEAT instruction).
;
; Operation:
;    y[n] = sum_{m=0:M-1}{ h[m] * x[n-m] }, 0 <= n < blockSize.
;
; Input:
;    w0 = S, ptr to mchp_fir_instance_q31 structure
;    w1 = pSrc      (const q31_t*)
;    w2 = pDst      (q31_t*)
;    w3 = blockSize  (uint32)
;
; Return:
;    (void)
;
; System resources usage:
;    {w0..w10}   used, not restored
;     AccuA      used, not restored
;     CORCON     saved, used, restored
;     MODCON     saved, used, restored
;     XMODSRT    saved, used, restored
;     XMODEND    saved, used, restored
;     YMODSRT    saved, used, restored
;     YMODEND    saved, used, restored
;
;............................................................................

    .extern _firPStateStart_q31

    .global _mchp_fir_q31
_mchp_fir_q31:

;............................................................................
; Save working registers and control registers.
;............................................................................

    push.l    w8
    push.l    w9
    push.l    w10

    ; Prepare CORCON for fractional computation.
    push.l    CORCON
    fractsetup w8

    ; Save modulo control registers.
    push.l    MODCON
    push.l    XMODSRT
    push.l    XMODEND
    push.l    YMODSRT
    push.l    YMODEND

;............................................................................
; Early exit if blockSize == 0.
;............................................................................

    cp0.l     w3
    bra       z, _fir_exit

;............................................................................
; Setup registers for modulo addressing (from mchp_fir_f32.s) [43].
;
;   MODCON: XWM = w6, YWM = w7, enable X and Y modulo addressing.
;   X modulo window: coefficients h[0..M-1]
;   Y modulo window: delay/state d[0..M-1]
;............................................................................

    mov.l    #0xC076, w8              ; XWM=w6, YWM=w7, set XMODEND/YMODEND bits
    mov.l    w8, MODCON               ; Enable X,Y modulo addressing.

    ; Read numTaps (M) from instance structure [43].
    mov.l    [w0 + firNumTaps_q31], w8 ; w8 = numTaps = M
    sl.l     w8, #2, w9              ; w9 = M * sizeof(q31_t) = M * 4
    sub.l    #1, w9                  ; w9 = M*4 - 1  (byte range for modulo)

    ; X modulo: coefficients [43].
    mov.l    [w0 + firPCoeffs_q31], w6 ; w6 -> h[0]
    mov.l    w6, XMODSRT             ; X modulo start = coeffs base address
    add.l    w6, w9, w10
    mov.l    w10, XMODEND            ; X modulo end = coeffs end address

    ; Y modulo: delay/state [43].
    mov.l    _firPStateStart_q31, w10 ; w10 = delay base address
    mov.l    w10, YMODSRT             ; Y modulo start = delay base address
    add.l    w10, w9, w10             ; w10 -> last byte of d[M-1]
    mov.l    w10, YMODEND             ; Y modulo end = delay end address

    ; Load current delay pointer from instance (may differ from base
    ; if a previous call already advanced it within the circular buffer).
    mov.l    [w0 + firPState_q31], w7 ; w7 -> d[current] (saved from last call)

;............................................................................
; Compute inner tap loop count.
;   Matches fir_aa.s [42] structure exactly:
;     - mpy.l does first multiply (also clears AccuA)         : 1 multiply
;     - DTB inner loop with w4=M-2 does M-2 middle MACs      : M-2 multiplies
;     - Last MAC (no post-inc on delay ptr)                   : 1 multiply
;     - Total: 1 + (M-2) + 1 = M multiplies per output sample
;
;   w4 = M - 2  (DTB count for middle MACs)
;   Note: fir_aa.s uses repeat #(M-3) which gives (M-3)+1 = M-2 iterations.
;         DTB with initial w4=M-2 also gives M-2 iterations. Same count.
;
;   Degenerate cases:
;     M == 1: w4 = -1, skip inner loop AND last MAC (only mpy.l + sacr.l)
;     M == 2: w4 = 0, skip inner loop (mpy.l + last MAC + sacr.l)
;............................................................................

    mov.l    [w0 + firNumTaps_q31], w8 ; Reload M (numTaps)
    sub.l    w8, #2, w4              ; w4 = M - 2  (inner DTB loop count)

;............................................................................

    push.l    w0                      ; Save instance pointer (S) for exit.
    push.l    w2                      ; Save return value (pDst).

;............................................................................
; Outer loop: filter each sample.
;   w0 = instance pointer (S)
;   w1 = running pSrc pointer (post-incremented)
;   w2 = running pDst pointer (post-incremented)
;   w3 = blockSize (outer loop counter, decremented by DTB)
;   w4 = M - 2 (inner loop count, reloaded each sample)
;   w5 = saved inner loop count (copy of w4)
;   w6 = coefficient pointer (X modulo)
;   w7 = delay pointer (Y modulo)
;............................................................................

    mov.l    w4, w5                  ; w5 = saved (M-2) for reload each sample.

startFilter_q31:

    ; Write new input sample into delay line at current Y position.
    mov.l    [w1++], w8              ; w8 = x[n] (next input sample).
    mov.l    w8, [w7]                ; d[current] = x[n].

    ; First multiply: clears AccuA and computes first product.
    ; Matches fir_aa.s [42]: mpy.l [w6]+=4, [w7]+=4, a
    mpy.l    [w6]+=4, [w7]+=4, a    ; a = h[0] * d[current]
                                      ; w6 -> h[1]  (X modulo)
                                      ; w7 -> d[next]  (Y modulo)

    ; Reload inner loop count.
    mov.l    w5, w4                  ; w4 = M - 2.

    ; Check degenerate cases.
    cp0.l    w4
    bra      n, _checkM1_q31        ; If M-2 < 0 (M==1), skip to store.
    bra      z, _lastMAC_q31        ; If M-2 == 0 (M==2), skip inner loop.

;............................................................................
; Inner tap loop: middle MACs (all but first and last).
;   mac.l [w6]+=4, [w7]+=4, a
;   - w6 steps through coefficients with X modulo wrapping.
;   - w7 steps through delay with Y modulo wrapping.
;   - AccuA accumulates the sum-of-products.
;   DTB with w4 = M-2 executes M-2 iterations.
;............................................................................

_innerMAC_q31:
    mac.l    [w6]+=4, [w7]+=4, a    ; a += h[m] * d[current]  [42]
                                      ; w6 -> h[m+1]  (X modulo)
                                      ; w7 -> d[next]  (Y modulo)
    DTB      w4, _innerMAC_q31      ; Decrement tap counter;
                                      ; branch if not zero.

;............................................................................
; Last MAC: no post-increment on delay pointer (identical to fir_aa.s) [42].
;   This ensures w7 stays at d[init-1] after the last multiply, so the
;   delay pointer is correctly positioned for the next output sample.
;............................................................................

_lastMAC_q31:
    mac.l    [w6]+=4, [w7], a       ; a += h[M-1] * d[last]  [42]
                                      ; w6 -> h[0]  (X modulo wraps)
                                      ; w7 stays at d[init-1]

;............................................................................
; Store filtered output sample (identical to fir_aa.s) [42].
;   sacr.l stores the saturated, rounded 32-bit result from AccuA.
;............................................................................

_storeFIR_q31:
    sacr.l   a, [w2++]              ; y[n] = sum_{m=0:M-1}(h[m]*x[n-m])  [42]
                                      ; w2 -> y[n+1]

;............................................................................
; Next output sample.
;............................................................................

    DTB      w3, startFilter_q31    ; Decrement blockSize counter;
                                      ; branch if not zero.

    bra      _fir_done_q31          ; Skip degenerate handler.

;............................................................................
; Degenerate case handler: M == 1.
;   Reached when M-2 < 0 (M==1). Only mpy.l was done, store directly.
;............................................................................

_checkM1_q31:
    bra      _storeFIR_q31          ; M=1: only mpy.l done, go straight to store.

;............................................................................
; Normal exit from outer loop.
;............................................................................

_fir_done_q31:
    pop.l    w0                      ; Discard saved pDst.
    pop.l    w0                      ; Restore instance pointer (S).

    ; Save updated delay pointer back to instance so the next call
    ; resumes at the correct position in the circular buffer.
    mov.l    w7, [w0 + firPState_q31]

;............................................................................
; Exit: restore saved control registers and working registers.
;............................................................................

_fir_exit:
    pop.l    YMODEND
    pop.l    YMODSRT
    pop.l    XMODEND
    pop.l    XMODSRT
    pop.l    MODCON

    pop.l    CORCON

    pop.l    w10
    pop.l    w9
    pop.l    w8

    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF