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
    .include    "dspcommon.inc"        ; floatsetup
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .dspic33cmsisdsp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _VectorCorrelate_f32: Vector correlation (using convolution).
;
; Operation:
;    r[n] = sum_(k=0:N-1){x[k]*y[k+n]},
; where:
;    x[n] defined for 0 <= n < N,
;    y[n] defined for 0 <= n < M, (M <= N),
;    r[n] defined for 0 <= n < N+M-1,
;
; Input:
;    w0 = x, ptr to source vector one
;    w1 = N, number elements in vector one
;    w2 = y, ptr to source vector two
;    w3 = M, number elements in vector two
;    w4 = r, ptr to destination vector, with R elements
;
; System resources usage:
;    {w0..w7}    used, not restored
;    w8       saved, used, restored
; plus resuorces from VectorConvolve.
;
;............................................................................
    ; w0 = pSrcA
    ; w1 = srcALen
    ; w2 = pSrcB
    ; w3 = srcBLen
    ; w4 = pDst
    ; External symbols.
    .extern    _mchp_conv_f32

    .global    _mchp_correlate_f32    ; export
_mchp_correlate_f32:

    ;............................................................................
    ; Save working registers.
    push.l    w8
    ;............................................................................
    
    ; First, revert y (source vector two).
    
    mov.l    w2, w7               ; w7-> y[0]
    sub.l    w3, #1, w5           ; w5 = M-1
    sl.l     w5, #2, w5           ; w5 = (M-1)*sizeof(float)
    add.l    w2, w5, w6           ; w6-> y[M-1]
    lsr.l    w3, w8               ; w8 = floor (M/2)
startRevert:                    
; {                               ; DTB (M/2-1)+1 times
                                  ; w5 up for grabs...
    mov.l    [w6], w5             ; w5 = y[M-1-n]
    mov.l    [w7], [w6--]         ; y[n] into y[M-1-n]
                                  ; w6-> y[M-1-(n+1)]
    mov.l    w5, [w7++]           ; y[M-1-n] into y[n]
    DTB      w8, startRevert
                                  ; w7-> y[n+1]
; }
    ;............................................................................
    ; Restore working registers.
    pop.l    w8
    ;............................................................................

    ; Then, invoke convolution...
    call    _mchp_conv_f32

;............................................................................

    return            ; NOTE that w0 is set up by _mchp_conv_f32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OEF
