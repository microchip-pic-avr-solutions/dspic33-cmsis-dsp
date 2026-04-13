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
; _mchp_cmplx_mag_squared_q31: Q31 complex vector squared magnitude.
;
; Description:
;    Computes the squared magnitude of each complex element in a Q31
;    complex source vector and stores the real-valued Q31 result in a
;    destination vector.
;
;    For each complex element i:
;      pDst[i] = pSrc[2*i]^2 + pSrc[2*i+1]^2
;              = Re[i]^2 + Im[i]^2
;
;    The complex source vector is stored in interleaved format:
;      {Re0, Im0, Re1, Im1, Re2, Im2, ...}
;    Each element is Q31 (4 bytes).
;
;    Uses the DSP engine's sqrac.l (square-and-accumulate) instruction
;    for single-cycle computation of Re^2 and Im^2, matching the
;    cplxsqrmag_aa.s implementation [70].
;
;    dsPIC33AK: uses DTB (no REPEAT instruction).
;
; Operation:
;    pDst[i] = pSrc[2*i] * pSrc[2*i] + pSrc[2*i+1] * pSrc[2*i+1]
;    for i = 0 to (numSamples - 1)
;
; Input:
;    w0 = pSrc        (const q31_t*) pointer to complex input vector
;                      (2*N elements, interleaved Re/Im)
;    w1 = pDst        (q31_t*) pointer to real output vector (N elements)
;    w2 = numSamples  (uint32) number of complex samples (N)
;
; Return:
;    (void)
;
; System resources usage:
;    {w0..w5}    used, not restored
;    {w13}       used, restored
;     AccuA      used, not restored
;     CORCON     saved, used, restored
;
; Notes:
;    - Output length = numSamples (one real value per complex input).
;    - Input length  = 2 * numSamples (interleaved Re/Im Q31 pairs).
;    - The result Re^2 + Im^2 is Q62 in the accumulator; sacr.l
;      extracts the upper 32 bits (Q31) with saturation/rounding.
;    - sqrac.l computes [src]^2 and accumulates in one cycle [70].
;    - pSrc and pDst must not overlap.
;
;............................................................................

    .global    _mchp_cmplx_mag_squared_q31    ; export

_mchp_cmplx_mag_squared_q31:

;............................................................................
; Save working registers (mirrors f32 version) [69].
;............................................................................

    push.l    w13                    ; Save w13 (used for Acc writeback in
                                      ; cplxsqrmag_aa.s pattern) [70].

;............................................................................
; Prepare CORCON for fractional computation [70].
;............................................................................

    push.l    CORCON
    fractsetup w4

;............................................................................
; Remap registers to match C calling convention:
;   w0 = pSrc, w1 = pDst, w2 = numSamples
;............................................................................

;............................................................................
; Early exit if numSamples == 0.
;............................................................................

    cp0.l     w2
    bra       z, _sqmag_exit

;............................................................................
; Setup destination pointer for accumulator writeback [70].
;   cplxsqrmag_aa.s uses w13 for Acc store-back (sacr.l a, [w13++]).
;   We follow the same pattern.
;............................................................................

    mov.l     w1, w13               ; w13 = running pDst pointer.
                                     ; w0 = running pSrc pointer.
                                     ; w2 = numSamples (DTB counter).

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Squared magnitude loop.
;
;   For each complex element:
;     1. Clear accumulator A.
;     2. sqrac.l Re (square-and-accumulate Re^2).
;     3. sqrac.l Im (square-and-accumulate Im^2).
;     4. Store result: pDst[i] = Re^2 + Im^2.
;
;   cplxsqrmag_aa.s [70] uses:
;     clr a
;     sqrac.l [w1]+=4, a    ; a += Re^2
;     sqrac.l [w1]+=4, a    ; a += Im^2
;     sacr.l  a, [w13++]    ; store result
;
;   We keep the identical inner sequence.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_sqmag_loop:

    ; Clear accumulator for this complex element.
    clr       a                     ; AccuA = 0.

    ; Square-and-accumulate: a += Re[i]^2.
    sqrac.l   [w0]+=4, a           ; a += pSrc[2*i]^2 = Re[i]^2.
                                    ; w0 -> Im[i].

    ; Square-and-accumulate: a += Im[i]^2.
    sqrac.l   [w0]+=4, a           ; a += pSrc[2*i+1]^2 = Im[i]^2.
                                    ; w0 -> Re[i+1] (next complex element).

    ; Store squared magnitude result.
    sacr.l    a, [w13++]           ; pDst[i] = Re[i]^2 + Im[i]^2.
                                    ; Post-increment output pointer.

    ; Next complex element.
    DTB       w2, _sqmag_loop      ; Decrement numSamples counter;
                                    ; branch if not zero.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Exit.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_sqmag_exit:

    pop.l     CORCON               ; Restore 32-bit CORCON.
    pop.l     w13                  ; Restore w13.

    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF