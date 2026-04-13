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
    .include    "dspcommon.inc"      ; fractsetup macro, matrix structure offsets
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_mat_sub_q31: Fixed-point (Q31) matrix subtraction.
;
; Description:
;    Element-by-element subtraction of two Q31 source matrices, storing the
;    saturated result into a destination matrix.
;    Dimensions of all three matrices (srcM1, srcM2, dstM) must match.
;
; Operation:
;    dstM[i][j] = srcM1[i][j] - srcM2[i][j]
;
;    i in {0, 1, ... , numRows-1}
;    j in {0, 1, ... , numCols-1}
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
;    {w0..w10}   used, not restored ({w8..w10} saved/restored)
;     AccuA      used, not restored
;     AccuB      used, not restored
;     CORCON     saved, used, restored
;
;............................................................................

    .global    _mchp_mat_sub_q31        ; export

_mchp_mat_sub_q31:

;............................................................................
; Save callee-saved registers.
;............................................................................

    push.l     w8
    push.l     w9
    push.l     w10

;............................................................................
; Extract matrix structure fields.
;............................................................................

    ; Load number of rows and columns from srcM1.
    mov.w      [w0 + #MATRIX_NUMROWS_OFF], w3    ; w3 = srcM1->numRows
    mov.w      [w0 + #MATRIX_NUMCOLS_OFF], w4    ; w4 = srcM1->numCols
    mov.l      [w0 + #MATRIX_PDATA_OFF],   w6    ; w6 = pointer to srcM1->pData

    ; Load number of rows and columns from srcM2.
    mov.w      [w1 + #MATRIX_NUMROWS_OFF], w9    ; w9  = srcM2->numRows
    mov.w      [w1 + #MATRIX_NUMCOLS_OFF], w10   ; w10 = srcM2->numCols
    mov.l      [w1 + #MATRIX_PDATA_OFF],   w7    ; w7  = pointer to srcM2->pData

;............................................................................
; Validate matrix dimensions (srcM1 vs srcM2).
;............................................................................

    ; Check for matching dimensions between srcM1 and srcM2.
    cp         w3, w9                             ; Compare numRows: srcM1 vs srcM2
    bra        nz, size_mismatch                  ; If not equal, branch to error
    cp         w4, w10                            ; Compare numCols: srcM1 vs srcM2
    bra        nz, size_mismatch                  ; If not equal, branch to error

;............................................................................
; Validate matrix dimensions (srcM1 vs dstM).
;............................................................................

    ; Load number of rows and columns from dstM.
    mov.w      [w2 + #MATRIX_NUMROWS_OFF], w9    ; w9  = dstM->numRows
    mov.w      [w2 + #MATRIX_NUMCOLS_OFF], w10   ; w10 = dstM->numCols

    ; Check for matching dimensions between srcM1 and dstM.
    cp         w3, w9                             ; Compare numRows: srcM1 vs dstM
    bra        nz, size_mismatch                  ; If not equal, branch to error
    cp         w4, w10                            ; Compare numCols: srcM1 vs dstM
    bra        nz, size_mismatch                  ; If not equal, branch to error

;............................................................................
; Load destination data pointer.
;............................................................................

    mov.l      [w2 + #MATRIX_PDATA_OFF], w8      ; w8 = pointer to dstM->pData

;............................................................................
; Compute total number of elements.
;............................................................................

    muluu.l    w3, w4, w0                         ; w0 = numRows * numCols (total elements)

;............................................................................
; Prepare for fractional computation.
;............................................................................

    push.l     CORCON                             ; Save 32-bit CORCON.
    fractsetup w5                                 ; Setup CORCON for fractional/saturating
                                                  ; arithmetic; w5 used as scratch by macro.

;............................................................................
; Early exit check.
;............................................................................

    cp0.l      w0                                 ; total elements == 0 ? (32-bit compare)
    bra        z, sub_done                        ; Yes => nothing to do, exit.

;............................................................................
; Loop: subtract each Q31 matrix element.
;   w6 = running srcM1->pData pointer
;   w7 = running srcM2->pData pointer
;   w8 = running dstM->pData pointer
;   w0 = loop counter (total elements)
;............................................................................

mat_sub_start:
    lac.l      [w6++], a                          ; Load 32-bit srcM1[i][j] into Accumulator A.
                                                  ; Post-increment srcM1 data pointer.
    sub.l      [w7++], a                          ; Subtract 32-bit srcM2[i][j] from Accumulator A
                                                  ; (saturated). Post-increment srcM2 data pointer.
    sac.l      a, [w8++]                          ; Store 32-bit saturated result to dstM[i][j].
                                                  ; Post-increment dstM data pointer.

    DTB        w0, mat_sub_start                  ; Decrement 32-bit element counter (w0);
                                                  ; branch to mat_sub_start if not zero.

;............................................................................
; Success exit.
;............................................................................

sub_done:
    pop.l      CORCON                             ; Restore 32-bit CORCON.

    pop.l      w10                                ; Restore callee-saved registers.
    pop.l      w9
    pop.l      w8

    mov.l      #MathSuccess, w0                   ; Return success status.
    return

;............................................................................
; Error exit: matrix dimensions do not match.
;............................................................................

size_mismatch:
    pop.l      w10                                ; Restore callee-saved registers.
    pop.l      w9
    pop.l      w8

    mov.l      #MathSizeMismatch, w0              ; Return size mismatch error.
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF
