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
;   FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S'          *
;   TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT           *
;   EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR        *
;   THIS SOFTWARE.                                                           *
;*****************************************************************************

; Local inclusions.

    .nolist
    .include    "dspcommon.inc"
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Static variable: start of YMOD delay buffer (Q31 decimator)
    .section *, bss, near
    .global _firDecimPStateStart_q31
    .align 4
_firDecimPStateStart_q31:   .space 4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_fir_decimate_init_q31: Initialize Q31 FIR decimator instance.
;
; Description:
;    Initializes the Q31 FIR decimator instance structure with the
;    decimation factor, number of taps, coefficient pointer, and state
;    buffer pointer. Saves the state buffer start address for YMOD base.
;
; Input:
;    w0 = S            ptr to mchp_fir_decimate_instance_q31
;    w1 = numTaps      number of filter taps (M)
;    w2 = decimFactor  decimation factor (D)
;    w3 = pCoeffs      const q31_t* coefficient array
;    w4 = pState       q31_t* state buffer
;                      (must be length numTaps, 2^n aligned for YMOD)
;
; Return:
;    (void)
;
; Instance structure layout (matches C struct):
;    [S + firDecM_q31]          = M (decimFactor)  [uint8_t, offset 0]
;    [S + firDecNumTaps_q31]    = numTaps           [uint16_t, offset 2]
;    [S + firDecPCoeffs_q31]    = pCoeffs           [q31_t*, offset 4]
;    [S + firDecPState_q31]     = pState            [q31_t*, offset 8]
;
; System resources usage:
;    {w0..w4}   used, not restored
;
;............................................................................

    .global    _mchp_fir_decimate_init_q31    ; export

; Input:
;    w0 = S            ptr to mchp_fir_decimate_instance_q31
;    w1 = numTaps      number of filter taps (M)
;    w2 = M            decimation factor (D)
;    w3 = pCoeffs      const q31_t* coefficient array
;    w4 = pState       q31_t* state buffer
;    w5 = blockSize    number of input samples
;
; Return:
;    w0 = MCHP_MATH_SUCCESS or MCHP_MATH_LENGTH_ERROR

_mchp_fir_decimate_init_q31:

;............................................................................
; Validate: blockSize must be a multiple of M (decimation factor).
; divul w5, w2 => quotient in w5, Z flag set if remainder == 0.
;............................................................................

    repeat   #9
    divul    w5, w2
    bra      z, _decim_init_ok
    movs.l   #MathLengthError, w0
    return

;............................................................................
; Store structure fields (same layout as f32 struct).
;   M        -> uint8_t  at offset 0  (byte store)
;   numTaps  -> uint16_t at offset 2  (halfword store)
;   pCoeffs  -> q31_t*   at offset 4  (word store)
;   pState   -> q31_t*   at offset 8  (word store)
;............................................................................

_decim_init_ok:
    ; S->M = M (decimation factor, byte)
    mov.b    w2, [w0 + #firDecM_q31]

    ; S->numTaps = numTaps (halfword)
    mov      w1, [w0 + #firDecNumTaps_q31]

    ; S->pCoeffs = pCoeffs
    mov.l    w3, [w0 + #firDecPCoeffs_q31]

    ; S->pState = pState
    mov.l    w4, [w0 + #firDecPState_q31]

    ; Save state buffer start for YMOD base during filtering.
    mov.l    w4, _firDecimPStateStart_q31

;............................................................................

    movs.l   #MathSuccess, w0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF