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
    .include    "dspcommon.inc"        ; floatsetup
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .dspic33cmsisdsp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_conv_f32: Vector convolution.
;
; Operation:
;    y[n] = sum_(k=0:n){x[k]*h[n-k]},    0 <= n < M
;    y[n] = sum_(k=n-M+1:n){x[k]*h[n-k]},    M <= n < N
;    y[n] = sum_(k=n-M+1:N-1){x[k]*h[n-k]},    N <= n < N+M-1
;
; Input:
;    w0 = x, ptr to source vector one
;    w1 = N, number elements in vector one
;    w2 = h, ptr to source vector two
;    w3 = M, number elements in vector two, M <= N
;    w4 = y, ptr to destination vector, with (N + M - 1) elements
;
; System resources usage:
;    {w0..w7}    used, not restored
;    {f0..f2}    used, not restored
;    {w8, w9}    saved, used, restored
;     AccuA        used, not restored
;     FCR        saved, used, restored
;
;............................................................................

    .global    _mchp_conv_f32    ; export
_mchp_conv_f32:

    ; Compare srcALen and srcBLen
    cp      w1, w3            ; compare srcALen ? srcBLen
    bra     ge, _no_swap

    ; swap lengths
    mov.l     w1, w5
    mov.l     w3, w1
    mov.l     w5, w3

    ; swap pointers
    mov.l     w0, w5
    mov.l     w2, w0
    mov.l     w5, w2

_no_swap:
    
    push.l fcr
    floatsetup w5               ; Setup FCR to default rounding, mask all exceptions.
;............................................................................
    ; Save working registers.
    push.l    w8                ; {w8 } to TOS
    push.l    w9                ; {w9} to TOS
;............................................................................
    ; save return value (y)
    push.l    w4                

;............................................................................
; First stage: y[n] = sum_(k=0:n){x[k]*h[n-k]}, 0 <= n < M.
;............................................................................

    ; Prepare operation.
    mov.l    w3,    w6                ; w6 = M
    mov.l    #1,    w9                ; w9 = 1
    
    ; Perform operation.
startOutFirst:

    ; Prepare operation.
    mov.l    w0,w7                ; w7-> x[0]
    mov.l    w2,w8                ; w8-> h[n]

    mov.l [w7], f0                ; f0 = x[0]
    mov.l [w8], f1                ; f1 = h[n]
    movc.s     #22, f2                  ; clr f2
    ; Perform operation.
    push.l w9                     ; save iterator value
1:
    mac.s f1, f0, f2              ; f2 = f2 + (x[k] * h[n-k])
    mov.l [++w7], f0              ; f0 = x[k+1]
    mov.l [--w8], f1              ; f1 = h[n-k-1]
    dtb w9, 1b
    mov.l f2, [w4++]              ; dstV[n]  = sum_(k=0:n){x[k]*h[n-k]}, 0 <= n < M.

    ; Update for next operation.
    add.l    #4, w2               ; w2-> h[n+1]
    add.l    [--W15], #1, w9      ; w9 = w9 + 1
    DTB  w6, startOutFirst


    mov.l     w3, w6               ; Restore w6
    ; Update for next stage.
    sub.l    #4, w2                ; w2-> h[M-1]
    add.l    #4, w0                ; w0-> x[1]
    
    
;............................................................................
    ; Second stage: y[n] = sum_(k=n-M+1:n){x[k]*h[n-k]}, M <= n < N. 
    ; ONLY if M < N!!!
;............................................................................

    ; Prepare operation.
    sub.l    w1,w3,w9              ; w9 = N-M
    bra    le,_begThird            ; M == N (skip second stage)

    ; Perform operation.
    push.l w6                      ; save w6

startOutSecond:
    ; Prepare operation.
    mov.l    w0,w7                ; w7-> x[0]
    mov.l    w2,w8                ; w8-> h[M-1]
    
    mov.l [w7], f0                ; f0 = x[0]
    mov.l [w8], f1                ; f1 = h[M-1]
    movc.s #22, f2                ; clr f2

    ; Perform operation.
                                  ; w7-> x[k+1]
                                  ; w8-> h[n-k-1]
1:
    mac.s f1, f0, f2              ; f2 = f2 + (x[k]*h[n-k])
    mov.l [++w7], f0              ; f0 = x[k+1]
    mov.l [--w8], f1              ; f1 = h[n-k-1]
    dtb w6, 1b                      
    mov.l [w15-4], w6             ; restore w6
    mov.l f2, [w4++]              ; y[n] = f2

    ; Update for next operation.
    add.l    #4, w0               ; w0-> x[k]
    dtb w9, startOutSecond
    pop.l w6


;............................................................................
    ; Third stage: y[n] = sum_(k=n-M+1:N-1){x[k]*h[n-k]}, N <= n < N+M-1.
    ; ONLY if M > 1!!!
;............................................................................
_begThird:
    ; Prepare operation.
    sub.l   w6, #1, w5             ; w5 = w6 - 1 = M-1
    sub.l   w6, #1, w6             ; w5 = w5 = (M-1)
    bra    le,_noMore              ; M == 1 (skip third stage)

; Perform operation.
; {    ; DTB (M-1) times
startOutThird:
    ; Prepare operation.
    mov.l    w0,w7                 ; w7-> x[k]
    mov.l    w2,w8                 ; w8-> h[M-1]
    movc.s #22, f2                 ; f2 = 0

    ; Perform operation.
; {    ; DTB N+M-1-n times
                                          
    mov.l [w7], f0                 ; f0 = x[0]
    mov.l [w8], f1                 ; f1 = h[M-1]
    push.l w6                      ; Save w6
1:

    mac.s f0, f1, f2               ; f2 += x[k]*h[n-k]
    mov.l [++w7], f0               ; f0 = x[k+1]
    mov.l [--w8], f1               ; f1 = h[n-k-1]
    dtb w6, 1b                       ; a  = x[k]*h[n-k]
; }
    mov.l f2, [w4++]                     ; y[n] store

    ; Update for next operation.
    add.l    #4,    w0                   ; w0-> x[k]
    sub.l    [--W15], #1, w6             ; w6--
    DTB w5, startOutThird
; }

_noMore:
;............................................................................

    pop.l    w1                ; restore return value

;............................................................................

    ; Restore working registers.
    pop.l    w9                ; {w9} from TOS
    pop.l    w8                ; {w8} from TOS
    pop.l    FCR               ; FCR from TOS
;............................................................................

    return    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OEF
