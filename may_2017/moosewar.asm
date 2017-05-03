        processor 6502
        include "vcs.h"
        include "macro.h"
        include "xmacro.h"

;;;;; All of the following were helpful in building this game:
;;;;; An Atari 2600 game! See http://8bitworkshop.com/
;;;;; Making Games for the Atari 2600 by Steven Hugg

;;;;; This is a 2600 template file. It draws a background color and
;;;;; that is it. Note that there are black areas in the overscan/underscan if
;;;;; run on stella. this is normal.


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
	VERTICAL_SYNC

; 37 lines BLANK
	TIMER_SETUP 37

	; clear
	lda 0
	sta COLUBK	
	sta WSYNC

    TIMER_WAIT	

; 192 scanlines 
	TIMER_SETUP 192
	lda BGColor
	sta COLUBK	
	sta WSYNC	
    TIMER_WAIT	

; 30 lines overscan
	TIMER_SETUP 30

	; clear
	lda 0
	sta COLUBK	
	sta WSYNC

    TIMER_WAIT	

; Frame is over, start next one
	jmp NextFrame
	
	org $fffc
	.word Start
	.word Start
