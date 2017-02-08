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

PLAYER_START_X  equ #$15
PLAYER_START_Y  equ #$BC ; needs to be even

CurrentLine             .byte
Player_X                .byte ; X position of ball sprint
Player_Y                .byte ; Y position of player sprite. 
Player_X_Tmp            .byte 
Player_Y_Tmp            .byte 

BORDER_COLOR equ #$EE 
MAX_Y equ #173
MIN_Y equ #0

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

        ; Check joysticks. This will use 2 scanlines in total
        sta WSYNC ; Give our joystick check a full scanline
        jsr CheckJoystick

        ; Clear sprite , then position sprite on X
        lda #00
        sta GRP0

        jsr PositionPlayerX ; 2 scanlines
    
		ldx #32
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

		; Need to draw alternate playfield after exactly 21 cycles
         lda CurrentLine ; 3 cycles
         cmp Player_Y ; 2 cycles
         bne NoPlayer ; 2 cycles if fall through, 3 if taken
         lda #$CC ; 2 cycles
         sta COLUP0 ; 3 cycles
         lda #$C0 ; 2 cycles
         sta GRP0 ; 3 cycles
         jmp SecondPlayfield ; 3 cycles
NoPlayer
        lda #$00 ; 2 cycles
        sta COLUP0 ; 3 cycles
        lda #$00 ; 2 cycles
        sta GRP0 ; 3 cycles
        nop
SecondPlayfield
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

; Handle the (very timing dependent) adjustment of X position for the player
PositionPlayerX
        lda Player_X
        sec
        sta WSYNC
        sta HMCLR ; Clear old horizontal pos

        ; Divide the X position by 15, the # of TIA color clocks per loop
DivideLoopX
        sbc #15
        bcs DivideLoopX

        ; A will contain remainder of division. Convert to fine adjust
        ; which is -7 to +8
        eor #7  ; calcs (23-A) % 16
        asl
        asl
        asl
        asl
        sta HMP0                ; set the fine position

        sta RESP0               ; set the coarse position

        sta WSYNC
        sta HMOVE               ; set the fine positioning

        rts

; This subroutine checks the player one joystick and moves the player accordingly
CheckJoystick
        ; First do any collision checks. Check player 0 with playfield (bit 1)
        bit CXP0FB ; Player 0/Playfield
        bpl .NoCollision
        jmp .ResetPlayerPos
.NoCollision
        ldx Player_X
        stx Player_X_Tmp ; Store so we can restore on collsion
        lda SWCHA
        and #$80 ; 1000000
        sta WSYNC ; make time for rest of logic
        beq .TestRight  ; checks bit 7 set
        dex 
.TestRight
        lda SWCHA
        and #$40 ; 0100000
        beq .TestUp ; checks bit 6 set
        inx
.TestUp
        stx Player_X        
        ; Now we repeat the process but with a SWCHA that is shifted left twice, so down is 
        ; bit 7 and up is bit 6
        ldx Player_Y
        stx Player_Y_Tmp ; Store so we can restore on collsion
        lda SWCHA
        and #$20 ; 00100000
        beq .TestDown  ; checks bit 5 set
        ; We need to do an explicit range check on Player_Y or the drawing kernel gets thrown off
        ; and collisions with border don't trigger properly
        cpx #MAX_Y
        beq .Done
        inx   
        inx ; we move in units of 2 Y positions to match kernel
.TestDown
        lda SWCHA
        and #$10 ; 00010000
        beq .Done ; checks bit 4 set
        cpx #MIN_Y
        beq .Done
        dex
        dex ; we move in units of 2 Y positions to match kernel
        jmp .Done
.ResetPlayerPos
        sta WSYNC ; mirror WSYNC with non-collsion logic
        ldx Player_X_Tmp
        stx Player_X
        ldx Player_Y_Tmp
        stx Player_Y
.Done
        stx Player_Y
        sta CXCLR ; clear collision checks
.JoystickReturn
        rts

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

; To make timing work, left/right side of screen is alway a wall.
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
 .byte #%11111111
 .byte #%10000000
 .byte #%10111111
 .byte #%10100000
 .byte #%10101111
 .byte #%10101000
 .byte #%10101011
 .byte #%10101011
 .byte #%10101011
 .byte #%10101011
 .byte #%10101011
 .byte #%10101011
 .byte #%10101011
 .byte #%10101011
 .byte #%10101011
 .byte #%10101011
 .byte #%10101011
 .byte #%10101011
 .byte #%10101011
 .byte #%10101011
 .byte #%10101000
 .byte #%10101111
 .byte #%10100000
 .byte #%10111111

PFData2
 .byte #%11111111
 .byte #%00000000
 .byte #%11111111
 .byte #%00000000
 .byte #%11111111
 .byte #%00000000
 .byte #%11111111
 .byte #%00000000
 .byte #%11111110
 .byte #%00000010
 .byte #%11111010
 .byte #%00001010
 .byte #%11101010
 .byte #%11101010
 .byte #%00001010
 .byte #%11111010
 .byte #%00000010
 .byte #%11111110
 .byte #%00000000
 .byte #%11111111
 .byte #%00000000
 .byte #%11111111
 .byte #%00000000
 .byte #%11111111

PFData5
 .byte #%11111111
 .byte #%00000000
 .byte #%11111111
 .byte #%00000000
 .byte #%11111111
 .byte #%00000000
 .byte #%11111111
 .byte #%00000011
 .byte #%11111011
 .byte #%00001011
 .byte #%11101011
 .byte #%00101011
 .byte #%10101011
 .byte #%11101011
 .byte #%00001011
 .byte #%11111011
 .byte #%00000011
 .byte #%11111111
 .byte #%00000000
 .byte #%11111111
 .byte #%00000000
 .byte #%11111111
 .byte #%00000000
 .byte #%11111111

PFData4
 .byte #%11111111
 .byte #%10000000
 .byte #%10111111
 .byte #%10110000
 .byte #%10110111
 .byte #%10110110
 .byte #%10110110
 .byte #%10110110
 .byte #%10110110
 .byte #%10110110
 .byte #%10110110
 .byte #%10110110
 .byte #%10110110
 .byte #%10110110
 .byte #%10110110
 .byte #%10110110
 .byte #%10110110
 .byte #%10110110
 .byte #%10110110
 .byte #%10110111
 .byte #%10110000
 .byte #%10111111
 .byte #%10000000
 .byte #%11111111

; Epilogue

        org $fffc
        .word Start     ; reset vector
        .word Start     ; BRK vector
