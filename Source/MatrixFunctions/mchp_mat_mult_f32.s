 ;****************************************************************************
;                                                                            *
;                       Software License Agreement                           *
;*****************************************************************************
;*****************************************************************************
; © [2026] Microchip Technology Inc. and its subsidiaries.                    *
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
; _mchp_mat_mult_f32: Single precision floating point Matrix Multiplication.
;
; Operation:
;    dstM[i][j] = sum_k(srcM1[i][k]*srcM2[k][j]), with
; i in {0, 1, ..., numRows1-1}
; j in {0, 1, ..., numCols2-1}
; k in {0, 1, ..., numCols1Rows2-1}
;
; Inputs:
;    w0 = pointer to source matrix 1 structure (srcM1)
;    w1 = pointer to source matrix 2 structure (srcM2)
;    w2 = pointer to destination matrix structure (dstM)
; Return:
;    w0 = status code:
;         MathSuccess        -> if operation successful
;         MathSizeMismatch   -> if matrix dimensions do not match
;
; System resources usage:
;    {w0..w7}    used, not restored
;    {w10..w12}  used, and restored
;    {f0..f2}    used, not restored
;     FCR        saved, used, restored
;
;............................................................................

    .global    _mchp_mat_mult_f32                 ; Export symbol
_mchp_mat_mult_f32:

;............................................................................    
    ; Load number of row of srcM2 and column of srcM1
    mov.w   [w0 + #MATRIX_NUMCOLS_OFF], w3        ; w3 = srcM1->numCols
    mov.w   [w1 + #MATRIX_NUMROWS_OFF], w4        ; w4 = srcM2->numRows
    
    ; Check for matching dimensions 
    cp      w3, w4                                ; Compare srcM1->numCols and srcM2->numRows
    bra     nz, size_mismatch                     ; If not equal, branch to error

    ; Load number of rows and columns of dstM
    mov.w   [w2 + #MATRIX_NUMROWS_OFF], w3        ; w3 = dstM->numRows
    mov.w   [w2 + #MATRIX_NUMCOLS_OFF], w4        ; w4 = dstM->numCols

    ; Load number of row of srcM1 and column of srcM2    
    mov.w   [w1 + #MATRIX_NUMCOLS_OFF], w13       ; w13 = srcM1->numCols
    mov.w   [w0 + #MATRIX_NUMROWS_OFF], w5        ; w5 = srcM1->numRows
    
    ; Check for matching dimensions between srcM and dstM
    cp      w4, w13                               ; Compare number of rows
    bra     nz, size_mismatch                     ; If not equal, branch to error
    cp      w3, w5                                ; Compare number of columns
    bra     nz, size_mismatch                     ; If not equal, branch to error

    ; Assignment of working registers
    mov.l   [w0 + #MATRIX_PDATA_OFF],  w4         ; w4 = pointer to srcM1->pData
    mov.l   [w1 + #MATRIX_PDATA_OFF],  w5         ; w5 = pointer to srcM2->pData
    mov.l   [w2 + #MATRIX_PDATA_OFF],  w3         ; w3 = pointer to dstM->pData

    mov.w   [w1 + #MATRIX_NUMCOLS_OFF], w2        ; w2 = number of columns of srcM2
    mov.w   [w0 + #MATRIX_NUMCOLS_OFF], w1        ; w1 = number of columns of srcM1
    mov.w   [w0 + #MATRIX_NUMROWS_OFF], w0        ; w0 = number of rows of srcM1

    ; Save working registers.
    push.l    w8                                  ; {w8 } to TOS
    push.l    w9                                  ; {w9 } to TOS
    push.l    w10                                 ; {w10} to TOS
    push.l    w11                                 ; {w11} to TOS
    push.l    w12                                 ; {w12} to TOS

;............................................................................
    ; Mask all FPU exceptions, set rounding mode to default and clear SAZ/FTZ

    push.l    FCR
    floatsetup    w10

;............................................................................

    push.l    w3                                  ; save return value (dstM)

;............................................................................

    sub.l    w1,  #1,  w8                         ; w8 = numCols1Rows2 - 1
    mov.l    w2,    w9                            ; w9 = numCols2
    sl.l    w1,#2,w1                              ; w1  = sizeof (Cols1Rows2)
    sl.l    w2,#2,w2                              ; w2  = sizeof (Cols2)

_doRows1:

; Outer loop: for each row i in srcM1 (numRows1)
    mov.l    w5,    w10                           ; w10-> srcM2[0][0]
    mov.l    w9,    w11
startCols2:
; {Middle loop: for each column j in srcM2 (numCols2)
    mov.l   [w10], f1                             ; f1 = srcM2[1][j]
    mov.l   [w4], f0                              ; f0 = srcM1[i][0]
    add.l   w10, w2, w7                           ; w7 -> srcM2[1][j]
    mul.s   f0, f1, f2                            ; f2 = f0*f1
    mov.l   w4,    w6                             ; w6 -> srcM1[i][0]
    mov.l   w8,    w12                            ; w12 = numCols1Rows2 - 1
startCols1Rows2:
; {Inner loop: for each k in 0..numCols1Rows2-1 (dot product)
    mov.l   [++w6], f0                            ; f0 = srcM1[i][k]       
    mov.l   [w7], f1                              ; f1 = srcM2[k][j]
    add.l   w7, w2, w7                            ; w7 -> srcM2[k+1][0]
    mac.s   f0, f1, f2                            ; f2 += srcM1[i][k]*srcM2[k][j]              
    DTB     w12, startCols1Rows2
; }
    add.l   w10, #4, w10                          ; srcM2[0][j+1]
    mov.l   f2, [w3++]                            ; dst[i][j] =; sum_k(srcM1[i][k]*srcM2[k][j])
    ; Update for next column.
    DTB        w11, startCols2
; }

    ; Update for next row.
    add.l    w4,w1,w4                             ; w4 -> srcM1[i][0]
    dtb    w0, _doRows1
_doneRows1:
;............................................................................
    pop.l    w0 
;............................................................................

    ; restore FCR.
    pop.l    FCR

;............................................................................

    ; Restore working registers.
    pop.l    w12                                  ; {w12} from TOS
    pop.l    w11                                  ; {w11} from TOS
    pop.l    w10                                  ; {w10} from TOS
    pop.l    w9                                   ; {w9 } from TOS
    pop.l    w8                                   ; {w8 } from TOS

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
