        processor 6502
        include "vcs.h"
        include "macro.h"

;;;;; An Atari 2600 game! See http://8bitworkshop.com/
;;;;; PlayerPal 2600 (http://www.alienbill.com/2600/playerpalnext.html and http://alienbill.com/2600/playfieldpal.html)
;;;;; Making Games for the Atari 2600 by Steven Hugg

;;;;; Todos!
;;; CONCEPT: MooseMaze
;;; TODOS:
;;; Color cycle 
;;; Complete a maze with exit
;;; Maybe doors open in a sequence? Can't have exit and walls at same level
;;; Multiple mazes  
;;; Create a timer
;;; Create a start screen?
;;; Create some sound effects/music
;;; Swap mazes half way through
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Variables segment

        seg.u Variables
        org $80

Temp                    .byte
Player_X                .byte ; X position of ball sprint
Player_Y                .byte ; Y position of player sprite. 
                              ; Note Y-positions are measured from _bottom_ of screen and increase going up

Player_X_Tmp            .byte 
Player_Y_Tmp            .byte 

; For use with subroutines
Spritedraw_Sprite_Number .byte
Spritedraw_Sprite_YPos .byte

; For drawing playfield
PF_frame_counter          .byte

PLAYER_START_X  equ #8
PLAYER_START_Y  equ #165 ; needs to be odd
PLAYER_SPRITE   equ #$FF   ; Sprite (1 line) for our ball
PLAYER_COLOR    equ #$60 ; Color for ball
PLAYER_SPRITE_HEIGHT equ #18 ; this is really 2ma greater than sprite height, there's a buffer empty line that clears the sprite
PLAYFIELD_BLOCK_HEIGHT equ #8
PLAYFIELD_ROWS equ #22

SCOREBOARD_HEIGHT equ #177 ; must be odd since compare is on odd lines
SCOREBOARD_BACKGROUND_COLOR equ #$00
PLAYFIELD_BACKGROUND_COLOR equ #$9E

MAX_Y equ #173
MIN_Y equ #16

BORDER_COLOR equ #$EF ; last bit has to be 1 to do playfield reflection


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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Kernel        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NextFrame
        lsr SWCHB       ; test Game Reset switch
        bcc Start       ; reset?

; 3 lines of VSYNC
        VERTICAL_SYNC

;;
;; 37 lines of underscan total
;;
        ; Check joysticks
        jsr CheckJoystick
        sta WSYNC ; this will commit to 1 scanline
        lda #0
        sta COLUPF
        lda #0
        sta PF_frame_counter
        lda #01
        sta CTRLPF

        ; Clear sprite color and sprite
        lda #00
        sta GRP0

        jsr PositionPlayerX ; 2 scanlines
        ldx #32 
PreLoop dex
        sta WSYNC
        bne PreLoop
        
SetupDrawing
        ;; We will use y to track our current scanline. 
        ldy #0
        sty PF_frame_counter
   
        ldy #192 ; one manual wsync 

        ; Setup header  
        lda #BORDER_COLOR 
        sta COLUPF
        lda #$00
        sta PF0
        sta PF1
        sta PF2

        ; Start background color for scoreboard
        lda #SCOREBOARD_BACKGROUND_COLOR
        sta COLUBK


        ; Complete last line of underscan
        sta WSYNC

;;
;; 192 lines of frame total     
;;



ScanLoop
        ; we expand our playfield data vertically into units 8 tall. Rather than
        ; test for mod 8 directly, we compare with a precalculated list of indexes

        ; Draw background
        lda PFData0,y
        sta PF0
        lda PFData1,y
        sta PF1
        lda PFData2,y
        sta PF2

        ; Wait for next scanline and decrement
        sta WSYNC
        dey

        ; Draw player sprite
        lda #0 ; sprite 0, player
        sta Spritedraw_Sprite_Number
        lda Player_Y
        sta Spritedraw_Sprite_YPos
        jsr DrawSprite

        ; If we've reached bottom of scoreboard, activate playfield background
        cpy #SCOREBOARD_HEIGHT
        bne ScanLoopEnd
        lda #PLAYFIELD_BACKGROUND_COLOR
        sta COLUBK
ScanLoopEnd
        sta WSYNC
        dey
        ; jump to start of loop if we have remaining lines
        bne ScanLoop

; 30 lines of overscan
; Clear background for remaining
OverscanCleanup
        lda #SCOREBOARD_BACKGROUND_COLOR
        sta COLUBK
        lda #00
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
; Subroutines
;;;

DrawSprite
    ;; Draw a given sprite. Note we assume all sprites are SPRITE_HEIGHT units high. This is double the rows of data
    ;; due to the two-line kernel. 
    ;; (!) This routine will blow out the X and A registers

    ;; set Spritedraw_Sprite_Number and Spritedraw_Sprite_YPos before claling

    lda Spritedraw_Sprite_YPos
    sty Temp  ; store our current line count into a temp variable, then subtract it from sprite positoin
    sbc Temp  
    bmi .Return ; If the subtraction is negative, we are above (closer to top of screen) for this sprite
    tax ; move the accumulator to our X index (it'll contain the index of the sprite line we want)
    
    ; Jump to end if we are past the end of the sprite
    cpx #PLAYER_SPRITE_HEIGHT
    bcs .Return

    ; Draw the current line of the sprite
    lda PLAYER_SPRITE_DATA,x
    sta GRP0
    lda PLAYER_COLOR_DATA,x
    sta COLUP0

.Return
    rts

; Handle the (very timing dependent) adjustment of X position for the player
PositionPlayerX
        lda Player_X
        sec
        sta WSYNC
        sta HMCLR ; Clear old horizontal pos

        ; Divide the X position by 15, the # of TIA color clocks per loop
DivideLoop
        sbc #15
        bcs DivideLoop

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
        ; First do any collision checks
        bit CXP0FB ; Player 0/Playfield
        bpl .NoCollision
        ldx Player_X_Tmp
        stx Player_X
        ldx Player_Y_Tmp
        stx Player_Y
.NoCollision
        ldx Player_X
        stx Player_X_Tmp ; Store so we can restore on collsion
        lda SWCHA
        and #$80 ; 1000000
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
.Done
        stx Player_Y
        sta CXCLR ; clear collision checks

        rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sprite data
;---Graphics Data from PlayerPal 2600---

; data lines are all doubled up to account for our two-line kernel. 
PLAYER_SPRITE_DATA
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



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
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
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
 .byte #%00110000
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
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000

PFData1
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00111111
 .byte #%00111111
 .byte #%00111111
 .byte #%00111111
 .byte #%00111111
 .byte #%00111111
 .byte #%00111111
 .byte #%00111111
 .byte #%00111111
 .byte #%00111111
 .byte #%00111111
 .byte #%00111111
 .byte #%00111111
 .byte #%00111111
 .byte #%00111111
 .byte #%00111111
 .byte #%00111111
 .byte #%00111111
 .byte #%00111111
 .byte #%00111111
 .byte #%00110011
 .byte #%00110011
 .byte #%00110011
 .byte #%00110011
 .byte #%00110011
 .byte #%00110011
 .byte #%00110011
 .byte #%00110011
 .byte #%00110011
 .byte #%00110011
 .byte #%00110011
 .byte #%00110011
 .byte #%00110011
 .byte #%00110011
 .byte #%00110011
 .byte #%00110011
 .byte #%00110011
 .byte #%00110011
 .byte #%00110011
 .byte #%00110011
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000

PFData2
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001100
 .byte #%11001100
 .byte #%11001100
 .byte #%11001100
 .byte #%11001100
 .byte #%11001100
 .byte #%11001100
 .byte #%11001100
 .byte #%11001100
 .byte #%11001100
 .byte #%11001100
 .byte #%11001100
 .byte #%11001100
 .byte #%11001100
 .byte #%11001100
 .byte #%11001100
 .byte #%11001100
 .byte #%11001100
 .byte #%11001100
 .byte #%11001100
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%11001111
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11000000
 .byte #%11000000
 .byte #%11000000
 .byte #%11000000
 .byte #%11000000
 .byte #%11000000
 .byte #%11000000
 .byte #%11000000
 .byte #%11000000
 .byte #%11000000
 .byte #%11000000
 .byte #%11000000
 .byte #%11000000
 .byte #%11000000
 .byte #%11000000
 .byte #%11000000
 .byte #%11000000
 .byte #%11000000
 .byte #%11000000
 .byte #%11000000
 .byte #%00001100
 .byte #%00001100
 .byte #%00001100
 .byte #%00001100
 .byte #%00001100
 .byte #%00001100
 .byte #%00001100
 .byte #%00001100
 .byte #%00001100
 .byte #%00001100
 .byte #%00001100
 .byte #%00001100
 .byte #%00001100
 .byte #%00001100
 .byte #%00001100
 .byte #%00001100
 .byte #%00001100
 .byte #%00001100
 .byte #%00001100
 .byte #%00001100
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%11111111
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000
 .byte #%00000000

; Epilogue

        org $fffc
        .word Start     ; reset vector
        .word Start     ; BRK vector
