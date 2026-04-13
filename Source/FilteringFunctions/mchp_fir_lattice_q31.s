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
    .include    "dspcommon.inc"
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_fir_lattice_q31: Q31 FIR lattice filter processing.
;
; Description:
;    Implements the CMSIS arm_fir_lattice_q31 algorithm (addition convention).
;    Structure follows firlatt_aa.s with mac.l instead of msc.l.
;
; Operation:
;    f(0)[n] = g(0)[n] = x[n]
;    f(m)[n] = f(m-1)[n] + k(m-1) * g(m-1)[n-1]
;    g(m)[n] = k(m-1) * f(m-1)[n] + g(m-1)[n-1]
;    y[n]    = f(M)[n]
;
; Input:
;    w0 = S          ptr to mchp_fir_lattice_instance_q31
;    w1 = pSrc       (const q31_t*) input vector
;    w2 = pDst       (q31_t*) output vector
;    w3 = blockSize  (uint32) number of input samples (N)
;
; Register mapping (CMSIS -> reference firlatt_aa.s):
;    CMSIS: w0=S, w1=pSrc, w2=pDst, w3=blockSize
;    Ref:   w0=N, w1=y,    w2=x,    w3=h (struct ptr)
;    After remapping:
;    w0 = N (blockSize, outer DTB counter)
;    w1 = pSrc (input pointer, like ref w2=x)
;    w2 = pDst (output pointer, like ref w1=y)
;    w3 = f(m) scratch (like ref w3)
;
; System resources usage:
;    {w0..w10}   used, not restored
;     AccuA      used, not restored
;     AccuB      used, not restored
;     CORCON     saved, used, restored
;
;............................................................................

    .global    _mchp_fir_lattice_q31    ; export

_mchp_fir_lattice_q31:

;............................................................................
; Save working registers.
;............................................................................

    push.l    w8
    push.l    w9
    push.l    w10

;............................................................................
; Prepare CORCON for fractional computation.
;............................................................................

    push.l    CORCON
    fractsetup w5

;............................................................................
; Save pDst for return cleanup (matches ref push.l w1).
;............................................................................

    push.l    w2

;............................................................................
; Load instance structure fields.
;   CMSIS struct: {numStages@0, pCoeffs@4, pState@8}
;   (equates: firLatticeNumStages_q31=0, firLatticePCoeffs_q31=4, firLatticePState_q31=8)
;............................................................................

    mov.l    [w0 + #firLatticePCoeffs_q31], w8   ; w8 -> k[0]
    mov.l    [w0 + #firLatticeNumStages_q31], w5 ; w5 = M (numStages)
    mov.l    [w0 + #firLatticePState_q31], w9    ; w9 -> del[0]

;............................................................................
; Setup for filtering (matches reference exactly).
;   w0 = N (blockSize, outer loop counter)
;   w1 = pSrc (input pointer)
;   w2 = pDst (output pointer)
;   w3 = f(m) scratch
;   w5 = M - 1 (inner loop count for DTB)
;   w7 = del[0] base (rewind copy)
;   w8 = k pointer (walking)
;   w9 = del pointer (walking)
;   w10 = k[0] base (rewind copy)
;............................................................................

    mov.l    w3, w0                    ; w0 = N (blockSize)
    mov.l    w8, w10                   ; w10 -> k[0] (for rewind)
    mov.l    w9, w7                    ; w7  -> del[0] (for rewind)
    sub.l    #1, w5                    ; w5 = M - 1

    cp0.l    w0
    bra      z, _latt_exit_nopop

;............................................................................
; Outer loop: filter N input samples.
;   Directly follows firlatt_aa.s.
;............................................................................

startFilter_q31:

    ;--------------------------------------------------------------------
    ; For m = 0 (recursion set up).
    ;--------------------------------------------------------------------

    lac.l    [w1++], a                 ; a = f(0)[n] = x[n]; w1 -> x[n+1]
    sac.l    a, w3                     ; w3 = x[n] = f(0)[n] (tmp, truncated)
    mov.l    [w9], w6                  ; w6 = g(0)[n-1]
    sac.l    a, [w9++]                 ; del[0] = g(0)[n] = x[n]; w9 -> del[1]

    ;--------------------------------------------------------------------
    ; For 1 <= m < M (recursion proper).
    ; Reference uses push/pop w5 to preserve DTB count across iterations.
    ;--------------------------------------------------------------------

    push.l   w5                        ; save (M-1) for next sample

startRecurse_q31:

    ; Upper branch: f(m)[n] = f(m-1)[n] + k(m-1) * g(m-1)[n-1]
    ; AccuA already holds f(m-1)[n].
    mac.l    [w8], w6, a               ; a += k[m-1] * g_prev => a = f(m)[n]

    ; Lower branch: g(m)[n] = k(m-1) * f(m-1)[n] + g(m-1)[n-1]
    lac.l    w6, b                     ; b = g(m-1)[n-1]
    mac.l    [w8], w3, b              ; b += k[m-1] * f_prev => b = g(m)[n]
    sac.l    a, w3                     ; w3 = truncate(a) = f(m)[n]
    add.l    #4, w8                    ; w8 -> k[m] (next coeff)

    ; Update state.
    mov.l    [w9], w6                  ; w6 = g(m)[n-1] (next stage's g_prev)
    sac.l    b, [w9++]                 ; del[m] = g(m)[n]; w9 -> del[m+1]

    ; Inner DTB loop.
    dtb      w5, startRecurse_q31

    pop.l    w5                        ; restore (M-1)

    ;--------------------------------------------------------------------
    ; For m = M (generate output).
    ; y[n] = f(M)[n] = f(M-1)[n] + k(M-1) * g(M-1)[n-1]
    ;--------------------------------------------------------------------

    mac.l    [w8], w6, a               ; a = f(M)[n]
    sac.l    a, [w2++]                 ; y[n] = f(M)[n]; w2 -> y[n+1]

    ;--------------------------------------------------------------------
    ; Rewind pointers.
    ;--------------------------------------------------------------------

    mov.l    w10, w8                   ; w8 -> k[0]
    mov.l    w7, w9                    ; w9 -> del[0]

    dtb      w0, startFilter_q31

;............................................................................
; Exit: discard saved pDst and restore registers.
;............................................................................

    pop.l    w0                        ; discard saved pDst

_latt_exit:
    pop.l    CORCON
    pop.l    w10
    pop.l    w9
    pop.l    w8

    return

;............................................................................
; Early exit when N == 0 (must pop saved pDst).
;............................................................................

_latt_exit_nopop:
    pop.l    w0                        ; discard saved pDst
    bra      _latt_exit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF
