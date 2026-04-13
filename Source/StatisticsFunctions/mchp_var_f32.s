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
; _mchp_var_f32: Computes the variance of the elements of a floating-point vector.
;
; Operation:
;    mean = (sum of all elements) / blockSize
;    variance = sum((x_i - mean)^2) / (blockSize - 1)
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
;    {f0..f4}    used, not preserved
;     FCR        saved, used, restored
;
;............................................................................

    .global    _mchp_var_f32    ; Export symbol
_mchp_var_f32:

    ; Save FPU control register and set up FPU for default operation
    push.l  fcr
    floatsetup w3                   ; Set up FPU control register

    mov.l     w1, w4                ; Copy blockSize to w4 (loop counter)
    mov.l     w0, w5                ; Copy input vector pointer to w5 (for iteration)
    cp.l      w1, #2
    bra       lt, doExit           ; If w1 <= 1, exit

    call      _mchp_mean_f32        ; Compute mean, result in f0

    mov.l     w4, w1                ; Restore blockSize to w1 (for denominator)
    mov.l     #0, f1                ; Initialize sum accumulator to 0
    mov.l     #0, f2                ; Clear f2 (used for vector element)
    mov.l     #0, f3                ; Clear f3 (used for temp calculations)
    mov.l     [w2], f0              ; Load mean value from output pointer (set by _mchp_mean_f32)

loop_start:
    cp      w4, #0                  ; Check if loop counter is zero
    bra     z, loop_end             ; Exit loop if all elements processed

    mov.l   [w5++], f2              ; Load next vector element into f2
    sub.s   f2, f0, f3              ; f3 = X_i - mean
    mul.s   f3, f3, f3              ; f3 = (X_i - mean)^2
    add.s   f1, f3, f1              ; Accumulate sum: f1 += (X_i - mean)^2

    dec     w4, w4                  ; Decrement loop counter
    bra     loop_start              ; Repeat loop

loop_end:
    ; f1 now contains the sum of (X_i - mean)^2

    dec       w1, w1                ; blockSize - 1 for sample variance denominator
    mov.l     w1, f0                ; Move denominator to f0
    li2f.s    f0, f0                ; Convert denominator to float
    div.s     f1, f0, f1            ; f1 = sum / (blockSize - 1)
    mov.l     f1, [w2]              ; Store result at output pointer

    pop.l   FCR                     ; Restore FPU control register

    return

doExit:
    mov.l  #0, w2 
    
    pop.l   FCR                     ; Restore FPU control register

    return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End of File
