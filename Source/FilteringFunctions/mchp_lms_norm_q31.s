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
; _mchp_lms_norm_q31: Q31 FIR filtering with Normalized LMS adaptation.
;
; Description:
;    Follows firlmsn_aa.s reference (DTB replaces repeat).
;
;    For each sample n:
;      1. b = E[n-1] + x[n]^2         (sqrac.l)
;      2. Store x[n] in delay; first FIR product (mpy.l)
;      3. Save intermediate energy
;      4. FIR middle + last MACs
;      5. Capture oldest sample x[n-M+1]
;      6. y[n] = sacr.l a
;      7. E[n] = intermediate - x[n-M+1]^2
;      8. nu = mu / (mu + E[n])
;      9. e[n] = r[n] - y[n]; attErr = nu * e[n]
;     10. h[m] += attErr * x[n-m]
;
; Input:
;    w0 = S       ptr to mchp_lms_norm_instance_q31
;    w1 = pSrc    (const q31_t*) input samples x[n]
;    w2 = pRef    (const q31_t*) reference samples r[n]
;    w3 = pDst    (q31_t*) output samples y[n]
;    w4 = pErr    (q31_t*) error output e[n]
;    w5 = N       (uint32) number of samples to process
;
; Return:
;    (void)
;
; Instance structure layout (from dspcommon.inc):
;    [S + 0 ]  numTaps (M)        lmsNormNumTaps_q31
;    [S + 4 ]  pState             lmsNormPState_q31
;    [S + 8 ]  pCoeffs            lmsNormPCoeffs_q31
;    [S + 12]  mu                 lmsNormMu_q31
;    [S + 16]  energy             lmsNormEnergy_q31
;
; Stack layout during main loop (offsets from w15):
;    [w15-4]   M-2 (saved loop count)
;    [w15-8]   energy E[n] (running)
;    [w15-12]  S (struct pointer)
;
; Register map:
;    w0  = N (sample counter for DTB)
;    w1  = pSrc running
;    w3  = pDst running
;    w4  = pErr running
;    w5  = scratch (oldest sample, div result, attErr)
;    w6  = mu
;    w7  = scratch (M-2 loop count)
;    w8  = coeff pointer (X modulo)
;    w9  = linear coeff pointer for adaptation
;    w10 = delay pointer (Y modulo)
;    w11 = energy storage pointer (points into stack)
;    w12 = pRef running
;    w13 = scratch
;    w14 = scratch
;
; System resources usage:
;    {w0..w14}   used, not restored
;     AccuA      used, not restored
;     AccuB      used, not restored
;     CORCON     saved, used, restored
;     MODCON     saved, used, restored
;     XMODSRT/END, YMODSRT/END saved, used, restored
;
;............................................................................

    .extern _lmsNormPStateStart_q31

    .global _mchp_lms_norm_q31    ; export

_mchp_lms_norm_q31:

;............................................................................
; Save working registers.
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
    bra       z, _lmsn_exit

;............................................................................
; Setup modulo addressing.
;............................................................................

    mov.l     #0xC0A8, w10
    mov.l     w10, MODCON

;............................................................................
; Load instance fields and setup modulo windows.
;............................................................................

    mov       [w0 + #lmsNormNumTaps_q31], w7  ; w7 = M
    sl.l      w7, #2, w9                      ; w9 = M * 4
    sub.l     #1, w9                          ; w9 = M*4 - 1

    ; X modulo: coefficients.
    mov.l     [w0 + #lmsNormPCoeffs_q31], w8
    mov.l     w8, XMODSRT
    add.l     w8, w9, w14
    mov.l     w14, XMODEND

    ; Y modulo: delay/state.
    mov.l     _lmsNormPStateStart_q31, w10
    mov.l     w10, YMODSRT
    add.l     w10, w9, w14
    mov.l     w14, YMODEND

;............................................................................
; Load current delay pointer from instance.
;............................................................................

    mov.l     [w0 + #lmsNormPState_q31], w10

;............................................................................
; Prepare filtering registers.
;............................................................................

    mov.l     w2, w12                          ; w12 = pRef
    mov.l     [w0 + #lmsNormMu_q31], w6       ; w6 = mu

    ; w11 = pointer to energy field in struct (for lac.l/sacr.l access).
    ; Reference uses w11 -> E storage, accessed with [w11].
    add.l     w0, #lmsNormEnergy_q31, w11      ; w11 -> &S->energy

    ; Push S and M-2 onto stack.
    push.l    w0                               ; [w15-8] = S
    sub.l     w7, #2, w7                       ; w7 = M - 2
    push.l    w7                               ; [w15-4] = M-2

    ; Use w0 as sample counter N (like reference).
    mov.l     w5, w0                           ; w0 = N

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Main sample loop.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_lmsn_startFilter:

;............................................................................
; Step 1: Pre-add energy: b = E[n-1] + x[n]^2.
;............................................................................

    lac.l     [w11], b                          ; b = E[n-1]
    sqrac.l   [w1], b                          ; b += x[n]^2

;............................................................................
; Step 2: Store x[n] in delay, first FIR product.
;............................................................................

    mov.l     [w1++], [w10]                    ; delay[p] = x[n]; pSrc++
    mpy.l     [w8]+=4, [w10]+=4, a             ; a = h[0]*d[0]

    ; Save intermediate energy.
    sacr.l    b, [w11]                         ; *w11 = E[n-1]+x[n]^2

;............................................................................
; Step 3: FIR middle MACs (M-2 via DTB).
;............................................................................

    mov.l     [w15-4], w7                      ; w7 = M - 2

    cp0.l     w7
    bra       n, _lmsn_firDone                 ; M == 1
    bra       z, _lmsn_lastMAC                 ; M == 2

_lmsn_innerMAC:
    mac.l     [w8]+=4, [w10]+=4, a
    DTB       w7, _lmsn_innerMAC

;............................................................................
; Step 4: Capture oldest sample, last FIR MAC.
; w10 now points at delay[p+M-1] = x[n-M+1] (oldest).
;............................................................................

_lmsn_lastMAC:
    mov.l     [w10], w5                        ; w5 = x[n-M+1]
    mac.l     [w8]+=4, [w10]+=4, a             ; a += h[M-1]*d[M-1]
                                                ; w8→h[0], w10→d[p] (wrapped)

_lmsn_firDone:

;............................................................................
; Step 5: Store FIR output y[n].
;............................................................................

    sacr.l    a, [w3]                          ; y[n] stored (don't advance yet)

;............................................................................
; Step 6: Complete energy: E[n] = (E[n-1]+x[n]^2) - x[n-M+1]^2.
;............................................................................

    sqr.l     w5, b                            ; b = x[n-M+1]^2
    lac.l     [w11], a                         ; a = E[n-1]+x[n]^2
    sub       a                                ; a -= b → E[n]
    sacr.l    a, [w11]                         ; Save E[n]

;............................................................................
; Step 7: nu = mu / (mu + E[n]).
; Reference: add.l w6,a; sacr.l a,w5; divfl w6,w5
;............................................................................

    add.l     w6, a                            ; a = E[n] + mu
    sacr.l    a, w5                            ; w5 = mu + E[n]

    push.l    w6                               ; Save mu (divfl clobbers it)
    repeat    #9
    divfl     w6, w5                           ; w6 = mu/(mu+E[n]) = nu

;............................................................................
; Step 8: Error and attenuated error.
; e[n] = r[n] - y[n]; attErr = nu * e[n]
;............................................................................

    lac.l     [w3++], a                        ; a = y[n]; advance pDst
    lac.l     [w12++], b                       ; b = r[n]; advance pRef
    sub       b                                ; b = r[n] - y[n]
    sacr.l    b, w5                            ; w5 = e[n]

    ; Store error output.
    mov.l     w5, [w4++]                       ; *pErr++ = e[n]

    ; attErr = nu * e[n]
    mpy.l     w5, w6, a                        ; a = e[n] * nu
    sacr.l    a, w5                            ; w5 = attErr
    pop.l     w6                               ; Restore mu

;............................................................................
; Step 9: Coefficient adaptation.
; h[m] += attErr * x[n-m], using lac.l / mac.l / sacr.l
;............................................................................

    mov.l     w8, w9                           ; w9 → h[0] (linear)
    mov.l     [w15-4], w7                      ; w7 = M - 2
    add.l     w7, #1, w7                       ; w7 = M - 1

_lmsn_startAdapt:
    lac.l     [w9], a
    mac.l     w5, [w10]+=4, a
    sacr.l    a, [w9++]
    DTB       w7, _lmsn_startAdapt

    ; Last coefficient (no delay advance).
    lac.l     [w9], a
    mac.l     w5, [w10], a
    sacr.l    a, [w9]

;............................................................................
; Next sample.
;............................................................................

    DTB       w0, _lmsn_startFilter

;............................................................................
; Clean up: unstack M-2, energy, S.
;............................................................................

    pop.l     w7                               ; Remove M-2
    pop.l     w13                              ; w13 = S (struct pointer)

;............................................................................
; Save updated state back to instance.
; Energy was already written to [w11] = &S->energy throughout the loop.
;............................................................................

    mov.l     w10, [w13 + #lmsNormPState_q31]  ; Save delay pointer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Exit.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_lmsn_exit:
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
