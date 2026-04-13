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
; _mchp_fir_interpolate_q31: Q31 FIR interpolation filter.
;
; Description:
;    Performs FIR interpolation (1:L) on a block of Q31 input samples.
;    For every 1 input sample, L output samples are produced.
;
;    The filter has M total taps with M/L taps per polyphase sub-filter.
;    The delay line holds M/L samples.
;
;    Inner MAC loop uses the same addressing pattern as firinter_aa.s [51]:
;      - Coefficients are accessed with stride R (L*4 bytes) between
;        polyphase taps: h[k], h[k+L], h[k+2L], ...
;      - Delay line is accessed sequentially (backwards): d[M/L-1], d[M/L-2], ...
;
;    dsPIC33AK: uses DTB (no REPEAT instruction).
;
; Operation:
;    For each input sample x[n]:
;      Store x[n] into delay line.
;      For k = 0 to L-1:
;        y[L*n + k] = sum_{j=0:q-1} h[k + j*L] * d[q-1-j]
;      where q = M/L (taps per polyphase sub-filter).
;
; Input:
;    w0 = S          ptr to mchp_fir_interpolate_instance_q31
;    w1 = pSrc       (const q31_t*) input vector
;    w2 = pDst       (q31_t*) output vector
;    w3 = blockSize  (uint32) number of INPUT samples
;
; Return:
;    (void)
;
; Instance structure layout:
;    [S + firInterL_q31]       = L (interpolation factor, byte)
;    [S + firInterPLen_q31]    = M (total number of taps, word)
;    [S + firInterPCoeffs_q31] = pCoeffs (q31_t*)
;    [S + firInterPState_q31]  = pState  (q31_t*)
;
; System resources usage:
;    {w0..w13}   used, not restored ({w8..w13} saved/restored)
;     AccuA      used, not restored
;     CORCON     saved, used, restored
;
; Notes:
;    - Number of output samples per call = blockSize * L.
;    - M must be a multiple of L.
;    - Delay line length = M/L (= q).
;    - State buffer must hold M/L q31_t values.
;
;............................................................................

    .global _mchp_fir_interpolate_q31    ; export

_mchp_fir_interpolate_q31:

;............................................................................
; Save working registers (mirrors f32 version) [47].
;............................................................................

    push.l    w8
    push.l    w9
    push.l    w10
    push.l    w11
    push.l    w12
    push.l    w13

;............................................................................
; Prepare CORCON for fractional computation.
;............................................................................

    push.l    CORCON
    fractsetup w7

;............................................................................
; Early exit if blockSize == 0.
;............................................................................

    cp0.l     w3
    bra       z, _interp_exit

;............................................................................
; Load instance structure fields [47].
;............................................................................

    mov.l     #0, w6                             ; Zero w6 before byte load.
    mov.b     [w0 + #firInterL_q31], w6       ; w6 = L (interpolation factor)
    mov.l     [w0 + #firInterPCoeffs_q31], w4 ; w4 -> h[0]
    mov.l     [w0 + #firInterPState_q31], w5  ; w5 -> d[0] (delay base)
    mov.l     #0, w13                          ; Zero w13 before word load.
    mov       [w0 + #firInterPLen_q31], w13   ; w13 = M (total taps)

;............................................................................
; Compute q = M / L (taps per polyphase sub-filter) [47].
;............................................................................

    mov.l     w13, w9                          ; w9 = M
    REPEAT    #9
    divul     w9, w6                           ; w9 = M / L = q

;............................................................................
; Compute coefficient stride = L * sizeof(q31_t) = L * 4 bytes [47][51].
;   This is the byte offset between polyphase taps:
;   h[k], h[k+L], h[k+2L], ...
;............................................................................

    sl.l      w6, #2, w12                      ; w12 = L * 4 (coeff stride in bytes)

;............................................................................
; Compute inner MAC loop count = q - 1 [47][51].
;   The inner loop does (q-1) MACs, then the first multiply is done
;   separately to initialize AccuA (or the last MAC is done separately).
;............................................................................

    sub.l     w9, #1, w7                       ; w7 = q - 1 (inner DTB count)

;............................................................................
; Save constants for reload inside loops.
;............................................................................

    push.l    w7                               ; Save (q-1).      [w15-12]
    push.l    w5                               ; Save delay base.  [w15-8]
    push.l    w6                               ; Save L.           [w15-4]

;............................................................................
; Outer loop: process one input sample per iteration.
;   For each input sample x[n]:
;     1. Shift delay line: d[k] = d[k-1] for k = q-1 down to 1.
;     2. Store x[n] into d[0].
;     3. Generate L output samples (one per polyphase sub-filter).
;
;   w1 = running pSrc pointer (input)
;   w2 = running pDst pointer (output)
;   w3 = blockSize (outer DTB counter)
;   w4 = coeff base pointer h[0]
;   w5 = delay base pointer d[0]
;   w6 = L (interpolation factor)
;   w7 = q - 1 (inner loop count)
;   w9 = q (polyphase length)
;   w12 = L*4 (coeff stride bytes)
;............................................................................

_doInter_q31:

;............................................................................
; Step 1: Shift delay line left by one position (matching firinter_aa.s [51]).
;   d[0] = d[1], d[1] = d[2], ... , d[q-2] = d[q-1]
;   Then write new input sample: d[q-1] = x[n].
;   This keeps newest sample at d[q-1] and oldest at d[0].
;
;   Source pointer: &d[1] (shift left)
;   Dest pointer:   &d[0]
;............................................................................

    mov.l     w7, w8                           ; w8 = q - 1 (number of moves)

    ; Set up w10 for writing new sample at d[q-1] after shift.
    ; For q==1: d[q-1] = d[0] = w5. For q>1: w10 will be advanced by shift loop.
    mov.l     w5, w10                          ; w10 -> d[0] (start of delay)

    cp0.l     w8
    bra       z, _skipShift_q31               ; If q == 1, no shifting needed.

    ; Set up for left shift: copy d[1]->d[0], d[2]->d[1], ...
    add.l     w5, #4, w11                      ; w11 -> d[1] (source)

_shiftDelay_q31:
    ; dsPIC33AK: mov.l does not support [Wn],[Wm] (mem-to-mem indirect).
    ; Route through w13 (scratch register).
    mov.l     [w11], w13                       ; w13 = d[k+1]
    mov.l     w13, [w10]                       ; d[k] = d[k+1]
    add.l     w10, #4, w10                     ; move destination forward
    add.l     w11, #4, w11                     ; move source forward
    DTB       w8, _shiftDelay_q31

_skipShift_q31:

    ; Store new input sample at d[q-1] (end of delay, newest position).
    ; w10 now points to d[q-1] after shift (or d[0] if q==1).
    mov.l     [w1++], w8                       ; w8 = x[n], advance pSrc.
    mov.l     w8, [w10]                        ; d[q-1] = x[n].

;............................................................................
; Step 2: Generate L output samples (polyphase sub-filters) [47][51].
;   For k = 0 to L-1:
;     y[L*n + k] = sum_{j=0:q-1} h[k + j*L] * d[q-1-j]
;
;   w11 = running coeff pointer h[k] (starts at h[0], increments by 4 each sub-filter)
;   w10 = running delay read pointer (starts at d[q-1], decrements)
;   w12 = L*4 = coeff stride between polyphase taps
;............................................................................

    mov.l     w4, w11                          ; w11 -> h[0] (first polyphase filter)
    mov.l     [w15-4], w6                      ; Reload L from stack.
    mov.l     [w15-12], w7                     ; Reload (q-1) from stack.

_startOutputs_q31:

    ; Reset delay read pointer to d[q-1] for this sub-filter.
    mov.l     w9, w8                           ; w8 = q
    sub.l     w8, #1, w8                       ; w8 = q - 1
    sl.l      w8, #2, w8                       ; w8 = (q-1) * 4 bytes
    add.l     w5, w8, w10                      ; w10 -> d[q-1]

    ; Initialize accumulator with first multiply [51]:
    ;   AccuA = h[k] * d[q-1]
    mov.l     [w11], w8                        ; w8 = h[k]
    mov.l     [w10--], w13                     ; w13 = d[q-1], w10 -> d[q-2]
    mpy.l     w8, w13, a                       ; a = h[k] * d[q-1]

    ; Save coeff pointer for stride access.
    mov.l     w11, w9                          ; w9 -> h[k] (will be advanced by stride)

    ; Inner MAC loop: j = 1 to q-1 [47][51].
    ;   a += h[k + j*L] * d[q-1-j]
    ;   Coeff access: h[k + j*L] => advance w9 by L*4 bytes each iteration.
    ;   Delay access: d[q-1-j]   => decrement w10 by 4 bytes each iteration.

    mov.l     [w15-12], w7                     ; Reload (q-1) for inner DTB.
    cp0.l     w7
    bra       z, _storeOutput_q31             ; If q == 1, only one tap, skip MAC loop.

_startOutput_q31:
    add.l     w9, w12, w9                      ; w9 -> h[k + (j+1)*L] (stride by L*4)
    mov.l     [w9], w8                         ; w8 = h[k + j*L]
    mov.l     [w10--], w13                     ; w13 = d[q-1-j], decrement
    mac.l     w8, w13, a                       ; a += h[k+j*L] * d[q-1-j]
    DTB       w7, _startOutput_q31

;............................................................................
; Store output sample [47][51].
;............................................................................

_storeOutput_q31:
    ; Advance h[k] pointer to next sub-filter: h[k+1].
    add.l     #4, w11                          ; w11 -> h[k+1]

    ; Reload (q-1) for next sub-filter.
    mov.l     [w15-12], w7

    ; Store output (Q31 saturated).
    sacr.l    a, [w2++]                        ; y[L*n+k] = result, advance pDst.

    ; Reload q (polyphase length) for delay pointer reset.
    mov.l     [w15-12], w8
    add.l     w8, #1, w9                       ; w9 = q (restore)

    ; Next sub-filter (next output of the L outputs).
    DTB       w6, _startOutputs_q31

;............................................................................
; Reload constants from stack for next input sample.
;............................................................................

    mov.l     [w15-4], w6                      ; Reload L.
    mov.l     [w15-8], w5                      ; Reload delay base.
    mov.l     [w15-12], w7                     ; Reload (q-1).
    add.l     w7, #1, w9                       ; Restore q.

;............................................................................
; Next input sample.
;............................................................................

    DTB       w3, _doInter_q31

;............................................................................
; Clean up stack (saved L, delay base, q-1).
;............................................................................

    sub.l     #12, w15                         ; Remove 3 push.l's from stack.

;............................................................................
; Exit: restore saved registers.
;............................................................................

_interp_exit:
    pop.l     CORCON

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