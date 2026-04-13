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
; _FIRStructInit: Initialization of FIR folating-point filter structure.
;
; Operation:
;    arm_fir_decimate_instance_f32 ->numTaps = numTaps;
;    arm_fir_decimate_instance_f32->M = M;
;    arm_fir_decimate_instance_f32->pCoeffs = pCoeffs;
;    arm_fir_decimate_instance_f32->pState = pState;
;    arm_fir_decimate_instance_f32->blockSize = blockSize;
;
; Input:
;    w0 = h, ptr arm_fir_decimate_instance_f32 filter structure (see included file)
;    w1 = numTaps;
;    w2 = firDecM_f32;
;    w3 = firDecPCoeffs_f32;
;    w4 = firDecPState_f32;
; Return:       execution status
;                   - \ref MCHP_MATH_SUCCESS      : Operation successful
;                  - \ref MCHP_MATH_LENGTH_ERROR : <code>blockSize</code> is not a multiple of <code>M</code>
;
; System resources usage:
;    {w0..w5}    used, not restored
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .global    _mchp_fir_decimate_init_f32    ; export
_mchp_fir_decimate_init_f32:
    repeat #9 
    divul     w5,w2
    bra z,    blockLengthCheck
    movs.l    #MathLengthError,w0
    return
;............................................................................
blockLengthCheck:
    ; Set up filter structure.
    mov      w1,[w0+firDecNumTaps_f32]        
    mov.b    w2,[w0+firDecM_f32] 
    mov.l    w3,[w0+firDecPCoeffs_f32]        
    mov.l    w4,[w0+firDecPState_f32]        
;............................................................................
    movs.l    #MathSuccess,w0
    return    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OEF



