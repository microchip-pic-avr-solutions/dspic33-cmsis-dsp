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
; _mchp_pid_q31: Q31 PID Controller (velocity/incremental form).
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PID Control Block Diagram:
;
;                                             ----   Proportional
;                                            |    |  Output
;                             ---------------| Kp |-----------------
;                            |               |    |                 |
;  state[0]                  |                ----                  |
;  Reference                 |                                     ---
;  Input         ---         |           --------------  Integral | + | Control   -------
;       --------| + | Error  |          |      Ki      | Output   |   | Output   |       |  state[2]
;               |   |--------|----------| ------------ |----------|+  |----------| Plant |--
;          -----| - |  (e)   |          |  1 - Z^(-1)  |          |   |          |       |  |
;         |      ---         |           --------------           | + |           -------   |
;         |                  |                                     ---                      |
;         | Measured         |         -------------------  Deriv   |                       |
;         | Output           |        |                   | Output  |                       |
;         |                   --------| Kd * (1 - Z^(-1)) |---------                        |
;         |                           |                   |                                 |
;         |                            -------------------                                  |
;         |                                                                                 |
;         |                                                                                 |
;          ---------------------------------------------------------------------------------
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Velocity (Incremental) PID Algorithm:
;
;   controlOutput[n] = controlOutput[n-1]
;                    + controlHistory[n]   * abcCoefficients[0]
;                    + controlHistory[n-1] * abcCoefficients[1]
;                    + controlHistory[n-2] * abcCoefficients[2]
;
; Where:
;   abcCoefficients[0] = A0 = Kp + Ki + Kd
;   abcCoefficients[1] = A1 = -(Kp + 2*Kd)
;   abcCoefficients[2] = A2 = Kd
;
;   controlHistory[n]   = e[n]   = measuredOutput[n] - referenceInput[n]
;   controlHistory[n-1] = e[n-1] = previous error (state0)
;   controlHistory[n-2] = e[n-2] = two-samples-ago error (state1)
;
;   controlOutput[n-1]  = state2 (accumulated output from previous call)
;   controlOutput[n]    = new accumulated output (stored back to state2)
;
; Note:
;   abcCoefficients, controlHistory, controlOutput, measuredOutput
;   and referenceInput are all members of the PID data structure.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Instance structure layout (mchp_pid_instance_q31):
;
;   Offset                     Field        Description
;   -------------------------  ----------   --------------------------------
;   [S + offsetKp_q31]         Kp           Proportional gain (q31_t)
;   [S + offsetKi_q31]         Ki           Integral gain (q31_t)
;   [S + offsetKd_q31]         Kd           Derivative gain (q31_t)
;   [S + offsetA0_q31]         A0           = Kp + Ki + Kd (q31_t)
;   [S + offsetA1_q31]         A1           = -(Kp + 2*Kd) (q31_t)
;   [S + offsetA2_q31]         A2           = Kd (q31_t)
;   [S + offsetstate0_q31]     state0       = e[n-1] error history (q31_t)
;   [S + offsetstate1_q31]     state1       = e[n-2] error history (q31_t)
;   [S + offsetstate2_q31]     state2       = controlOutput[n-1] (q31_t)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Prototype:
;   q31_t mchp_pid_q31(mchp_pid_instance_q31 *S, q31_t in);
;
; Operation:
;   1. Load coefficients A0, A1, A2 from instance.
;   2. Load error history e[n-1], e[n-2] and accumulated output from instance.
;   3. Compute:
;        a  = controlOutput[n-1]
;        a += A0 * e[n]
;        a += A1 * e[n-1]
;        a += A2 * e[n-2]
;        controlOutput[n] = Sat(Round(a))
;   4. Shift error history:
;        e[n-2] = e[n-1]
;        e[n-1] = e[n]
;   5. Store new controlOutput[n] into state2.
;   6. Return output in w0 (C calling convention).
;
; Input:
;   w0 = Address of PID data structure (mchp_pid_instance_q31 *S)
;   w1 = Current error input e[n] (q31_t)
;
; Return:
;   w0 = PID control output (q31_t)
;
; System resources usage:
;   {w0..w7}    used, not restored
;    AccuA      used, not restored
;    CORCON     saved, used, restored
;
; Cycle count: ~16 cycles per PID iteration (matches pid_aa.s [71])
;
; Notes:
;   - Uses Q31 fractional multiply-accumulate via DSP AccuA.
;   - sacr.l provides saturation and rounding on output.
;   - No division or sqrt — pure 3-tap MAC chain.
;   - dsPIC33AK compatible (no REPEAT instruction used).
;   - Coefficients A0, A1, A2 must be pre-computed by
;     _mchp_pid_init_q31 before calling this function.
;
;............................................................................

    .global    _mchp_pid_q31    ; export

_mchp_pid_q31:

;............................................................................
; Prepare CORCON for fractional computation.
;............................................................................

    push.l    CORCON                            ; Save 32-bit CORCON.
    fractsetup w3                               ; Setup CORCON for fractional/saturating
                                                 ; arithmetic; w3 used as scratch by macro.

;............................................................................
; Load PID coefficients from instance structure.
;   A0 = Kp + Ki + Kd
;   A1 = -(Kp + 2*Kd)
;   A2 = Kd
;............................................................................

    mov.l     [w0 + #offsetA0_q31], w2         ; w2 = A0 = Kp + Ki + Kd.
    mov.l     [w0 + #offsetA1_q31], w3         ; w3 = A1 = -(Kp + 2*Kd).
    mov.l     [w0 + #offsetA2_q31], w4         ; w4 = A2 = Kd.

;............................................................................
; Load error history and accumulated output from instance structure.
;   state0 = e[n-1]   (previous error)
;   state1 = e[n-2]   (two-samples-ago error)
;   state2 = controlOutput[n-1]  (previous accumulated output)
;............................................................................

    mov.l     [w0 + #offsetstate0_q31], w5     ; w5 = e[n-1] (controlHistory[n-1]).
    mov.l     [w0 + #offsetstate1_q31], w6     ; w6 = e[n-2] (controlHistory[n-2]).
    mov.l     [w0 + #offsetstate2_q31], w7     ; w7 = controlOutput[n-1].

;............................................................................
; Compute PID control output using velocity (incremental) form.
;
;   AccuA = controlOutput[n-1]
;         + A0 * controlHistory[n]      (current error)
;         + A1 * controlHistory[n-1]    (previous error)
;         + A2 * controlHistory[n-2]    (two-samples-ago error)
;
;   Identical MAC chain to pid_aa.s [71]:
;     lac.l   controlOutput[n-1], a
;     mac.l   A0, e[n], a
;     mac.l   A1, e[n-1], a
;     mac.l   A2, e[n-2], a
;     sacr.l  a -> controlOutput[n]
;............................................................................

    ; Initialize accumulator with previous control output.
    lac.l     w7, a                             ; a = controlOutput[n-1].

    ; Accumulate A0 * e[n] (proportional + integral + derivative contribution).
    mac.l     w2, w1, a                         ; a += (Kp+Ki+Kd) * e[n].

    ; Accumulate A1 * e[n-1] (negative feedback of previous error).
    mac.l     w3, w5, a                         ; a += -(Kp+2Kd) * e[n-1].

    ; Accumulate A2 * e[n-2] (derivative correction from oldest error).
    mac.l     w4, w6, a                         ; a += Kd * e[n-2].

    ; Extract saturated, rounded control output.
    sacr.l    a, w7                             ; w7 = controlOutput[n] = Sat(Round(a)).

;............................................................................
; Update PID state (shift error history for next iteration).
;
;   state1 = state0      =>  e[n-2] <- e[n-1]  (shift oldest)
;   state0 = e[n]        =>  e[n-1] <- e[n]    (store current error)
;   state2 = output      =>  controlOutput[n-1] <- controlOutput[n]
;............................................................................

    ; Shift error history: e[n-2] = e[n-1].
    mov.l     w5, [w0 + #offsetstate1_q31]     ; state1 = old e[n-1].

    ; Store current error: e[n-1] = e[n].
    mov.l     w1, [w0 + #offsetstate0_q31]     ; state0 = current error input.

    ; Store new accumulated output: controlOutput[n-1] = controlOutput[n].
    mov.l     w7, [w0 + #offsetstate2_q31]     ; state2 = new control output.

;............................................................................
; Return value.
;   w0 = PID control output (q31_t, C calling convention).
;............................................................................

    mov.l     w7, w0                            ; w0 = control output (return value).

;............................................................................
; Restore CORCON and return.
;............................................................................

    pop.l     CORCON                            ; Restore 32-bit CORCON.
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF