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
; _mchp_mat_scale_q31: Fixed-point (Q31) matrix scale with post-shift.
;
; Description:
;    Multiplies every element of a Q31 source matrix by a Q31 scale value,
;    applies a post-shift, and stores the saturated result into a
;    destination matrix.  Matches the ARM CMSIS arm_mat_scale_q31 semantics:
;
;      pDst[n] = (pSrc[n] * scaleFract) >> (31 - shift)
;
;    which ARM implements as:
;      temp = ((q63_t)in * scaleFract) >> 32
;      out  = temp << (shift + 1)
;
;    The dsPIC fractional multiply (mpy.l) computes (a * b) << 1 into
;    the accumulator.  sacr.l extracts the upper 32 bits (>> 32).
;    Combined: sacr.l(mpy.l(a,b)) = (a*b) >> 31.
;    We need (a*b) >> (31 - shift), so we apply sftac a, #(-shift)
;    (negative = left shift) before sacr.l.
;
; Prototype (matches ARM CMSIS):
;    mchp_status mchp_mat_scale_q31(
;        const mchp_matrix_instance_q31 * pSrc,
;        q31_t scaleFract,
;        int32_t shift,
;        mchp_matrix_instance_q31 * pDst);
;
; Input (dsPIC33AK calling convention, 32-bit params in sequential registers):
;    w0 = pointer to source matrix structure (pSrc)
;    w1 = scale value (scaleFract), Q31 format
;    w2 = shift amount (int32_t)
;    w3 = pointer to destination matrix structure (pDst)
;
; Return:
;    w0 = status code:
;         MathSuccess        -> if operation successful
;         MathSizeMismatch   -> if matrix dimensions do not match
;
; System resources usage:
;    {w0..w7}    used, not restored
;    {w8, w13}   used, restored (callee-saved)
;     AccuA      used, not restored
;     CORCON     saved, used, restored
;
;............................................................................

    .global    _mchp_mat_scale_q31        ; export

_mchp_mat_scale_q31:

;............................................................................
; Save callee-saved registers and parameters that will be clobbered.
;............................................................................

    push.l     w8                                 ; Save w8 (will hold sftac shift value)
    push.l     w13                                ; Save w13 (used for accumulator writeback)

;............................................................................
; Save parameters before extracting matrix fields.
;   w1 = scaleFract (need to preserve)
;   w2 = shift (need to preserve)
;   w3 = pDst (need to preserve)
;............................................................................

    mov.l      w1, w8                             ; w8 = scaleFract (save)
    neg.l      w2, w4                             ; w4 = -shift (sftac amount: positive = right)

;............................................................................
; Extract matrix structure fields.
;............................................................................

    ; Load fields from pDst (w3).
    mov.w      [w3 + #MATRIX_NUMROWS_OFF], w5    ; w5 = pDst->numRows
    mov.w      [w3 + #MATRIX_NUMCOLS_OFF], w6    ; w6 = pDst->numCols
    mov.l      [w3 + #MATRIX_PDATA_OFF],   w3    ; w3 = pDst->pData

    ; Load fields from pSrc (w0).
    mov.w      [w0 + #MATRIX_NUMCOLS_OFF], w1    ; w1 = pSrc->numCols
    mov.l      [w0 + #MATRIX_PDATA_OFF],   w2    ; w2 = pSrc->pData
    mov.w      [w0 + #MATRIX_NUMROWS_OFF], w0    ; w0 = pSrc->numRows

;............................................................................
; Validate matrix dimensions.
;............................................................................

    cp         w1, w6                             ; Compare numCols
    bra        nz, size_mismatch                  ; If not equal, branch to error
    cp         w0, w5                             ; Compare numRows
    bra        nz, size_mismatch                  ; If not equal, branch to error

;............................................................................
; Prepare for fractional computation.
;............................................................................

    push.l     CORCON                             ; Save 32-bit CORCON.
    fractsetup w5                                 ; Setup CORCON for fractional/saturating
                                                  ; arithmetic; w5 used as scratch by macro.

;............................................................................
; Compute total number of elements: w0 = numRows * numCols.
;............................................................................

    muluu.l    w0, w1, w0                         ; w0 = numRows * numCols (total elements)

;............................................................................
; Setup pointers for loop.
;   w2 = running source pointer (pSrc->pData)
;   w3 = pDst->pData (will be moved to w13 for sacr.l store)
;   w8 = scaleFract
;   w4 = -shift (sftac amount)
;   w0 = loop counter (total elements)
;............................................................................

    mov.l      w3, w13                            ; w13 = running destination pointer

;............................................................................
; Scale loop: one element per iteration with sftac for shift.
;
;   For each element:
;     1. mpy.l w8, [w2]+=4, a  -- fractional multiply: a = scaleFract * pSrc[n] << 1
;     2. sftac a, w4            -- shift accumulator by -shift (left shift by shift)
;     3. sacr.l a, [w13++]     -- store saturated Q31 result to pDst[n]
;............................................................................

    cp0.l      w0                                 ; blockSize == 0?
    bra        z, scale_done                      ; Yes => nothing to do

scale_loop:
    mpy.l      w8, [w2]+=4, a                    ; a = scaleFract * pSrc[n] (fractional, <<1)
    sftac      a, w4                              ; a shift by -shift (left shift by shift)
    sacr.l     a, [w13++]                         ; pDst[n] = saturated Q31 result

    DTB        w0, scale_loop                     ; Decrement counter; branch if not zero.

;............................................................................
; Success exit.
;............................................................................

scale_done:
    pop.l      CORCON                             ; Restore 32-bit CORCON.
    pop.l      w13                                ; Restore w13.
    pop.l      w8                                 ; Restore w8.

    mov.l      #MathSuccess, w0                   ; Return success status.
    return

;............................................................................
; Error exit: matrix dimensions do not match.
;............................................................................

size_mismatch:
    pop.l      w13                                ; Restore w13.
    pop.l      w8                                 ; Restore w8.

    mov.l      #MathSizeMismatch, w0              ; Return size mismatch error.
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF
