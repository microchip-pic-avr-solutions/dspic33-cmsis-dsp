;*****************************************************************************
;                       Software License Agreement                           *
;*****************************************************************************
;© [2026] Microchip Technology Inc. and its subsidiaries.                    *
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
;    FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S          *
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
; mchp_power_f32: Vector Power.
;
; Operation:
;    powVal = sum (pSrc[n] * pSrc[n]), with
;    n in {0, 1,... , blockSize-1}
;
; Input:
;    w0 = ptr to source vector (pSrc)
;    w1 = number elements in vector(s) (blockSize)
;    w2 = ptr to result (pResult)
; Output:
;    *pResult = power value (powVal)
;
; System resources usage:
;    {w0..w2}    used, not restored
;    {f0, f1}    used, not restored
;     FCR        saved, used, restored
;............................................................................

    .global    _mchp_power_f32    ; export
_mchp_power_f32:
    movc.s  #22,  f0         ; f0 = 0.0
    mov.l   [w0], f1         ; f1 = pSrc[0]

    ; Mask all FPU exceptions, set rounding mode to default and clear SAZ/FTZ
    push.l    FCR
    floatsetup    w3         ; w3 can be used as scratch if needed

;............................................................................

    cp0.l   w1
    bra     nz, check_one

    mov.l   #0, [w2]                ; *pResult = 0
    clr.l   [w3]                    ; *pIndex  = 0
    pop.l   FCR
    return

check_one:
    cp.l    w1, #1
    bra     nz, v_pow_start

    mov.l   [w0], f0                ; f0 = src[0]
    mov.l   f0, [w2]
    clr.l   [w3]
    pop.l   FCR
    return

v_pow_start:
    mac.s  f1, f1, f0          ; f0 += pSrc[n]*pSrc[n]
    mov.l  [++w0], f1          ; f1 = pSrc[n+1]
    dtb    w1, v_pow_start
;............................................................................

    ; Store result to *pResult
    mov.l   f0, [w2]           ; *pResult = f0

    ; restore FCR.
    pop.l    FCR

    return    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OEF
