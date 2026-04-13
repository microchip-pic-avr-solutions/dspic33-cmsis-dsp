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
    .include    "dspcommon.inc"
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_biquad_cascade_df1_init_q31: Initialize Q31 DF1 biquad cascade.
;
; Description:
;    Initializes the Q31 Direct Form I biquad cascade filter instance.
;
;    Direct Form I uses 4 state elements per section:
;      x[n-1], x[n-2], y[n-1], y[n-2]
;
;    Coefficient layout per section (5 x q31_t):
;      b0, b1, b2, a1, a2
;
;    State layout per section (4 x q31_t):
;      x[n-1], x[n-2], y[n-1], y[n-2]
;
; Input:
;    w0 = S          ptr to mchp_biquad_cascade_df1_instance_q31
;    w1 = numStages  (uint8) number of 2nd order stages
;    w2 = pCoeffs    (const q31_t*) coefficient array [b0,b1,b2,a1,a2]*S
;    w3 = pState     (q31_t*) state buffer [x1,x2,y1,y2]*S
;    w4 = postShift  (int8) bit shift applied to output of each stage
;
; Return:
;    (void)
;
; System resources usage:
;    {w0..w4}    used, not restored
;
;............................................................................

    .global    _mchp_biquad_cascade_df1_init_q31

_mchp_biquad_cascade_df1_init_q31:

    ; S->numStages = numStages
    mov.b      w1, [w0 + #iirCasNumStage_q31]

    ; S->pCoeffs = pCoeffs
    mov.l      w2, [w0 + #iirCasPCoeffs_q31]

    ; S->pState = pState
    mov.l      w3, [w0 + #iirCasPState_q31]

    ; S->postShift = postShift
    mov.b      w4, [w0 + #iirCasPostShift_q31]

    return

    .end
