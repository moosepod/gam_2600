        processor 6502
        include "vcs.h"
        include "macro.h"


;;;;; This is a 2600 cart template file. It draws a background color and
;;;;; that is it. Note that there are black areas in the overscan/underscan if
;;;;; run on stella. this is norma

;;;;; All of the following were helpful in building this game:
;;;;; An Atari 2600 game! See http://8bitworkshop.com/
;;;;; Making Games for the Atari 2600 by Steven Hugg



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Variables segment

        seg.u Variables
        org $80

BGColor	equ $21

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Code segment

        seg Code
        org $f000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Start
        CLEAN_START

NextFrame
; Initialization -- turn on vblank, set VSYNC for 3 scan lines, turn off VSYNC
	lda #2
    sta VBLANK
	lda #2
	sta VSYNC
	sta WSYNC
	sta WSYNC
	sta WSYNC
	lda #0
	sta VSYNC

; 37 lines BLANK
	ldx #37
BlankLoop	sta WSYNC	
	dex		
	bne BlankLoop	

; Re-enable output (disable VBLANK)
	lda #0
    sta VBLANK

; 192 scanlines 
	ldx #192
	lda BGColor
ScanLoop
	sta COLUBK	
	sta WSYNC	
	dex
	bne ScanLoop

; Enable VBLANK again
	lda #2
    sta VBLANK
; 30 lines overscan
	ldx #30
OverscanLoop	sta WSYNC
	dex
	bne OverscanLoop


; Frame is over, start next one
	jmp NextFrame
	
	org $fffc
	.word Start
	.word Start
