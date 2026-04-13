;*****************************************************************************
;                                                                            *
;                       Software License Agreement                           *
;*****************************************************************************
;*****************************************************************************
; © [2026] Microchip Technology Inc. and its subsidiaries.                    *
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
; _FFTComplexIP2_noBitRev_f32: Single precision floating-point FFT function on a complex vector. (with no bit-reversal)
;
; Operation:
;    dstV[n] = FFT(srcV), 0 <= n < numElems
;    The functionality is same as FFTComplex Function, except for the part that it takes
;    twid factor generated for 2*N points to compute FFT.
;    This is to aid re-usage of twid factors passed onto realFFT function.
;
; Input:
;    w0 = log to the base_2 of N (log2N)
;    w1 = ptr to source/destination vector (srcV)
;    w2 = ptr to N/2 sized twid factors.
; Return:
;    w0 = ptr to destination vector (dstV)
;
; System resources usage:
;    {w0..w7 }    used, not restored
;    {w8..w10}    saved, used, restored
;    {f0..f7 }    used, not restored
;    {f8..f12}    saved, used, restored
;............................................................................
   .extern    _mchp_copy_f32
   .extern    _mchp_scale_f32
   .global    _FFTComplexIP2_noBitRev_f32   ; export
_FFTComplexIP2_noBitRev_f32:
    
;............................................................................
    ; Save working registers.
    push.l    w8                ; {w8} to TOS
    push.l    w9                ; {w9 to TOS
    push.l    w10               ; {w10} to TOS
    push.l    w11               ; {w11} to TOS
    push.l    w12               ; {w12} to TOS
    push.l    f12                ; {f12} to TOS
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
													  
    mov.l    w0,w9                    ; w9 = N
    mov.l    #0x1,w3                ; initialize twidds offset,
                                    ; also used as num butterflies
    mov.l    w2,w8                  ; w8-> WN(0) (real part)
    ; Preform all k stages, k = 1:log2N.
    ; NOTE: for first stage, 1 butterfly per twiddle factor (w3 = 1)
    ; and N/2 groups  (w9 = N/2) for factors WN(0), WN(1), ..., WN(N/2-1).                                                    
_doStage:
    ; Perform all butterflies in each stage, grouped per twiddle factor.
    
    ; Update counter for groups.
    lsr.l    w9,w9                ; w9 = N/(2^k)
    
    sl.l    w9,#3,w12             ; w12= lower offset
                                  ; nGrps+sizeof(floatcomplex)  ;; *4 bytes per element
    ; Set pointers to upper "leg" of butterfly:
    mov.l    w1,w10               ; w10-> srcCV (upper leg)
    ; Perform all the butterflies in each stage.
    mov.l    w3,    w6            ; w6 = butterflies per group
startBflies:
;{                                ; do 2^(k-1) butterflies
    ; Set pointer to lower "leg" of butterfly.
    add.l    w12,w10,w11          ; w11-> srcCV + lower offset
                                  ; (lower leg)
                                
    ; Prepare offset for twiddle factors.
    sl.l    w3,#4,w7              ; oTwidd*sizeof(floatcomplex);; *4 bytes per element

    ; Perform each group of butterflies, one for each twiddle factor.
    mov.l    w9,w5                ; w5 = nGrps-1 ;; 
startGroup:
;{   
    mov.l   [w11++], f1          ; f1= Br ; [w11]->Bi
    mov.l   [w10++], f0          ; f0= Ar ; [w10]->Ai
    mov.l   [w11--], f3          ; f3= Bi ; [w11]->Br
    mov.l   [w10--], f4          ; f4= Ai ; [w10]->Ar

    
    sub.s   f0, f1, f2           ; f2 = Ar - Br
     
   mov.l   [w8],    f9          ; f9 = Wr  (read real at current twiddle base)
    mov.l   [w8+#4], f10         ; f10 = Wi (read imag at base + 4) 
    
    cp0.l w4
    BRA NEQ, skip_negate         ;if w4 == 0,then negate wi value
    neg.s f10,f10
    
    skip_negate:
    sub.s   f4, f3, f11          ; f11 = Ai - Bi
    
    mul.s   f2, f10, f7          ; f7 = (Ar - Br)*Wi
    mul.s   f2, f9, f12           ; f12 = (Ar - Br)*Wr
    
    add.s  f1, f0, f2            ; f2 = Ar + Br
    
    mul.s   f10, f11, f6         ; f6 = (Ai - Bi)*Wi
    mac.s   f11, f9, f7          ; f7 = (Ar - Br)*Wi + (Ai - Bi)*Wr
    
    add.s  f3, f4, f5            ; f5 = Ai + Bi

    mov.l f2, [w10++]            ; Save Cr

    sub.s   f12, f6, f12           ; f12 = (Ar - Br)*Wr - (Ai - Bi)*Wi
    
    add.l   w8, w7, w8           ; pTwidd-> for next group
    
    mov.l f5, [w10++]            ; Save Ci
    
    mov.l   f12, [w11++]          ; Save Dr
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
    ;lsr.l w0,w0
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
    pop.l    f12                 ; {f12} from TOS
    pop.l    w12                ; {w12} from TOS
    pop.l    w11                ; {w11} from TOS
    pop.l    w10                ; {w10 from TOS
    pop.l    w9                 ; {w9} from TOS
    pop.l    w8                 ; {w8} from TOS

;............................................................................
																			 
    return    
    
    
;............................................................................    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _FFTReal_SplitFunction_f32: Split function for FFT real function.
;
; Operation:
;    dstV[n] = Split_function(srcV), 0 <= n < numElems
;
; Input:
;    w0 = log to the base_2 of N (log2N)
;    w1 = ptr to source/destination vector (srcV)
;    w2 = ptr to N/2 twid factors.
; Return:
;    w0 = ptr to destination vector (dstV)
;
; System resources usage:
;    {w0..w7 }    used, not restored
;    {w8..w9 }    saved, used, restored
;    {f0..f7 }    used, not restored
;    {f8..f12}    saved, used, restored
;............................................................................

   .global    _FFTReal_SplitFunction_f32   ; export
_FFTReal_SplitFunction_f32:
;............................................................................
    push.l    w8                        ; {w8} to TOS
    push.l    w9                        ; {w9} to TOS
    push.l    f8                        ; {f8} to TOS
    push.l    f9                        ; {f9} to TOS
    push.l    f10                       ; {f10} to TOS
    push.l    f11                       ; {f11} to TOS
    push.l    f12                       ; {f12} to TOS
      
    push.l    w1                        ; save return value.


; Store Input Parameters
    add.l        w2,#8, w4               ; w4 ---> Wr+1 = COS(*)

_INPUTPARAMSSTORED:
    mov.l        w1,    w8               ; W8  ---> Pr[0], first bin
    ;mov.l        #4,    w2
    ;sl.l         w2,w0,w2
    sl.l         w0, #2, w2
    add.l        w1,w2,w9                ; w9 ---> Pr[N], last bin

    lsr.l        w2,#4,w6                ; N/2
    sub.l        w6,#1,w6                ; w6 = BIN_CNTR = (N/2)-2

    mov.l        #0x3F000000, f12        ; f12 = 0.5

; DC and Nyquist Bin

    mov.l    [w8++], f0                  ; f0 = Pr[0]
    mov.l    [w8--], f1                  ; f1 = Pi[0]
     
    mov.l   #0,w0                        ; w0 = 0    
    
    add.s   f0, f1, f2                   ; f2 = Pr[0] + Pi[0]
    sub.s   f0, f1, f3                   ; f3 = (Pr[0] - Pi[0])/2

    
    mov.l   f2, [W8++]                   ; Gr[0] = (Pr[0] + Pi[0])/2
    mov.l   f3, [w9++]                   ; Gr[N] = (Pr[0] - Pi[0])/2
    
    mov.l   w0,[W8++]                    ; Pi[0] = 0
    mov.l   w0,[w9++]                    ; Gi[N] = 0    
    sub.l   w9,#16, w9                   ; w9---> Gr[N-1], w8---> Gr[1]

; Bin 1 to N-1, k=1:(N/2-1)
BIN_START:
        mov.l   [w9++], f4          ; f4 = Pr[N-k]
        mov.l   [w8++], f5          ; f5 = Pr[k]
        
        mov.l   [w9--], f6          ; f6 = Pi[N-k]
        mov.l   [w8--], f7          ; f7 = Pi[k]

        add.s   f4, f5, f0          ; f0 = Pr[N-k] + Pr[N]
        add.s   f6, f7, f1          ; f1 = Pi[N-k] + Pi[N]

        NOP                         ; Stall cycle
        
        mul.s   f0, f12, f0         ; Radd[k]=(Pr[k]+Pr[N-k])/2
        mul.s   f1, f12, f1         ; Iadd[k]=(Pi[k]+Pi[N-k])/2
        
        mov.l   [w4++], f10         ; f10 = Wr
        mov.l   [w4++], f11         ; f11 = Wi
	
	;cp0.l w3
	;BRA NEQ, skip_negate         ;if w4 == 0,then negate wi value
	neg.s f11,f11
        
        sub.s   f0, f4, f2          ; Rsub[k]=(Pr[k]-Pr[N-k])/2
        sub.s   f1, f6, f3          ; Isub[k]=(Pi[k]-Pi[N-k])/2
          
                        ; w9---> Gr[N-k],
                        ; w8---> Gr[k]
;MERGE_BFLY
;...........................................................................
; Equations for Butterfly Computation
; f0 = Gr(k)=Radd + (Wr*Iadd + Wi*Rsub)  
; f1 = Gi(k)=Isub - (Wr*Rsub + Wi*Iadd)
; f2 = Gr(N-k)=Radd - (Wr*Iadd + Wi*Rsub)  
; f3 = Gi(N-k)=-Isub - (Wr*Rsub + Wi*Iadd)        
; f10 = Wr   
; f11 = Wi     
;............................................................................
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
        mul.s   f1, f10, f5        ; f5 = Iadd*Wr
        mul.s   f10, f2, f6        ; f6 = Rsub*Wr
        mul.s   f11, f1, f4        ; f4 = Iadd*Wi
        
        NOP
        
        mac.s   f2, f11, f5        ; f5 = Rsub*Wi + Iadd*Wr  
        
        NOP
        
        sub.s   f4, f6, f6         ; f6 = Iadd*Wi - Wr*Rsub
        
        sub.l   w9,#8, w9           ; w9 = w9 - 8 -> G[N-k-1]
        
        add.s   f0, f5, f8         ; f8  = (Radd + (Iadd*Wr+Rsub*Wi))
        add.s   f3, f6, f10        ; f10 = (Isub - (Wr*Rsub - Wi*Iadd))  
        sub.s   f0, f5, f9         ; f9  = (Radd - (Iadd*Wr+Rsub*Wi)) 
        sub.s   f6, f3, f11        ; f11 = (-Isub - (Wr*Rsub - Wi*Iadd))
                
        mov.l   f8,  [w8++]        ; Gr(k)=(Radd + (Iadd*Wr+Rsub*Wi))
        mov.l   f10, [w8++]        ; Gi(k) = (Isub - (Wr*Rsub - Wi*Iadd))  
        mov.l   f9,  [w9 + 8]      ; Gr(N-k) = (Radd - (Iadd*Wr+Rsub*Wi))  
        mov.l   f11, [w9 + 12]     ; Gi(N-k)=(-Isub - (Wr*Rsub - Wi*Iadd))


        DTB         w6, BIN_START 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        mov.l   [++w8], f0         ; f0 = Gr[N/2]
        neg.s   f0,f0              ; f0 = -f0
        mov.l   f0, [w8]           ; Gr[N/2] = f0


_DONEREALFFT:
;............................................................................
; Context Restore
        pop.l    w0                    ; Restore return value
          
        pop.l   f12                   ; {f12} from TOS
        pop.l   f11                   ; {f11} from TOS
        pop.l   f10                   ; {f10} from TOS
        pop.l   f9                    ; {f9 } from TOS
        pop.l   f8                    ; {f8 } from TOS
        POP.l   w9                    ; {w9 } from TOS
        POP.l   w8                    ; {w8 } from TOS

;............................................................................
;............................................................................
    return        
    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _IFFTReal_SplitFunction_f32: Split function for IFFT real function.
;
; Operation:
;    dstV[n] = Split_function(srcV), 0 <= n < numElems
;
; Input:
;    w0 = log to the base_2 of N (log2N)
;    w1 = ptr to source/destination vector (srcV)
;    w2 = ptr to N/2 twid factors.
; Return:
;    w0 = ptr to destination vector (dstV)
;
; System resources usage:
;    {w0..w7 }    used, not restored
;    {w8..w9 }    saved, used, restored
;    {f0..f7 }    used, not restored
;    {f8..f11}    saved, used, restored
;............................................................................

;............................................................................
    .extern _IFFTComplexIP_f32   ; export
    .global _IFFTReal_SplitFunction_f32
    _IFFTReal_SplitFunction_f32:
;............................................................................
; Context Save
        push.l    w8                        ; {w8 } to TOS
        push.l    w9                        ; {w9 } to TOS
        push.l    f8                        ; {f8 } to TOS
        push.l    f10                       ; {f10} to TOS
        push.l    f11                       ; {f11} to TOS
        
        mov.l     #0x3F000000, f8           ; f8 = 0.5
        
        
; Store Input Parameters
        add.l     w2,#8, w4              ; w4 ---> Wr+1 = COS(*)

_INPUTPARAMSSTOREDIFFT:
        mov.l     w1, w8                 ; w8  ---> Pr[0], first bin
        ;mov.l     #4, w2                 ; w2 = 4
        ;sl.l      w2, w0, w2             ; 4*N
	sl.l      w0, #2, w2
        add.l     w1, w2, w9             ; w9 ---> Pr[N], last bin

        lsr.l     w2, #4, w6             ; N/2
        sub.l     w6, #1, w6             ; w6 = BIN_CNTR = (N/2)-2


; DC and Nyquist Bin

        mov.l   [w8], f0                 ; f0 = Pr[0]
        mov.l   [w9], f2                 ; f2 = Pr[N]
        
        add.s   f0, f2, f4
        mul.s   f4, f8, f4               ; f4 = (Pr[0] + Pr[N])/2
        
        mov.l   #0,w0        
        mov.l   w0,[W9++]                ; Gr[N] = 0
        mov.l   w0,[w9++]                ; Gi[N] = 0
        
        sub.s   f4, f2, f5               ; f5 = (Pr[0] - Pr[N])/2
        mov.l   f4, [w8++]               ; Gr[0] = (Pr[0] + Pr[N])/2
        mov.l   f5, [w8++]               ; Gi[0] = (Pr[0] - Pr[N])/2

        sub.l   w9, #16, w9              ; w9---> Gr[N-1], w8---> Gr[1]


; Bin 1 to N-1, k=1:(N/2-1)
IFFT_BIN_START:
        mov.l   [w9++], f0               ; f0 = Pr[N-k]
        mov.l   [w8++], f2               ; f2 = Pr[k]
        
        mov.l   [w9--], f1               ; f1 = Pi[N-k]
        mov.l   [w8--], f3               ; f3 = Pi[k]        
        
        add.s   f2, f0, f4               ; f4 = Pr[N-k]
        add.s   f1, f3, f6               ; f6 = Pr[k]

        NOP
        
        mul.s   f4, f8, f4               ; f4 = Radd = (Pr[k] + Pr[N-k])/2         
        mul.s   f6, f8, f6               ; f6 = Iadd = (Pi[k] + Pi[N-k])/2 
        
        mov.l   [w4++], f10              ; f10 = Wr
        mov.l   [w4--], f11              ; f11 = Wi  
	
	;cp0.l w3
	;BRA NEQ, skip_negate         ;if w4 == 0,then negate wi value
	;neg.s f11,f11
        
        sub.s   f4, f0, f5               ; f5 = Rsub = (Pr[k]-Pr[N-k])/2
        sub.s   f6, f1, f7               ; f7 = Isub = (Pi[k]-Pi[N-k])/2

;MERGE_BFLY
;...........................................................................
; Equations for Butterfly Computation

; Gr(k)  = Radd - (Rsub*Wi + Iadd*Wr)
; Gi(k)  = (Isub + (Wr*Rsub - Wi*Iadd))
; Gr(N-k) = Radd + (Rsub*Wi + Iadd*Wr)
; Gi(N-k) = (-Isub + (Wr*Rsub - Wi*Iadd))
;............................................................................
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Iadd*Wi 32-bit multiplication
             

; Rsub*Wi + Iadd*Wr 32-bit multiplication   
       
        mul.s   f10, f6, f0        ; f0 = Wr*Iadd
        mul.s   f10, f5, f1        ; f1 = Wr*Rsub
        mul.s   f11, f6, f2        ; f2 = Wi*Iadd

        NOP
        
        mac.s   f5, f11, f0        ; f0 = Rsub*Wi + Iadd*Wr
        
        sub.l   w9,#8, w9        
        sub.s   f1, f2, f2         ; f2 = Wr*Rsub - Wi*Iadd
        
        NOP
        
        sub.s   f4, f0, f10        ; f10 = Radd - (Rsub*Wi + Iadd*Wr)
        add.s   f0, f4, f11        ; f11 = Radd + (Rsub*Wi + Iadd*Wr)
        
        add.s   f2, f7, f0         ; f0 = (Isub + (Wr*Rsub - Wi*Iadd))
        sub.s   f2, f7, f1         ; f1 = (-Isub + (Wr*Rsub - Wi*Iadd))

        mov.l   f10, [w8++]        ; Gr(  k) = Radd - (Rsub*Wi + Iadd*Wr)
        mov.l   f11, [w9+8]        ; Gr(N-k) = Radd + (Rsub*Wi + Iadd*Wr)

        mov.l   f0, [w8++]         ; Gi(  k) = (Isub + (Wr*Rsub - Wi*Iadd))
        mov.l   f1, [w9+12]        ; Gi(N-k) = (-Isub + (Wr*Rsub - Wi*Iadd))
        
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        add.l       w4,#8,w4           ; Next Twiddle Factor (Wr)
        dtb         w6, IFFT_BIN_START
        
        
        mov.l      [++w8], f0
        neg.s      f0, f0
        mov.l      f0, [w8++]            ; B=-Pi(N/2)/2 


_DONEREALIFFT:
;............................................................................
; Context Restore
          
        pop.l    f11                   ; {f11} from TOS
        pop.l    f10                   ; {f10} from TOS
        pop.l    f8                    ; {f8} from TOS
        pop.l    w9                    ; {w9} from TOS
        pop.l    w8                    ; {w8} from TOS
;............................................................................
        RETURN    
    



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
    
    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
    .global _FFTComplex2IP_f32
    
    _FFTComplex2IP_f32:
;............................................................................
    ; Save working registers.
    ; none to save...
;............................................................................

    ;push.l    w1                ; save return value (srcCV)

;............................................................................

    ; Compute IFFT using DIF FFT algorithm.
    push.l    w0                ; save log2NVal
    push.l    w1                ; save pointer to srcCV
    call _FFTComplexIP2_noBitRev_f32
    pop.l    w0                ; restore pointer to srcCV
    pop.l    w1                ; restore log2NVal

    ; Finally, unscramble results back to natural order.
    call _mchp_bitreversal_f32

;............................................................................

    ;pop.l    w0                ; restore return value
;............................................................................

    ; Restore working registers.
    ; none to restore...

;............................................................................

    return 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; mchp_rfft_fast_f32: Compute the real FFT or inverse real FFT
;
; Operation:
;    Performs an in-place real FFT transform.
;    If ifftFlag = 0:
;        Compute RFFT  (forward real FFT)
;    If ifftFlag = 1:
;        Compute IRFFT (inverse real FFT)
;
; Input:
;    W0 = pointer to mchp_rfft_fast_instance_f32 S
;         (contains internal CFFT instance, twiddle tables, fftLenRFFT)
;    W1 = pointer to input vector p
;    W2 = pointer to output vector pOut
;    W3 = ifftFlag
;         0 = forward RFFT
;         1 = inverse RFFT
;
; Return:
;    none (void)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.global    _FFTRealIP_f32   
.global    _mchp_rfft_fast_f32  

_mchp_rfft_fast_f32:

    ; ---------------------------------------------------------
    ; Save inputs for copy operation
    ; ---------------------------------------------------------
    push.l     w0                 ; Sint
    push.l     w2                 ; pOut
    push.l     w3                 ; ifftFlag

    mov.l   [w0+16], w4           ; w4 = rfftLen
    sl.l    w4, #1, w4            ; w4 = 2 * rfftLen

    mov.l   w1, w0                ; w0 = pSrc
    mov.l   w2, w1                ; w1 = pDst
    mov.l   w4, w2                ; w2 = blockSize

    call    _mchp_copy_f32        ; Copy pSrc -> pDst

    ; ---------------------------------------------------------
    ; Restore parameters
    ; ---------------------------------------------------------
    pop.l    w3                   ; ifftFlag
    pop.l    w1                   ; pDst
    pop.l    w0                   ; Sint

    ; ---------------------------------------------------------
    ; Setup FPU
    ; ---------------------------------------------------------
    push.l   FCR
    floatsetup w4

    ; Save return pointer (pDst)
    push.l   w1

    ; ---------------------------------------------------------
    ; Load CFFT parameters
    ; ---------------------------------------------------------
    mov.l   [w0+#0], w4           ; w4 = cfftLen
    mov.l   [w0+#4], w5           ; w5 = pTwiddle
    mov.l   [w0+16], w6           ; w6 = fftLenRFFT

    ; ---------------------------------------------------------
    ; Branch: ifftFlag == 0 ? forward
    ; ---------------------------------------------------------
    cp      w3, #0
    bra     Z, _forward_path

; -------------------------------------------------------------
;                        INVERSE PATH
; -------------------------------------------------------------
_inverse_path:

    mov.l   w5, w2                ; w2 = pTwiddle
    mov.l   w6, w0                ; w0 = rfftLen

    ; Save parameters for IFFT split
    push.l  w3
    push.l  w4
    push.l  w1
    push.l  w2

    call    _IFFTReal_SplitFunction_f32

    pop.l   w2                    ; twid
    pop.l   w1                    ; srcCV
    pop.l   w0                    ; rfftLen
    pop.l   w4                    ; ifftFlag

    ; Compute N/2 scaling
    mov.l   w0, w3                ; w3 = N/2
    mov.l   w3, f1
    movc.s  #1, f0
    li2f.s  f1, f1
    div.s   f0, f1, f2            ; f2 = 1 / (N/2)

    sl.l    w3, #1, w3            ; w3 = N

    ; Call complex FFT core
    push.l  w3                    ; N
    push.l  f2                    ; scale factor
    
    call    _FFTComplex2IP_f32

    ; Scale final output
    mov.l   w0, w1             ; w1 = output vector
    pop.l   f0                 ; f0 = scaling factor
    pop.l   w2                 ; w2 = block size

    call    _mchp_scale_f32

    pop.l   w1
    pop.l   FCR

    bra     finish

; -------------------------------------------------------------
;                        FORWARD PATH
; -------------------------------------------------------------
_forward_path:

    mov.l   w5, w2                ; pTwiddle
    mov.l   w4, w0                ; cfftLen
    mov.l   w3, w4                ; ifftFlag (always 0 here)

    ; Save parameters
    push.l  w4
    push.l  w6
    push.l  w1
    push.l  w2

    call    _FFTComplex2IP_f32

    pop.l   w2
    pop.l   w1
    pop.l   w0
    pop.l   w3

    ; Merge real FFT
    call    _FFTReal_SplitFunction_f32

    pop.l   w2
    pop.l   FCR

finish:
    return
    .end




