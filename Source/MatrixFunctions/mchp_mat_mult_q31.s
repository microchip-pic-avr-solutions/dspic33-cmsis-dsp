;****************************************************************************
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
;    software) that may accompany Microchip software. SOFTWARE IS AS IS.     *
;    NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS     *
;    SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,         *
;    MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT       *
;    WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,           *
;    INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY        *
;    KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF        *
;    MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE        *
;    FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S          *
;    TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT          *
;    EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR       *
;   THIS SOFTWARE.                                                           *
;*****************************************************************************

; Local inclusions.

    .nolist
    .include    "dspcommon.inc"      ; fractsetup macro, matrix structure offsets
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_mat_mult_q31: Fixed-point (Q31) matrix multiplication.
;
; Description:
;    Multiplies two Q31 source matrices and stores the saturated result
;    into a destination matrix. The inner dimension of srcM1 (numCols)
;    must equal the outer dimension of srcM2 (numRows). The destination
;    matrix dimensions must match the result (srcM1->numRows x srcM2->numCols).
;
; Operation:
;    dstM[i][j] = sum_k( srcM1[i][k] * srcM2[k][j] ), with
;
;    i in {0, 1, ... , numRows1-1}
;    j in {0, 1, ... , numCols2-1}
;    k in {0, 1, ... , numCols1Rows2-1}
;
; Input:
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
;    {w0..w14}   used, not restored ({w8..w14} saved/restored)
;     AccuA      used, not restored
;     CORCON     saved, used, restored
;
; NOTE: Source matrix data may reside in const/program memory (PSV).
;   DSP instructions (mpy.l [Ws], [Wt], Acc) can only access data RAM,
;   so we pre-load both operands via mov.l (which CAN read PSV) into
;   working registers, then use the register-register form:
;       mpy.l  Wn, Wm, Acc
;       mac.l  Wn, Wm, Acc
;   This ensures correct operation regardless of memory placement.
;
;............................................................................

    .global    _mchp_mat_mult_q31        ; export

_mchp_mat_mult_q31:

;............................................................................
; Extract matrix structure fields and validate dimensions.
;............................................................................

    ; Load srcM1 and srcM2 dimensions.
    mov.w      [w0 + #MATRIX_NUMROWS_OFF], w5    ; w5  = srcM1->numRows
    mov.w      [w0 + #MATRIX_NUMCOLS_OFF], w3    ; w3  = srcM1->numCols
    mov.w      [w1 + #MATRIX_NUMROWS_OFF], w4    ; w4  = srcM2->numRows
    mov.w      [w1 + #MATRIX_NUMCOLS_OFF], w6    ; w6  = srcM2->numCols

    ; Check inner dimension: srcM1->numCols must equal srcM2->numRows.
    cp         w3, w4
    bra        nz, size_mismatch

    ; Load dstM dimensions.
    mov.w      [w2 + #MATRIX_NUMROWS_OFF], w9    ; w9  = dstM->numRows
    mov.w      [w2 + #MATRIX_NUMCOLS_OFF], w10   ; w10 = dstM->numCols

    ; dstM->numRows must equal srcM1->numRows.
    cp         w9, w5
    bra        nz, size_mismatch

    ; dstM->numCols must equal srcM2->numCols.
    cp         w10, w6
    bra        nz, size_mismatch

;............................................................................
; Load data pointers from matrix structures.
;............................................................................

    mov.l      [w0 + #MATRIX_PDATA_OFF], w4      ; w4 = srcM1->pData
    mov.l      [w1 + #MATRIX_PDATA_OFF], w5      ; w5 = srcM2->pData
    mov.l      [w2 + #MATRIX_PDATA_OFF], w7      ; w7 = dstM->pData

;............................................................................
; Save working registers and prepare for fractional computation.
;............................................................................

    push.l     w8
    push.l     w9
    push.l     w10
    push.l     w11
    push.l     w12
    push.l     w13
    push.l     w14

    push.l     CORCON
    fractsetup w10                                ; CORCON for fractional / saturating

;............................................................................
; Prepare loop counters and stride values.
;
;   w3  = numCols1Rows2 (inner dimension, then byte stride for srcM1 rows)
;   w5  = srcM2->pData base (constant)
;   w6  = numCols2 byte stride (srcM2 column stride)
;   w7  = running pointer to dstM->pData
;   w8  = numCols1Rows2 (inner loop reload count)
;   w9  = numCols2 (column loop reload count)
;   w11 = srcM1 row base pointer (advances each outer row)
;   w12 = srcM2 column base pointer (resets each outer row)
;   w13 = numRows1 (outer row loop counter)
;............................................................................

    mov.l      w3, w8                             ; w8  = numCols1Rows2
    mov.l      w6, w9                             ; w9  = numCols2
    sl.l       w3, #2, w3                         ; w3  = numCols1Rows2 * 4 (srcM1 row stride)
    sl.l       w6, #2, w6                         ; w6  = numCols2 * 4 (srcM2 column stride)
    mov.l      w4, w11                            ; w11 = srcM1 row base pointer
    mov.l      w5, w12                            ; w12 = srcM2 base pointer (constant)

    mov.w      [w2 + #MATRIX_NUMROWS_OFF], w13   ; w13 = numRows1

;............................................................................
; Outer loop: iterate over rows of srcM1.
;............................................................................

_doRows:

    mov.l      w9, w10                            ; w10 = numCols2 (column counter)
    mov.l      w12, w2                            ; w2  = srcM2 column pointer (reset to base)

_doCols:

;............................................................................
; Inner loop: compute dot product of srcM1 row[i] and srcM2 col[j].
;
;   Both operands are pre-loaded via mov.l into registers (w14, w0)
;   before mpy.l / mac.l to handle const/PSV source data correctly.
;   w4  = running srcM1 row pointer.
;   w1  = running srcM2 column pointer (steps by w6 = numCols2 bytes).
;............................................................................

    mov.l      w11, w4                            ; w4 = srcM1 row pointer (reset to row start)
    mov.l      w2, w1                             ; w1 = srcM2 column pointer (current column)

    ; First multiply: initialize accumulator.
    mov.l      [w4], w14                          ; w14 = srcM1[i][0]
    add.l      w4, #4, w4                         ; w4 -> srcM1[i][1]
    mov.l      [w1], w0                           ; w0  = srcM2[0][j]
    add.l      w1, w6, w1                         ; w1 -> srcM2[1][j]
    mpy.l      w14, w0, a                         ; a   = srcM1[i][0] * srcM2[0][j]

    ; Remaining multiply-accumulate iterations.
    mov.l      w8, w5                             ; w5 = inner loop count (numCols1Rows2)
    sub.l      w5, #1, w5                         ; w5 = numCols1Rows2 - 1
    bra        z, _storeDot                       ; If inner dim == 1, skip to store.

_doDot:
    mov.l      [w4], w14                          ; w14 = srcM1[i][k]
    add.l      w4, #4, w4                         ; w4 -> srcM1[i][k+1]
    mov.l      [w1], w0                           ; w0  = srcM2[k][j]
    add.l      w1, w6, w1                         ; w1 -> srcM2[k+1][j]
    mac.l      w14, w0, a                         ; a  += srcM1[i][k] * srcM2[k][j]
    DTB        w5, _doDot                         ; decrement w5; branch if nonzero

;............................................................................
; Store dot product result to destination matrix.
;............................................................................

_storeDot:
    sac.l      a, [w7++]                          ; dstM[i][j] = AccA (truncated); advance dst

    add.l      w2, #4, w2                         ; Advance srcM2 column pointer to next column

    dec.l      w10, w10                           ; Decrement column counter
    bra        nz, _doCols                        ; If columns remain, repeat middle loop

;............................................................................
; Advance srcM1 row pointer to next row.
;............................................................................

    add.l      w11, w3, w11                       ; w11 -> srcM1[i+1][0]

    dec.l      w13, w13                           ; Decrement row counter
    bra        nz, _doRows                        ; If rows remain, repeat outer loop

;............................................................................
; Success exit: restore saved registers and return.
;............................................................................

    pop.l      CORCON

    pop.l      w14
    pop.l      w13
    pop.l      w12
    pop.l      w11
    pop.l      w10
    pop.l      w9
    pop.l      w8

    mov.l      #MathSuccess, w0
    return

;............................................................................
; Error exit: matrix dimensions do not match.
;............................................................................

size_mismatch:
    mov.l      #MathSizeMismatch, w0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF
