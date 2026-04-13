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
; _mchp_mat_add_f32: Single-precision floating-point matrix addition.
;
; Operation:
;    dstM[i][j] = srcM1[i][j] + srcM2[i][j]
;
; Inputs:
;    w0 = pointer to first source matrix structure (srcM1)
;    w1 = pointer to second source matrix structure (srcM2)
;    w2 = pointer to destination matrix structure (dstM)
;
; Return:
;    w0 = status code:
;         MathSuccess        -> if operation successful
;         MathSizeMismatch   -> if matrix dimensions do not match
;
; System resources usage:
;    {w0..w5}    used, not restored
;    {f0..f2}    used, not restored
;     FCR        saved, used, restored
;
;............................................................................

    .global    _mchp_mat_add_f32    ; Export symbol
_mchp_mat_add_f32:

;............................................................................
    ; Load number of rows and columns from srcM1
    mov.w   [w0 + #MATRIX_NUMROWS_OFF], w3        ; w3 = srcM1->numRows
    mov.w   [w0 + #MATRIX_NUMCOLS_OFF], w4        ; w4 = srcM1->numCols
    mov.l   [w0 + #MATRIX_PDATA_OFF],  w6         ; w6 = pointer to srcM1->pData    

    ; Load number of rows and columns from srcM2
    mov.w   [w1 + #MATRIX_NUMROWS_OFF], w9        ; w9 = srcM2->numRows
    mov.w   [w1 + #MATRIX_NUMCOLS_OFF], w10       ; w10 = srcM2->numCols
    mov.l   [w1 + #MATRIX_PDATA_OFF],  w7         ; w7 = pointer to srcM2->pData

    ; Check for matching dimensions between srcM1 and srcM2
    cp      w3, w9                                ; Compare number of rows
    bra     nz, size_mismatch                     ; If not equal, branch to error
    cp      w4, w10                               ; Compare number of columns
    bra     nz, size_mismatch                     ; If not equal, branch to error

    ; Load number of rows and columns from dstM
    mov.w   [w2 + #MATRIX_NUMROWS_OFF], w9        ; w9 = dstM->numRows
    mov.w   [w2 + #MATRIX_NUMCOLS_OFF], w10       ; w10 = dstM->numCols

    ; Check for matching dimensions between srcM1 and dstM
    cp      w3, w9                                ; Compare number of rows
    bra     nz, size_mismatch                     ; If not equal, branch to error
    cp      w4, w10                               ; Compare number of columns
    bra     nz, size_mismatch                     ; If not equal, branch to error

    ; Calculate total number of elements (rows * columns)
    muluu.l    w3, w4, w4                         ; w4 = total number of elements

;............................................................................
    ; Save FPU control register, set up FPU for default operation
    push.l fcr
    floatsetup w5

    ; Load pointer to destination matrix data
    mov.l     [w2 + #MATRIX_PDATA_OFF], w5        ; w5 = pointer to dstM->pData
;............................................................................

    mov.l    w5, w3                               ; Save destination pointer (optional, for return or future use)

;............................................................................
mat_add_start:
    mov.l [w6++], f0                              ; f0 = srcM1[n]
    mov.l [w7++], f1                              ; f1 = srcM2[n]
    add.s f0, f1, f2                              ; f2 = f0 + f1
    mov.l f2, [w5++]                              ; dstM[n] = f2
    DTB w4, mat_add_start                         ; Decrement w4, branch if not zero (loop for all elements)
;............................................................................

    ; Restore FPU control register
    pop.l    FCR

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
