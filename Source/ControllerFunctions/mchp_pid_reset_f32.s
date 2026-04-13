;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; _mchp_pid_reset_f32:
;
;
; Operation: Clears State[0], State[1], State[2]
; Input:
;       w0 = Address of PID data structure, pid_instance_f32 
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

        .global _mchp_pid_reset_f32                 ; provide global scope to routine
_mchp_pid_reset_f32:

        push.l    FCR                               ; Save FCR             
        floatsetup      w1                          ; Setup FCR for default rounding mode, disabled FTZ/SAZ and mask all excpetions.

	    mov.l	#0x0, w1
        mov.l   w1, [w0+ offsetstate0_f32]
        mov.l   w1, [w0+ offsetstate1_f32]
        mov.l   w1, [w0+ offsetstate2_f32]
        
	pop.l   FCR                                     ; restore FCR.
        return
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OEF

