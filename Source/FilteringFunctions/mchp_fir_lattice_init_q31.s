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
; _mchp_fir_lattice_init_q31: Initialize Q31 FIR lattice filter instance.
;
; Description:
;    Initializes the Q31 FIR lattice filter instance structure with the
;    number of stages, reflection coefficient pointer, and state buffer
;    pointer.
;
;    Mirrors the mchp_fir_lattice_init_f32 API from filtering_functions.h [45].
;
; Operation:
;    S->numStages = numStages
;    S->pCoeffs   = pCoeffs  (reflection coefficients k[0..M-1])
;    S->pState    = pState   (delay line g(m)[n-1], m = 0..M-1)
;
; Input:
;    w0 = S          ptr to mchp_fir_lattice_instance_q31
;    w1 = numStages  (uint16) number of lattice stages (M)
;    w2 = pCoeffs    (const q31_t*) reflection coefficients
;    w3 = pState     (q31_t*) state buffer (length = numStages)
;
; Return:
;    (void)
;
; System resources usage:
;    {w0..w3}    used, not restored
;
;............................................................................

    .global    _mchp_fir_lattice_init_q31    ; export

_mchp_fir_lattice_init_q31:

;............................................................................
; Store instance structure fields.
;   Layout matches float version (numStages, pCoeffs, pState) [45].
;............................................................................

    ; S->numStages = numStages
    mov.l    w1, [w0 + #firLatticeNumStages_q31]

    ; S->pCoeffs = pCoeffs (reflection coefficients)
    mov.l    w2, [w0 + #firLatticePCoeffs_q31]

    ; S->pState = pState (delay line)
    mov.l    w3, [w0 + #firLatticePState_q31]

;............................................................................

    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF