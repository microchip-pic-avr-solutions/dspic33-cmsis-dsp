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
; _mchp_pid_reset_q31: Reset Q31 PID controller states.
;
; Description:
;    Clears the PID controller state variables (error history and
;    accumulated output) to zero. Does NOT modify the PID gains
;    (Kp, Ki, Kd) or the derived coefficients (A0, A1, A2).
;
;    Mirrors mchp_pid_reset_f32.s [74].
;
; Operation:
;    state0 = 0  (e[n-1])
;    state1 = 0  (e[n-2])
;    state2 = 0  (accumulated output)
;
; Input:
;    w0 = S     ptr to mchp_pid_instance_q31
;
; Return:
;    (void)
;
; System resources usage:
;    {w0, w1}    used, not restored
;
;............................................................................

    .global    _mchp_pid_reset_q31    ; export

_mchp_pid_reset_q31:

;............................................................................
; Clear all three state variables [74].
;............................................................................

    mov.l     #0x0, w1
    mov.l     w1, [w0 + #offsetstate0_q31]     ; state0 = 0 (e[n-1])
    mov.l     w1, [w0 + #offsetstate1_q31]     ; state1 = 0 (e[n-2])
    mov.l     w1, [w0 + #offsetstate2_q31]     ; state2 = 0 (accumulated output)

;............................................................................

    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF