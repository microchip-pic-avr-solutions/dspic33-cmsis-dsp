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
;    software) that may accompany Microchip software. SOFTWARE IS "AS IS."   *
;    NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS     *
;    SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,         *
;    MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT       *
;    WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,           *
;    INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY        *
;    KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF        *
;    MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE        *
;    FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIPS           *
;    TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT          *
;    EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR       *
;   THIS SOFTWARE.                                                           *
;*****************************************************************************

    ; Local inclusions.

    .nolist
    .include    "dspcommon.inc"      ; fractsetup
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _FFTComplexIP2_noBitRev_q31: Fixed-point (Q31) FFT function on a complex
;    vector (with no bit-reversal).
;
; Description:
;    Same functionality as the complex FFT function, except it takes twiddle
;    factors generated for 2*N points to compute the FFT. This enables
;    re-use of twiddle factors passed into the real FFT function.
;
;    An implicit scaling of 1/2 is applied at every stage to prevent
;    overflow in fractional mode, so the final output is scaled by 1/N.
;
;    DIF butterfly (Q31 fractional with 1/2 scaling):
;      Cr = (Ar + Br) / 2
;      Ci = (Ai + Bi) / 2
;      Dr = ((Ar - Br)*Wr - (Ai - Bi)*Wi) / 2
;      Di = ((Ar - Br)*Wi + (Ai - Bi)*Wr) / 2
;
; Operation:
;    dstV[n] = FFT(srcV), 0 <= n < numElems
;
; Input:
;    w0 = N/2 (number of complex points, i.e. half the real FFT length)
;    w1 = ptr to source/destination vector (srcV)
;    w2 = ptr to N/2 sized twiddle factors (for 2*N points)
;    w3 = ifftFlag (0 = forward FFT, nonzero = inverse FFT)
;
; Return:
;    w0 = ptr to destination vector (dstV)
;
; System resources usage:
;    {w0..w7}    used, not restored
;    {w8..w14}   saved, used, restored
;     AccuA      used, not restored
;     AccuB      used, not restored
;     CORCON     saved, used, restored
;
;............................................................................

    .extern    _mchp_copy_q31
    .extern    _mchp_scale_q31

    .global    _FFTComplexIP2_noBitRev_q31        ; export

_FFTComplexIP2_noBitRev_q31:

;............................................................................
    ; Save working registers.
    push.l    w8                ; {w8} to TOS
    push.l    w9                ; {w9} to TOS
    push.l    w10               ; {w10} to TOS
    push.l    w11               ; {w11} to TOS
    push.l    w12               ; {w12} to TOS
    push.l    w13               ; {w13} to TOS
    push.l    w14               ; {w14} to TOS

;............................................................................

    ; Prepare CORCON for fractional computation.
    push.l    CORCON
    fractsetup w8

;............................................................................

    push.l    w1                    ; save return value (srcCV)

;............................................................................

    ; FFT proper.
    mov.l    w0,w9                  ; w9 = N/2 (halved each stage as group count)
    mov.l    #0x1,w3                ; initialize twiddle offset,
                                    ; also used as num butterflies
    mov.l    w2,w8                  ; w8-> WN(0) (real part)

    ; Preform all k stages, k = 1:log2N.
    ; NOTE: for first stage, 1 butterfly per twiddle factor (w3 = 1)
    ; and N/2 groups (w9 = N/2) for factors WN(0), WN(1), ..., WN(N/2-1).

_doStage_rq31_core:
    ; Perform all butterflies in each stage, grouped per twiddle factor.

    ; Update counter for groups.
    lsr.l    w9,w9                ; w9 = N/(2^k)

    sl.l    w9,#3,w12             ; w12= lower offset
                                  ; nGrps*sizeof(fractcomplex) ;; *8 bytes per complex element

    ; Set pointers to upper "leg" of butterfly:
    mov.l    w1,w10               ; w10-> srcCV (upper leg)

    ; Perform all the butterflies in each stage.
    mov.l    w3,    w6            ; w6 = butterflies per group

startBflies_rq31_core:
;{                                ; do 2^(k-1) butterflies
    ; Set pointer to lower "leg" of butterfly.
    add.l    w12,w10,w11          ; w11-> srcCV + lower offset (lower leg)

    ; Prepare twiddle stride (2x stride for 2*N-point twiddle table).
    sl.l    w3,#4,w7              ; w7 = oTwidd*sizeof(fractcomplex) = w3*16

    ; Perform each group of butterflies, one for each twiddle factor.
    mov.l    w9,w5                ; w5 = nGrps

startGroup_rq31_core:
;{
    ; --- DIF Butterfly (Q31) — matches reference rfft_aa.s exactly ---
    ; Compute lower leg first (in-accumulator), then upper leg.

    mov.l   [w11++], w13          ; w13 = Br.                [w11]->Bi
    subr.l  w13, [w10++], w4      ; w4  = Ar - Br.           [w10]->Ai

    mpy.l   [w8]+=4, w4, a        ; a   = (Ar-Br)*Wr.       [w8]->Wi
    mpy.l   [w8], w4, b           ; b   = (Ar-Br)*Wi.

    mov.l   [w11--], w14          ; w14 = Bi.                [w11]->Br
    subr.l  w14, [w10--], w4      ; w4  = Ai - Bi.           [w10]->Ar

    msc.l   [w8]-=4, w4, a        ; a  -= (Ai-Bi)*Wi => Dr.  [w8]->Wr
    mac.l   [w8], w4, b           ; b  += (Ai-Bi)*Wr => Di.

    sacr.l  a, #1, [w11++]        ; Store 1/2*Dr (overwrite Br). [w11]->Bi
    sacr.l  b, #1, [w11++]        ; Store 1/2*Di (overwrite Bi). [w11]->next

    add.l   w8, w7, w8            ; pTwidd-> for next group

    lac.l   [w10++], a            ; a  = Ar.                  [w10]->Ai
    lac.l   [w10--], b            ; b  = Ai.                  [w10]->Ar

    add.l   w13, a                ; a  = Ar + Br.
    add.l   w14, b                ; b  = Ai + Bi.

    sacr.l  a, #1, [w10++]        ; Store (Ar+Br)/2.          [w10]->Ai
    sacr.l  b, #1, [w10++]        ; Store (Ai+Bi)/2.          [w10]->next

    dtb w5, startGroup_rq31_core
; }

    add.l    w12,w10,w10          ; w10-> upper leg (next set)
    mov.l    w2,w8                ; rewind twiddle pointer  ; [w8]->Wr[0]
    dtb    w6, startBflies_rq31_core
; }

    ; Update offset to factors.
    sl.l    w3,w3                ; oTwidd *= 2

    ; Find out whether to perform another stage...
    cp.l w9, #1                  ; till w9 = N becomes 1
    BRA   NZ, _doStage_rq31_core

;............................................................................
_completedFFT_rq31_core:
    pop.l        w0              ; restore return value

;............................................................................
    ; Restore working registers.
    pop.l     CORCON
    pop.l    w14                ; {w14} from TOS
    pop.l    w13                ; {w13} from TOS
    pop.l    w12                ; {w12} from TOS
    pop.l    w11                ; {w11} from TOS
    pop.l    w10                ; {w10} from TOS
    pop.l    w9                 ; {w9} from TOS
    pop.l    w8                 ; {w8} from TOS

;............................................................................

    return


;............................................................................

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _FFTRealSplit_q31: Split function for forward real FFT (Q31).
;
; Description:
;    Post-processing split operation for a real FFT.
;    Takes the output of an N/2-point complex FFT and combines the
;    symmetric/antisymmetric parts using twiddle factors to produce
;    the N-point real FFT result.
;
;    Mirrors _FFTReal_SplitFunction_f32 algorithm exactly, using Q31
;    fractional DSP engine instructions. The /2 operations use
;    sacr.l with #1 shift instead of floating-point multiply by 0.5.
;
; Input:
;    w0 = N (real FFT length, i.e., number of real samples)
;    w1 = ptr to source/destination vector (srcV)
;    w2 = ptr to twiddle factors (split twiddle table)
;
; Return:
;    w0 = ptr to destination vector (dstV)
;
; System resources usage:
;    {w0..w7}    used, not restored
;    {w8..w14}   saved, used, restored
;     AccuA      used, not restored
;     AccuB      used, not restored
;     CORCON     saved, used, restored
;
; Register allocation in main loop:
;    w4  = twiddle running pointer (Wr, Wi pairs)
;    w8  = forward data pointer (Gr[k])
;    w9  = reverse data pointer (Gr[N-k])
;    w10 = Radd (temp)
;    w11 = Rsub (temp)
;    w12 = Iadd (temp)
;    w13 = Isub (temp)
;    w14 = Wr
;    w7  = Wi (negated)
;    w3  = T1 (temp)
;    w5  = T2 (temp)
;    w6  = loop counter
;
;............................................................................

    .global    _FFTRealSplit_q31       ; export

_FFTRealSplit_q31:
;............................................................................
    push.l    w8                        ; {w8} to TOS
    push.l    w9                        ; {w9} to TOS
    push.l    w10                       ; {w10} to TOS
    push.l    w11                       ; {w11} to TOS
    push.l    w12                       ; {w12} to TOS
    push.l    w13                       ; {w13} to TOS
    push.l    w14                       ; {w14} to TOS

    push.l    CORCON
    fractsetup w8

    push.l    w1                        ; save return value.

; Store Input Parameters
    add.l        w2, #8, w4             ; w4 ---> Wr[1] (skip first twiddle pair)

_INPUTPARAMSSTORED_Q31:
    mov.l        w1,    w8              ; w8  ---> Pr[0], first bin
    sl.l         w0, #2, w2            ; w2 = 4*N (byte offset to Pr[N])
    add.l        w1, w2, w9            ; w9 ---> Pr[N], last bin

    lsr.l        w2, #4, w6            ; w6 = N/2
    sub.l        w6, #1, w6            ; w6 = BIN_CNTR = (N/2) - 2
                                        ; (loop runs N/2-1 times for bins 1..N/2-1)

; DC and Nyquist Bin
;   Gr[0] = Pr[0] + Pi[0]
;   Gr[N] = Pr[0] - Pi[0]
;   Gi[0] = 0
;   Gi[N] = 0
;
; (No /2 on DC/Nyquist, matching the f32 version which also omits *0.5 here)

    mov.l    [w8], w10                  ; w10 = Pr[0]
    mov.l    [w8+4], w11                ; w11 = Pi[0]

    mov.l    #0, w0                     ; w0 = 0

    lac.l    w10, a                     ; a = Pr[0]
    add.l    w11, a                     ; a = Pr[0] + Pi[0]
    sacr.l   a, [w8++]                  ; Gr[0] = Pr[0] + Pi[0]; w8 -> Pi[0] slot

    lac.l    w10, a                     ; a = Pr[0]
    sub.l    w11, a                     ; a = Pr[0] - Pi[0]
    sacr.l   a, [w9++]                  ; Gr[N] = Pr[0] - Pi[0]; w9 past Gr[N]

    mov.l    w0, [w8++]                 ; Gi[0] = 0; w8 -> Gr[1]
    mov.l    w0, [w9++]                 ; Gi[N] = 0
    sub.l    w9, #16, w9               ; w9 ---> Gr[N-1]; w8 ---> Gr[1]

; Bin 1 to N/2-1, k = 1:(N/2-1)
;
; Equations (matching f32 _FFTReal_SplitFunction_f32):
;
;   Radd = (Pr[k] + Pr[N-k]) / 2
;   Iadd = (Pi[k] + Pi[N-k]) / 2
;   Rsub = (Pr[k] - Pr[N-k]) / 2
;   Isub = (Pi[k] - Pi[N-k]) / 2
;
;   Wi is negated (matching f32: neg.s f11,f11)
;
;   T1 = Iadd*Wr + Rsub*Wi       (with negated Wi)
;   T2 = Iadd*Wi - Rsub*Wr       (with negated Wi)
;
;   Gr(k)   = Radd + T1
;   Gi(k)   = Isub + T2
;   Gr(N-k) = Radd - T1
;   Gi(N-k) = T2 - Isub

BIN_START_Q31:
        ; Load data values for conjugate pair.
        mov.l   [w9++], w10         ; w10 = Pr[N-k]
        mov.l   [w8++], w11         ; w11 = Pr[k]

        mov.l   [w9--], w12         ; w12 = Pi[N-k]
        mov.l   [w8--], w13         ; w13 = Pi[k]

        ; Radd = (Pr[k] + Pr[N-k]) / 2
        lac.l   w10, a
        add.l   w11, a              ; a = Pr[N-k] + Pr[k]
        sacr.l  a, #1, w10          ; w10 = Radd

        ; Iadd = (Pi[k] + Pi[N-k]) / 2
        lac.l   w12, a
        add.l   w13, a              ; a = Pi[N-k] + Pi[k]
        sacr.l  a, #1, w12          ; w12 = Iadd

        ; Load twiddle factors.
        mov.l   [w4++], w14         ; w14 = Wr
        mov.l   [w4++], w7          ; w7 = Wi
        neg.l   w7, w7              ; negate Wi (matching f32: neg.s f11,f11)

        ; Rsub = (Pr[k] - Pr[N-k]) / 2  = Pr[k] - Radd
        ; (Since Radd = (Pr[k]+Pr[N-k])/2, then Pr[k] - Radd = (Pr[k]-Pr[N-k])/2)
        lac.l   w11, a
        sub.l   w10, a              ; a = Pr[k] - Radd = Rsub
        sacr.l  a, w11              ; w11 = Rsub

        ; Isub = (Pi[k] - Pi[N-k]) / 2  = Pi[k] - Iadd
        lac.l   w13, a
        sub.l   w12, a              ; a = Pi[k] - Iadd = Isub
        sacr.l  a, w13              ; w13 = Isub

        ; Now: w10=Radd, w11=Rsub, w12=Iadd, w13=Isub, w14=Wr, w7=Wi(negated)

;MERGE_BFLY
;...........................................................................
; Butterfly computation (matching f32 split):
;   T1 = Iadd*Wr + Rsub*Wi
;   T2 = Iadd*Wi - Rsub*Wr
;
;   Gr(k)   = Radd + T1
;   Gi(k)   = Isub + T2
;   Gr(N-k) = Radd - T1
;   Gi(N-k) = T2 - Isub
;............................................................................

        ; T1 = Iadd*Wr + Rsub*Wi
        mpy.l   w12, w14, a         ; a = Iadd * Wr
        mac.l   w11, w7, a          ; a += Rsub * Wi  => a = T1

        ; T2 = Iadd*Wi - Rsub*Wr
        mpy.l   w12, w7, b          ; b = Iadd * Wi
        msc.l   w11, w14, b         ; b -= Rsub * Wr  => b = T2

        ; Save T1 and T2 to temp registers (w3 and w5 are free).
        sacr.l  a, w3               ; w3 = T1
        sacr.l  b, w5               ; w5 = T2

        sub.l   w9, #8, w9          ; w9 -> Gr[N-k-1] (decrement reverse pointer)

        ; Gr(k) = Radd + T1
        lac.l   w10, a              ; a = Radd
        add.l   w3, a               ; a = Radd + T1
        sacr.l  a, [w8++]           ; Store Gr(k); w8 -> Gi(k)

        ; Gi(k) = Isub + T2
        lac.l   w13, a              ; a = Isub
        add.l   w5, a               ; a = Isub + T2
        sacr.l  a, [w8++]           ; Store Gi(k); w8 -> Gr(k+1)

        ; Gr(N-k) = Radd - T1
        lac.l   w10, a              ; a = Radd
        sub.l   w3, a               ; a = Radd - T1
        sacr.l  a, w0               ; w0 = Gr(N-k) (temp)
        mov.l   w0, [w9 + 8]       ; Store Gr(N-k)

        ; Gi(N-k) = T2 - Isub
        lac.l   w5, a               ; a = T2
        sub.l   w13, a              ; a = T2 - Isub
        sacr.l  a, w0               ; w0 = Gi(N-k) (temp)
        mov.l   w0, [w9 + 12]      ; Store Gi(N-k)

        DTB     w6, BIN_START_Q31

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Handle N/2 bin: negate imaginary part (matching f32: neg.s f0,f0 on Gi[N/2])
        mov.l   [w8+4], w10         ; w10 = Gi[N/2]
        neg.l   w10, w10             ; negate
        mov.l   w10, [w8+4]          ; store back


_DONEREALFFT_Q31:
;............................................................................
; Context Restore
        pop.l    w0                    ; Restore return value

        pop.l   CORCON
        pop.l   w14
        pop.l   w13
        pop.l   w12
        pop.l   w11
        pop.l   w10
        pop.l   w9
        pop.l   w8

;............................................................................
    return



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _IFFTRealSplit_q31: Split function for inverse real FFT (Q31).
;
; Description:
;    Pre-processing split operation for inverse real FFT.
;    Reverses the forward split to reconstruct N/2-point complex data
;    from N-point real FFT output, prior to running the complex IFFT core.
;
;    Mirrors _IFFTReal_SplitFunction_f32 algorithm exactly.
;
; Input:
;    w0 = N (real FFT length)
;    w1 = ptr to source/destination vector (srcV)
;    w2 = ptr to twiddle factors (split twiddle table)
;
; Return:
;    (no explicit return value used by caller)
;
; System resources usage:
;    {w0..w7}    used, not restored
;    {w8..w14}   saved, used, restored
;     AccuA      used, not restored
;     AccuB      used, not restored
;     CORCON     saved, used, restored
;
;............................................................................

    .global _IFFTRealSplit_q31

_IFFTRealSplit_q31:
;............................................................................
; Context Save
        push.l    w8
        push.l    w9
        push.l    w10
        push.l    w11
        push.l    w12
        push.l    w13
        push.l    w14

        push.l    CORCON
        fractsetup w8

; Store Input Parameters
        add.l     w2, #8, w4           ; w4 ---> Wr[1] (skip first twiddle pair)

_INPUTPARAMSSTOREDIFFT_Q31:
        mov.l     w1, w8               ; w8  ---> Pr[0], first bin
        sl.l      w0, #2, w2          ; w2 = 4*N bytes
        add.l     w1, w2, w9          ; w9 ---> Pr[N], last bin

        lsr.l     w2, #4, w6          ; w6 = N/2
        sub.l     w6, #1, w6          ; w6 = BIN_CNTR = (N/2) - 2


; DC and Nyquist Bin (matching f32 IFFT split):
;   Gr[0] = (Pr[0] + Pr[N]) / 2
;   Gi[0] = (Pr[0] - Pr[N]) / 2
;   Gr[N] = 0
;   Gi[N] = 0

        mov.l   [w8], w10              ; w10 = Pr[0]
        mov.l   [w9], w11              ; w11 = Pr[N]

        ; (Pr[0] + Pr[N]) / 2
        lac.l   w10, a
        add.l   w11, a
        sacr.l  a, #1, w12             ; w12 = (Pr[0] + Pr[N]) / 2

        mov.l   #0, w0
        mov.l   w0, [w9++]             ; Gr[N] = 0
        mov.l   w0, [w9++]             ; Gi[N] = 0

        ; (Pr[0] - Pr[N]) / 2 = (Pr[0]+Pr[N])/2 - Pr[N]
        lac.l   w12, a
        sub.l   w11, a                 ; a = (Pr[0]+Pr[N])/2 - Pr[N] = (Pr[0]-Pr[N])/2
        sacr.l  a, w13                 ; w13 = (Pr[0] - Pr[N]) / 2

        mov.l   w12, [w8++]            ; Gr[0] = (Pr[0] + Pr[N]) / 2
        mov.l   w13, [w8++]            ; Gi[0] = (Pr[0] - Pr[N]) / 2

        sub.l   w9, #16, w9           ; w9 ---> Gr[N-1]; w8 ---> Gr[1]


; Bin 1 to N/2-1, k = 1:(N/2-1)
;
; Equations (matching f32 _IFFTReal_SplitFunction_f32):
;
;   Radd = (Pr[k] + Pr[N-k]) / 2
;   Iadd = (Pi[k] + Pi[N-k]) / 2
;   Rsub = (Pr[k] - Pr[N-k]) / 2
;   Isub = (Pi[k] - Pi[N-k]) / 2
;
;   Wi is NOT negated for IFFT (matching f32 where neg.s is commented out)
;
;   T1 = Iadd*Wr + Rsub*Wi
;   T2 = Wr*Rsub - Wi*Iadd
;
;   Gr(k)   = Radd - T1
;   Gi(k)   = Isub + T2
;   Gr(N-k) = Radd + T1
;   Gi(N-k) = T2 - Isub

IFFT_BIN_START_Q31:
        mov.l   [w9++], w10            ; w10 = Pr[N-k]
        mov.l   [w8++], w11            ; w11 = Pr[k]

        mov.l   [w9--], w12            ; w12 = Pi[N-k]
        mov.l   [w8--], w13            ; w13 = Pi[k]

        ; Radd = (Pr[k] + Pr[N-k]) / 2
        lac.l   w11, a
        add.l   w10, a
        sacr.l  a, #1, w10             ; w10 = Radd

        ; Iadd = (Pi[k] + Pi[N-k]) / 2
        lac.l   w13, a
        add.l   w12, a
        sacr.l  a, #1, w12             ; w12 = Iadd

        ; Load twiddle factors (no negation for IFFT).
        mov.l   [w4++], w14            ; w14 = Wr
        mov.l   [w4--], w7             ; w7 = Wi  (read without advancing past)

        ; Rsub = (Pr[k] - Pr[N-k]) / 2 = Pr[k] - Radd
        lac.l   w11, a
        sub.l   w10, a                 ; a = Pr[k] - Radd
        sacr.l  a, w11                 ; w11 = Rsub

        ; Isub = (Pi[k] - Pi[N-k]) / 2 = Pi[k] - Iadd
        lac.l   w13, a
        sub.l   w12, a                 ; a = Pi[k] - Iadd
        sacr.l  a, w13                 ; w13 = Isub

        ; Now: w10=Radd, w11=Rsub, w12=Iadd, w13=Isub, w14=Wr, w7=Wi

;MERGE_BFLY (IFFT)
;...........................................................................
; T1 = Iadd*Wr + Rsub*Wi
; T2 = Wr*Rsub - Wi*Iadd
;............................................................................

        mpy.l   w14, w12, a            ; a = Wr * Iadd
        mac.l   w11, w7, a             ; a += Rsub * Wi  => a = T1

        mpy.l   w14, w11, b            ; b = Wr * Rsub
        msc.l   w7, w12, b             ; b -= Wi * Iadd  => b = T2

        ; Save T1, T2 to temp registers.
        sacr.l  a, w3                  ; w3 = T1
        sacr.l  b, w5                  ; w5 = T2

        sub.l   w9, #8, w9            ; w9 -> Gr[N-k-1]

        ; Gr(k) = Radd - T1
        lac.l   w10, a
        sub.l   w3, a
        sacr.l  a, [w8++]              ; Store Gr(k)

        ; Gi(k) = Isub + T2
        lac.l   w13, a
        add.l   w5, a
        sacr.l  a, [w8++]              ; Store Gi(k)

        ; Gr(N-k) = Radd + T1
        lac.l   w10, a
        add.l   w3, a
        sacr.l  a, w0                  ; w0 = Gr(N-k) (temp)
        mov.l   w0, [w9+8]            ; Store Gr(N-k)

        ; Gi(N-k) = T2 - Isub
        lac.l   w5, a
        sub.l   w13, a
        sacr.l  a, w0                  ; w0 = Gi(N-k) (temp)
        mov.l   w0, [w9+12]           ; Store Gi(N-k)

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        add.l       w4, #8, w4        ; Next Twiddle Factor (advance past Wi to next Wr)
        dtb         w6, IFFT_BIN_START_Q31


        ; Negate Pi(N/2) — matching f32
        mov.l      [w8+4], w10         ; w10 = Pi(N/2)
        neg.l      w10, w10
        mov.l      w10, [w8+4]         ; Store negated value


_DONEREALIFFT_Q31:
;............................................................................
; Context Restore

        pop.l    CORCON
        pop.l    w14
        pop.l    w13
        pop.l    w12
        pop.l    w11
        pop.l    w10
        pop.l    w9
        pop.l    w8
;............................................................................
        RETURN



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _FFTComplex2IP_q31: Wrapper that calls the core complex FFT (with 2*N
;    twiddle factors) then performs bit-reversal reordering.
;
;    Mirrors _FFTComplex2IP_f32 exactly.
;
; Input:
;    w0 = N/2 (number of complex points)
;    w1 = ptr to complex data (in-place)
;    w2 = ptr to twiddle factors
;    w3 = ifftFlag (0 = forward, nonzero = inverse)
;
; Return:
;    w0 = ptr to output vector
;
;............................................................................

    .extern _mchp_bitreversal_q31

    .global _FFTComplex2IP_q31

_FFTComplex2IP_q31:

    ; Call core FFT (no bit-reversal).
    ; w3 = ifftFlag is passed through to the core.
    push.l    w0                ; save N/2 (complex FFT length)
    push.l    w1                ; save pointer to srcCV
    call _FFTComplexIP2_noBitRev_q31
    pop.l    w0                ; restore pointer to srcCV
    pop.l    w1                ; restore N/2 (fftLen for bitreversal)

    ; Unscramble results back to natural order.
    ; w0 = pSrc, w1 = fftLen = N/2 (complex points).
    call _mchp_bitreversal_q31

    return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_rfft_q31: Compute the real FFT or inverse real FFT (Q31).
;
; Operation:
;    Performs a real FFT transform on Q31 data.
;    The transform direction (forward/inverse) is determined by the
;    ifftFlagR field stored in the instance structure during initialization.
;
;    If ifftFlagR = 0:
;        Compute RFFT  (forward real FFT)
;    If ifftFlagR = 1:
;        Compute IRFFT (inverse real FFT)
;
;    Forward path:
;      1. Copy input to output buffer.
;      2. Run N/2-point complex FFT + bit reversal (_FFTComplex2IP_q31).
;      3. Apply forward real FFT split (_FFTRealSplit_q31).
;
;    Inverse path:
;      1. Copy input to output buffer.
;      2. Apply inverse real FFT split (_IFFTRealSplit_q31).
;      3. Run N/2-point complex FFT + bit reversal (_FFTComplex2IP_q31).
;      (FFT core applies implicit 1/(N/2) scaling via 1/2 per stage.)
;
;    ARM-compatible 3-parameter signature.
;
; Input (dsPIC33AK calling convention, 32-bit params in sequential registers):
;    W0 = pointer to mchp_rfft_instance_q31 S
;         Structure layout (ARM-compatible):
;           [w0 +  0] = fftLenRFFT   (uint32_t, N)
;           [w0 +  4] = ifftFlagR    (uint32_t, 0=fwd, 1=inv)
;           [w0 +  8] = pCfft        (mchp_cfft_instance_q31 *)
;           [w0 + 12] = pTwiddle     (const q31_t *)
;           [w0 + 16] = pTwiddleRFFT (const q31_t *)
;    W1 = pointer to input vector pSrc
;    W2 = pointer to output vector pDst
;
; Return:
;    none (void)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.global    _FFTRealIP_q31
.global    _mchp_rfft_q31

_mchp_rfft_q31:

    ; ---------------------------------------------------------
    ; Save inputs for copy operation
    ; ---------------------------------------------------------
    push.l     w0                 ; Sint (instance pointer)
    push.l     w2                 ; pDst

    mov.l   [w0], w6              ; w6 = fftLenRFFT = N
    sl.l    w6, #1, w6            ; w6 = 2 * N (number of Q31 words to copy)

    mov.l   w1, w0                ; w0 = pSrc
    mov.l   w2, w1                ; w1 = pDst
    mov.l   w6, w2                ; w2 = blockSize = 2*N

    call    _mchp_copy_q31        ; Copy pSrc -> pDst

    ; ---------------------------------------------------------
    ; Restore parameters
    ; ---------------------------------------------------------
    pop.l    w1                   ; pDst (now also the working buffer)
    pop.l    w0                   ; Sint (instance pointer)

    ; ---------------------------------------------------------
    ; Setup CORCON for fractional mode
    ; ---------------------------------------------------------
    push.l   CORCON
    fractsetup w4

    ; Save return pointer (pDst)
    push.l   w1

    ; ---------------------------------------------------------
    ; Load instance parameters (ARM-compatible struct layout)
    ;   [w0 +  0] = fftLenRFFT = N
    ;   [w0 +  4] = ifftFlagR
    ;   [w0 + 12] = pTwiddle
    ; ---------------------------------------------------------
    mov.l   [w0+#0], w4           ; w4 = fftLenRFFT = N
    mov.l   [w0+#4], w3           ; w3 = ifftFlagR (from struct)
    mov.l   [w0+#12], w5          ; w5 = pTwiddle

    ; ---------------------------------------------------------
    ; Branch: ifftFlagR == 0 ? forward
    ; ---------------------------------------------------------
    cp      w3, #0
    bra     Z, _forward_path_rq31

; -------------------------------------------------------------
;                        INVERSE PATH
; -------------------------------------------------------------
_inverse_path_rq31:

    mov.l   w5, w2                ; w2 = pTwiddle
    mov.l   w4, w0                ; w0 = N (for split function)

    ; Save parameters for after IFFT split
    push.l  w4                    ; N
    push.l  w5                    ; pTwiddle
    push.l  w1                    ; data pointer

    call    _IFFTRealSplit_q31

    pop.l   w1                    ; data pointer
    pop.l   w5                    ; pTwiddle
    pop.l   w4                    ; N

    ; Compute N/2 for complex FFT core.
    lsr.l   w4, w0                ; w0 = N/2
    mov.l   w5, w2                ; w2 = pTwiddle
    mov.l   #1, w3                ; w3 = ifftFlag = 1 (inverse FFT)

    ; Save data pointer for after FFT.
    push.l  w1                    ; data pointer

    ; Call N/2-point complex FFT + bit reversal.
    call    _FFTComplex2IP_q31

    ; The DIF FFT core already applies 1/2 per stage, giving implicit
    ; 1/(N/2) scaling. For Q31 RFFT this is the desired behavior —
    ; no additional scaling call is needed (unlike f32 which uses
    ; explicit floating-point division).

    pop.l   w1                    ; discard saved data pointer

    pop.l   w1                    ; restore pDst
    pop.l   CORCON

    bra     finish_rq31

; -------------------------------------------------------------
;                        FORWARD PATH
; -------------------------------------------------------------
_forward_path_rq31:

    mov.l   w5, w2                ; pTwiddle

    ; Compute N/2 for complex FFT core.
    lsr.l   w4, w0                ; w0 = N/2
    mov.l   #0, w3                ; w3 = ifftFlag = 0 (forward FFT)

    ; Save parameters for after FFT.
    push.l  w4                    ; N
    push.l  w5                    ; pTwiddle
    push.l  w1                    ; data pointer

    ; Call N/2-point complex FFT + bit reversal.
    call    _FFTComplex2IP_q31

    pop.l   w1                    ; data pointer
    pop.l   w2                    ; pTwiddle (used by split function)
    pop.l   w0                    ; N

    ; Apply forward real FFT split.
    call    _FFTRealSplit_q31

    pop.l   w2                    ; restore pDst (discard)
    pop.l   CORCON

finish_rq31:
    return
    .end
