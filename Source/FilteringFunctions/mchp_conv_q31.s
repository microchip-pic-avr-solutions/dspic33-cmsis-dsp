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
    .include    "dspcommon.inc"      ; fractsetup
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_conv_q31: Q31 vector convolution.
;
; Description:
;    Computes the convolution of two Q31 vectors x[] (length N) and
;    h[] (length M), producing output y[] of length (N + M - 1).
;
;    If srcALen < srcBLen, the pointers and lengths are swapped so that
;    the longer vector is always x[] (srcA) and the shorter is h[] (srcB).
;    This ensures the inner MAC loop count is bounded by M.
;
;    The convolution is split into three phases:
;      Phase 1: Partial overlap ramp-up   (output indices 0..M-2)
;      Phase 2: Full overlap              (output indices M-1..N-1)
;      Phase 3: Partial overlap ramp-down (output indices N..N+M-2)
;
;    Phase 2 inner loop is identical to vcon_aa.s [63]:
;      mpy.l / mac.l / sacr.l  using DSP accumulators.
;
;    dsPIC33AK: uses DTB (no REPEAT instruction).
;
; Operation:
;    y[n] = sum_{k=max(0,n-N+1):min(n,M-1)} x[n-k] * h[k]
;    for n = 0 to N + M - 2
;
; Input:
;    w0 = pSrcA     (const q31_t*) pointer to first source vector
;    w1 = srcALen   (uint32)       length of first source vector (N)
;    w2 = pSrcB     (const q31_t*) pointer to second source vector
;    w3 = srcBLen   (uint32)       length of second source vector (M)
;    w4 = pDst      (q31_t*)       pointer to output vector (N+M-1 elements)
;
; Return:
;    (void)
;
; System resources usage:
;    {w0..w9}    used, not restored
;    {w8, w9}    saved, used, restored
;     AccuA      used, not restored
;     CORCON     saved, used, restored
;
; Notes:
;    - Output length = srcALen + srcBLen - 1.
;    - pDst must be pre-allocated for (N+M-1) q31_t elements.
;    - If either length is 0, function returns immediately.
;
;............................................................................

    .global    _mchp_conv_q31    ; export

_mchp_conv_q31:

;............................................................................
; Ensure srcA is the longer vector (swap if needed) [66].
;   If srcALen < srcBLen:
;     swap lengths (w1 <-> w3)
;     swap pointers (w0 <-> w2)
;............................................................................

    cp.l      w1, w3                ; Compare srcALen vs srcBLen.
    bra       ge, _no_swap_q31      ; If srcALen >= srcBLen, no swap needed.

    ; Swap lengths.
    mov.l     w1, w5
    mov.l     w3, w1
    mov.l     w5, w3

    ; Swap pointers.
    mov.l     w0, w5
    mov.l     w2, w0
    mov.l     w5, w2

_no_swap_q31:

;............................................................................
; After swap:
;   w0 = pSrcA (x, longer vector, length N = w1)
;   w1 = N (srcALen, the longer length)
;   w2 = pSrcB (h, shorter vector, length M = w3)
;   w3 = M (srcBLen, the shorter length)
;   w4 = pDst (y, output)
;............................................................................

;............................................................................
; Setup CORCON for fractional computation [66].
;............................................................................

    push.l    CORCON
    fractsetup w5

;............................................................................
; Save working registers [66].
;............................................................................

    push.l    w8
    push.l    w9

;............................................................................
; Save output pointer for return value [66].
;............................................................................

    push.l    w4

;............................................................................
; Early exit if either length is 0.
;............................................................................

    cp0.l     w1
    bra       z, _conv_exit_q31
    cp0.l     w3
    bra       z, _conv_exit_q31

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Phase 1: Partial overlap ramp-up [66].
;   Output indices n = 0 to M-2.
;   Number of MACs increases from 1 to M-1.
;
;   For output y[n]:
;     y[n] = sum_{k=0:n} x[n-k] * h[k]
;
;   x pointer starts at x[n] and walks backwards.
;   h pointer starts at h[0] and walks forward.
;   Number of MACs = n + 1 (increases each output).
;
;   Phase 1 produces (M - 1) output samples.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    mov.l     w3, w5                ; w5 = M
    sub.l     w5, #1, w5            ; w5 = M - 1 (phase 1 output count)
    cp0.l     w5
    bra       z, _phase2_q31       ; If M == 1, skip phase 1.

    mov.l     #1, w6                ; w6 = current MAC count (starts at 1)
    mov.l     w0, w7                ; w7 -> x[0] (x start, will advance)

_phase1_loop_q31:

    ; Setup for this output sample.
    clr       a                     ; AccuA = 0.
    mov.l     w7, w8                ; w8 -> x[n] (walks backwards through x).
    mov.l     w2, w9                ; w9 -> h[0] (walks forward through h).
    mov.l     w6, w5                ; w5 = MAC count for this output.

    ; Inner MAC loop for phase 1.
_phase1_mac_q31:
    mac.l     [w8]-=4, [w9]+=4, a  ; a += x[n-k] * h[k].
                                     ; x ptr decrements, h ptr increments.
    DTB       w5, _phase1_mac_q31

    ; Store output y[n].
    sacr.l    a, [w4++]             ; y[n] = result.

    ; Advance: next output has one more MAC.
    add.l     #1, w6                ; MAC count++.
    add.l     w7, #4, w7            ; w7 -> x[n+1] (advance x start).

    ; More phase 1 outputs?
    sub.l     w3, #1, w5            ; w5 = M - 1 (total phase 1 outputs)
    cp.l      w6, w5
    bra       le, _phase1_loop_q31

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Phase 2: Full overlap [66].
;   Output indices n = M-1 to N-1.
;   Number of MACs = M (constant).
;
;   For output y[n]:
;     y[n] = sum_{k=0:M-1} x[n-k] * h[k]
;
;   x pointer starts at x[n] and walks backwards.
;   h pointer starts at h[0] and walks forward.
;
;   Phase 2 produces (N - M + 1) output samples.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_phase2_q31:

    ; Compute phase 2 output count.
    mov.l     w1, w5                ; w5 = N
    sub.l     w5, w3, w5            ; w5 = N - M
    add.l     #1, w5                ; w5 = N - M + 1 (phase 2 count)
    cp0.l     w5
    bra       z, _phase3_q31       ; If N == M, skip phase 2 (only 0 outputs).

    ; x start pointer for phase 2: x[M-1].
    mov.l     w3, w6                ; w6 = M
    sub.l     w6, #1, w6            ; w6 = M - 1
    sl.l      w6, #2, w6            ; w6 = (M-1) * 4 bytes
    add.l     w0, w6, w7            ; w7 -> x[M-1]

    ; Save phase 2 outer count on stack (DTB counter).
    push.l    w5                    ; [w15-4] = N-M+1 (phase 2 count)

_phase2_loop_q31:

    ; Setup for this output sample.
    mov.l     w7, w8                ; w8 -> x[n] (read pointer, walks backward).
    mov.l     w2, w9                ; w9 -> h[0] (read pointer, walks forward).

    ; First multiply (initialize accumulator).
    mpy.l     [w8]-=4, [w9]+=4, a  ; a = x[n] * h[0].

    ; Remaining MACs: M - 1 total.
    mov.l     w3, w5                ; w5 = M
    sub.l     w5, #2, w5            ; w5 = M - 2 (remaining MACs for DTB).
    cp0.l     w5
    bra       n, _phase2_store_q31 ; M == 1: no more MACs.
    bra       z, _phase2_lastmac_q31 ; M == 2: one more MAC (DTB can't handle 0).

_phase2_mac_q31:
    mac.l     [w8]-=4, [w9]+=4, a  ; a += x[n-k] * h[k].
    DTB       w5, _phase2_mac_q31

_phase2_lastmac_q31:
    ; Last MAC (handles M == 2 case, or falls through from DTB loop).
    mac.l     [w8]-=4, [w9]+=4, a  ; a += x[n-(M-1)] * h[M-1].

_phase2_store_q31:
    ; Store output y[n].
    sacr.l    a, [w4++]             ; y[n] = result.

    ; Advance x start for next output.
    add.l     w7, #4, w7            ; w7 -> x[n+1].

    ; Outer phase 2 loop: decrement saved counter.
    mov.l     [w15-4], w5           ; Reload phase 2 counter from stack.
    sub.l     #1, w5                ; Decrement.
    mov.l     w5, [w15-4]           ; Save back.
    cp0.l     w5
    bra       gt, _phase2_loop_q31 ; More outputs remaining.

    ; Clean up phase 2 stack.
    sub.l     #4, w15               ; Pop saved phase 2 counter.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Phase 3: Partial overlap ramp-down [66].
;   Output indices n = N to N+M-2.
;   Number of MACs decreases from M-1 to 1.
;
;   For output y[n]:
;     y[n] = sum_{k=n-N+1:M-1} x[n-k] * h[k]
;
;   Phase 3 produces (M - 1) output samples.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_phase3_q31:

    mov.l     w3, w5                ; w5 = M
    sub.l     w5, #1, w5            ; w5 = M - 1 (phase 3 output count)
    cp0.l     w5
    bra       z, _conv_exit_q31    ; If M == 1, no phase 3.

    ; x starts at x[N-1] (last element of x).
    mov.l     w1, w6
    sub.l     w6, #1, w6            ; w6 = N - 1
    sl.l      w6, #2, w6            ; w6 = (N-1) * 4 bytes
    add.l     w0, w6, w7            ; w7 -> x[N-1]

    ; h starts at h[1] for first phase 3 output (and advances each output).
    add.l     w2, #4, w9            ; w9 -> h[1]

    ; MAC count starts at M-1 and decreases.
    mov.l     w3, w6
    sub.l     w6, #1, w6            ; w6 = M - 1 (initial MAC count)

_phase3_loop_q31:

    ; Setup for this output sample.
    clr       a                     ; AccuA = 0.
    mov.l     w7, w8                ; w8 -> x[N-1] (walks backward).
    mov.l     w9, w5                ; w5 -> h[k_start] (walks forward).
    mov.l     w6, w3                ; w3 = MAC count for this output.

    ; Inner MAC loop for phase 3.
    ; Use a temporary pointer register for h.
    push.l    w9                    ; Save h start for next output advance.

_phase3_mac_q31:
    mac.l     [w8]-=4, [w5]+=4, a  ; a += x[n-k] * h[k].
    DTB       w3, _phase3_mac_q31

    ; Store output y[n].
    sacr.l    a, [w4++]             ; y[n] = result.

    pop.l     w9                    ; Restore h start pointer.

    ; Advance h start for next output (skip one more h element).
    add.l     w9, #4, w9            ; w9 -> h[k_start + 1].

    ; Decrease MAC count.
    sub.l     #1, w6                ; MAC count--.

    ; More phase 3 outputs?
    cp0.l     w6
    bra       gt, _phase3_loop_q31

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Exit: restore saved registers and return [66].
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_conv_exit_q31:

    pop.l     w0                    ; Restore/discard saved pDst.
    pop.l     w9                    ; Restore w9.
    pop.l     w8                    ; Restore w8.
    pop.l     CORCON                ; Restore 32-bit CORCON.

    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF