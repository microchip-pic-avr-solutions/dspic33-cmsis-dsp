;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; mchp_copy_f32: Copy elements from pSrc to pDst
;
; Operation:
;    pDst[n] = pSrc[n], 0 <= n < blockSize
;
; Input:
;    W0 = pointer to pSrc
;    W1 = pointer to pDst
;    W2 = blockSize  (number of float32 elements)
;
; Return:
;    none   (void)
;
; System resources usage:
;    {W0..W3} used, not restored
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .dspic33cmsisdsp, code

    .global _mchp_copy_f32
_mchp_copy_f32:

    ; W2 = blockSize
    ; For REPEAT we need blockSize-1 in W3

    sub.l   W2, #1, W3          ; W3 = blockSize - 1

    repeat  W3                  ; execute copy blockSize times
    mov.l   [W0++], [W1++]      ; pDst[n] = pSrc[n]

    return
