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
;    software) that may accompany Microchip software. SOFTWARE IS "AS IS."   *
;    NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS     *
;    SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,         *
;    MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT       *
;    WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,           *
;    INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY        *
;    KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF        *
;    MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE        *
;    FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIPS           *
;    TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT          *
;    EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR       *
;   THIS SOFTWARE.                                                           *
;*****************************************************************************

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Local inclusions.

    .nolist
    .include    "dspcommon.inc"      ; Common DSP definitions
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_copy_q31: Fixed-point (Q31) vector copy.
;
; Description:
;    Copies elements from a Q31 source vector to a Q31 destination vector.
;    This is a pure data-movement operation — no arithmetic, no accumulator,
;    no CORCON/FCR setup required.
;
;    dsPIC33AK does NOT have the REPEAT instruction; DTB is used for
;    all loop control.
;
; Operation:
;    pDst[n] = pSrc[n], with
;
;    n in {0, 1, ... , blockSize-1}
;
; Input:
;    w0 = ptr to source vector (pSrc)
;    w1 = ptr to destination vector (pDst)
;    w2 = number of elements to copy (blockSize)
;
; Return:
;    no return value (void)
;
; System resources usage:
;    {w0..w2}    used, not restored
;
; Notes:
;    - pSrc and pDst must not overlap (undefined behavior if they do).
;    - Each element is 32 bits (4 bytes, sizeof(q31_t)).
;    - No CORCON or FCR setup is needed (pure data movement).
;    - No accumulator or FPU register is used.
;
;............................................................................

    .global    _mchp_copy_q31        ; export

_mchp_copy_q31:

;............................................................................
; Early exit check.
;............................................................................

    cp0.l      w2                     ; blockSize == 0 ? (32-bit compare)
    bra        z, _copy_exit          ; Yes => nothing to copy, exit.

;............................................................................
; Copy loop: copy each Q31 element from pSrc to pDst.
;
;   w0 = running pSrc pointer (post-incremented each iteration)
;   w1 = running pDst pointer (post-incremented each iteration)
;   w2 = loop counter (blockSize, decremented by DTB)
;
;   The mov.l instruction performs a 32-bit data move from source
;   to destination. Post-increment addressing advances both pointers
;   by 4 bytes (sizeof(q31_t)) per iteration.
;
;   DTB (Decrement-Test-Branch) is used instead of REPEAT, as the
;   dsPIC33AK512MPS512 does not support the REPEAT instruction.
;............................................................................

v_copy_start:
    mov.l      [w0++], [w1++]       ; pDst[n] = pSrc[n].
                                      ; Post-increment pSrc pointer (+4 bytes).
                                      ; Post-increment pDst pointer (+4 bytes).

    DTB        w2, v_copy_start      ; Decrement 32-bit blockSize counter (w2);
                                      ; branch to v_copy_start if not zero.

;............................................................................
; Exit: return to caller.
;............................................................................

_copy_exit:
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF