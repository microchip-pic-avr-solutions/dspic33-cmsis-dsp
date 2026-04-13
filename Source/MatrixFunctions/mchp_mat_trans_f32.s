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
    .include    "dspcommon.inc"                   ; Common DSP definitions and macros
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .dspic33cmsisdsp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_mat_trans_f32: Single-precision floating-point matrix transposition.
;
; Operation:
;    dstM[i][j] = srcM[j][i]
;
; Inputs:
;    w0 = pointer to source matrix structure (srcM)
;    w1 = pointer to destination matrix structure (dstM)
;
; Return:
;    w0 = status code:
;         MathSuccess        -> if operation successful
;         MathSizeMismatch   -> if matrix dimensions do not match
;
; System resources usage:
;    {w0..w7}    used, not restored
;............................................................................

    .global    _mchp_mat_trans_f32                ; Export symbol
_mchp_mat_trans_f32:

;............................................................................
    ; Load number of rows and columns from dstM
    mov.w   [w1 + #MATRIX_NUMROWS_OFF], w5        ; w5 = dstM->numRows
    mov.w   [w1 + #MATRIX_NUMCOLS_OFF], w6        ; w6 = dstM->numCols
    mov.l   [w1 + #MATRIX_PDATA_OFF],  w2         ; w2 = pointer to dstM->pData

    ; Load number of columns and rows from srcM
    mov.w   [w0 + #MATRIX_NUMCOLS_OFF], w1        ; w1 = srcM->numCols
    mov.l   [w0 + #MATRIX_PDATA_OFF],  w3         ; w3 = pointer to srcM->pData
    mov.w   [w0 + #MATRIX_NUMROWS_OFF], w0        ; w0 = srcM->numRows

    ; Check for valid transposition dimensions:
    ; dstM rows must equal srcM cols, dstM cols must equal srcM rows
    cp      w5, w1                                ; Compare dstM->numRows and srcM->numCols
    bra     nz, size_mismatch                     ; If not equal, branch to error
    cp      w6, w0                                ; Compare dstM->numCols and srcM->numRows
    bra     nz, size_mismatch                     ; If not equal, branch to error
;............................................................................

    mov.l    w0, w6                               ; w6 = srcM->numRows
    mov.l    w2,  w0                              ; Save destination pointer (optional, for return or future use)

;............................................................................

    ; Prepare operation.
    mov.l   w1, w4                                ; w4 = srcM->numCols
    sl.l    w1, #2, w1                            ; w1 = srcM->numCols * sizeof(float)

    ; Perform operation.
    push.l   w6                                   ; Save srcM->numRows for inner loop
startCol:
    ; Loop over columns of srcM (for each column c = 0 to srcM->numCols-1)
    mov.l    w3, w5                               ; w5 = pointer to srcM[0][c]
startRows:
    ; Loop over rows of srcM (for each row r = 0 to srcM->numRows-1)
        mov.l    [w5], [w2++]                     ; Store srcM[r][c] at dstM[c][r] (transposed position)
                                                  ; Advance dstM pointer
        add.l    w5, w1, w5                       ; w5 = pointer to srcM[r+1][c]
        dtb w6, startRows                         ; Decrement and branch if not zero (rows)
    mov.l [w15-4], w6                             ; Restore w6 (srcM->numRows) after DTB
    add.l #4, w3                                  ; w3 = pointer to srcM[0][c+1]
    dtb   w4, startCol                            ; Decrement and branch if not zero (columns)
    pop.l     w6                                  ; Restore srcM->numRows for next column iteration

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
