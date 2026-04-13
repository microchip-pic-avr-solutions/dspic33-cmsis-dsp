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

    ; Static variable: start of YMOD delay buffer (Q31 LMS)
    .section *, bss, near
    .global _lmsPStateStart_q31
    .align 4
_lmsPStateStart_q31:   .space 4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_lms_init_q31: Initialize Q31 LMS filter instance.
;
; Description:
;    Initializes the Q31 LMS adaptive filter instance structure with
;    the number of taps, coefficient pointer, state buffer pointer,
;    and step size (mu). Saves the state buffer start address for
;    YMOD base during filtering.
;
;    Mirrors the mchp_lms_init_f32.s implementation [56].
;
; Operation:
;    S->numTaps  = numTaps
;    S->pCoeffs  = pCoeffs
;    S->pState   = pState
;    S->mu       = mu
;
; Input:
;    w0 = S          ptr to mchp_lms_instance_q31
;    w1 = numTaps    (uint16)
;    w2 = pCoeffs    (q31_t*)
;    w3 = pState     (q31_t*)
;    w4 = mu         (q31_t) step size
;    w5 = blockSize  (uint32) number of samples per block
;
; Return:
;    (void)
;
; System resources usage:
;    {w0..w5}    used, not restored
;
;............................................................................

    .global    _mchp_lms_init_q31    ; export

_mchp_lms_init_q31:

;............................................................................
; Store instance structure fields (same layout as f32) [56].
;............................................................................

    ; S->numTaps = numTaps
    mov        w1, [w0 + #lmsNumTaps_q31]

    ; S->pCoeffs = pCoeffs
    mov.l      w2, [w0 + #lmsPCoeffs_q31]

    ; S->pState = pState
    mov.l      w3, [w0 + #lmsPState_q31]

    ; S->mu = mu (Q31 step size)
    mov.l      w4, [w0 + #lmsMu_q31]

    ; Save state buffer start for YMOD base (like f32 init) [56].
    mov.l      w3, _lmsPStateStart_q31

;............................................................................

    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF