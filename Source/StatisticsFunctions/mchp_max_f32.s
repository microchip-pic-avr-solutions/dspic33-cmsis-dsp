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
    .include    "dspcommon.inc"        ; floatsetup
    .list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .section .dspic33cmsisdsp, code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; _mchp_max_f32: Single precision floating point VectorMax function
;                Finds the maximum value in a float32 vector and its last index.
;
; Operation:
;   - Scans the input vector pSrc of length blockSize.
;   - Determines the maximum value (maxVal) among all elements.
;   - If multiple elements have the same maximum value, stores the last index (highest index) where maxVal occurs in *pIndex.
;   - Stores the maximum value in *pResult.
;
; Inputs:
;   w0 = pSrc      ; pointer to source vector
;   w1 = blockSize ; number of elements in vector
;   w2 = pResult   ; pointer to result (max value)
;   w3 = pIndex    ; pointer to index of max value
;
; Outputs:
;   f0 = maxVal    ; maximum value found
;   [w2] = maxVal  ; stored at *pResult
;   [w3] = index   ; last index of maxVal stored at *pIndex
;
; System resources usage:
;   {w0..w6}    used, not restored
;   {f0, f1}    used, not restored
;
;............................................................................

    .global    _mchp_max_f32    ; export
_mchp_max_f32:
;.............................................................................
    push.l FCR
    floatsetup w5
;.............................................................................

    cp0.l   w1
    bra     nz, check_one

    mov.l   #0, [w2]                ; *pResult = 0
    clr.l   [w3]                    ; *pIndex  = 0
    pop.l   FCR
    return

check_one:
    cp.l    w1, #1
    bra     nz, start_main

    mov.l   [w0], f0                ; f0 = src[0]
    mov.l   f0, [w2]
    clr.l   [w3]
    pop.l   FCR
    return

start_main:
    mov.l    w1, w6                  ; w6 = N
    mov.l    w1, w5                  ; w5 to hold N - index of max element
    sub.l    w1, #1, w4              ; w4 = N-1
    mov.l    [w0++], f0              ; f0 = srcV[0]
    mov.l    [w0], f1                ; f1 = srcV[1]
    
compare:
    max.s   f0, f1, f0               ; f0 = MAX(f0, f1)
    cpq.s   f0, f1                   ; compare f0, f1
    fbra    une, skip_index_update   ; skip if not equal
    mov.l   w4, w5                   ; w5 = N - curr_max

skip_index_update:
    mov.l    [++w0], f1              ; f1 = srcV[n+1]
    dtb w4,  compare                 
    mov.l    f0, [w2]                ; *pResult = maxVal
    sub.l    w6, w5, [w3]            ; max_element = N - w5
    
;.............................................................................    
    pop.l    FCR                    ; Restore FCR.
;............................................................................

    return    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


