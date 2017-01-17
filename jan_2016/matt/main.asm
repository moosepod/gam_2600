        processor 6502
        include "vcs.h"
        include "macro.h"

;;;;; An Atari 2600 game! See http://8bitworkshop.com/
;;;;; PlayerPal 2600 (http://www.alienbill.com/2600/playerpalnext.html and http://alienbill.com/2600/playfieldpal.html)
;;;;; Making Games for the Atari 2600 by Steven Hugg

;;;;; FriendShip is an Atari 2600 game built as part of One Game A Month (http://www.onegameamonth.com/)
;;;;; It is primarily a project to learn how to develop 2600 games in assembly language, so is very tech driven.
;;;;; In addition I wanted to grapple with some of the challenges, so the game kernel is my own (and not one of the certainly better
;;;;; ones available)
;;;;;
;;;;; Basic concept: you sail your ship using the joystick (plugged into left joystick port)
;;;;; You'll be blocked by yellow sandbars. 
;;;;; Your goal is to reach the other ship, your friend ship
;;;;; You can exit through various points to go to the next set of mazes

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Variables segment

        seg.u Variables
        org $80

CurrentLine                    .byte

BORDER_COLOR equ #$EE 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Code segment

        seg Code
        org $f000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Start
        CLEAN_START

Initialize
		lda #0
		sta CTRLPF

NextFrame
        lsr SWCHB       ; test Game Reset switch
        bcc Start       ; reset?

; 3 lines of VSYNC
        VERTICAL_SYNC

;;
;; 37 lines of underscan total
;;

		ldx #36
UnderscanExtraLoop dex
        sta WSYNC
        bne UnderscanExtraLoop

        lda #BORDER_COLOR 
        sta COLUPF

        ; Setup for start of kernel
        lda #192 ; number of lines in main loop
        sta CurrentLine
;;
;; 192 lines of frame total     
;;
		; We store the current line (0 being the bottom of the screen)
Kernel
		;; We have a two line kernel. First line sets the playfield,
		;; then swaps to alternative playfield, then swaps back
		;; 
		;; We have 24 lines of playfield total and increment the counter every 8
		
		; cycle until we hit the right spot to switch playfields and back
		sta WSYNC
		lsr
		lsr
		lsr ; 3 lsr = Divide by 8 to get our index 
		tay

		; Draw playfield        
        lda PFData0,y
        sta PF0
        lda PFData1,y
        sta PF1
        lda PFData2,y
        sta PF2

        ; Immediately switch to second playfield
        lda PFData3,y
        sta PF0
        lda PFData4,y
        sta PF1
        lda PFData5,y
        sta PF2

       	; And back       
        lda PFData0,y
        sta PF0
        lda PFData1,y
        sta PF1
        lda PFData2,y
        sta PF2

		sta WSYNC

		; Line 2 of kernel

		; Need to draw alternate playfield after 26 cycles
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop

		; Switch to second playfield
        lda PFData3,y
        sta PF0
        lda PFData4,y
        sta PF1
        lda PFData5,y
        sta PF2

		ldy CurrentLine	
		dey
		dey

		sty CurrentLine

		; Calculate our y index for the next playfield
		tya
		bne Kernel ; the lsr should set the Z flag
;;
;; 30 lines of overscan
;;
		lda #0
        sta PF0
        sta PF1
        sta PF2

		ldx #30
PostLoop
        dex
        sta WSYNC
        bne PostLoop

        jmp NextFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This file will be merged by make with the map data (map.asm) and the footer (footer.asm)
;;; So edit main.asm then use make
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PFData0
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000

PFData1
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101

PFData2
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101


PFData3
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%01010000
 .byte #%10100000
 .byte #%10100000

PFData4
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%01010101

PFData5
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
 .byte #%01010101
 .byte #%10101010
