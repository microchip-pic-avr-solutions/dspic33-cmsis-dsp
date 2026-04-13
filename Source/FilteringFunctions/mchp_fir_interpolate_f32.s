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
; _mchp_fir_interpolate_f32: Single precision floating-point, Ratio 1:R interpolation by FIR (low pass) filtering.
;
; Operation:
;    y[R*n] = H(x[n])
;
; x[n] defined for 0 <= n < N,
; y[n] defined for 0 <= n < N*R,
; h[k] defined for 0 <= k < M (M = q*R, 1 < q integer).
; d[k] defined for 0 <= k < M/R.
;
; Input:
;    w0 = ptr _mchp_fir_interpolate_init_f32 filter structure
;    w1 = x, ptr input samples (0 <= n < N)
;    w2 = y, ptr output samples (0 <= n < N*R)
;    w3 = N, number of input samples (N = p*R, 1 < p integer)
; Return:
;    (void)
;
; System resources usage:
;    {w0..w7}    used, not restored
;    {f0..f2}    used, not restored
;    {w9..w12}    saved, used, restored
;     FCR        saved, used, restored
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .global    _mchp_fir_interpolate_f32    ; export
_mchp_fir_interpolate_f32:

;............................................................................
    ; Save working registers.
    push.l    w9         ; {w9 } to TOS
    push.l    w10        ; {w10} to TOS
    push.l    w11        ; {w11} to TOS
    push.l    w12        ; {w12} to TOS
    push.l    w13        ; {w13} to TOS
;............................................................................

    push.l    FCR        ; save FCR
    floatsetup    w7     ; Setup FCR for default rounding modes, SAZ/FTZ disabled, masked exceptions.

    mov.b    [w0+firInterL_f32],w6
    mov.l    [w0+firInterPCoeffs_f32],w4    ; w4 -> h[0]
    mov.l    [w0+firInterPState_f32],w5     ; w5-> d[0]
    mov    [w0+firInterPLen_f32],w13     ; w13 = M

    ; Compute M/R = q:
    mov.l    w13, w9                     ; w9 = M
    REPEAT #9
    divul    w9, w6                     ; w9 = M/R


    sub.l    w9, #1, w7                 ; w7 = M/R - 1 
    
    sl.l    w6, #2, w12                 ; w12= R*sizeof(sample)
    sub.l    #1,w13                      ; w13 = M-1
    push.l     w7                       ; save w7 = M/R-1
    push.l     w5                       ; save w5 = d[0]
    push.l     w6                       ; save R
    
    
    ; Generate the N*R output samples from the N input samples.
_doInter:
    ; Make room in delay for next input sample.
    sub.l    w7, #1, w11         ; w11 = M/R - 2
    add.l    w5, #4, w9          ; w9-> d[1]
    mov.l    w5, w10             ; w10->d[0]
    repeat    w11            
; {                              ; repeat (M/R-2)+1 times
    mov.l    [w9++],[w10++]       ; d[k] <- d[k+1]
                                  ; w9-> d[k+2]
                                  ; w10->d[k+1]
; }
                            ; now:
                                ; w9-> d[M/R]
                                ; w10->d[M/R-1]

    ; Place next input sample in delay.
    mov.l    [w1++],[w10]       ; d[M/R-1] = x[n]
                                ; w1-> x[n+1]
    ; Set up next R outputs.
    mov.l    w4,w11             ; w11->h[0]
    mov.l    w10,w5             ; w5-> d[M/R-1]

    ; Generate next R outputs.
startOutputs:
; {                             ; do (R-1)+1 times
    ; Set up next output.
     mov.l    w5,w10            ; w10->d[M/R-1]

    ; Generate next output.
    ; (Perform all MAC.)
    mov.l    [w11], f0          ; f0 = h[0]
    mov.l    [w10--], f1        ; f1 = d[M/R-1]
    mov.l    w11,w9             ; w9-> h[k]
    mul.s    f0, f1, f2         ; f2 = h[k]*d[M/R-1]
    
startOutput:
; {Loop (M/R - 1) times
    
    mov.l   [w9+w12], f0         ; f0 = h[R*(k+1)]
    mov.l   [w10--], f1          ; f1 = d[M/R-1-k]
    add.l   w9,w12,w9            ; w9-> h[R*(k+1)]
    mac.s   f0, f1, f2           ; f2 += h[R*k]*d[M/R-1-k]
    dtb     w7, startOutput
; }
    add.l    #4, w11             ; w11->h[k+1]
    mov.l    [w15-12], w7
    mov.l    f2, [w2++]         ; store y[R*n+k]
                                ; w2-> y[R*n+k+1]

    ; Update for next sample.
    dtb     w6, startOutputs
; }
    mov.l    [w15-4],    w6
    ; Update for next R samples.
    mov.l    [w15-8],    w5       ; restore W5 to d[0]
    ; Process next input sample.
    dtb w3, _doInter

;............................................................................

_completedFIRInterpolate:
    sub.l    #12, w15         ; restore stack

;............................................................................

    ; Restore FCR.
    pop.l    FCR

;............................................................................

    ; Restore working registers.

    pop.l    w13                ; {w13} from TOS
    pop.l    w12                ; {w12} from TOS
    pop.l    w11                ; {w11} from TOS
    pop.l    w10                ; {w10} from TOS
    pop.l    w9                ; {w9} from TOS

;............................................................................
    return    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OEF
