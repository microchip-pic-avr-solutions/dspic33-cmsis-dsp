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
; _mchp_fir_lattice_f32: Single precision Folating point FIR filtering with lattice implementation.
;
; Operation:
;    f(0)[n] = g(0)[n] = x[n],
;    f(m)[n] = f(m-1)[n] - k_(m-1)*g(m-1)[n-1],
;    g(m)[n] = -k_(m-1)*f(m-1)[n] + g(m-1)[n-1],
; and   y[n] =f(M)[n];
;
; x[n] defined for 0 <= n < N,
; y[n] defined for 0 <= n < N,
; k[m] defined for 0 <= m < M, and
; g(m)[n] defined for 0 <= m < M, for -M <= n < N.
;
; Input:
;    w0 = s, ptr filter structure (see included file)
;    w1 = x, ptr input samples (0 <= n < N)
;    w2 = y, ptr output samples (0 <= n < N)
;    w3 = N, number of input samples (N)
; Return:
;    (void)
;
; System resources usage:
;    {w0..w7}    used, not restored
;    {w8..w10}    saved, used, restored
;    {f0..f4}    used, not restored
;............................................................................

    .global    _mchp_fir_lattice_f32    ; export
_mchp_fir_lattice_f32:

;............................................................................

    ; Save working registers.
    push.l    w8        ; {w8 } to TOS
    push.l    w9        ; {w9 } to TOS
    push.l    w10       ; {w10} to TOS

;............................................................................

    ; Prepare FCR for float computation.
    push.l    FCR       ; Save FCR
    floatsetup    w5    ; Setup FCR for default rounding mode, SAZ/FTZ disabled, with all FPU exceptions masked.
               
;............................................................................
    mov.l    [w0+firLatticePCoeffs_f32],w8       ; w8-> k[0]
;............................................................................

    ; Set up filter structure.
    mov      [w0+firLatticeNumStage_f32],w5        ; w5= M
    mov.l    w8,w10                        ; w10->k[0] (for rewind)
    mov.l    [w0+firLatticePState_f32],w9        ; w9-> del[0]
    mov.l    w9,w7                         ; w7->del[0] (for rewind)

    ; Set up filtering.
    sub.l    #1,  w5                       ; w5 = M-1

    ; Filter the N input samples.
    ; Note that at this point, we have x-> x[0], and del[m] = g(m)[n-1].
; {Loop (N) times
    push.l    w5                           ; Save w5 for future use.

startFilter:
    ; For m = 0 (recursion set up).
    
    mov.l [w1], f0                        ; F0 = x[n]
    mov.l [w9], f1                      ; F1 = del[m] = g(0)[n-1]
    mov.l [w1++], [w9++]                ; g(0)[n] = x[n]
                                        ; w9-> del[m+1] = (g(1)[n-1])
                                        ; w1 -> x[n+1]

    ; For 1 <= m < M (recursion proper).
    mov.l    [w8], f2                   ; F2 = k[0]
    mov.l    [w15-4], w5                ; Restore w5
startRecurse:    
; {Loop (M-2)+1 times
    ; Compute recursive terms.
                                       
    ; Upper branch:f(m)[n] =f(m-1)[n] - k_(m-1)*g(m-1)[n-1].
    
    mul.s     f2, f0, f4                    ; F4 = k[m]*f[m][n]
    mul.s     f2, f1, f3                    ; F3 = k[m]*g(0)[n-1]
    
    ; Lower branch: g(m)[n] = -k_(m-1)*f(m-1)[n] + g(m-1)[n-1].
    NOP                                     ; Stall cycle.
    mov.l     [++w8], f2                    ; F2 = k[m]
    add.s     f1, f4, f4                    ; F4 = g(m)[n]
    
    add.s     f0, f3, f3                    ; F3 = f(m-1)[n] - k_(m-1)*g(m-1)[n-1]

    mov.l     [w9], f1                      ; f1 = g(m)[n-1]
    mov.l     f4, [w9++]                    ; save g(m)[n]
                                            ; w9-> del[m+1] (g(m+1)[n-1])
    mov.s     f3, f0                        ; F0 = f(m)[n]
    dtb w5, startRecurse
; }

    ; For m = M (generate output).
    ; y[n] =f(M)[n] =f(M-1)[n] - k_(M-1)*g(M-1)[n-1].
    
    mul.s     f1, f2, f2                   ; f2 = k_(M-1)*g(M-1)[n-1].
    ; Rewind pointers.
    mov.l    w10,w8                        ; w8-> k[0]
    mov.l    w7,w9                         ; w9-> del[0]
    NOP                                    ; Stall cycle.
    add.s    f0, f2, f2                    ; f2 = f(M-1)[n] - k_(M-1)*g(M-1)[n-1].
    NOP                                    ; Stall cycle.
    NOP                                    ; Stall cycle.
    mov.l     f2, [w2++]                   ; save y[n] =f(M)[n]
                                           ; w2-> y[n+1]
    dtb w3, startFilter
; }
    pop.l    w5

;............................................................................

_completedFIRLattice:

    pop.l    FCR               ; restore FCR.

;............................................................................

    ; Restore working registers.
    pop.l    w10               ; {w10} from TOS
    pop.l    w9                ; {w9 } from TOS
    pop.l    w8                ; {w8 } from TOS

;............................................................................

    return    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OEF
