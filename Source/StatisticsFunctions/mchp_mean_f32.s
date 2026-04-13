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
; _mchp_mean_f32: Single precision floating point Vector Mean function
;                 Computes the arithmetic mean of a float32 vector.
;
; Operation:
;   - Scans the input vector pSrc of length blockSize.
;   - Computes the sum of all elements.
;   - Divides the sum by blockSize to obtain the mean value.
;   - Stores the mean value in *pResult.
;
; Inputs:
;   w0 = pSrc      ; pointer to source vector
;   w1 = blockSize ; number of elements in vector
;   w2 = pResult   ; pointer to result (mean value)
;
; Outputs:
;   f0 = meanVal   ; mean value found
;   [w2] = meanVal ; stored at *pResult
;
; System resources usage:
;   {w0..w2}    used, not restored
;   {f0..f2}    used, not restored
;............................................................................

    .global    _mchp_mean_f32    ; export
_mchp_mean_f32:
;...........................................................................
    ; Save the status of FCR
    push.l fcr
    floatsetup w3               ; Setup FCR to default rounding, mask all exceptions.
;...........................................................................

    mov.l  w1, f0              ; f0 = int(N)
    li2f.s f0, f2              ; f2 = len(srcV)
;............................................................................
    movc.s #22, f0             ; f0 = 0
_sum:
    mov.l [w0++], f1           ; f1 = srcV[n]
    add.s f0, f1, f0           ; f0 += f1
    DTB   w1, _sum
;............................................................................
    div.s    f0, f2, f0        ; f0 = return value
;............................................................................

;...........................................................................
    mov.l  f0, [w2]
    ; Restore fcr
    pop.l fcr
;...........................................................................

    return    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OEF
