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

PLAYER_START_X  equ #8
PLAYER_START_Y  equ #170 ; needs to be odd

CurrentLine             .byte
Player_X                .byte ; X position of ball sprint
Player_Y                .byte ; Y position of player sprite. 

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
        lda #PLAYER_START_X
        sta Player_X
        lda #PLAYER_START_Y
        sta Player_Y
		lda #1
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
        lda #$C0
        sta PF0
        lda PFData1,y
        sta PF1
        lda PFData2,y
        sta PF2

		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop

        ; Immediately switch to second playfield
        lda PFData5,y
        sta PF2
        lda PFData4,y
        sta PF1

       	; And back       
        lda PFData2,y
        sta PF2
        lda PFData1,y
        sta PF1

		sta WSYNC

		; Line 2 of kernel

		; Need to draw alternate playfield after 21 cycles
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
		nop
		nop
		nop

		; Switch to second playfield
        lda PFData5,y
        sta PF2
        lda PFData4,y
        sta PF1

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

    align $100; make sure data doesn't cross page boundary

Player_Sprite_Data
        .byte #%00011000;$0C
        .byte #%00011000;$0C
        .byte #%00011100;$0C
        .byte #%00011100;$0C
        .byte #%00011110;$0C
        .byte #%00011110;$0C
        .byte #%00010000;$0C
        .byte #%00010000;$0C
        .byte #%00010000;$0C
        .byte #%00010000;$0C
        .byte #%01111110;$F4
        .byte #%01111110;$F4
        .byte #%01111110;$F4
        .byte #%01111110;$F4
        .byte #%00111100;$F4
        .byte #%00111100;$F4
        .byte #%00000000 ; blank line to offset sprite (we never reach 0)
        .byte #%00000000 ; buffer line that clears sprite on last line
        .byte #%00000000 ; blank line to offset sprite (we never reach 0)
        .byte #%00000000 ; buffer line that clears sprite on last line
;---End Graphics Data---

;---Color Data from PlayerPal 2600---

; color lines are doubled up to account for our two line kernel.
PLAYER_COLOR_DATA
        .byte #$0C;
        .byte #$0C;
        .byte #$0C;
        .byte #$0C;
        .byte #$0C;
        .byte #$0C;
        .byte #$0C;
        .byte #$0C;
        .byte #$0C;
        .byte #$0C;
        .byte #$F4;
        .byte #$F4;
        .byte #$F4;
        .byte #$F4;
        .byte #$F4;
        .byte #$F4;
        .byte #$F4;
        .byte #$F4;
        .byte #$F4;
        .byte #$F4;
;---End Color Data---

PFData0
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000

PFData3
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000
 .byte #%11110000

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

PFData4
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

PFData5
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

; Epilogue

        org $fffc
        .word Start     ; reset vector
        .word Start     ; BRK vector
