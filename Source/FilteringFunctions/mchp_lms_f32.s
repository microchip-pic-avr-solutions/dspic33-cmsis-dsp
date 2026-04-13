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
; _mchp_lms_f32: FIR filtering with LMS coefficient adaptation.
;
; Operation:
;    y[n] = sum(m=0:M-1){h[m]*x[n-m]},
;
;    h(n+1)[m] = h(n)[m] + mu*(r[n]-y[n])*x[n-m], 0<= m < M.
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
; Input:
;    w0 = filter structure (mchp_lms_instance_f32, h)
;    w1 = x, ptr input samples (0 <= n < N)
;    w2 = r, ptr reference samples (0 <= n < N)
;    w3 = y, ptr output samples (0 <= n < N)
;    f0 = mu.
;    w5 = N, number of input samples (N)
; Return:
;    (void)
;
; System resources usage:
;    {w0..w7}    used, not restored
;    {f0..f4}    used, not restored
;    {w8..w12}    saved, used, restored
;     MODCON        saved, used, restored
;     XMODSRT    saved, used, restored
;     XMODEND    saved, used, restored
;     YMODSRT    saved, used, restored
;     YMODEND    saved, used, restored
;
;............................................................................
    .extern    _lmsPStateStart_f32
    .global    _mchp_lms_f32    ; export
_mchp_lms_f32:

;............................................................................

    ; Save working registers.
    
    push.l    w7                 ; w7  to TOS
    push.l    w8                 ; w8  to TOS
    push.l    w9                 ; w9  to TOS
    push.l    w10                ; w10 to TOS
    push.l    w11                ; w11 to TOS
    push.l    w12                ; w12 to TOS

;............................................................................
    ;Setup CORCON and FCR
    
    push.l    CORCON
    push.l    FCR
    fractsetup    w7
    floatsetup    w7

;............................................................................

    ; Prepare core registers for modulo addressing.
    push.l    MODCON
    push.l    XMODSRT
    push.l    XMODEND
    push.l    YMODSRT
    push.l    YMODEND


    ; Setup registers for modulo addressing.
    mov.l    #0xC0A8,w10                 ; XWM = w8, YWM = w10
                                         ; set XMODEND and YMODEND bits
    mov.l    w10, MODCON                 ; enable X,Y modulo addressing


    
    mov      [w0+lmsNumTaps_f32],w7        ; w7 = M
    push.l   w7
    sl.l     w7, #2, w7                ; w9 = numCoeffs*sizeof(coeffs)
    sub.l    #1, w7                    ; w9 =  numCoeffs*sizeof(coeffs)-1
    
    
    mov.l    [w0+lmsPCoeffs_f32], w8    ; w8 -> h[0]
    mov.l    w8, XMODSRT                 ; init'ed to coeffs base address
                                         ; (increasing buffer, 2^n aligned)
    add.l    w8,w7,w9
    mov.l    w9, XMODEND                 ; init'ed to coeffs end address
    
    

    mov.l    _lmsPStateStart_f32, w10    ; w10 -> d[0]
    mov.l    w10, YMODSRT                ; init'ed to delay base address
                                         ; (increasing buffer, 2^n aligned)
    add.l    w10,w7,w10
    mov.l    w10, YMODEND                ; init'ed to delay end address
    
    pop.l    w7
    mov.l    w2,w12                     ; w12->r[0]
    sub.l    #2,w7                      ; W7 = M-2
    ;............................................................................
    push.l    w7                           ; Save w7 for future use.
    ;............................................................................
    
    ; Perpare to filter all samples.
    mov.l    [w0+lmsPState_f32], w10       ; w10 points at current delay
                                        ; sample d[m], 0 <= m < M
                                        ; referred to as delay[0]
                                        ; for each iteration...
    
    mov.l    [w0+lmsMu_f32],f0                      ; f0 = mu


    ; Perform filtering of all samples.
startFilter:
; { Loop (N) times

    ; Prepare to filter sample.
    mov.l   [w1++],[w10]                 ; store new sample into delay
    
    mov.l     [w8++], f1                 ; f1 = h[0]
    mov.l     [w10], f2                  ; f2 = delay[0]
    mpy.l     w5, [w10]+=4, A            ; Dummy op tp increment w10 on Y-modulo addressing.
    mul.s     f1, f2, f3                 ; f3 = h[0]*delay[0]
    mov.l     [w8++], f1                 ; f1 = h[1]
    mov.l     [w10], f2                  ; f2 = delay[1]
    mpy.l     w5, [w10]+=4, A            ; Dummy op tp increment w10 on Y-modulo addressing.
    
    ; (Perform all but last MACs.)
start_mac:
    mac.s     f1, f2, f3                 ; f3 += h[n]*delay[m]
    mov.l     [w10], f2                  ; f2 = delay[m]
    mpy.l     w5, [w10]+=4, A            ; Dummy op tp increment w10 on Y-modulo addressing.
    mov.l     [w8++], f1                 ; f1 = h[n]
    dtb w7,   start_mac
    
    mac.s     f1, f2, f3                 ; f3 += h[M-1]*delay[M-1]
    mov.l     [w15-4], w7                ; restore w7
    mov.l     [w12++], f4                ; f4 = r[n]
    mov.l     w8,    w6                  ; w6-> h[0]

    ; With the new output, and the corresponding reference sample,
    ; update the filter coefficients.
    
    sub.s   f4, f3, f4                ; f4 = r[n] - y[n] = current_error
    mov.l   f4,[w4++]
    mov.l   f3, [w3++]                ; y[n] =  sum_{m=0:M-1}(h[m]*x[n-m])
                                      ; w3-> y[n+1]  
                                 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                          
    add.l   w7, #1, w11               ; w11= M-1
    mul.s   f0, f4, f4                ; f4  = mu*(r[n]-y[n])

    ; Adaptation: h[m] = h[m] + attError*x[n-m].
    ; Here the h[m] cannot be addressed as a circular buffer,
    ; because their values are accessed via a 'LAC' instruction...
    ; Thus, use w6 instead.

    ; Prepare adaptation.

    ; Perform adaptation (all but last one coefficient).
; {    

    mov.l   [w6], f1               ; f1 = h[m]
    mov.l   [w10], f2              ; f2 = delay[m]
    NOP
startAdapt:
    mac.s   f4, f2, f1             ; f1 += delay[m]* mu*(r[n]-y[n])
    mpy.l   w5, [w10]+=4, A        ; Dummy op to increment w10 on Y-modulo addressing.
    NOP                            ; Stall cycle.
    mov.l   [w10], f2              ; f2 = delay[m]
    mov.l   f1, [w6++]             ; Update h[m]
    mov.l   [w6], f1               ; f1 = h[m]
    dtb w11, startAdapt
; }

    ; Perform adaptation for last coefficient.
    mac.s   f4, f2, f1             ; f1 += delay[m]*mu*(r[n]-y[n])
    NOP                            ; Stall cycle.
    NOP                            ; Stall cycle.
    NOP                            ; Stall cycle.
    mov.l   f1, [w6++]             ; Update h[M-1]
    
; }
    dtb w5, startFilter
    pop.l w7
;............................................................................

    ; Update delay pointer.
    mov.l    w10,[w0+lmsPState_f32]            ; note that the delay pointer
                        ; may wrap several times around
                        ; d[m], 0 <= m < M, depending
                        ; on the value of N
                        ; (it is the same as delay[0])


    ; Restore core registers for modulo addressing.
    pop.l    YMODEND
    pop.l    YMODSRT
    pop.l    XMODEND
    pop.l    XMODSRT
    pop.l    MODCON

;............................................................................

_restore:

    ; Restore CORCON and FCR.
    pop.l    FCR
    pop.l    CORCON

;............................................................................


    ; Restore working registers.
    pop.l    w12                ; w12 from TOS
    pop.l    w11                ; w11from TOS
    pop.l    w10                ; w10 from TOS
    pop.l    w9                ; w9 from TOS
    pop.l    w8                ; w8 from TOS
    pop.l    w7                ; w7 from TOS


;............................................................................

    return    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OEF

