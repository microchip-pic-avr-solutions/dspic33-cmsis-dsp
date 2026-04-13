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

    ; Static variable: start of YMOD delay buffer (Q31)
    .section *,bss,near
    .global _firPStateStart_q31
    .align 4
_firPStateStart_q31:   .space 4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_fir_init_q31: Initialization of Q31 FIR filter structure.
;
; Description:
;    Initializes the Q31 FIR filter instance structure with the number
;    of taps, coefficient pointer, and state buffer pointer. Saves the
;    state buffer start address for use as YMOD base during filtering.
;
;    Mirrors the mchp_fir_init_f32.s implementation [44].
;
; Input:
;    w0 = S, ptr to mchp_fir_instance_q31 filter structure
;    w1 = numTaps
;    w2 = pCoeffs (const q31_t*)
;    w3 = pState  (q31_t*)
;
; Return:
;    (void)
;
; System resources usage:
;    {w0..w3}    used, not restored
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .global    _mchp_fir_init_q31    ; export
_mchp_fir_init_q31:

;............................................................................

    ; Set up filter structure (same layout as f32) [44].
    mov.l    w1, [w0]                          ; S->numTaps = numTaps
                                                ; w0 =&(S->numTaps)

    mov.l    w2, [w0 + firPCoeffs_q31]         ; S->pCoeffs = pCoeffs
                                                ; w0 =&(S->pCoeffs)

    mov.l    w3, [w0 + firPState_q31]          ; S->pState = pState
                                                ; w0 =&(S->pState)

    mov.l    w3, _firPStateStart_q31           ; Save start of YMOD buffer [44]

;............................................................................

    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF