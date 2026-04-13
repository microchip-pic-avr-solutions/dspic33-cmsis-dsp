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
; _mchp_cmplx_mag_f32: magnitude complex on single precision floating point complex numbers.
;
; Operation:
;   pDst[i] = sqrt((pSrc[2*i] * pSrc[2*i]) +
;             (pSrc[2*i+1] * pSrc[2*i+1]))
;   for i = 0 .. (numSamples - 1)
;
; Input:
;   w0 = numSamples (number of complex samples)
;   w1 = pointer to destination real output vector (pDst)
;   w2 = pointer to source complex input vector (pSrc)
;        Layout: {real0, imag0, real1, imag1, ...}
;
; Output:
;   None (results written to pDst via w1)
;
; System Resources Usage:
;   {w0..w4}    used, not preserved
;   {f0..f3}    used, not preserved
;    FCR        saved, modified, restored
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.global _mchp_cmplx_mag_f32
_mchp_cmplx_mag_f32:
    ; Mask all FPU exceptions, set rounding mode to default and clear SAZ/FTZ
    mov.l w0, w4
    mov.w w2, w0
    mov.l w4, w2
     
    push.l fcr
    floatsetup w3
    
    mov.l [w2++], f0               ; f0 = srcCV.real[0]
    mov.l [w2], f2                 ; f2 = srcVV.imag[0]
    mul.s f0, f0, f3               ; f3 = f0*f0
    sub.l w0, #1, w0               ; w0 = N-1
    push.l w1                    
    
start_sqmag:
    mov.s f3, f1                   ; f1 = f3
    mov.l [++w2], f0               ; f0 = srcCV.real[n]
    mac.s f2, f2, f1               ; f1 += f2*f2
    mov.l [++w2], f2               ; f2 = srcCV.imag[n]
    mul.s f0, f0, f3               ; f3 = f0*f0
    ;NOP
    ;mov.l f1, [w1++]               ; dstV[n] = real*real + imag*imag
    sqrt.s f1, f1                  ; f1 = sqrt(real² + imag²)
    mov.l  f1, [w1++]
    dtb w0, start_sqmag
    
    mov.s f3, f1                   ; f1 = f3
    mac.s f2, f2, f1               ; f1 = real*real + imag*imag
    sqrt.s f1, f1
    mov.l f1, [w1++]               ; dstV[N-1] = real*real + imag*imag
    
    
    pop.l w0                       ; Restore return value
    pop.l FCR                      ; return FCR
    
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OEF
