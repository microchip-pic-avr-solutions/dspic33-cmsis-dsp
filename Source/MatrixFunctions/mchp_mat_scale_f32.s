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
    .include    "dspcommon.inc"                   ; Common DSP definitions and macros
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .dspic33cmsisdsp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_mat_scale_f32: Single precision floating point Matrix scale.
;
; Operation:
;    dstM[i][j] = sclVal * srcM[i][j]
;
; Inputs:
;    w0 = pointer to source matrix structure (srcM)
;    w1 = pointer to destination matrix structure (dstM)
;    f0 = scale value (sclVal)
; Return:
;    w0 = status code:
;         MathSuccess        -> if operation successful
;         MathSizeMismatch   -> if matrix dimensions do not match
;
; System resources usage:
;    {w0..w4}    used, not restored
;    {f0..f2}    used, not restored
;............................................................................

    .global    _mchp_mat_scale_f32                ;  Export symbol
_mchp_mat_scale_f32:
;............................................................................
    ; Load number of rows and columns from dstM
    mov.w   [w1 + #MATRIX_NUMROWS_OFF], w5        ; w5 = dstM->numRows
    mov.w   [w1 + #MATRIX_NUMCOLS_OFF], w6        ; w6 = dstM->numCols
    mov.l   [w1 + #MATRIX_PDATA_OFF],  w2         ; w2 = pointer to dstM->pData

    ; Load number of rows and columns from srcM1
    mov.w   [w0 + #MATRIX_NUMCOLS_OFF], w1        ; w1 = srcM->numCols
    mov.l   [w0 + #MATRIX_PDATA_OFF],  w3         ; w3 = pointer to srcM->pData   
    mov.w   [w0 + #MATRIX_NUMROWS_OFF], w0        ; w0 = srcM->numRows 

    ; Check for matching dimensions between srcM1 and dstM
    cp      w1, w6                                ; Compare number of columns
    bra     nz, size_mismatch                     ; If not equal, branch to error
    cp      w0, w5                                ; Compare number of rows
    bra     nz, size_mismatch                     ; If not equal, branch to error

    ; Prepare operation.
    muluu.l    w0,w1,w0                           ; w0 = numRows*numCols
   
   ; Mask all FPU exceptions, set rounding mode to default and clear SAZ/FTZ
    push.l fcr
    floatsetup w4
;............................................................................
    mov.l [w3++], f1                              ; f1 = srcM[0] (first element of source matrix)
    mov.l w2, w4                                  ; w4 = pointer to dstM->pData (save for loop)
    mul.s f0, f1, f2                              ; f2 = sclVal * srcM[0] (first scaled value)
    sub.l w0, #1, w0                              ; w0 = total elements - 1 (loop counter)
    1:
    mov.l [w3++], f1                              ; f1 = srcM[n+1]
    mov.l f2, [w4++]                              ; dstM[n] = previous scaled value
    mul.s f1, f0, f2                              ; f2 = sclVal * srcM[n+1]
    ;NOP                                          ; Cycle stall (if needed)
    DTB w0, 1b

    mov.l f2, [w4++]                              ; dstM[N-1] = last scaled value

;............................................................................
    pop.l FCR                                     ; restore FCR.s
;............................................................................

    mov.l     #MathSuccess, w0               ; Return success status
    return    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
size_mismatch:
    mov.l     #MathSizeMismatch, w0          ; Return error status for size mismatch
    return

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End of File
