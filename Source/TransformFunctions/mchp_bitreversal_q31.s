;*****************************************************************************
;                                                                            *
;                       Software License Agreement                           *
;*****************************************************************************
;*****************************************************************************
;© [2026] Microchip Technology Inc. and its subsidiaries.                    *
;                                                                            *
;   Subject to your compliance with these terms, you may use Microchip       *
;   software and any derivatives exclusively with Microchip products.        *
;    You are responsible for complying with 3rd party license terms          *
;    applicable to your use of 3rd party software (including open source     *
;    software) that may accompany Microchip software. SOFTWARE IS "AS IS."   *
;    NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS     *
;    SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,         *
;    MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT       *
;    WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,           *
;    INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY        *
;    KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF        *
;    MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE        *
;    FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIPS           *
;    TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT          *
;    EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR       *
;   THIS SOFTWARE.                                                           *
;*****************************************************************************

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Local inclusions.

    .nolist
    .include    "dspcommon.inc"
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_bitreversal_q31: Fixed-point (Q31) complex in-place bit reversal.
;
; Description:
;    Performs an in-place bit-reverse re-ordering of a complex Q31 vector.
;    Uses a pure software bit-reversal algorithm (shift/test loop).
;
;    NOTE: The XBREV hardware approach (movr.l [w2],[w2++]) does NOT
;    produce correct bit-reversed pointer increments on dsPIC33AK for
;    Q31 data. This software implementation is used instead.
;
; Operation:
;    For each index i in {0, 1, ..., N-1}:
;      Compute j = bitrev(i) using log2(N) bits.
;      If j > i, swap complex elements: data[i] <-> data[j].
;
; Input:
;    w0 = ptr to complex source/destination vector (pSrc)
;    w1 = fftLen (N = number of complex samples)
;
; Return:
;    w0 = ptr to source vector (pSrc) — unchanged
;
; System resources usage:
;    {w0..w7}    used, not restored
;    {w8, w9}    saved, used, restored
;
;............................................................................

    .global    _mchp_bitreversal_q31        ; export

_mchp_bitreversal_q31:

    ; Save callee-saved registers.
    push.l     w8
    push.l     w9

    ; Register allocation:
    ;   w0 = pSrc (base pointer, preserved for return)
    ;   w1 = N (fftLen)
    ;   w2 = log2(N)
    ;   w3 = j (bit-reversed index) / temp
    ;   w4 = temp for swap
    ;   w5 = i (loop index)
    ;   w6 = bit loop counter
    ;   w7 = temp (copy of i for bit extraction)
    ;   w8 = ptr to data[i]
    ;   w9 = ptr to data[j]

    ; Compute log2(N) into w2.
    mov.l      #0, w2
    mov.l      w1, w7
_bitrev_log2:
    lsr.l      w7, w7
    cp0.l      w7
    bra        z, _bitrev_log2_done
    add.l      #1, w2
    bra        _bitrev_log2
_bitrev_log2_done:
    ; w2 = log2(N).

    mov.l      #0, w5                ; w5 = i = 0.

_bitrev_outer:
    ; Compute j = bitrev(i) with w2 bits.
    mov.l      #0, w3                ; w3 = j = 0.
    mov.l      w5, w7                ; w7 = temp copy of i.
    mov.l      w2, w6                ; w6 = bit counter = log2(N).

_bitrev_bits:
    sl.l       w3, w3                ; j <<= 1.
    btst.lz    w7, #0                ; Test LSB of w7; Z = ~bit0.
    bra        z, _bitrev_noset      ; If bit0==0 (Z=1), skip set.
    add.l      #1, w3                ; j |= 1.
_bitrev_noset:
    lsr.l      w7, w7                ; w7 >>= 1.
    sub.l      #1, w6                ; bit counter--.
    cp0.l      w6
    bra        nz, _bitrev_bits

    ; w3 = bitrev(i). Swap only if j > i.
    cp.l       w3, w5
    bra        le, _bitrev_noswap

    ; Compute addresses: data[i] = pSrc + i*8, data[j] = pSrc + j*8.
    sl.l       w5, #3, w8            ; w8 = i * 8.
    add.l      w0, w8, w8            ; w8 = &data[i].
    sl.l       w3, #3, w9            ; w9 = j * 8.
    add.l      w0, w9, w9            ; w9 = &data[j].

    ; Swap real parts (offset +0).
    mov.l      [w8], w4              ; w4 = data[i].re
    mov.l      [w9], w7              ; w7 = data[j].re
    mov.l      w7, [w8]              ; data[i].re = data[j].re
    mov.l      w4, [w9]              ; data[j].re = data[i].re

    ; Swap imag parts (offset +4).
    mov.l      [w8+#4], w4           ; w4 = data[i].im
    mov.l      [w9+#4], w7           ; w7 = data[j].im
    mov.l      w7, [w8+#4]           ; data[i].im = data[j].im
    mov.l      w4, [w9+#4]           ; data[j].im = data[i].im

_bitrev_noswap:
    add.l      #1, w5                ; i++.
    cp.l       w5, w1                ; i < N?
    bra        lt, _bitrev_outer

    ; Restore callee-saved registers.
    pop.l      w9
    pop.l      w8

    ; w0 still contains original pSrc pointer (unchanged).
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF
