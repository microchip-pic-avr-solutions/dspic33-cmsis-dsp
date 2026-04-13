;*****************************************************************************
;                                                                            *
;                       Software License Agreement                           *
;*****************************************************************************
;*****************************************************************************
; © [2026] Microchip Technology Inc. and its subsidiaries.                   *
;                                                                            *
;   Subject to your compliance with these terms, you may use Microchip       *
;   software and any derivatives exclusively with Microchip products.        *
;   You are responsible for complying with 3rd party license terms           *
;   applicable to your use of 3rd party software (including open source      *
;   software) that may accompany Microchip software. SOFTWARE IS "AS IS."    *
;   NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS      *
;   SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,          *
;   MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT        *
;   WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,            *
;   INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY         *
;   KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF         *
;   MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE         *
;   FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIP’S           *
;   TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT           *
;   EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR        *
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
; _TwidFactorInit_f32: Floating-point FFT twiddle factor initialization.
;
; Operation:
;    Generates the first half of the complex twiddle factor set required
;    for an N-point radix-2 FFT:
;
;        WN(k) = cos(2*pi*k/N) - j*sin(2*pi*k/N)
;
;    for k = 0 .. (N/2 - 1)
;
;    The twiddle factors are stored sequentially in memory as:
;
;        [ real0, imag0, real1, imag1, ... ]
;
;    The imaginary component is negated to produce the conjugate form
;    required by CMSIS-style decimation-in-time FFT implementations.
;
; Input:
;    w0 = FFT length (N)
;    w1 = pointer to destination twiddle factor buffer
;
; Output:
;    Twiddle factor table written to memory at address w1
;
; Return:
;    no return value
;
; System resources usage:
;    {w0..w4}    used, w0 restored
;    {f0..f6}    used, not restored
;     FCR        saved, used, restored
;
; Notes:
;    - N must be a power of two.
;    - Only N/2 twiddle factors are generated.
;    - Uses floating-point trigonometric instructions (sin, cos).
;    - The destination buffer must be 4-byte aligned.
;    - Intended for use with floating-point radix-2 FFT routines.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   .global _TwidFactorInit_f32   

_TwidFactorInit_f32:

    ;---------------------------------------------------------------------
    ; Prologue: save working registers and configure floating-point unit
    ;---------------------------------------------------------------------
    push.l w1                     ; Preserve pointer register
    push.l FCR                    ; Save Floating-Point Control Register
    floatsetup w4                 ; Configure FPU: default rounding, mask exceptions

    ;---------------------------------------------------------------------
    ; Load FFT length
    ;---------------------------------------------------------------------
    mov.l w0, w3                  ; w3 = N (FFT size)

    ;---------------------------------------------------------------------
    ; Compute angle increment: 2*pi / N
    ;---------------------------------------------------------------------
    mov.l w3, f1                  ; Convert N to float
    li2f.s f1, f0                 ; f0 = (float)N
    movc.s #3, f1                 ; f1 = constant 2*pi
    div.s  f1, f0, f2             ; f2 = 2*pi/N

    ;---------------------------------------------------------------------
    ; Initialize loop constants
    ;---------------------------------------------------------------------
    movc.s  #1, f0                ; f0 = 1.0 (loop increment)
    movc.s  #1, f5                ; f5 = 1.0 (conjugate multiplier)
    mov.l   #0, f1                ; f1 = 0.0 (k index)

    ;---------------------------------------------------------------------
    ; Loop count = N/2 twiddle factors
    ;---------------------------------------------------------------------
    asr.l   w3, #1, w3            ; w3 = N / 2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
twid_start:

    ;---------------------------------------------------------------------
    ; Compute angle = k * (2*pi/N)
    ;---------------------------------------------------------------------
    mul.s f1, f2, f4              ; f4 = k * 2*pi/N

    ;---------------------------------------------------------------------
    ; Compute cosine component
    ;---------------------------------------------------------------------
    cos.s f4, f6                  ; f6 = cos(angle)
    mov.l f6, [w1++]              ; Store real part

    ;---------------------------------------------------------------------
    ; Compute sine component
    ;---------------------------------------------------------------------
    sin.s f4, f6                  ; f6 = sin(angle)
    mul.s f5, f6, f6              ; Apply conjugation if required
    mov.l f6, [w1++]              ; Store imaginary part

    ;---------------------------------------------------------------------
    ; Increment k and loop
    ;---------------------------------------------------------------------
    add.s f0, f1, f1              ; k = k + 1
    dtb w3, twid_start            ; Loop until w3 == 0

    ;---------------------------------------------------------------------
    ; Epilogue: restore registers and return
    ;---------------------------------------------------------------------
    pop.l FCR                    ; Restore FP control register
    pop.l w0                     ; Restore saved register
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OEF
