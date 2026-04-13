;*****************************************************************************
;                                                                            *
;                       Software License Agreement                           *
;*****************************************************************************
;*****************************************************************************
; © [2026] Microchip Technology Inc. and its subsidiaries.                    *
;                                                                            *
;   Subject to your compliance with these terms, you may use Microchip       *
;   software and any derivatives exclusively with Microchip products.        *
;   You are responsible for complying with third-party license terms         *
;   applicable to your use of third-party software (including open source    *
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
;   EXCEED THE AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR    *
;   THIS SOFTWARE.                                                           *
;*****************************************************************************

    ; Local inclusions.
    .nolist
    .include    "dspcommon.inc"
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .dspic33cmsisdsp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_mat_init_f32: Single-precision floating-point matrix initialization.
;
; Operation:
;    S->numRows  = nRows
;    S->numCols  = nColumns
;    S->pData    = pData
;
; Inputs:
;    w0 = pointer to matrix structure S (mchp_matrix_instance_f32 *)
;    w1 = nRows (uint16_t)
;    w2 = nColumns (uint16_t)
;    w3 = pointer to data array (float32_t *)
; Return:
;    None (void)
;
; System resources usage:
;    {w0..w4}    used, not restored
;
;............................................................................

    .global    _mchp_mat_init_f32
_mchp_mat_init_f32:

    ; S->numRows = nRows
    mov.w   w1, [w0 + #MATRIX_NUMROWS_OFF]           ; Store nRows at S+0

    ; S->numCols = nColumns
    mov.w   w2, [w0 + #MATRIX_NUMCOLS_OFF]           ; Store nColumns at S+2

    ; S->pData = pData (32-bit pointer)
    mov.l   w3, [w0 + #MATRIX_PDATA_OFF]             ; Store pData at S+4

    return

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End of File

