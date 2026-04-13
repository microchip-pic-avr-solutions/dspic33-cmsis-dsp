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
; _mchp_biquad_cascade_df1_q31: Q31 cascade biquad IIR, Direct Form I.
;
; Description:
;    Processes a block of Q31 input samples through a cascade of second-
;    order IIR sections implemented in Direct Form I.
;
;    Direct Form I difference equation per section:
;
;      y[n] = b0*x[n] + b1*x[n-1] + b2*x[n-2] - a1*y[n-1] - a2*y[n-2]
;
;    This topology uses separate input (x) and output (y) delay lines:
;      - No feedback dependency within the feedforward (b) path
;      - Feedback (a) path uses previous output values (already computed)
;      - All 5 multiply-accumulates can be pipelined efficiently
;
;    Matches the iircan_aa.s parallel-load MAC pipeline style [41]:
;      - Uses mpy.l / mac.l / msc.l with auto-increment pointers
;      - Single DTB for sample loop (no stack-based counters)
;      - No push/pop inside the sample loop
;      - ~8-10 cycles per sample per section
;
;    The output of one section feeds the input of the next (cascade).
;
; Input:
;    w0 = S          ptr to mchp_biquad_cascade_df1_instance_q31
;    w1 = pSrc       (const q31_t*) input samples
;    w2 = pDst       (q31_t*) output samples
;    w3 = blockSize  (uint32) number of samples to process
;
; Return:
;    (void)
;
; Instance structure layout:
;    [S + iirCasNumStage_q31]  = numStages (uint8)
;    [S + iirCasPCoeffs_q31]   = pCoeffs   (const q31_t*)
;                                 layout: [b0,b1,b2,a1,a2] per stage
;    [S + iirCasPState_q31]    = pState    (q31_t*)
;                                 layout: [xn1,xn2,yn1,yn2] per stage
;
; System resources usage:
;    {w0..w9}    used, not restored
;    {w8,w9}     saved, used, restored
;     AccuA      used, not restored
;     CORCON     saved, used, restored
;
; DF1 state layout per section (4 x q31_t = 16 bytes):
;    Offset 0:  x[n-1]
;    Offset 4:  x[n-2]
;    Offset 8:  y[n-1]
;    Offset 12: y[n-2]
;
; Coefficient layout per section (5 x q31_t = 20 bytes):
;    Offset 0:  b0
;    Offset 4:  b1
;    Offset 8:  b2
;    Offset 12: a1
;    Offset 16: a2
;
; Cycle count per sample per section: ~10 cycles
;   (5 MAC operations + state update + DTB)
;
;............................................................................

    .global    _mchp_biquad_cascade_df1_q31    ; export

_mchp_biquad_cascade_df1_q31:

;............................................................................
; Save working registers (minimal, like iircan_aa.s) [41].
;............................................................................

    push.l    w8
    push.l    w9

;............................................................................
; Prepare CORCON for fractional computation.
;............................................................................

    push.l    CORCON
    fractsetup w5

;............................................................................
; Early exit if blockSize == 0.
;............................................................................

    cp0.l     w3
    bra       z, _df1_exit

;............................................................................
; Load instance structure fields [40].
;............................................................................

    mov.l     #0, w4                             ; Zero w4 before byte load.
    mov.b     [w0 + #iirCasNumStage_q31], w4  ; w4 = numStages (zero-extended)
    mov.l     [w0 + #iirCasPCoeffs_q31], w8   ; w8 -> b0 of stage 0
    mov.l     [w0 + #iirCasPState_q31], w9    ; w9 -> xn1 of stage 0

;............................................................................
; Save pDst and blockSize for cascade [40].
;............................................................................

    push.l    w2                               ; Save pDst base.
    push.l    w3                               ; Save blockSize.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Stage loop: process each biquad section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_df1_startStage:

    ; Save coeff and state base pointers for this section.
    mov.l     w8, w5                           ; w5 -> coeff base (b0) for this section.
    mov.l     w9, w6                           ; w6 -> state base (xn1) for this section.

    ; Reload blockSize for this stage.
    mov.l     [w15-4], w3                      ; w3 = blockSize (from stack).

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sample loop: DF1 biquad butterfly.
;
;   y[n] = b0*x[n] + b1*x[n-1] + b2*x[n-2] - a1*y[n-1] - a2*y[n-2]
;
;   Register map:
;     w1  = pSrc (running, post-increment)
;     w2  = pDst (running, post-increment)
;     w3  = blockSize (DTB counter)
;     w5  = coeff base (b0, rewound each sample)
;     w6  = state base (xn1, rewound each sample)
;     w7  = scratch (x[n], y[n])
;     w8  = running coeff pointer (auto-increment via MAC)
;     w9  = scratch for state reads
;     AccuA = computation accumulator
;
;   Pipeline:
;     1. a  = b0 * x[n]           (mpy.l)         — 1 cycle
;     2. a += b1 * x[n-1]         (mac.l)         — 1 cycle
;     3. a += b2 * x[n-2]         (mac.l)         — 1 cycle
;     4. a -= a1 * y[n-1]         (msc.l)         — 1 cycle
;     5. a -= a2 * y[n-2]         (msc.l)         — 1 cycle
;     6. y[n] = sacr.l a          (store output)   — 1 cycle
;     7. State update: shift x/y  (mov.l x 4)     — 2-3 cycles
;     8. DTB                                       — 1 cycle
;                                 Total: ~9-10 cycles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_df1_startSample:

    ; Reset coeff pointer to section base.
    mov.l     w5, w8                           ; w8 -> b0.

    ;=== Load x[n] ===
    mov.l     [w1++], w7                       ; w7 = x[n], advance pSrc.

    ;=== MAC 1: a = b0 * x[n] ===
    mpy.l     [w8]+=4, w7, a                   ; a = b0 * x[n].
                                                ; w8 -> b1.

    ;=== MAC 2: a += b1 * x[n-1] ===
    mov.l     [w6], w9                         ; w9 = x[n-1] (state offset 0).
    mac.l     [w8]+=4, w9, a                   ; a += b1 * x[n-1].
                                                ; w8 -> b2.

    ;=== MAC 3: a += b2 * x[n-2] ===
    mov.l     [w6+4], w9                       ; w9 = x[n-2] (state offset 4).
    mac.l     [w8]+=4, w9, a                   ; a += b2 * x[n-2].
                                                ; w8 -> a1.

    ;=== MSC 4: a -= a1 * y[n-1] ===
    mov.l     [w6+8], w9                       ; w9 = y[n-1] (state offset 8).
    msc.l     [w8]+=4, w9, a                   ; a -= a1 * y[n-1].
                                                ; w8 -> a2.

    ;=== MSC 5: a -= a2 * y[n-2] ===
    mov.l     [w6+12], w9                      ; w9 = y[n-2] (state offset 12).
    msc.l     [w8]+=4, w9, a                   ; a -= a2 * y[n-2].
                                                ; w8 -> b0 of NEXT section.

    ;=== Extract y[n] ===
    sacr.l    a, w9                            ; w9 = y[n] (32-bit saturated result).

    ;=== State update (shift delay lines) ===
    ; NOTE: mov.l does not support memory-to-memory indirect addressing
    ; on dsPIC33AK, so we route through a temp register.

    ; x[n-2] = x[n-1]  (shift x delay via temp w7, after saving x[n])
    push.l    w7                               ; save x[n] on stack.
    mov.l     [w6], w7                         ; w7 = state[0] (x[n-1]).
    mov.l     w7, [w6+4]                       ; state[1] = x[n-1].
    pop.l     w7                               ; restore w7 = x[n].

    ; x[n-1] = x[n]    (store newest input)
    mov.l     w7, [w6]                         ; state[0] = x[n].

    ; y[n-2] = y[n-1]  (shift y delay via temp w7, now free)
    mov.l     [w6+8], w7                       ; w7 = state[2] (y[n-1]).
    mov.l     w7, [w6+12]                      ; state[3] = y[n-1].

    ; y[n-1] = y[n]    (store newest output)
    mov.l     w9, [w6+8]                       ; state[2] = y[n].

    ;=== Store output y[n] ===
    mov.l     w9, [w2++]                       ; *pDst++ = y[n].

    ;=== Next sample ===
    DTB       w3, _df1_startSample             ; Decrement blockSize;
                                                ; branch if not zero.

;............................................................................
; Advance pointers for next section.
;............................................................................

    ; Coeff pointer already advanced to next section's b0 by
    ; the last msc.l [w8]+=4 in the MAC chain. Save it.
    ; (w8 is already at next section start.)

    ; State pointer: advance by 16 bytes (4 x q31_t per section).
    add.l     w6, #16, w9                      ; w9 -> next section's state.

;............................................................................
; Cascade feed: next stage's pSrc = this stage's pDst (rewind).
;............................................................................

    mov.l     [w15-8], w1                      ; w1 = pDst base (becomes pSrc).
    mov.l     [w15-8], w2                      ; w2 = pDst base (rewind for next stage).

;............................................................................
; Next stage.
;............................................................................

    DTB       w4, _df1_startStage              ; Decrement numStages;
                                                ; branch if not zero.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; All stages completed.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Clean up stack (saved pDst, blockSize).
    sub.l     #8, w15

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Exit.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_df1_exit:
    pop.l     CORCON
    pop.l     w9
    pop.l     w8

    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF
