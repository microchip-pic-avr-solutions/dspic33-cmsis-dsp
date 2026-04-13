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
    .include    "dspcommon.inc"     ; floatsetup
         
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .dspic33cmsisdsp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_cfft_f32 : Single precision floating-point FFT Complex function (in-place).
;
; Operation:
;    dstV[n] = FFTComplex(srcV[n]), 0 <= n < numElems
;
; Input:
;    w0 = ptr to mchp_cfft_instance_f32 structure
;    w1 = ptr to source vector (Complex dstV)
;    w2 = ifft flag
;    w3 = Bit reverse flag
; Return:
;    None
;
; System resources usage:
;    {w0..w7}    used, not restored
;    {w8..w12}    saved, used, restored
;    {f0..f7}    used, not restored
;    {f8..f11}    saved, used, restored
;
;............................................................................

   .extern    _mchp_scale_f32
   .global    _FFTComplexIP_noBitRev_f32   ; export
_FFTComplexIP_noBitRev_f32:
    
;............................................................................
    ; Save working registers.
    push.l    w8                ; {w8} to TOS
    push.l    w9                ; {w9} to TOS
    push.l    w10               ; {w10} to TOS
    push.l    w11               ; {w11} to TOS
    push.l    w12               ; {w12} to TOS
    push.l    f8                ; {f8} to TOS
    push.l    f9                ; {f9} to TOS
    push.l    f10               ; {f10} to TOS
    push.l    f11               ; {f11} to TOS
;............................................................................

    ; Mask all FPU exceptions, set rounding mode to default and clear SAZ/FTZ

    push.l FCR                     ; Save FCR
    floatsetup w8

;............................................................................
    push.l    w1                    ; save return value (srcCV)

;............................................................................

    ; FFT proper.
    mov.l    w0,  w9                  ; w9 = N
    mov.l    #0x1,w3                  ; initialize twidds offset,
                                      ; also used as num butterflies
    mov.l    w2,  w8                  ; w8-> WN(0) (real part)


    ; Preform all k stages, k = 1:log2N.
    ; NOTE: for first stage, 1 butterfly per twiddle factor (w3 = 1)
    ; and N/2 groups  (w9 = N/2) for factors WN(0), WN(1), ..., WN(N/2-1).
                                
                                
_doStage:
    ; Perform all butterflies in each stage, grouped per twiddle factor.
    
    ; Update counter for groups.
    lsr.l    w9,  w9              ; w9 = N/(2^k)
    
    sl.l     w9,  #3, w12         ; w12= lower offset
                                  ; nGrps+sizeof(floatcomplex)  ;; *4 bytes per element


    ; Set pointers to upper "leg" of butterfly:
    mov.l    w1,  w10             ; w10-> srcCV (upper leg)


    ; Perform all the butterflies in each stage.
    mov.l    w3,  w6              ; w6 = butterflies per group
startBflies:
;{                                ; do 2^(k-1) butterflies
    ; Set pointer to lower "leg" of butterfly.
    add.l    w12, w10, w11        ; w11-> srcCV + lower offset
                                  ; (lower leg)
                                
    ; Prepare offset for twiddle factors.
    sl.l     w3,  #3,  w7         ; oTwidd*sizeof(floatcomplex);; *4 bytes per element

    ; Perform each group of butterflies, one for each twiddle factor.
    mov.l    w9,  w5              ; w5 = nGrps-1 ;; 
startGroup:
;{   
    mov.l   [w11++], f1          ; f1= Br ; [w11]->Bi
    mov.l   [w10++], f0          ; f0= Ar ; [w10]->Ai
    mov.l   [w11--], f3          ; f3= Bi ; [w11]->Br
    mov.l   [w10--], f4          ; f4= Ai ; [w10]->Ar

    
    sub.s   f0, f1, f2           ; f2 = Ar - Br
     
    mov.l   [w8],    f9          ; f9 = Wr  (read real at current twiddle base)
    mov.l   [w8+#4], f10         ; f10 = Wi (read imag at base + 4) 
    
    cp0.l   w4
    BRA     NEQ, skip_negate     ;if w4 == 0,then negate wi value
    neg.s   f10, f10
    
    skip_negate:
    sub.s   f4, f3, f11          ; f11 = Ai - Bi
    
    mul.s   f2, f10, f7          ; f7 = (Ar - Br)*Wi
    mul.s   f2, f9, f8           ; f8 = (Ar - Br)*Wr
    
    add.s  f1, f0, f2            ; f2 = Ar + Br
    
    mul.s   f10, f11, f6         ; f6 = (Ai - Bi)*Wi
    mac.s   f11, f9, f7          ; f7 = (Ar - Br)*Wi + (Ai - Bi)*Wr
    
    add.s  f3, f4, f5            ; f5 = Ai + Bi

    mov.l f2, [w10++]            ; Save Cr

    sub.s   f8, f6, f8           ; f8 = (Ar - Br)*Wr - (Ai - Bi)*Wi
    
    add.l   w8, w7, w8           ; pTwidd-> for next group
    
    mov.l f5, [w10++]            ; Save Ci
    
    mov.l   f8, [w11++]          ; Save Dr
    mov.l   f7, [w11++]          ; Save Di
    
    dtb w5, startGroup
; }
    add.l    w12,w10,w10          ; w10-> upper leg (next set)
    mov.l    w2,w8                ; rewind twiddle pointer  ; [w8]->Wr[0]
    dtb    w6, startBflies
; }

    ; Update offset to factors.
    sl.l    w3,w3                ; oTwidd *= 2


    ; Find out whether to perform another stage...
    cp.l w9, #1                  ; till w9 = N becomes 1
    BRA   NZ, _doStage
;............................................................................
_completedFFT:
    pop.l        w1              ; restore return value

;............................................................................    
    pop.l   FCR
    ; Restore working registers.
    pop.l    f11                ; {f11} from TOS
    pop.l    f10                ; {f10} from TOS
    pop.l    f9                 ; {f9} from TOS
    pop.l    f8                 ; {f8} from TOS
    pop.l    w12                ; {w12} from TOS
    pop.l    w11                ; {w11} from TOS
    pop.l    w10                ; {w10} from TOS
    pop.l    w9                 ; {w9} from TOS
    pop.l    w8                 ; {w8} from TOS

;............................................................................
    return    
    
    
;............................................................................

    
.global _mchp_cfft_f32

_mchp_cfft_f32:

    ; Load fftLen and twiddle pointer
    mov.l   [w0], w4            ; w4 = fftLen (uint16)
    mov.l   [w0+#4], w5         ; w5 = pTwiddle

    ; Branch on IFFT flag
    cp      w2, #0
    bra     Z, _forward_path

; ---------------- Inverse FFT path ----------------

    mov     w4, w0              ; w0 = N (fft length)
    mov.l   w4, f0              ; f0 = N
    sl.l    w4, w4              ; w4 = 2*N (scratch use)
    li2f.s  f0, f0              ; f0 = float(N)

    movc.s  #1, f1              ; f1 = 1.0
    div.s   f1, f0, f0          ; f0 = 1/N  (scaling factor)

    ; Save context for call
    push.l  w4                  ; scratch N*2
    mov.l   w2, w4              ; w4 = ifftFlag
    mov.l   w5, w2              ; w2 = pTwiddle

    push.l  w3                  ; bitRev flag
    push.l  w0                  ; N
    push.l  w1                  ; data ptr
    push.l  f0                  ; scale factor (1/N)

    call    _FFTComplexIP_noBitRev_f32

    ; Restore context
    pop.l   f0
    pop.l   w0
    pop.l   w1
    pop.l   w3

    ; Optional bit-reversal
    cp0.l   w3
    bra     z, _skip_call
    call    _mchp_bitreversal_f32
_skip_call:

    mov     w0, w1              ; set output ptr
    pop.l   w2                  ; restore twiddle ptr

    call    _mchp_scale_f32
    bra     finish

; ---------------- Forward FFT path ----------------
_forward_path:

    mov     w4, w0              ; w0 = log2N
    mov     w2, w4              ; w4 = ifftFlag
    mov     w5, w2              ; w2 = pTwiddle

    push.l  w0
    push.l  w1
    push.l  w3

    call    _FFTComplexIP_noBitRev_f32

    pop.l   w3
    pop.l   w0                  ; source vector
    pop.l   w1                  ; fft length

    ; Optional bit-rev
    cp0.l   w3
    bra     z, _skip_call_f
    call    _mchp_bitreversal_f32
_skip_call_f:

finish:
    return
    .end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OEF



