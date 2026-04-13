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
; _mchp_pid_init_q31: Initialize Q31 PID controller and compute coefficients.
;
; Description:
;    Initializes the Q31 PID controller instance structure and computes
;    the derived PID coefficients A0, A1, A2 from the user-supplied
;    Kp, Ki, Kd gains.
;
;    Mirrors mchp_pid_init_f32.s [73] and pid_aa.s _PIDCoeffCalc [71]:
;
;      A0 = Kp + Ki + Kd
;      A1 = -(Kp + 2*Kd)
;      A2 = Kd
;
;    Optionally resets the controller state (state0, state1, state2)
;    if the reset flag (w1) is nonzero.
;
; Input:
;    w0 = S     ptr to mchp_pid_instance_q31
;    w1 = reset flag (0 = do not reset, nonzero = reset states to 0)
;
; Instance structure layout (mchp_pid_instance_q31):
;    [S + offsetKp_q31]     = Kp     (q31_t)
;    [S + offsetKi_q31]     = Ki     (q31_t)
;    [S + offsetKd_q31]     = Kd     (q31_t)
;    [S + offsetA0_q31]     = A0     (q31_t) = Kp + Ki + Kd
;    [S + offsetA1_q31]     = A1     (q31_t) = -(Kp + 2*Kd)
;    [S + offsetA2_q31]     = A2     (q31_t) = Kd
;    [S + offsetstate0_q31] = state0 (q31_t) = error history e[n]
;    [S + offsetstate1_q31] = state1 (q31_t) = error history e[n-1]
;    [S + offsetstate2_q31] = state2 (q31_t) = accumulated output
;
; Return:
;    (void)
;
; System resources usage:
;    {w0..w5}    used, not restored
;     AccuA      used, not restored
;     AccuB      used, not restored
;     CORCON     saved, used, restored
;
;............................................................................

    .global    _mchp_pid_init_q31    ; export

_mchp_pid_init_q31:

;............................................................................
; Prepare CORCON for fractional computation [73].
;............................................................................

    push.l    CORCON
    fractsetup w2

;............................................................................
; Load Kp, Ki, Kd from instance structure [73].
;............................................................................

    mov.l     [w0 + #offsetKp_q31], w2         ; w2 = Kp
    mov.l     [w0 + #offsetKi_q31], w3         ; w3 = Ki
    mov.l     [w0 + #offsetKd_q31], w4         ; w4 = Kd

;............................................................................
; Compute A0 = Kp + Ki + Kd [71][73].
;............................................................................

    lac.l     w2, a                             ; a = Kp
    add.l     w3, a                             ; a = Kp + Ki
    add.l     w4, a                             ; a = Kp + Ki + Kd
    sacr.l    a, w5                             ; w5 = A0
    mov.l     w5, [w0 + #offsetA0_q31]         ; Store A0.

;............................................................................
; Compute A1 = -(Kp + 2*Kd) [71][73].
;............................................................................

    lac.l     w4, a                             ; a = Kd
    add.l     w4, a                             ; a = 2*Kd
    add.l     w2, a                             ; a = Kp + 2*Kd
    neg       a                                 ; a = -(Kp + 2*Kd)
    sacr.l    a, w5                             ; w5 = A1
    mov.l     w5, [w0 + #offsetA1_q31]         ; Store A1.

;............................................................................
; Compute A2 = Kd [71][73].
;............................................................................

    mov.l     w4, [w0 + #offsetA2_q31]         ; A2 = Kd (direct copy).

;............................................................................
; Optionally reset states [73].
;............................................................................

    cp0       w1
    bra       z, _pid_init_no_reset

    mov.l     #0x0, w2
    mov.l     w2, [w0 + #offsetstate0_q31]     ; state0 = 0
    mov.l     w2, [w0 + #offsetstate1_q31]     ; state1 = 0
    mov.l     w2, [w0 + #offsetstate2_q31]     ; state2 = 0

_pid_init_no_reset:

;............................................................................
; Restore CORCON and return [73].
;............................................................................

    pop.l     CORCON
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF