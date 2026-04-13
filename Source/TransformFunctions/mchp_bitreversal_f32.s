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
;    software) that may accompany Microchip software. SOFTWARE IS ?AS IS.?   *
;    NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS     *
;    SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,         *
;    MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT       *
;    WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,           *
;    INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY        *
;    KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF        *
;    MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE        *
;    FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIP?S          *
;    TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT          *
;    EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR       *
;   THIS SOFTWARE.                                                           *
;*****************************************************************************

    ; Local inclusions.

    .nolist                         
    .include    "dspcommon.inc"
       ; MODCON, XBREV
    .list                           

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .dspic33cmsisdsp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _BitReverseComplex: Complex (in-place) Bit Reverse re-organization.
;
; Operation:
;
; Input:
;    w0 = number stages in FFT (log2NVal)
;    w1 = ptr to complex source vector (srcCV)
; Return:
;    w0 = ptr to source vector (srcCV)
;
; System resources usage:
;    {w0..w6}    used, not restored
;     XBREV        saved, used, restored
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*****************************************************************************
;   mchp_bitreversal_f32: 
;
;   Notes:
;     - pBitRevTable, bitRevLength are ignored (dsPIC uses XBREV hardware)
;     - fftLen = number of complex samples (N)
;     - XBREV pivot = fftLen
;
;*****************************************************************************

    .section .dspic33cmsisdsp, code

    .global _mchp_bitreversal_f32
_mchp_bitreversal_f32:

    ;----------------------------------------------------------
    ; Save XBREV (must preserve)
    ;----------------------------------------------------------
    push.l    XBREV

    ;----------------------------------------------------------
    ; W0 = pSrc
    ; W1 = fftLen (N)
    ; W2 = pBitRevTable (UNUSED)
    ; W3 = bitRevLength (UNUSED)
    ;
    ; Microchip algorithm expects:
    ;   W3 = N (pivot for XBREV)
    ;----------------------------------------------------------
    mov.l     w1, w3
    mov.l     w3, XBREV         ; Setup hardware bit-reversal pivot

    ;----------------------------------------------------------
    ; Local pointers
    ;----------------------------------------------------------
    mov.l     w0, w1            ; w1: sequential index (src)
    mov.l     w0, w2            ; w2: bit-reversed index (via XBREV)
    mov.l     #4, w6            ; offset to imag (float32)

startBitRev:
    cp.l      w2, w1
    bra       le, skipSwap

    ;----------------------------------------------------------
    ; Swap complex values: (real, imag)
    ;----------------------------------------------------------
    mov.l     [w1],     w4
    mov.l     [w1+w6],  w5

    mov.l     [w2],     [w1]
    mov.l     [w2+w6],  [w1+w6]

    mov.l     w4, [w2]
    mov.l     w5, [w2+w6]

skipSwap:
    add.l     w1, #8, w1        ; next complex element
    movr.l    [w2], [w2++]      ; bit-reversed increment
    dtb       w3, startBitRev   ; loop

    ;----------------------------------------------------------
    ; Restore XBREV
    ;----------------------------------------------------------
    pop.l     XBREV

    return
    .end
