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
; _mchp_iir_lattice_init_q31: Initialize Q31 IIR lattice filter instance.
;
; Description:
;    Initializes the Q31 IIR lattice filter instance structure with
;    the number of stages, reflection coefficient pointer (pkCoeffs),
;    ladder coefficient pointer (pvCoeffs), and state buffer pointer.
;
;    Mirrors the mchp_iir_lattice_init_f32.s implementation [58].
;    Structure layout matches filtering_functions.h [45]:
;
;    typedef struct {
;        uint16_t  numStages;
;        q31_t    *pState;
;        q31_t    *pkCoeffs;   (reflection coefficients)
;        q31_t    *pvCoeffs;   (ladder coefficients)
;    } mchp_iir_lattice_instance_q31;
;
; Operation:
;    S->numStages = numStages
;    S->pkCoeffs  = pkCoeffs
;    S->pvCoeffs  = pvCoeffs
;    S->pState    = pState
;
; Input:
;    w0 = S          ptr to mchp_iir_lattice_instance_q31
;    w1 = numStages  (uint16) number of lattice stages (M)
;    w2 = pkCoeffs   (const q31_t*) reflection coefficients k[0..M-1]
;    w3 = pvCoeffs   (const q31_t*) ladder coefficients g[0..M]
;    w4 = pState     (q31_t*) state buffer d[0..M]
;
; Return:
;    (void)
;
; System resources usage:
;    {w0..w4}    used, not restored
;
;............................................................................

    .global    _mchp_iir_lattice_init_q31    ; export

_mchp_iir_lattice_init_q31:

;............................................................................
; Store instance structure fields (same layout as f32) [58].
;............................................................................

    ; S->numStages = numStages
    mov        w1, [w0 + #iirLatticeNumStage_q31]

    ; S->pkCoeffs = pkCoeffs (reflection coefficients)
    mov.l      w2, [w0 + #iirLatticePkCoeffs_q31]

    ; S->pvCoeffs = pvCoeffs (ladder coefficients)
    mov.l      w3, [w0 + #iirLatticePvCoeffs_q31]

    ; S->pState = pState (delay line)
    mov.l      w4, [w0 + #iirLatticePState_q31]

;............................................................................

    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF