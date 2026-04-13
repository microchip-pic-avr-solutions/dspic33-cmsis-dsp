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
    .include    "dspcommon.inc"        
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .dspic33cmsisdsp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_fir_interpolate_init_f32: Initialization of FIR interpolate folating-point filter structure.
;
; Operation:
;    mchp_fir_interpolate_instance_f32->L = L;
;    mchp_fir_interpolate_instance_f32->phaseLength = phaseLength;
;    mchp_fir_interpolate_instance_f32->pCoeffs = pCoeffs;
;    mchp_fir_interpolate_instance_f32->pState = pState;
;
; Input:
;    w0 = h, ptr _mchp_fir_interpolate_init_f32 filter structure (see included file)
;    w1 = L (upsample factor);
;    w2 = numTaps(filter coefficients);
;    w3 = pCoeffs (pointer to coefficients);
;    w4 = pState (pointer to state buffer);
;    w5 = blockSize (N, number of input samples (N = p*R, 1 < p integer));
; Return:
;                   - \ref MCHP_MATH_SUCCESS      : Operation successful
;                  - \ref MCHP_MATH_LENGTH_ERROR : <code>numTaps</code> is not a multiple of <code>L</code>
;
;
; System resources usage:
;    {w0..w5}    used, not restored
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .global    _mchp_fir_interpolate_init_f32    ; export
_mchp_fir_interpolate_init_f32:

;............................................................................
    mov.b     w2,w6
    repeat #9 
    divul     w6,w1
    bra z,    lengthCheck
    movs.l    #MathLengthError,w0
    return
;............................................................................
lengthCheck:

    ; Set up filter structure.
    mov.b    w1,[w0+firInterL_f32]        
    mov      w2,[w0+firInterPLen_f32] 
    mov.l    w3,[w0+firInterPCoeffs_f32]        
    mov.l    w4,[w0+firInterPState_f32]        
;............................................................................
    movs.l    #MathSuccess,w0

    return    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OEF



