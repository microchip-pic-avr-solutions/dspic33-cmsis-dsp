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
; _mchp_iir_lattice_f32: IIR filtering with lattice implementation.
;
; Operation for an Mth order filter:
;## Filter samples.
;   for n = 1:N
;
;   ## Get new sample.
;   current = x(n);
;
;   ## Lattice structure.
;   for m = 1:M
;      after     = current  - k(M+1-m) * d(m+1);
;      d(m)      = d(m+1) + k(M+1-m) * after;
;      current   = after;
;   end
;   d(M+1) = after;
;
;   ## Ladder structure (computes output).
;   if (g == 0)
;      y(n) = d(M+1);
;   else
;      for m = 1:M+1
;         y(n) = y(n) + g(M+2-m)*d(m);
;      endfor
;   endif
;
;endif
;
; x[n] defined for 0 <= n < N,
; y[n] defined for 0 <= n < N,
; k[m] defined for 0 <= m < M,
; g[m] defined for 0 <= m <= M, and
; d[m] defined for 0 <= m <= M,
; 0 <= n < N.
;
; Input:
;    w0 = S, ptr filter structure
;    w2 = y, ptr output samples (0 <= n < N)
;    w1 = x, ptr input samples (0 <= n < N) 
;    w3 = N, number of input samples (N)
; System resources usage:
;    {w0..w7}    used, not restored
;    {f0..f4}    used, not restored
;    {w8..w9}   saved, used, restored
;    FCR        saved, used, restored
;............................................................................



    .global    _mchp_iir_lattice_f32    ; export
_mchp_iir_lattice_f32:

;............................................................................

    ; Save working registers.
    push.l    w8                ; {w8} to TOS
    push.l    w9                ; {w9} to TOS

;............................................................................
    ; Mask all FPU exceptions, set rounding mode to default and clear SAZ/FTZ

    push.l    FCR
    floatsetup    w8


    ; Set up filter structure.
    mov      [w0+ iirLatticeNumStage_f32],    w7            ; w7= M
    mov.l    [w0+ iirLatticePState_f32],w5            ; w5->del[0]
    sub.l    #1,w7                             ; w7= M-1
    sl.l     w7, #2, w4                        ; w4= (M-1)*sizeof(sample)
    mov.l    [w0+iirLatticePkCoeffs_f32],w8            ; w8-> k[0]

    add.l    w5, #4, w9                        ; w9->del[1]
    add.l    w4, w8, w8                        ; w8-> k[M-1]
    mov.l    w8, w4                            ; w4-> k[M-1] (for rewind)
    sub.l    #1, w7                            ; w7= M-2
    push.l    w7

    ; Set up filtering.
    ; Filter the N input samples.
; {Loop (N) times

startFilter:
; .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  . .

    ; Lattice structure.
    mov.l [w8--], f1             ; f1 = k[M-1-m]
    mov.l [w9++], f2             ; f2 = del[m+1]    
    mov.l [w1++], f0             ; f0 = x[n]
                                 ; w1-> x[n+1]

    ; All but last two iteration...

    mul.s f1, f2, f3             ; f3 = k[M-1-m]*del[m+1]    
    NOP
; { Loop (M-2) times
startLattice:

    ; Upper branch: 
    ; after = current - k[M-1-m]*del[m+1].
    
    mov.s f2, f4                              ; f4 = f2
    sub.s f0, f3, f3                          ; f[m-1] = x[n] - k[M-1-m]*del[m+1] = after
    mov.l [w9++], f2                          ; f2 = del[m+1]
    NOP
    ; Lower branch: del[m] = del[m+1] + k[M-1-m]*after.
    mac.s f1, f3, f4                          ; f4 g[m-1] = del[m+1] + k[M-1-m]*after
    mov.l [w8--], f1                          ; f1 = k[M-1-m]
    mov.s f3, f0                              ; f0 = current (next)
    mul.s f1, f2, f3                          ; f3 = k[M-1-m]*del[m+1]
    mov.l f4, [w5++]                          ; del[m] (updated)
                                              ; w5->del[m+1]
    dtb w7, startLattice
; }
                                               
    ; One before last iteration...
    ; Upper branch: after = current - k[1]*del[M-2+1].
    sub.s    f0, f3, f0                       ; f0 -= k[1]*del[M-2+1] = after
    mov.s    f2, f4                           ; f4 = f2
    mov.l [W15-4], w7                         ; Restore w7 from stack.
                                                    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Lower branch: del[M-2] = del[M-2+1] + k[1]*after.
    mac.s f1, f0, f4                       ; f4 = del[M-2+1] + k[1]*after

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Last iteration...
    
    ; Upper branch: after = current - k[0]*del[M-1+1].
    
    mov.l    [w8], f1                     ; f1 = k[0]
    mov.l    [w9], f2                     ; f2 = del[M-1+1]
    NOP
    mul.s    f1, f2, f3                   ; f3 = k[0]*del[M-1+1]
    NOP
    NOP
    NOP
    sub.s    f0, f3, f0                   ; f0(new_after) = after - k[0]*del[M-1+1]
    NOP
    mov.l     f4, [w5++]                   ; del[M-2] (updated)
                                           ; w5->del[M-1]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    mac.s   f0, f1, f2                   ; f2 += k[0]*after
    mov.l    [w0+iirLatticePvCoeffs_f32],w8      ; w8-> g[0]
    CP0.l    w8                          ; w8 == NULL ?
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Update last delay.
    mov.l    f0, [++w5]                 ; del[M] = after
    mov.l    f2, [w5-4]                 ; del[M-1] (updated)


    ; Only for zero-pole implementations,
    ; but not for all-pole implementations...
    bra    z,_allPole                    ; Yes => all pole
                                         ; No  => zero-pole

    mov.l    [w8++], f1                  ; f1 = g[0]
    mov.l    [w5--], f2                  ; f2 = del[M]
    NOP
    mul.s    f1, f2, f3                  ; f3 = g[0]*del[M]
    mov.l    [w8++], f1                  ; f1 = g[1]
    mov.l    [w5--], f2                  ; f2 = del[M-1]
    NOP
start_mac:
    mac.s    f1, f2, f3                  ; f3 += g[m]*del[M-m]
    mov.l    [w8++], f1                  ; f1 = g[m+1]
    mov.l    [w5--], f2                  ; f2 = del[M-m-1]
    DTB w7, start_mac
    mov.l   [W15-4], w7                  ; w7 = M-2
    mac.s    f1, f2, f3                  ; f3 += g[M-2]*del[2]
    mov.l    [w8], f1
    mov.l    [w5], f2
    NOP
    mac.s    f1, f2, f3                  ; f3 += g[M]*del[0]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    bra    _storeOutput

_allPole:
    mov.s    f0, f3                      ; f3 = f0
    add.l    w7, #2, w8                  ; w8 = M
    sl.l     w8, #2, w8                  ; w8 = (M)*sizeof(sample)
    sub.l    w5,w8,w5                    ; w5->del[0]

_storeOutput:
    ; Store output.
    mov.l    f3, [w2++]                ; store y[n]
                                       ; w2-> y[n+1]

    ; Rewind pointer.
    mov.l    w4, w8                 ; w8-> k[M-1]
    add.l    w5, #4, w9             ; w9->del[1]
    dtb w3, startFilter
; }

    sub.l     #4, w15           ; Unstack push.l w7
_completedIIR:
;............................................................................

    ; Restore FCR.
    pop.l    FCR

;............................................................................

    ; Restore working registers.
    pop.l    w9                ; {w9} from TOS
    pop.l    w8                ; {w8} from TOS

;............................................................................

    return    

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OEF
