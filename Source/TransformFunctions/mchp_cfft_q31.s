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
;    FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIPS         	 *
;    TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT          *
;    EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR       *
;   THIS SOFTWARE.                                                           *
;*****************************************************************************

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Local inclusions.

    .nolist
    .include    "dspcommon.inc"      ; fractsetup macro
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .cmsisdspmchp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_cfft_q31: Fixed-point (Q31) Complex DIF FFT (in-place).
;
; Description:
;    Performs an in-place radix-2 Decimation-In-Frequency complex FFT on
;    Q31 data. The input is expected in natural order; the output is
;    produced in bit-reversed order.
;
;    An implicit scaling of 1/2 is applied at every stage to prevent
;    overflow in fractional mode, so the final output is scaled by 1/N.
;
;    The implementation mirrors the structure of mchp_cfft_f32.s, replacing
;    all FPU (float) operations with DSP engine fractional operations
;    (lac.l / add.l / sub.l / mpy.l / mac.l / msc.l / sac.l / sacr.l)
;    taken from the original fft_aa.s DIF butterfly.
;
; Operation:
;    dstV[n] = FFTComplex(srcV[n]), 0 <= n < N
;
; Input:
;    w0 = ptr to mchp_cfft_instance_q31 structure
;    w1 = ptr to source/destination complex vector (in-place)
;    w2 = ifft flag (0 = forward FFT, nonzero = inverse FFT)
;    w3 = bit reverse flag (0 = no bit reversal, nonzero = apply bit reversal)
;
; Return:
;    None
;
; System resources usage:
;    {w0..w7}    used, not restored
;    {w8..w14}   saved, used, restored
;     AccuA      used, not restored
;     AccuB      used, not restored
;     CORCON     saved, used, restored
;
; Notes:
;    - Input data magnitude of real and imaginary parts must be < 0.5
;      to prevent saturation.
;    - Output is in bit-reversed order; use bit-reverse copy if natural
;      order is required.
;
;............................................................................

    .extern    _mchp_scale_q31
    .extern    _mchp_bitreversal_q31
    .global    _mchp_cfft_q31                    ; export
    .global    _FFTComplexIP_noBitRev_q31        ; export (core, no bit-reversal)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _mchp_cfft_q31: Top-level entry point.
;   Handles forward / inverse branching, then calls the core FFT.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_mchp_cfft_q31:

;............................................................................
; Extract instance structure fields.
;   Assumed layout of mchp_cfft_instance_q31:
;     [w0 + 0]  = fftLen (N)
;     [w0 + 4]  = ptr to twiddle factor table (pTwiddle)
;............................................................................

    mov.l      [w0 + 0], w4          ; w4 = fftLen = N.
    mov.l      [w0 + 4], w5          ; w5 = pTwiddle.

;............................................................................
; Branch on IFFT flag.
;............................................................................

    cp0.l      w2                     ; ifftFlag == 0 ? (32-bit compare)
    bra        z, _forward_path_q31   ; Yes => forward FFT.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inverse FFT path.
;   1. Call core FFT (no bit-reversal).
;   2. Scale output by 1/N.
;   3. Optionally apply bit-reversal.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_inverse_path_q31:

    ; Compute log2(N).
    mov.l      w4, w0                ; w0 = N.
    mov.l      #0, w6                ; w6 = log2 counter.
    mov.l      w0, w7                ; w7 = N (temp).
_log2_inv_q31:
    lsr.l      w7, w7                ; w7 >>= 1.
    cp0.l      w7
    bra        z, _log2_inv_done_q31
    add.l      #1, w6
    bra        _log2_inv_q31
_log2_inv_done_q31:
    mov.l      w6, w0                ; w0 = log2(N).

    ; Save context for scaling after FFT.
    push.l     w3                     ; Save bitRev flag.
    push.l     w4                     ; Save N.
    push.l     w1                     ; Save data pointer.

    ; Setup parameters for core FFT.
    mov.l      w2, w3                ; w3 = ifftFlag (nonzero = inverse).
    mov.l      w5, w2                ; w2 = pTwiddle.
                                      ; w0 = log2(N).
                                      ; w1 = data pointer.
                                      ; w3 = ifftFlag.

    ; Call core FFT (no bit-reversal).
    call       _FFTComplexIP_noBitRev_q31

    ; Restore context.
    pop.l      w1                     ; w1 = data pointer (FFT output).
    pop.l      w4                     ; w4 = N.
    pop.l      w3                     ; w3 = bitRev flag.

    ; Scale output by 1/N.
    ; For Q31 in-place: each element is right-shifted by log2(N) bits,
    ; which was already done implicitly (1/2 per stage). If additional
    ; scaling is needed, call _mchp_scale_q31.
    ;
    ; Note: If implicit 1/2 per stage already provides 1/N scaling,
    ; this call can be omitted. Included for completeness.
    ; To enable scaling, uncomment the block below and save/restore w3
    ; (bitRev flag) around it:
    ;   push.l     w3                   ; save bitRev flag
    ;   mov.l      w1, w0              ; w0 = pSrc
    ;   mov.l      w1, w2              ; w2 = pDst (in-place)
    ;   sl.l       w4, #1, w3          ; w3 = blockSize = 2*N
    ;   call       _mchp_scale_q31
    ;   pop.l      w3                   ; restore bitRev flag

    bra        _cfft_done_q31

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Forward FFT path.
;   1. Call core FFT (no bit-reversal).
;   2. Optionally apply bit-reversal.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_forward_path_q31:

    ; Compute log2(N).
    mov.l      w4, w0                ; w0 = N.
    mov.l      #0, w6                ; w6 = log2 counter.
    mov.l      w0, w7                ; w7 = N (temp).
_log2_fwd_q31:
    lsr.l      w7, w7                ; w7 >>= 1.
    cp0.l      w7
    bra        z, _log2_fwd_done_q31
    add.l      #1, w6
    bra        _log2_fwd_q31
_log2_fwd_done_q31:
    mov.l      w6, w0                ; w0 = log2(N).

    ; Save bitRev flag and data pointer.
    push.l     w3                     ; Save bitRev flag.
    push.l     w1                     ; Save data pointer.
    push.l     w4                     ; Save N.

    ; Setup parameters for core FFT.
    mov.l      #0, w3                ; w3 = ifftFlag = 0 (forward FFT).
    mov.l      w5, w2                ; w2 = pTwiddle.
                                      ; w0 = log2(N).
                                      ; w1 = data pointer.
                                      ; w3 = ifftFlag.

    ; Call core FFT (no bit-reversal).
    call       _FFTComplexIP_noBitRev_q31

    ; Restore context.
    pop.l      w4                     ; w4 = N.
    pop.l      w1                     ; w1 = data pointer.
    pop.l      w3                     ; w3 = bitRev flag.

;............................................................................
; Common exit (forward and inverse).
;............................................................................

_cfft_done_q31:

    ; Optional bit-reversal.
    ;   At this point:
    ;     w0 = return value from FFT core (ptr to output = pSrc)
    ;     w1 = data pointer (pSrc, restored from stack)
    ;     w3 = bitRev flag (restored from stack)
    ;     w4 = N (fftLen, restored from stack)
    ;
    ;   _mchp_bitreversal_q31 expects: w0 = pSrc, w1 = fftLen (N).

    cp0.l      w3                     ; bitReverseFlag == 0?
    bra        z, _cfft_skip_bitrev   ; Yes => skip bit-reversal.

    ; Setup registers for _mchp_bitreversal_q31 (SW implementation).
    mov.l      w1, w0                 ; w0 = pSrc (data pointer).
    mov.l      w4, w1                 ; w1 = fftLen = N.

    call       _mchp_bitreversal_q31

_cfft_skip_bitrev:

    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; _FFTComplexIP_noBitRev_q31: Core in-place radix-2 DIF FFT (Q31).
;
; Description:
;    Performs log2(N) stages of radix-2 DIF butterflies using the DSP
;    engine accumulators. Each butterfly computes:
;
;        upper_re = (Ar + Br) / 2
;        upper_im = (Ai + Bi) / 2
;        temp_re  = (Ar - Br) / 2
;        temp_im  = (Ai - Bi) / 2
;        lower_re = temp_re * Wr - temp_im * Wi
;        lower_im = temp_re * Wi + temp_im * Wr
;
;    The 1/2 scaling per stage prevents overflow and results in a total
;    output scaling of 1/N.
;
;    Input is in natural order; output is in bit-reversed order.
;
; Input:
;    w0 = log2(N)
;    w1 = ptr to complex data vector (in-place, interleaved Re/Im Q31)
;    w2 = ptr to twiddle factor table (complex Q31, interleaved Re/Im)
;    w3 = ifftFlag (0 = forward FFT, nonzero = inverse FFT)
;
; Return:
;    w0 = ptr to output vector (same as input, in-place)
;
; System resources usage:
;    {w0..w7}    used, not restored
;    {w8..w14}   saved, used, restored
;     AccuA      used, not restored
;     AccuB      used, not restored
;     CORCON     saved, used, restored
;
;............................................................................

_FFTComplexIP_noBitRev_q31:

;............................................................................
; Save working registers.
;............................................................................

    push.l     w8                     ; Save w8.
    push.l     w9                     ; Save w9.
    push.l     w10                    ; Save w10.
    push.l     w11                    ; Save w11.
    push.l     w12                    ; Save w12.
    push.l     w13                    ; Save w13.
    push.l     w14                    ; Save w14.

;............................................................................
; Prepare CORCON for fractional computation.
;............................................................................

    push.l     CORCON                 ; Save 32-bit CORCON.
    MOV.l      #0xF0, w7             ; Fractional mode, saturation enabled,
    MOV.l      w7, CORCON            ; super-saturation, convergent rounding.

;............................................................................
; Save return value.
;............................................................................

    push.l     w1                     ; Save srcCV / dstCV pointer for return.
    push.l     w3                     ; Save ifftFlag for use inside butterfly.

;............................................................................
; FFT initialization.
;   w0 = log2(N) (also used as stage counter)
;   w1 = ptr to complex data
;   w2 = ptr to twiddle factors
;   w3 = twiddle offset / number of butterflies per group (starts at 1)
;   w8 = twiddle factor base pointer (rewound each butterfly set)
;   w9 = N (total complex points, computed from log2N)
;   [w15-4] = ifftFlag (saved on stack for butterfly Wi negation)
;............................................................................

    mov.l      #0x1, w9              ; w9 = 1 (to be shifted to compute N).
    sl.l       w9, w0, w9            ; w9 = N = (1 << log2N).
    mov.l      #0x1, w3              ; Initialize butterflies per group = 1.
    mov.l      w2, w8                ; w8 -> WN(0) (twiddle factor base).

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Stage loop: perform all log2(N) stages.
;
;   For stage k (k = 1 to log2N):
;     - Number of butterfly groups = N / (2^k)          => w9
;     - Number of butterflies per group = 2^(k-1)       => w3
;     - Twiddle stride = butterflies * 8 bytes           => w7
;     - Upper-to-lower offset = groups * 8 bytes         => w12
;
;   For the first stage: 1 butterfly per group, N/2 groups.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_doStage_q31:

    ; Update group counter: halve the number of groups.
    lsr.l      w9, w9                ; w9 = N / (2^k) (number of groups).

    ; Compute upper-to-lower leg offset in bytes.
    ; Each complex element = 2 x 4 bytes = 8 bytes.
    sl.l       w9, #3, w12           ; w12 = groups * 8 = offset to lower leg.

    ; Initialize data pointer for this stage.
    mov.l      w1, w10               ; w10 -> data[0] (upper leg base).

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Butterfly set loop (OUTER): iterate over butterflies per group.
;   Matches F32 structure: outer loop over butterfly indices, inner loop
;   over groups. Each butterfly index uses one twiddle factor across all
;   groups; twiddle advances between groups within the inner loop.
;
;   w6  = butterfly index counter (outer, counts down from w3).
;   w10 = upper leg base pointer (advances between butterfly indices).
;   w8  = twiddle pointer (rewound after each inner loop pass).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    mov.l      w3, w6                ; w6 = butterflies per group (outer counter).

_doBflySet_q31:

    ; Compute lower leg pointer from upper leg pointer + offset.
    add.l      w10, w12, w11         ; w11 = w10 + offset -> lower leg.

    ; Prepare twiddle stride for this stage.
    sl.l       w3, #3, w7            ; w7 = oTwidd * sizeof(fractcomplex) = w3*8.

    ; Setup inner loop counter: number of groups.
    mov.l      w9, w5                ; w5 = nGrps (inner loop counter).

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Group loop (INNER): perform one butterfly per group at the current
; butterfly index, advancing the twiddle between groups.
;
;   DIF butterfly (Q31 fractional with 1/2 scaling):
;   Follows the reference fft_aa.s butterfly structure exactly —
;   compute lower leg first (in-accumulator, no intermediate extraction),
;   then compute upper leg.
;
;     Lower output:  Dr = ((Ar-Br)*Wr - (Ai-Bi)*Wi) / 2
;                    Di = ((Ar-Br)*Wi + (Ai-Bi)*Wr) / 2
;     Upper output:  Cr = (Ar + Br) / 2
;                    Ci = (Ai + Bi) / 2
;
;   Register usage within butterfly:
;     w10 = upper leg pointer (post-incremented after upper stores)
;     w11 = lower leg pointer (post-incremented after lower stores)
;     w8  = twiddle pointer (advanced by twiddle stride per group)
;     w4  = (Ar - Br), then (Ai - Bi) — full difference, not halved
;     w13 = Br (saved for upper sum)
;     w14 = Bi (saved for upper sum)
;     w7  = twiddle stride (precomputed, reused across groups)
;     AccuA = Dr computation, then Ar
;     AccuB = Di computation, then Ai
;
;   Strategy (matches fft_aa.s):
;     1. Load Br, compute Ar-Br, multiply by twiddle for Dr/Di
;     2. Load Bi, compute Ai-Bi, accumulate into Dr/Di
;     3. Store lower leg (Dr/2, Di/2)
;     4. Load Ar/Ai (still original), add Br/Bi, store upper leg
;
;   w6, w9 are NOT used inside this inner loop.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_doBfly_q31:

    ;--------------------------------------------------------------------
    ; DIF butterfly (Q31 fractional with 1/2 scaling).
    ;
    ; Compute lower leg first (in-accumulator), then upper leg.
    ;
    ; For forward FFT (ifftFlag==0): twiddle is W = cos - j*sin,
    ;   so Wi from table (which is +sin) must be negated.
    ; For inverse FFT (ifftFlag!=0): twiddle is W = cos + j*sin,
    ;   Wi used as-is from table.
    ;
    ; Register map inside butterfly:
    ;   w4  = Ar-Br, then Ai-Bi (full difference, no halving)
    ;   w9  = temp: Wi (conditionally negated), then restored
    ;   w13 = Br (preserved for upper sum)
    ;   w14 = Bi (preserved for upper sum)
    ;   w8  = twiddle pointer (Wr, Wi pairs), advanced after use
    ;   w7  = twiddle stride (precomputed, NOT clobbered in butterfly)
    ;   AccA = Dr computation, then Ar+Br
    ;   AccB = Di computation, then Ai+Bi
    ;--------------------------------------------------------------------

    ;--- Load Br, compute Ar-Br ---

    mov.l      [w11++], w13          ; w13 = Br.                [w11]->Bi
    subr.l     w13, [w10++], w4      ; w4  = Ar - Br.           [w10]->Ai

    ;--- Load twiddle factor Wi ---
    ;    Q31 twiddle table stores cos + j*sin. Unlike the F32 table
    ;    (which stores cos - j*sin), no sign adjustment is needed —
    ;    the DIF butterfly math uses Wi directly for both directions.

    mov.l      [w8+#4], w9           ; w9  = Wi (from table).

    ;--- Start twiddle multiply with Wr and Wi' ---

    mpy.l      [w8], w4, a           ; a   = (Ar-Br)*Wr.       [w8] still ->Wr
    mpy.l      w9, w4, b             ; b   = (Ar-Br)*Wi'.

    ;--- Load Bi, compute Ai-Bi, finish Dr/Di ---

    mov.l      [w11--], w14          ; w14 = Bi.                [w11]->Br
    subr.l     w14, [w10--], w4      ; w4  = Ai - Bi.           [w10]->Ar

    msc.l      w9, w4, a             ; a  -= (Ai-Bi)*Wi' => Dr.
    mac.l      [w8], w4, b           ; b  += (Ai-Bi)*Wr  => Di. [w8] still ->Wr

    ;--- Store lower leg (with 1/2 scaling) ---

    sacr.l     a, #1, [w11++]        ; Store 1/2*Dr (overwrite Br). [w11]->Bi
    sacr.l     b, #1, [w11++]        ; Store 1/2*Di (overwrite Bi). [w11]->next

    ;--- Advance twiddle for next group ---
    ;    w8 still points to Wr of current twiddle pair.
    ;    Advance by stride (w7 = butterfliesPerGroup * 8 bytes).

    add.l      w8, w7, w8            ; w8 -> next group's twiddle Wr.

    ;--- Compute and store upper leg (sums with 1/2 scaling) ---
    ; w13 = Br (saved), w14 = Bi (saved), original Ar/Ai still at [w10].

    lac.l      [w10++], a            ; a  = Ar.                  [w10]->Ai
    lac.l      [w10--], b            ; b  = Ai.                  [w10]->Ar

    add.l      w13, a                ; a  = Ar + Br.
    add.l      w14, b                ; b  = Ai + Bi.

    sacr.l     a, #1, [w10++]        ; Store (Ar+Br)/2.          [w10]->Ai
    sacr.l     b, #1, [w10++]        ; Store (Ai+Bi)/2.          [w10]->next

    DTB        w5, _doBfly_q31       ; Decrement group counter (w5);
                                      ; branch to _doBfly_q31 if not zero.

; } end group loop.

;............................................................................
; Advance to next butterfly index.
;   Upper pointer (w10) has advanced past all upper legs for the current
;   butterfly index. Skip past the lower leg region.
;   Restore w9 (group count) from w12: w9 = w12 / 8.
;............................................................................

    lsr.l      w12, #3, w9           ; w9 = groups (recover from w12=groups*8).

    add.l      w12, w10, w10         ; w10 -> skip lower leg region.

    ; Rewind twiddle pointer for next butterfly index.
    mov.l      w2, w8                ; Restore twiddle base pointer.

    DTB        w6, _doBflySet_q31    ; Decrement butterfly counter (w6);
                                      ; branch to _doBflySet_q31 if not zero.

; } end butterfly set loop.

;............................................................................
; Prepare for next stage.
;............................................................................

    ; Double the number of butterflies per group for next stage.
    sl.l       w3, w3                ; w3 *= 2 (butterflies per group doubles).

    ; Check if more stages remain.
    dtb        w0, _doStage_q31      ; Decrement stage counter (w0 = log2N);
                                      ; branch to _doStage_q31 if not zero.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; FFT core completed.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_completedFFT_q31:

    ; Discard saved ifftFlag from stack.
    pop.l      w0                     ; Discard ifftFlag (was pushed after retval).

    ; Restore return value.
    pop.l      w0                     ; w0 = ptr to output vector (srcCV / dstCV).

;............................................................................
; Restore CORCON and working registers.
;............................................................................

    pop.l      CORCON                 ; Restore 32-bit CORCON.
    pop.l      w14                    ; Restore w14.
    pop.l      w13                    ; Restore w13.
    pop.l      w12                    ; Restore w12.
    pop.l      w11                    ; Restore w11.
    pop.l      w10                    ; Restore w10.
    pop.l      w9                     ; Restore w9.
    pop.l      w8                     ; Restore w8.

    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EOF