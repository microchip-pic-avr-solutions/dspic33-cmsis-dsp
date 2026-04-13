;*****************************************************************************
;                                                                            *
;                       Software License Agreement                           *
;*****************************************************************************
;*****************************************************************************
; © [2026] Microchip Technology Inc. and its subsidiaries.                   *
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
    .include    "dspcommon.inc"        ; Common DSP definitions and macros
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .dspic33cmsisdsp, code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_std_f32: Computes the standard deviation of the elements of a floating-point vector.
;
; Operation:
;    mean = (sum of all elements) / blockSize
;    variance = sum((x_i - mean)^2) / (blockSize - 1)
;    stddev = sqrt(variance)
;
; Inputs:
;    w0 = pointer to input vector (pSrc)
;    w1 = blockSize (number of elements)
;    w2 = pointer to output value (pResult)
;
; Return:
;        None
;
; System resources usage:
;    {w0..w7}    used, not preserved
;    {f0..f5}    used, not preserved
;     FCR        saved, used, restored
;
;............................................................................

    .global    _mchp_std_f32    ; Export symbol
_mchp_std_f32:

    push.l  fcr                     ; Save FPU control register
    floatsetup w3                   ; Set up FPU control register

    mov.l     w0, w4                ; Copy input vector pointer (pSrc) to w4 (for iteration)
    mov.l     w1, w5                ; Copy blockSize to w5 (for iteration)
    mov.l     w2, w6                ; Copy output pointer (pResult) to w6

    cp.l      w1, #2
    bra       lt, doExit           ; If w1 <= 1, exit

    call      _mchp_var_f32         ; Compute variance, result in f1

    mov.s     f1, f0                ; Move variance to f0 for sqrt
    mov.l     w6, w0                ; Set w0 to output pointer for sqrt function

    sqrt.s    f0, f1

    mov.l     f1, [w6]              ; Store stddev result at *pResult

    pop.l   FCR                     ; Restore FPU control register

    return

doExit:
    mov.l  #0, w2 
    
    pop.l   FCR                     ; Restore FPU control register

    return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End of File
