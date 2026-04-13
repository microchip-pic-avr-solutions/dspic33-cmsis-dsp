;*****************************************************************************
;                                                                            *
;                       Software License Agreement                           *
;*****************************************************************************
;*****************************************************************************
;© [2026] Microchip Technology Inc. and its subsidiaries.                    *
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
;   INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY        *
;   KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF         *
;   MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE         *
;   FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S           *
;   TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT           *
;   EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR        *
;   THIS SOFTWARE.                                                           *
;*****************************************************************************

; Local inclusions.

    .nolist
    .include    "dspcommon.inc"
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_fir_interpolate_init_q31: Initialize Q31 FIR interpolator instance.
;
; Description:
;    Initializes the Q31 FIR interpolator instance structure with the
;    interpolation factor (L), number of filter taps (numTaps),
;    coefficient pointer, and state buffer pointer.
;
;    Validates that numTaps is a multiple of L. Returns error otherwise.
;
;    Mirrors the mchp_fir_interpolate_init_f32.s implementation [48].
;
; Operation:
;    S->L        = L
;    S->pLen     = numTaps
;    S->pCoeffs  = pCoeffs
;    S->pState   = pState
;
; Input:
;    w0 = S         ptr to mchp_fir_interpolate_instance_q31
;    w1 = L         interpolation (upsample) factor
;    w2 = numTaps   total number of filter coefficients (must be multiple of L)
;    w3 = pCoeffs   const q31_t* coefficient array
;    w4 = pState    q31_t* state buffer
;    w5 = blockSize (uint32) number of input samples
;
; Return:
;    w0 = status code:
;         MathSuccess      -> if operation successful
;         MathLengthError  -> if numTaps is not a multiple of L
;
; System resources usage:
;    {w0..w6}    used, not restored
;
;............................................................................

    .global    _mchp_fir_interpolate_init_q31    ; export

_mchp_fir_interpolate_init_q31:

;............................................................................
; Validate: numTaps must be a multiple of L.
;   Compute numTaps mod L. If remainder != 0, return error.
;............................................................................

    mov.b     w2, w6                          ; w6 = numTaps (copy for division)
    repeat    #9
    divul     w6, w1                          ; w6 = numTaps / L, remainder in w6?
                                               ; (uses standard dsPIC divul sequence)
    bra       z, _interp_init_ok              ; If remainder == 0, numTaps is multiple of L.

    ; numTaps is NOT a multiple of L => return error.
    movs.l    #MathLengthError, w0
    return

;............................................................................
; Store structure fields (same layout as f32) [48].
;............................................................................

_interp_init_ok:

    ; S->L = L (interpolation factor)
    mov.b     w1, [w0 + #firInterL_q31]

    ; S->pLen = numTaps (total number of filter taps)
    mov       w2, [w0 + #firInterPLen_q31]

    ; S->pCoeffs = pCoeffs
    mov.l     w3, [w0 + #firInterPCoeffs_q31]

    ; S->pState = pState
    mov.l     w4, [w0 + #firInterPState_q31]

;............................................................................
; Return success.
;............................................................................

    movs.l    #MathSuccess, w0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF