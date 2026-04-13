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
; _mchp_lms_norm_f32: FIR filtering with Normalized LMS coefficient adaptation.
;
; Operation:
;    y[n] = sum_{m=0:M-1}(h[m]*x[n-m]), 0 <= n < N.
;
;    h(n+1)[m] = h(n)[m] + nu*(r[n]-y[n])*x[n-m], 0 <= m < M.
; with
;    nu[n] = mu/(mu+E[n]),
; where
;    E[n] = E[n-1] + (x[n])^2 - (x[n-M+1])^2
; an estimate of the input signal energy at each sample.
;
; x[n] defined for 0 <= n < N,
; r[n] defined for 0 <= n < N,
; y[n] defined for 0 <= n < N,
; h[m] defined for 0 <= m < M as an increasing circular buffer,
; mu in [-1, 1).
; NOTE: delay defined for 0 <= m < M as an increasing circular buffer.
; NOTE: filter coefficients should not be allocated in program memory,
;    since in this case they cannot be adapted at run time.
;
; NOTE that the energy estimate may be also expressed as:
;
;    E[n] = x[n]^2 + x[n-1]^2 + ... + x[n-M+2]^2,
;
; then, to avoid saturation while computing the estimated energy,
; the input signal values should be bound so that
;
;    sum_{m=0:-M+2}((x[n+m])^2) < 1, 0 <= n < N.
;
; Input:
;    w0 = filter structure (mchp_lms_norm_instance_f32, h)
;    w1 = x, ptr input samples (0 <= n < N)
;    w2 = r, ptr reference samples (0 <= n < N)
;    w3 = y, ptr output samples (0 <= n < N)
;    w4-> E[-1] on start up, and E[N-1] upon return.
;    w5 = N, number of input samples (N)

;
; System resources usage:
;    {w0..w7}    used, not restored
;    {f0..f6}    used, not restored
;    {w8..w12}    saved, used, restored
;     AccuA        used, not restored
;     FCR        saved, used, restored
;     CORCON        saved, used, restored
;     MODCON        saved, used, restored
;     XMODSRT    saved, used, restored
;     XMODEND    saved, used, restored
;     YMODSRT    saved, used, restored
;     YMODEND    saved, used, restored
;............................................................................
    .extern     _lmsNormPStateStart_f32
    .global     _mchp_lms_norm_f32    ; export
_mchp_lms_norm_f32:

;............................................................................

    ; Save working registers.
    push.l    w8                 ; {w8} to TOS
    push.l    w9                 ; {w9} to TOS
    push.l    w10                ; {w10} to TOS
    push.l    w11                ; {w11} to TOS
    push.l    w12                ; {w12} to TOS

;............................................................................
    ; Mask all FPU exceptions, set rounding mode to default and clear SAZ/FTZ

    push.l    FCR
    floatsetup    w7

;............................................................................

    ; Prepare core registers for modulo addressing.
    push.l    MODCON
    push.l    XMODSRT
    push.l    XMODEND
    push.l    YMODSRT
    push.l    YMODEND

;............................................................................

    ; Setup registers for modulo addressing.
    mov.l    #0xC0A8,w10                ; XWM = w8, YWM = w10
                                        ; set XMODEND and YMODEND bits
    mov.l    w10,MODCON                 ; enable X,Y modulo addressing
    
    mov    [w0+lmsNormNumTaps_f32],w7        ; w7 = M
    sl.l     w7, #2, w7                ; w7 = numCoeffs*sizeof(coeffs)
    sub.l    #1, w7                    ; w7 =  numCoeffs*sizeof(coeffs)-1


    mov.l    [w0+lmsNormPCoeffs_f32],w8    ; w8 -> h[0]
    mov.l    w8,XMODSRT                   ; init'ed to coeffs base address
                                          ; (increasing buffer,
                                          ;  2^n aligned)
    add.l    w8,w7,w9                     ; w8 -> last byte of h[M-1]
    mov.l    w9,XMODEND                   ; init'ed to coeffs end address
    
    

    mov.l    _lmsNormPStateStart_f32,w10    ; w10 -> d[0]
    mov.l    w10,YMODSRT                  ; init'ed to delay base address
                                          ; (increasing buffer,
                                          ;  2^n aligned)
    add.l    w10,w7,w10
    mov.l    w10,YMODEND                  ; init'ed to delay end address


    ; Perpare to filter all samples.
    mov.l    [w0+lmsNormPState_f32],w10  ; w10 points at current delay
                                         ; sample d[m], 0 <= m < M
                                         ; referred to as delay[0]
                                         ; for each iteration...
    mov.l    w2,w12                      ; w12-> r[0] 
    mov      [w0+lmsNormNumTaps_f32],w7  ; w7 = M
    sub.l    #2,w7                       ; W7 = M-2
    mov.l    [w0+lmsNormEnergy_f32],w11 ; w11->E[-1]
    push.l   w7                          ; Save M-2 for future use.
;............................................................................
startFilter:

    ; Perform filtering of all samples.
; {Loop (N-1)+1 times
    
    mov.l w11, f6                     ; f6 = E[n-1]
    mov.l [w1++],[w10]                  ; store new sample into delay
    mov.l [w8++], f4                    ; f4 = h[0]
    mov.l [w10], f5                     ; f5 = delay[0]
    mpy.l w5, [w10]+=4, A               ; Dummy DSP op to increment w10 on Y-modulo addressing.
    mac.s f5, f5, f6                    ; f6 = E[n-1] + (x[n])^2
    mul.s f4, f5, f5                    ; f5 = h[0]*delay[0]
        
    ; Filter each sample.
    ; (Perform all MACs.)
    
    mov.l [w8++], f2                    ; f2 = h[1]
    mov.l [w10], f3                     ; f3 = delay[1]
    mpy.l w5, [w10]+=4, A               ; dummy mpy instruction to increment w10 on Y-modulo addressing.
perform_mac:
    mac.s f2, f3, f5                    ; f5 += h[m]*delay[n-m]
    mov.l [w10], f3                     ; f3 = delay[n+1]
    mpy.l w5, [w10]+=4, A               ; dummy mpy instruction to increment w10 on Y-modulo addressing.
    mov.l [w8++], f2                    ; f2 = h[m+1]
    dtb   w7, perform_mac

    mul.s f3, f3, f4                    ; f4 = (x[n-M+1])^2
    mov.l [w15-4], w7                   ; restore loop counter
    mac.s f2, f3, f5                    ; f5 = h[M-1]*x[n-M-1]    
    nop                                 ; stall cycle
    sub.s f6, f4, f4                    ; f4 = E[n-1] + (x[n])^2 - (x[n-M+1])^2
    nop                                 ; stall cycle
    nop                                 ; stall cycle
    mov.l f4, w11                       ; *w11= E[n] (estimate)
    nop                                 ; stall cycle
    add.s f4, f0, f4                    ; mu + E[n] (denominator)
    nop                                 ; stall cycle
    nop                                 ; stall cycle
    div.s f0, f4, f4                    ; f4 = mu/(mu+E[n])
    mov.l f5, [w3++]                    ; y[n] = sum_{m=0:M-1}(h[m]*x[n-m])
    
    ; With the new output, and the corresponding reference sample,
    ; compute normalize factor.
    mov.l [w12++], f2                    ; f2 = r[n]
    nop
    sub.s f2, f5, f1                     ; f1 = r[n] - y[n] = current error
    mov.l f1,[w4++]
    
    ; Adaptation: h[m] = h[m] + attError*x[n-m].
    ; Here the h[m] cannot be addressed as a circular buffer,
    ; because their values are accessed via a 'LAC' instruction...
    ; Thus, use w9 instead.

    ; Prepare adaptation.
    mov.l    w8,w9                    ; w9-> h[0]
    push.l   w7
    ; Perform adaptation (all but last two coefficients).
    add.l w7, #1, w7                  ; w7 = M-1
    ; CPU stalled till div.s is complete.
    nop                               ; stall cycle
    nop                               ; stall cycle
    nop                               ; stall cycle
    nop                               ; stall cycle
    nop                               ; stall cycle
    nop                               ; stall cycle
    mul.s f1, f4, f1                  ; f1 = nu[n]*(r[n]-y[n])
    mov.l [w10], f3                   ; f3 = delay[0]
    mpy.l w5, [w10]+=4, A             ; dummy mpy instruction to increment w10 on Y-modulo addressing.
    mov.l [w9], f2                    ; f2 = h[m]
    nop                               ; stall cycle
    
; {Loop (M-1) times
startAdapt:
    mac.s  f1, f3, f2                  ; f2 = h[m] + attError*delay[m]
    mov.l  [w10], f3                   ; f3 = h[m+1]
    mpy.l  w5, [w10]+=4, A             ; dummy mpy instruction to increment w10 on Y-modulo addressing.
    nop                                ; stall cycle
    mov.l  f2, [w9++]                  ; store adapted h[m]
    mov.l  [w9], f2                    ; f2 = h[m]
    dtb w7, startAdapt
; }
    pop.l w7
    ; Perform adaptation for last coefficient.
    mpy.l w5, [w10]-=4, A
    mac.s f1, f3, f2                  ; f2 = attError*delay[m]
    nop                               ; stall cycle
    nop                               ; stall cycle
    nop                               ; stall cycle
    mov.l f2, [w9]                    ; store adapted h[m]
    
    
    dtb w5, startFilter
; }
pop.l w7

;............................................................................

    ; Update delay pointer.
    mov.l    w10,[w0+lmsNormPState_f32]            ; note that the delay pointer
                                            ; may wrap several times around
                                            ; d[m], 0 <= m < M, depending
                                            ; on the value of N
                                            ; (it is the same as delay[0])
   mov.l     w11,[w0+lmsNormEnergy_f32]

    ; Restore core registers for modulo addressing.
    pop.l    YMODEND
    pop.l    YMODSRT
    pop.l    XMODEND
    pop.l    XMODSRT
    pop.l    MODCON

;............................................................................

    ; Restore FCR.
    pop.l    FCR

;............................................................................


    ; Restore working registers.

    pop.l    w12                ; {w12} from TOS
    pop.l    w11                ; {w11} from TOS
    pop.l    w10                ; {w10} from TOS
    pop.l    w9                 ; {w9 } from TOS
    pop.l    w8                 ; {w8 } from TOS

;............................................................................

    return    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OEF
