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
    .include    "dspcommon.inc"      ; Common DSP definitions, matrix structure offsets
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_mat_trans_q31: Fixed-point (Q31) matrix transposition.
;
; Description:
;    Transposes a Q31 source matrix and stores the result into a destination
;    matrix. The destination matrix must have swapped dimensions relative to
;    the source (dstM->numRows == srcM->numCols and
;    dstM->numCols == srcM->numRows).
;
; Operation:
;    dstM[i][j] = srcM[j][i]
;
;    i in {0, 1, ... , srcM->numCols-1}
;    j in {0, 1, ... , srcM->numRows-1}
;
; Input:
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
;
;............................................................................

    .global    _mchp_mat_trans_q31        ; export

_mchp_mat_trans_q31:

;............................................................................
; Extract matrix structure fields from srcM.
;............................................................................

    ; Load number of rows and columns from srcM.
    mov.w      [w0 + #MATRIX_NUMROWS_OFF], w4    ; w4 = srcM->numRows
    mov.w      [w0 + #MATRIX_NUMCOLS_OFF], w5    ; w5 = srcM->numCols
    mov.l      [w0 + #MATRIX_PDATA_OFF],   w3    ; w3 = pointer to srcM->pData

;............................................................................
; Extract matrix structure fields from dstM.
;............................................................................

    ; Load number of rows and columns from dstM.
    mov.w      [w1 + #MATRIX_NUMROWS_OFF], w6    ; w6 = dstM->numRows
    mov.w      [w1 + #MATRIX_NUMCOLS_OFF], w7    ; w7 = dstM->numCols
    mov.l      [w1 + #MATRIX_PDATA_OFF],   w2    ; w2 = pointer to dstM->pData

;............................................................................
; Validate matrix dimensions.
;    dstM->numRows must equal srcM->numCols (transposed rows).
;    dstM->numCols must equal srcM->numRows (transposed cols).
;............................................................................

    cp         w6, w5                             ; Compare dstM->numRows vs srcM->numCols
    bra        nz, size_mismatch                  ; If not equal, branch to error

    cp         w7, w4                             ; Compare dstM->numCols vs srcM->numRows
    bra        nz, size_mismatch                  ; If not equal, branch to error

;............................................................................
; Prepare loop counters and row stride.
;
;   w4 = srcM->numRows (inner loop count for DTB, saved/restored each column)
;   w5 = srcM->numCols (outer loop counter — columns of srcM)
;   w3 = running srcM column base pointer (advances each outer iteration)
;   w2 = running dstM data pointer (sequential write)
;   w1 = row stride in bytes = srcM->numCols * 4
;............................................................................

    sl.l       w5, #2, w1                         ; w1 = srcM->numCols * 4 (row stride in bytes
                                                  ;       to step down one row in srcM).
                                                  ; w4 = srcM->numRows (inner loop count for DTB).
                                                  ; DTB executes body w4 times (decrement-then-branch-if-nonzero),
                                                  ; so w4 = numRows gives exactly numRows iterations.

;............................................................................
; Outer loop: iterate over columns of srcM (each column becomes a row
;             in dstM). w5 = column counter.
;............................................................................

    push.l     w4                                 ; Save inner loop count on stack.

startCol:

;............................................................................
; Inner loop: iterate over rows of srcM for the current column.
;   w6 -> current srcM column pointer (walks down rows).
;   w4 -> inner loop counter (srcM->numRows).
;............................................................................

    mov.l      w3, w6                             ; w6 = pointer to srcM[0][c] (column base).

startRows:
    ; Copy srcM[r][c] to dstM[c][r] (transposed position).
    mov.l      [w6], [w2++]                       ; dstM[c][r] = srcM[r][c].
                                                  ; Post-increment dstM pointer (sequential write).
    add.l      w6, w1, w6                         ; w6 -> srcM[r+1][c] (step down by row stride).

    DTB        w4, startRows                      ; Decrement inner counter (w4);
                                                  ; branch to startRows if not zero.

;............................................................................
; Advance to next column of srcM.
;............................................................................

    mov.l      [w15-4], w4                        ; Restore w4 (inner loop count) from stack.
    add.l      #4, w3                             ; w3 -> srcM[0][c+1] (next column base pointer).

    DTB        w5, startCol                       ; Decrement outer column counter (w5);
                                                  ; branch to startCol if not zero.

;............................................................................
; Clean up stack.
;............................................................................

    pop.l      w4                                 ; Remove saved inner loop count from stack.

;............................................................................
; Success exit.
;............................................................................

    mov.l      #MathSuccess, w0                   ; Return success status.
    return

;............................................................................
; Error exit: matrix dimensions do not match.
;............................................................................

size_mismatch:
    mov.l      #MathSizeMismatch, w0              ; Return size mismatch error.
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF
