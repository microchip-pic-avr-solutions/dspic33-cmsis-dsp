;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; _mchp_pid_init_f32:
;
;
; Operation: Initialize mchp_pid_instance_f32 and compute the PID coefficients to use 
;            based on values of Kp, Ki and Kd provided. The calculated coefficients are:
;             A = Kp + Ki + Kd
;             B = -(Kp + 2*Kd)
;             C = Kd
; Input:
;       w0 = Address of PID data structure, pid_instance_f32 
;       w1 = Reset flag
;
; Return:
;       (void)
;
; System resources usage:
;       {w0..w2}        used, not restored
;       {f0..f3}        used, not restored
;        FCR         saved, used, restored
;............................................................................
        ; Local inclusions.

        .nolist
        .include        "dspcommon.inc"         ; floatsetup
        .list

        .global _mchp_pid_init_f32                ; provide global scope to routine
_mchp_pid_init_f32:

        push.l    FCR                       ; Save FCR             
        floatsetup      w2                  ; Setup FCR for default rounding mode, disabled FTZ/SAZ and mask all excpetions.
        
        ;Calculate Coefficients from Kp, Ki and Kd

        mov.l	    [w0 + offsetKp_f32], f0			; f0 = Kp
        mov.l       [w0 + offsetKi_f32], f1			; f1 = Ki
        mov.l       [w0 + offsetKd_f32], f2			; f2 = Kd
        
        add.s   f0, f1, f3           ; F3 = Kp + Ki
        add.s   f3, f2, f3           ; F3 = Kp + Ki + Kd
        
        mov.l   f3, [w0 + offsetA0_f32]           ; A0 =  (Kp + Ki + Kd)
	
	add.s   f2, f2, f3
        add.s   f0, f3, f3
        neg.s   f3, f3               ; F3 = -(Kp + 2Kd)
        
        mov.l   F3, [w0 + offsetA1_f32]           ; A1 =  -(Kp + 2Kd)
        
        mov.l   F2, [w0 + offsetA2_f32]             ; A2 = Kd

        
        
        cp0     w1
        bra     z, _doNotReset
	mov.l	#0x0, w1
        mov.l   w1, [w0+ offsetstate0_f32]
        mov.l   w1, [w0+ offsetstate1_f32]
        mov.l   w1, [w0+ offsetstate2_f32]
_doNotReset:
	pop.l   FCR                  ; restore FCR.
        return
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OEF

