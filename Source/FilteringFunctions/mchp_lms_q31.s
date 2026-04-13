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
;   FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S           *
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
; _mchp_lms_q31: Q31 FIR filtering with LMS coefficient adaptation.
;
; Description:
;    Performs FIR filtering with LMS coefficient adaptation on a block
;    of Q31 input samples.
;
;    For each sample n:
;      1. FIR filter: y[n] = sum_{m=0:M-1}(h[m]*x[n-m])
;      2. Compute error: e[n] = r[n] - y[n]
;      3. Attenuate error: attErr = mu * e[n]
;      4. Update coefficients: h[m] += attErr * x[n-m], 0 <= m < M
;
;    Uses modulo (circular) addressing for delay buffer.
;    Coefficients are accessed linearly (not modulo), since adaptation
;    requires read-modify-write via lac.l/mac.l/sacr.l sequence, matching
;    the firlms_aa.s approach [61].
;
;    dsPIC33AK: uses DTB (no REPEAT instruction).
;
; Operation:
;    y[n] = sum_{m=0:M-1}(h[m]*x[n-m]), 0 <= n < N.
;    h(n+1)[m] = h(n)[m] + mu*(r[n]-y[n])*x[n-m], 0 <= m < M.
;
; Input:
;    w0 = S       ptr to mchp_lms_instance_q31
;    w1 = pSrc    (const q31_t*) input samples x[n]
;    w2 = pRef    (const q31_t*) reference samples r[n]
;    w3 = pDst    (q31_t*) output samples y[n]
;    w4 = pErr    (q31_t*) error output e[n]
;    w5 = N       (uint32) number of samples to process
;
; Return:
;    (void)
;
; Instance structure layout:
;    [S + lmsNumTaps_q31]   = numTaps (M)
;    [S + lmsPCoeffs_q31]   = pCoeffs (q31_t*)
;    [S + lmsPState_q31]    = pState  (q31_t*, current delay position)
;    [S + lmsMu_q31]        = mu      (q31_t)
;
; System resources usage:
;    {w0..w14}   used, not restored
;     AccuA      used, not restored
;     AccuB      used, not restored
;     CORCON     saved, used, restored
;     MODCON     saved, used, restored
;     XMODSRT    saved, used, restored
;     XMODEND    saved, used, restored
;     YMODSRT    saved, used, restored
;     YMODEND    saved, used, restored
;
;............................................................................

    .extern _lmsPStateStart_q31

    .global _mchp_lms_q31    ; export

_mchp_lms_q31:

;............................................................................
; Save working registers (mirrors f32 version) [57].
;............................................................................

    push.l    w8
    push.l    w9
    push.l    w10
    push.l    w11
    push.l    w12
    push.l    w13
    push.l    w14

;............................................................................
; Prepare CORCON for fractional computation.
;............................................................................

    push.l    CORCON
    fractsetup w7

;............................................................................
; Save modulo control registers.
;............................................................................

    push.l    MODCON
    push.l    XMODSRT
    push.l    XMODEND
    push.l    YMODSRT
    push.l    YMODEND

;............................................................................
; Early exit if N == 0.
;............................................................................

    cp0.l     w5
    bra       z, _lms_exit

;............................................................................
; Setup modulo addressing [61].
;   X modulo: coefficients (w8)
;   Y modulo: delay/state (w10)
;   MODCON: XWM=w8, YWM=w10
;............................................................................

    mov.l     #0xC0A8, w10                    ; XWM=w8, YWM=w10
    mov.l     w10, MODCON

;............................................................................
; Load instance fields and setup modulo windows [57].
;............................................................................

    mov       [w0 + #lmsNumTaps_q31], w7      ; w7 = M (numTaps)
    sl.l      w7, #2, w9                      ; w9 = M * 4
    sub.l     #1, w9                          ; w9 = M*4 - 1

    ; X modulo: coefficients.
    mov.l     [w0 + #lmsPCoeffs_q31], w8     ; w8 -> h[0]
    mov.l     w8, XMODSRT
    add.l     w8, w9, w14
    mov.l     w14, XMODEND

    ; Y modulo: delay/state.
    mov.l     _lmsPStateStart_q31, w10        ; w10 -> d[0]
    mov.l     w10, YMODSRT
    add.l     w10, w9, w14
    mov.l     w14, YMODEND

;............................................................................
; Load current delay pointer from instance.
;............................................................................

    mov.l     [w0 + #lmsPState_q31], w10      ; w10 = current delay position

;............................................................................
; Prepare filtering registers.
;   w1  = pSrc (x) running pointer
;   w2  = pRef (r) -> saved as w12
;   w3  = pDst (y) running pointer
;   w4  = pErr (e) error output pointer
;   w5  = N (outer loop counter)
;   w6  = h[0] base (for linear coeff access during adaptation)
;   w7  = M (numTaps) -> compute M-2 for DTB inner loop
;   w8  = coefficient pointer (X modulo)
;   w10 = delay pointer (Y modulo)
;   w11 = mu (Q31 step size)
;............................................................................

    mov.l     w2, w12                          ; w12 -> r[0] (reference)
    mov.l     [w0 + #lmsMu_q31], w11          ; w11 = mu (Q31)
    mov.l     w8, w6                           ; w6 -> h[0] (linear base for adaptation)

    ; Compute inner MAC loop count: M-2 for DTB.
    sub.l     w7, #2, w7                       ; w7 = M - 2
    push.l    w7                               ; Save M-2 for reload.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Main sample loop: process N samples [57][61].
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

startFilter_q31:

;............................................................................
; Step 1: Write new input sample into delay line [61].
;............................................................................

    mov.l     [w1++], w13                      ; w13 = x[n], advance pSrc.
    mov.l     w13, [w10]                       ; d[current] = x[n].

;............................................................................
; Step 2: FIR filter y[n] = sum_{m=0:M-1}(h[m]*x[n-m]).
;
; Reference (firlms_aa.s) uses:
;   mpy.l [w8]+=4, [w10]+=4, a    ; 1st product: h[0]*d[0]
;   repeat w4                       ; (M-2)+1 = M-1 mac products
;   mac.l [w8]+=4, [w10]+=4, a
;
; DTB equivalent: mpy.l (1) + DTB M-2 mac (M-2) + last mac (1) = M.
;............................................................................

    ; First product: a = h[0]*delay[current] (clears acc, multiplies).
    mpy.l     [w8]+=4, [w10]+=4, a            ; a = h[0]*d[0]
                                                ; w8 -> h[1], w10 -> d[1]

    ; Reload inner loop count.
    mov.l     [w15-4], w7                      ; w7 = M - 2

    ; Check degenerate cases.
    cp0.l     w7
    bra       n, _lms_firDone                  ; M == 1: mpy.l was enough.
    bra       z, _lms_lastMAC                  ; M == 2: skip inner loop.

;............................................................................
; Inner MAC loop: M-2 iterations (all-but-last).
;............................................................................

_lms_innerMAC:
    mac.l     [w8]+=4, [w10]+=4, a            ; a += h[m] * d[m]
    DTB       w7, _lms_innerMAC

;............................................................................
; Last MAC: post-increment on both pointers so w10 wraps back to
; delay[current] via modulo (matching reference's repeat behavior).
;............................................................................

_lms_lastMAC:
    mac.l     [w8]+=4, [w10]+=4, a            ; a += h[M-1] * d[last]
                                               ; w8 wraps to h[0]
                                               ; w10 wraps to delay[current]

_lms_firDone:

;............................................................................
; Step 3: Compute error e[n] = r[n] - y[n] and store outputs [61].
;............................................................................

    ; Load reference sample.
    lac.l     [w12++], b                       ; b = r[n], advance pRef.

    ; Compute error: b = r[n] - y[n].
    sub       b                                ; b = r[n] - y[n] = e[n].
    sacr.l    b, w13                           ; w13 = e[n] (integer copy).

    ; Store error output.
    sacr.l    b, [w4++]                        ; *pErr++ = e[n].

    ; Store filtered output y[n].
    sacr.l    a, [w3++]                        ; y[n] = sum result.
                                                ; w3 -> y[n+1].

;............................................................................
; Step 4: Compute attenuated error = mu * e[n] [61].
;............................................................................

    mpy.l     w13, w11, a                      ; a = mu * e[n]
    sacr.l    a, w13                           ; w13 = attErr = mu * e[n]

;............................................................................
; Step 5: Update coefficients h[m] += attErr * x[n-m] [61].
;
;   Adaptation walk (identical to firlms_aa.s pattern):
;     - Coefficients accessed linearly via w6 (not modulo),
;       because we need read-modify-write (lac.l / mac.l / sacr.l).
;     - Delay accessed via Y modulo (w10).
;     - For each tap m = 0 to M-1:
;         h[m] = h[m] + attErr * x[n-m]
;
;   firlms_aa.s [61] uses:
;     lac.l  [w6], a             ; a = h[m]
;     mac.l  w5, [w10]+=4, a    ; a += attErr * delay[m]
;     sacr.l a, [w6++]           ; h[m] = updated, advance
;     dtb    w11, startAdapt
;
;     (last coefficient: mac.l w5, [w10], a; sacr.l a, [w6])
;............................................................................

    mov.l     [w15-4], w7                      ; w7 = M - 2
    add.l     w7, #1, w9                       ; w9 = M - 1 (all-but-last update count)
    mov.l     w6, w14                          ; w14 -> h[0] (linear walk for update)

    ; Check degenerate: M == 1.
    cp0.l     w9
    bra       z, _lms_lastAdapt               ; Only one coefficient.

;............................................................................
; Adaptation loop: all-but-last coefficient [61].
;............................................................................

startAdapt_q31:
    lac.l     [w14], a                         ; a = h[m]
    mac.l     w13, [w10]+=4, a                 ; a += attErr * delay[m]
                                                ; w10 advances (Y modulo).
    sacr.l    a, [w14++]                       ; h[m] = updated.
                                                ; w14 -> h[m+1].
    DTB       w9, startAdapt_q31              ; Decrement counter;
                                                ; branch if not zero.

;............................................................................
; Last coefficient adaptation (no post-inc on delay) [61].
;............................................................................

_lms_lastAdapt:
    lac.l     [w14], a                         ; a = h[M-1]
    mac.l     w13, [w10], a                    ; a += attErr * delay[M-1]
    sacr.l    a, [w14]                         ; h[M-1] = updated.

;............................................................................
; Reload loop constants for next sample.
;............................................................................

    mov.l     [w15-4], w7                      ; Reload M-2.

;............................................................................
; Next sample.
;............................................................................

    DTB       w5, startFilter_q31              ; Decrement N counter;
                                                ; branch if not zero.

;............................................................................
; Clean up stack.
;............................................................................

    pop.l     w7                               ; Remove saved M-2.

;............................................................................
; Save updated delay pointer back to instance [57].
;............................................................................

    mov.l     w10, [w0 + #lmsPState_q31]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Exit: restore saved registers [57].
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_lms_exit:
    pop.l     YMODEND
    pop.l     YMODSRT
    pop.l     XMODEND
    pop.l     XMODSRT
    pop.l     MODCON

    pop.l     CORCON

    pop.l     w14
    pop.l     w13
    pop.l     w12
    pop.l     w11
    pop.l     w10
    pop.l     w9
    pop.l     w8

    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF