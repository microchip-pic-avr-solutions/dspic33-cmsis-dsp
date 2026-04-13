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
    .include    "dspcommon.inc"      ; fractsetup, structure offsets
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_fir_decimate_q31: Q31 FIR decimation filter.
;
; Description:
;    Performs FIR filtering with decimation on a block of Q31 input samples.
;    For every R input samples, one filtered output sample is produced.
;    Uses a linear sliding delay line.
;    Algorithm directly follows the proven firdecim_aa.s reference.
;
;    dsPIC33AK: uses DTB for outer loop, repeat for delay slide/copy/MAC.
;
; Operation:
;    y[k] = sum_{m=0:M-1}{ h[m] * x[k*R - m] }, 0 <= k < blockSize/R
;
; Input:
;    w0 = S          ptr to mchp_fir_decimate_instance_q31
;    w1 = pSrc       (const q31_t*)  input vector
;    w2 = pDst       (q31_t*)        output vector
;    w3 = blockSize  (uint32)        number of INPUT samples
;
; Return:
;    (void)
;
; Instance structure layout (matches C struct):
;    [S + firDecM_q31]          = M / decimFactor (R)  [uint8_t, offset 0]
;    [S + firDecNumTaps_q31]    = numTaps              [uint16_t, offset 2]
;    [S + firDecPCoeffs_q31]    = pCoeffs              [q31_t*, offset 4]
;    [S + firDecPState_q31]     = pState               [q31_t*, offset 8]
;
; System resources usage:
;    {w0..w11}   used, not restored
;     AccuA      used, not restored
;     CORCON     saved, used, restored
;
; DTB and REPEAT instruction usage:
;    1 level DTB instruction  (outer output loop)
;    3 level REPEAT instruction (delay slide, input copy, inner MAC)
;
; Notes:
;    - blockSize must be a multiple of decimFactor (R).
;    - Number of output samples = blockSize / R.
;    - State buffer must be at least numTaps long and zeroed before first call.
;
;............................................................................

    .global _mchp_fir_decimate_q31         ; export

_mchp_fir_decimate_q31:

;............................................................................
; Save working registers.
;............................................................................

    push.l    w8
    push.l    w9
    push.l    w10
    push.l    w11

;............................................................................
; Prepare CORCON for fractional computation.
;............................................................................

    push.l    CORCON
    fractsetup w7

;............................................................................
; Save return value placeholder (pDst).
;............................................................................

    push.l    w2

;............................................................................
; Load instance structure fields and remap to match firdecim_aa.s registers.
;
; firdecim_aa.s register mapping at start of main loop:
;   w0 = N (number of output samples, outer DTB counter)
;   w1 = pSrc (running input pointer)    <<< note: swapped vs CMSIS API
;   w2 = pDst (running output pointer)   <<< note: swapped vs CMSIS API
;   w3 = M - 2 (inner MAC repeat count)
;   w4 = pCoeffs base (preserved)
;   w5 = pState base (delay buffer, preserved)
;   w6 = R - 1 (input copy repeat count)
;   w7 = M - R - 2 (delay slide repeat count)
;   w8 = scratch (delay dest pointer)
;   w9 = R * 4 (byte stride)
;   w10 = scratch (delay src pointer / MAC delay walk)
;   w11 = scratch (MAC coeff walk, loaded from w4 each iteration)
;
; CMSIS API: w0=S, w1=pSrc, w2=pDst, w3=blockSize
; Need: w0=N, w1=pSrc (already), w2=pDst (already)
;............................................................................

    ; Read struct fields into temporaries.
    mov.l    #0, w6                            ; Zero w6 before byte load.
    mov.b    [w0 + #firDecM_q31], w6          ; w6  = R (decimation factor, zero-extended)
    mov.l    [w0 + #firDecPCoeffs_q31], w4    ; w4  = pCoeffs -> h[0]
    mov.l    [w0 + #firDecPState_q31], w5     ; w5  = pState (delay buffer)
    mov      [w0 + #firDecNumTaps_q31], w8    ; w8  = M (numTaps)

    ; Compute N = blockSize / R.
    ; divul uses w3 as dividend, w6 as divisor.
    ; Result: quotient in w3, remainder in w4. (trashes w4!)
    ; Save pCoeffs first.
    push.l   w4
    repeat   #9
    divul    w3, w6                           ; w3 = blockSize / R = N
    pop.l    w4                               ; Restore pCoeffs

    ; Remap: w0 = N (outer loop counter for DTB).
    mov.l    w3, w0                           ; w0 = N

    cp0.l    w0
    bra      z, _decim_exit_no_pop

    ; Precompute loop constants (exactly as firdecim_aa.s).
    ; w8 still = M, w6 still = R.
    sl.l     w6, #2, w9                       ; w9 = R * 4
    sub.l    w8,    w6, w7                    ; w7 = M - R
    sub.l    #2,    w8                        ; w8 = M - 2
    sub.l    #2,    w7                        ; w7 = M - R - 2
    sub.l    #1,    w6                        ; w6 = R - 1
    mov.l    w8, w3                           ; w3 = M - 2 (inner MAC repeat count)

;............................................................................
; Outer loop: produce one output sample per iteration.
;   Directly follows firdecim_aa.s algorithm.
;............................................................................

_decim_start:

    ;--------------------------------------------------------------------
    ; Step 1: Slide delay line to make room for R new input samples.
    ;   Copy d[R..M-1] down to d[0..M-R-1].
    ;--------------------------------------------------------------------

    add.l    w5, w9, w10                      ; w10 -> d[R]
    mov.l    w5, w8                           ; w8  -> d[0]
    mov.l    w4, w11                          ; w11 -> h[0] (save pCoeffs for MAC)

    repeat   w7                               ; repeat (M-R-2)+1 = M-R-1 times
    mov.l    [w10++], [w8++]                  ; d[k] <- d[R+k]

    mov.l    [w10], [w8++]                    ; copy last element
                                               ; w8  -> d[M-R]
                                               ; w10 -> d[M-1]

    ;--------------------------------------------------------------------
    ; Step 2: Place next R input samples into delay tail.
    ;   d[M-R..M-1] <- x[n..n+R-1]
    ;--------------------------------------------------------------------

    repeat   w6                               ; repeat (R-1)+1 = R times
    mov.l    [w1++], [w8++]                   ; d[M-R+k] <- x[n+k]
                                               ; w1 -> x[n+R]
                                               ; w8 -> d[M]

    ;--------------------------------------------------------------------
    ; Step 3: Compute FIR output.
    ;   First multiply: mpy.l clears AccuA and does h[0]*d[M-1].
    ;   Then M-1 MAC operations via repeat.
    ;   Total: M multiplications.
    ;
    ;   w11 walks h[] forward (X prefetch): h[0], h[1], ...
    ;   w10 walks d[] backward (Y prefetch): d[M-1], d[M-2], ...
    ;--------------------------------------------------------------------

    mpy.l    [w11]+=4, [w10]-=4, a            ; a = h[0]*d[M-1]
                                               ; w11 -> h[1], w10 -> d[M-2]

    repeat   w3                               ; repeat (M-2)+1 = M-1 times
    mac.l    [w11]+=4, [w10]-=4, a            ; a += h[k]*d[M-1-k]

    ;--------------------------------------------------------------------
    ; Step 4: Store filtered output (saturated/rounded Q31).
    ;--------------------------------------------------------------------

    sacr.l   a, [w2++]                        ; y[k] = result

    ;--------------------------------------------------------------------
    ; Next output sample.
    ;--------------------------------------------------------------------

    dtb      w0, _decim_start

;............................................................................
; Restore saved pDst and exit.
;............................................................................

    pop.l    w0                               ; Discard saved pDst

;............................................................................
; Exit: restore saved control registers and working registers.
;............................................................................

_decim_exit:

    pop.l    CORCON

    pop.l    w11
    pop.l    w10
    pop.l    w9
    pop.l    w8

    return

;............................................................................
; Early exit when N == 0 (must still pop saved pDst to balance stack).
;............................................................................

_decim_exit_no_pop:
    pop.l    w0                               ; Discard saved pDst
    bra      _decim_exit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF
