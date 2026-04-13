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
        .include        "dspcommon.inc"
        .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.section .dspic33cmsisdsp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_pid_f32:
; Prototype:
;              tPID_f32* PID ( tPID_f32 *fooPIDStruct )
;
; Operation:
;
;                                             ----   Proportional
;                                            |    |  Output
;                             ---------------| Kp |-----------------
;                            |               |    |                 |
;state[0]                    |                ----                  |
;Reference                   |                                     ---
;Input         ---           |           --------------  Integral | + | Control   -------
;     --------| + |  Control |          |      Ki      | Output   |   | Output   |       |  state[2]
;             |   |----------|----------| ------------ |----------|+  |----------| Plant |--
;        -----| - |Difference|          |  1 - Z^(-1)  |          |   |          |       |  |
;       |      ---  (error)  |           --------------           | + |           -------   |
;       |                    |                                     ---                      |
;       | Measured           |         -------------------  Deriv   |                       |
;       | Outut              |        |                   | Output  |                       |
;       |                     --------| Kd * (1 - Z^(-1)) |---------                        |
;       |                             |                   |                                 |
;       |                              -------------------                                  |
;       |                                                                                   |
;       |                                                                                   |
;        -----------------------------------------------------------------------------------
;
;   controlOutput[n] = controlOutput[n-1]
;                    + controlHistory[n] * abcCoefficients[0]
;                    + controlHistory[n-1] * abcCoefficients[1]
;                    + controlHistory[n-2] * abcCoefficients[2]
;
;  where:
;   abcCoefficients[0] = Kp + Ki + Kd
;   abcCoefficients[1] = -(Kp + 2*Kd)
;   abcCoefficients[2] = Kd
;   controlHistory[n] = measuredOutput[n] - referenceInput[n]
;  where:
;   abcCoefficients, controlHistory, controlOutput, measuredOutput and controlReference
;   are all members of the data structure tPID.
;
; Input:
;       w0 = Address of tPID data structure

; Return:
;       w0 = Address of tPID data structure
;
; System resources usage:
;       {w0..w3}        used, not restored
;       {f0..f3}        used, not restored
;        FCR         saved, used, restored
;............................................................................

        .global _mchp_pid_f32                    ; provide global scope to routine
_mchp_pid_f32:

    push.l	    FCR				; save fcr             
    floatsetup      w3				; Setup fcr for default rounding mode, disabled saz/ftz, with all exceptions masked.
    
    add.l	w0,  #offsetA0_f32, w6		; w6 = Base Address of A0 A1 and A2 Coefficients array [(Kp+Ki+Kd), -(Kp+2Kd), Kd]

	
    mov.l       [w0 + offsetstate2_f32], f1     ; f1 += state[2]				
    mov.l       [w6++], f2			; f2 => (Kp+Ki+Kd)=>[A0]
    mac.s	f2, f0, f1			; f1 += (Kp+Ki+Kd) * in
						; w6 => -(Kp+2Kd)[A1]

    mov.l       [w0 + offsetstate0_f32], f2	; f2 => state[0]
    mov.l	[w6++], f3			; f3 => -(Kp+2Kd)[A1]
    mac.s	f3, f2, f1			; f1 += -(Kp+2Kd) * state[0]
						; w6 => Kd[A2]
						
    mov.l       [w6], f3			; f3 => kd
    mov.l       [w0 + offsetstate1_f32], f2
    mac.s	f3, f2, f1			; f1 += Kd * state[1]
						; f3 => Kd[A2]
    
    add.l	w0, #offsetstate0_f32, w3	;w3 -> state[0]
    add.l	w0, #offsetstate1_f32, w4	;w4 -> state[1]
    add.l	w0, #offsetstate2_f32, w5	;w5 -> state[2]
    mov.l	[w3],[w4]			;state[0] => State[1]
    mov.l	f0, [w3]			;      in => state[0]
    mov.l	f1,[w5]			        ;     out => State[2]
							
    mov.s	f1,f0				; return out
    pop.l	FCR				; restore FCR.
       

    return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OEF

