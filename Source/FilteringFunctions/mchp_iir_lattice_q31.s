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
; _mchp_iir_lattice_q31: Q31 IIR lattice filter processing.
;
; Description:
;    Performs IIR lattice filtering on a block of Q31 input samples.
;    Algorithm follows iirlatt_aa.s reference exactly.
;
;    ## Lattice structure (for each sample):
;      current = x[n]
;      for m = 0 to M-1:
;        after    = current  - k[M-1-m] * d[m+1]
;        d[m]     = d[m+1]  + k[M-1-m] * after
;        current  = after
;      end
;      d[M] = after
;
;    ## Ladder structure (computes output):
;      y[n] = sum_{m=0:M} g[m] * d[M-m]
;
;    Lattice uses pre-loaded register operands for msc.l to avoid
;    the msc.l [Ws],[Wt],Acc form. The lower branch uses
;    mac.l [w8]-=4, w6, a (proven working form).
;    Ladder uses repeat / mac.l with two memory-indirect operands.
;
; Input:
;    w0 = S          ptr to mchp_iir_lattice_instance_q31
;    w1 = pSrc       (const q31_t*) input vector
;    w2 = pDst       (q31_t*) output vector
;    w3 = blockSize  (uint32_t) number of input samples (N)
;
; Return:
;    (void)
;
; Instance structure layout (CMSIS):
;    [S + 0]  = numStages  (uint16_t, M)
;    [S + 4]  = pState     (q31_t*)    -> d[0..M]
;    [S + 8]  = pkCoeffs   (q31_t*)    -> k[0..M-1]
;    [S + 12] = pvCoeffs   (q31_t*)    -> g[0..M]
;
; After register remap (to match iirlatt_aa.s):
;    w0  = N (outer loop counter)
;    w1  = pDst (output pointer, post-incremented)
;    w2  = pSrc (input pointer, post-incremented)
;    w3  = S (struct pointer)
;    w4  = k[M-1] pointer (saved for rewind)
;    w5  = d[0] (state base, incremented during lattice, rewound)
;    w6  = scratch (after value in lattice)
;    w7  = DTB loop counter / repeat count (M-2 on stack)
;    w8  = k pointer (walks from k[M-1] down during lattice)
;    w9  = d pointer (walks from d[1] up during lattice)
;    w10 = scratch (pre-loaded d value)
;
; System resources usage:
;    {w0..w10}   used, not restored
;     AccuA      used, not restored
;     CORCON     saved, used, restored
;
; Notes:
;    - pkCoeffs array length = M.
;    - pvCoeffs array length = M + 1.
;    - pState array length   = M + 1.
;    - Each element is Q31 (4 bytes).
;    - numStages is uint16_t in the C struct.
;    - Minimum numStages = 3 (same constraint as reference library).
;
;............................................................................

    .global    _mchp_iir_lattice_q31    ; export

_mchp_iir_lattice_q31:

;............................................................................
; Save working registers.
;............................................................................

    push.l    w8                     ; Save w8.
    push.l    w9                     ; Save w9.
    push.l    w10                    ; Save w10.

;............................................................................
; Prepare CORCON for fractional computation.
;............................................................................

    push.l    CORCON                 ; Save 32-bit CORCON.
    fractsetup w8                    ; Setup CORCON for fractional/saturating
                                      ; arithmetic; w8 used as scratch by macro.

;............................................................................
; Early exit if blockSize == 0.
;............................................................................

    cp0.l     w3
    bra       z, _iir_latt_exit

;............................................................................
; Remap registers to match reference iirlatt_aa.s convention:
;   CMSIS entry:     w0=S, w1=pSrc, w2=pDst, w3=blockSize
;   Reference needs: w0=N, w1=pDst, w2=pSrc, w3=S
;............................................................................

    mov.l     w0, w6                 ; w6 = S (temp save)
    mov.l     w3, w0                 ; w0 = N (blockSize = outer loop counter)
    mov.l     w2, w3                 ; w3 = pDst (temp, will go to w1)
    mov.l     w1, w2                 ; w2 = pSrc (input)
    mov.l     w3, w1                 ; w1 = pDst (output)
    mov.l     w6, w3                 ; w3 = S (struct pointer)

;............................................................................
; Load instance structure fields.
;............................................................................

    mov       [w3 + #iirLatticeNumStage_q31], w7  ; w7 = M (16-bit load)
    ze        w7, w7                 ; Zero-extend to 32 bits.
    mov.l     [w3 + #iirLatticePState_q31], w5     ; w5 -> d[0]
    mov.l     [w3 + #iirLatticePkCoeffs_q31], w8   ; w8 -> k[0]

;............................................................................
; Setup for filtering.
;............................................................................

    sub.l     #1, w7                 ; w7 = M - 1
    sl.l      w7, #2, w4             ; w4 = (M-1) * 4 bytes
    add.l     w5, #4, w9             ; w9 -> d[1]
    add.l     w4, w8, w8             ; w8 -> k[M-1]
    mov.l     w8, w4                 ; w4 -> k[M-1] (saved for rewind)
    sub.l     #1, w7                 ; w7 = M - 2
    push.l    w7                     ; Save (M-2) on stack.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Outer loop: filter N input samples.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_startFilter_q31:

;............................................................................
; Lattice structure.
; Get new input sample: a = x[n] (current in accumulator).
;............................................................................

    lac.l     [w2++], a              ; a = x[n] (current)
                                      ; w2 -> x[n+1]

;............................................................................
; Inner lattice loop: M-2 iterations (DTB).
;
; Each iteration:
;   1. Pre-load d[m+1] into w10 from [w9].
;   2. msc.l [w8], w10, a           ; a -= k[M-1-m] * d[m+1]
;                                    ; (one memory indirect + one register)
;   3. sacr.l a, w6                 ; w6 = after
;   4. lac.l w10, a                 ; a = d[m+1] (already in register)
;   5. mac.l [w8]-=4, w6, a         ; a += k[M-1-m] * after; w8 decrements
;   6. sacr.l a, [w5++]             ; d[m] stored; w5 advances
;   7. lac.l w6, a                  ; a = after = new current
;   8. add.l w9, #4, w9             ; w9 -> d[m+2]
;   9. dtb w7, loop
;............................................................................

_startLattice_q31:

    ; Pre-load d[m+1] into register w10.
    mov.l     [w9], w10              ; w10 = d[m+1]

    ; Upper branch: after = current - k[M-1-m] * d[m+1].
    ; Use msc.l with one memory-indirect operand [w8] and one register w10.
    msc.l     [w8], w10, a           ; a -= k[M-1-m] * d[m+1]

    sacr.l    a, w6                  ; w6 = after

    ; Lower branch: d[m] = d[m+1] + k[M-1-m] * after.
    lac.l     w10, a                 ; a = d[m+1] (from register)
    mac.l     [w8]-=4, w6, a         ; a += k[M-1-m] * after
                                      ; w8 -> k[M-2-m]

    sacr.l    a, [w5++]              ; d[m] (updated); w5 -> d[m+1]
    lac.l     w6, a                  ; a = after = current (next)

    add.l     w9, #4, w9             ; w9 -> d[m+2] (advance d pointer)

    dtb       w7, _startLattice_q31  ; Decrement w7; branch if not zero.

;............................................................................
; Restore w7 = M-2 from stack (for ladder repeat count later).
;............................................................................

    mov.l     [w15-4], w7            ; w7 = M-2

;............................................................................
; One-before-last iteration.
; Upper branch: after = current - k[1] * d[M-2+1].
;............................................................................

    mov.l     [w9], w10              ; w10 = d[M-1]
    msc.l     [w8], w10, a           ; a -= k[1] * d[M-1]

    sacr.l    a, w6                  ; w6 = after

    ; Lower branch: d[M-2] = d[M-2+1] + k[1] * after.
    lac.l     w10, a                 ; a = d[M-1]
    mac.l     [w8]-=4, w6, a         ; a += k[1] * after
                                      ; w8 -> k[0]

    sacr.l    a, [w5++]              ; d[M-2] (updated); w5 -> d[M-1]
    lac.l     w6, a                  ; a = after = current (last)

    add.l     w9, #4, w9             ; w9 -> d[M]

;............................................................................
; Last iteration.
; Upper branch: after = current - k[0] * d[M].
;............................................................................

    mov.l     [w9], w10              ; w10 = d[M]
    msc.l     [w8], w10, a           ; a -= k[0] * d[M]

    sacr.l    a, w6                  ; w6 = after

    ; Lower branch: d[M-1] = d[M] + k[0] * after.
    lac.l     w10, a                 ; a = d[M]
    mac.l     [w8], w6, a            ; a += k[0] * after (no decrement)

    sacr.l    a, [w5++]              ; d[M-1] (updated); w5 -> d[M]

    ; Update last delay: d[M] = after.
    mov.l     w6, [w5]               ; d[M] = after

;............................................................................
; Ladder structure.
; Compute y[n] = sum_{m=0:M} g[m] * d[M-m].
;
; w8 -> g[0] (loaded from struct), walks forward with +=4.
; w5 -> d[M] (from lattice end), walks backward with -=4.
; repeat w7 for (M-2)+1 = M-1 iterations (middle products).
; + first mpy.l + last mac.l = M+1 total products.
;............................................................................

    ; Load pvCoeffs pointer -> w8 (g[0]).
    mov.l     [w3 + #iirLatticePvCoeffs_q31], w8  ; w8 -> g[0]

    ; First product: g[0] * d[M].
    mpy.l     [w8]+=4, [w5]-=4, a    ; a = g[0] * d[M]
                                      ; w8 -> g[1], w5 -> d[M-1]

    ; Middle products: (M-2)+1 = M-1 iterations.
    repeat    w7                      ; repeat (M-2)+1 = M-1 times
    mac.l     [w8]+=4, [w5]-=4, a    ; a += g[m+1] * d[M-m-1]

    ; Last product: g[M] * d[0].
    mac.l     [w8], [w5], a           ; a += g[M] * d[0]

;............................................................................
; Store output y[n].
;............................................................................

    sacr.l    a, [w1++]              ; y[n] = ladder result
                                      ; w1 -> y[n+1]

;............................................................................
; Rewind pointers for next sample.
;............................................................................

    mov.l     w4, w8                 ; w8 -> k[M-1] (rewind)
    add.l     w5, #4, w9             ; w9 -> d[1]

    dtb       w0, _startFilter_q31   ; Decrement N; branch if not zero.

;............................................................................
; Clean up stack: remove saved (M-2).
;............................................................................

    sub.l     #4, w15                ; Unstack push.l w7

;............................................................................
; Exit: restore saved registers.
;............................................................................

_iir_latt_exit:
    pop.l     CORCON                 ; Restore 32-bit CORCON.
    pop.l     w10                    ; Restore w10.
    pop.l     w9                     ; Restore w9.
    pop.l     w8                     ; Restore w8.

    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF
