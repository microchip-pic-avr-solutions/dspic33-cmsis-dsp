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
; _mchp_fir_decimate_f32: Single precision folating-point, Ratio R:1 decimation by FIR filtering.
;
; Operation:
;    y[n] = H(x[R*n])
;
; x[n] defined for 0 <= n < N*R,
; y[n] defined for 0 <= n < N, (N = p*R, p integer),
; h[k] defined for 0 <= k < M (M = q*R, q integer).
;
; Input:
;    w0 = filter structure (mchp_fir_decimate_instance_f32, h)
;    w1 = pSrc, ptr input samples (0 <= n < N*R)
;    w2 = pDst, ptr output samples (0 <= n < N)
;    w3 = blockSize, number of output samples (N = p*R, p integer)
;
; System resources usage:
;    {w0..w7}    used, not restored
;    {f0..f2}    used, not restored
;    {w8..w11}    saved, used, restored
;     FCR        saved, used, restored
;
; DTB and REPEAT instruction usage.
;    1 level DTB instruction
;    3 level REPEAT instruction
;............................................................................

 
     .global    _mchp_fir_decimate_f32    ; export
_mchp_fir_decimate_f32:

;............................................................................

    ; Save working registers.
    push.l    w8         ; {w8 } to TOS
    push.l    w9         ; {w9 } to TOS
    push.l    w10        ; {w10} to TOS
    push.l    w11        ; {w11} to TOS
    push.l    w12        ; {w12} to TOS
    push.l    w13        ; {w13} to TOS

;............................................................................

    push.l    FCR          ; Save FCR
    floatsetup    w7       ; Setup FCR with default rounding mode, SAZ/FTZ disabled and all exceptions masked.

    ; Get parameters from filter structure.
    mov.b    [w0+firDecM_f32], w6                          ; w6 = R
    mov.l    [w0+firDecPCoeffs_f32], w4        ; w4-> h[0]
    mov.l    [w0+firDecPState_f32],  w5        ; w5-> d[0]
    mov      [w0+firDecNumTaps_f32],  w8       ; w8 = M

;............................................................................
    push.l w4
    repeat #9
    divul    w3, w6 
    pop.l w4
    
    mov.l #1,w13
    ; Set up filtering.
    sl.l     w6, #2, w9               ; w9= R*sizeof(sample)
    sub.l    w8,    w6,    w7         ; w7 = M-R
    sub.l    #1,    w8                ; w8 = M-1
    sub.l    #2,    w7                ; w7 = M-R-1
    sub.l    #1,    w6                ; w6 = R-1
    push.l   w8                       ; Save w8 = M-1 for future use.


       
startDecim:

    ; Make room in delay for next R input samples.
    add.l    w5,    w9, w10               ; w10->d[R]
    mov.l    w5,    w12                    ; w12-> d[0]
    
    
    repeat    w7            
; {                                    ; repeat (M-R-1)+1 times
    mov.l    [w10++],[w12++]                ; d[k] <- d[R+k]
                                           ; w12-> d[k+1]
                                           ; w10->d[R+k+1]
; }
    mov.l    [w10],[w12++]
                                        ; now:
                                            ; w12-> d[M-1-R]
    
    
      
    ; Place next R input samples in delay.
    cp0 w13 
    bra z, skipPadding
    push w6
addPadding:
    mov.l    #0,[w12++]
    dtb w6, addPadding
    
    pop w6
    mov.l    [w1++],[w12++]   
    mov.l    #0,w13
    bra  paddingDone
skipPadding:   

    repeat    w6            
; {                                    ; repeat (R-1)+1 times
    mov.l    [w1++],[w12++]                ; d[M-1-R+k] <- x[n+k]
                                          ; w1-> x[n+k+1]
                                          ; w8-> d[M-1-R+k+1]
; }
paddingDone:					  
                                        ; now:
                                          ; w1-> x[n+R]
                                          ; w8-> d[M]

    ; Set up next output.
    mov.l    [w4], f0                   ; f0 = h[0]
    mov.l    [w10--], f1                ; f1 = del[M-1]
                                        ; w10->d[M-2] = x[n+R-2]
    add.l    w4, #4, w11                ; w11 -> h[1]
    mul.s    f0, f1, f2                 ; f2 = h[0]*del[M-1]

    mov.l    [w11], f0                  ; f0 = h[1]
    mov.l    [w10], f1                  ; f1 = del[M-2]
    
    mov.l    [w15-4], w8                ; w8 = M-1
    ; Generate next output.
    ; (Perform all but last MAC.)
; Loop (M-2)+1 times
start_mac:
;{
    mac.s    f0, f1, f2                  ; f2 += h[k]*d[M-1-k] = h[k]*x[n+R-1-k]
                                            
    mov.l    [++w11], f0                 ; f0 = h[k]
                                         ; w11-> h[k+1]
    mov.l    [--w10], f1                 ; f1 = d[M-1-k]
                                         ; w10->d[M-1-k-1] = x[n+R-1-k-1]
    dtb w8, start_mac
;}
    mov.l    f2, [w2++]                  ; store y[n]
                                         ; w2-> y[n+1]
                                         ; now:
                                            ; w11-> h[M+1]
                                            ; w10->d[-2] = x[n+R-M-1]
; }
                                        ; now:
                                            ; w2-> y[N]
                                            ; w1-> x[N*R]
    
    dtb w3, startDecim
    pop.l   w8                          ; Restore stack.

;............................................................................

_completedFIRDecimate:

;............................................................................

    pop.l    FCR

;............................................................................

    ; Restore working registers.

    pop.l    w13                ; {w13} from TOS
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

