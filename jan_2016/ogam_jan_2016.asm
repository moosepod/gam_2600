        processor 6502
        include "vcs.h"
        include "macro.h"

;;;;; An Atari 2600 game! See http://8bitworkshop.com/

;;;;; Todos!
;;; use total line counter instead of piecemeil
;;; use collision check instead of Y check for walls
;;; add "map" using playfield
;;; add "prize" on map
;;; can capture prize by touching prize
;;; show text on prize capture
;;; multiple maps 
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

PLAYER_START_X  equ #9
PLAYER_START_Y  equ #150
PLAYER_SPRITE   equ #$FF   ; Sprite (1 line) for our ball
PLAYER_COLOR    equ #$60 ; Color for ball
PLAYER_SPRITE_HEIGHT equ #8 ; this is really 1 less than the sprite height

SCOREBOARD_HEIGHT equ #15
BORDER_HEIGHT equ #8
TOTAL_TOP_HEIGHT equ #23

BORDER_COLOR equ #$51 ; last bit has to be 1 to do playfield reflection

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
        sta Player_X_Tmp
        lda #PLAYER_START_Y
        sta Player_Y
        sta Player_Y_Tmp

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
        lda #$00
        sta COLUPF

        jsr PositionPlayerX ; 2 scanlines
        ldx #33 
PreLoop dex
        sta WSYNC
        bne PreLoop
        
;;
;; 192 lines of frame total
;;
        ;; We will use y to track our current scanline. 
        ldy #192
        jsr DrawScoreboardAndTop
        sta WSYNC
        dey ; matches WSYNC, keeps track of line

; Loop until we hit the vertical position we want for the player. 
        ; This first part makes sure the sprite doesn't move past the boundary. Collision detection
        ; should be catching this but there's a line where it does not. This should be refactored.      
        lda #191
        sbc #TOTAL_TOP_HEIGHT
        cmp Player_Y
        beq SkipVLoop
        bcc SkipVLoop ; Skip timing break below if Y is already below our top
        lda #BORDER_HEIGHT
        cmp Player_Y
        beq SkipVLoop ; Skip timing break below if Y is already below our top

VLoop   dey
        sta WSYNC
        cpy Player_Y
        bne VLoop

; Draw the player sprite
SkipVLoop
        ; Setup for sprite drawing
        ldx #PLAYER_SPRITE_HEIGHT  ; sprite data index
SpriteLoop
        lda PLAYER_SPRITE_DATA,x
        sta GRP0
        lda PLAYER_COLOR_DATA,x
        sta COLUP0
        sta WSYNC
        dey ; track scanlines
        dex
        bne SpriteLoop
       
        ; Loop until we are at BORDER_HEIGHT, meaning all scan lines processed except for the bottom
        cpy #BORDER_HEIGHT
        beq DrawBottomBorder
VWait   dey
        cpy #BORDER_HEIGHT
        sta WSYNC
        bne VWait
        
        ;; Draw bottom line of playfield
DrawBottomBorder
        lda #BORDER_COLOR
        sta CTRLPF
        lda #$ff 
        sta PF0
        sta PF1
        sta PF2

        ldx #BORDER_HEIGHT
BottomLoop
        dex
        sta WSYNC
        bne BottomLoop
        
        lda #0
        sta PF0
        sta PF1
        sta PF2
     
; 30 lines of overscan
        ldx #30
        clc
PostLoop 
        dex
        sta WSYNC
        bne PostLoop

; go to next frame
        nop
        jmp NextFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Subroutines
;;;

DrawScoreboardAndTop
        ldx #SCOREBOARD_HEIGHT
.Timer
        dey ; keep track of our lines
        dex
        sta WSYNC
        bne .Timer
        
        ; Draw  
        lda #BORDER_COLOR 
        sta COLUPF
        lda #$ff 
        sta PF0
        sta PF1
        sta PF2
        
        ldx #BORDER_HEIGHT
.Timer2
        dey ; keep track of our lines
        dex
        sta WSYNC
        bne .Timer2
        
        ;; draw first line (playfield only) then reset playfield
        lda #$10 
        sta PF0
        lda #0
        sta PF1
        sta PF2
        
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
        inx   
.TestDown
        lda SWCHA
        and #$10 ; 00010000
        beq .Done ; checks bit 4 set
        dex
.Done
        stx Player_Y
        sta CXCLR ; clear collision checks

        rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sprite data
;---Graphics Data from PlayerPal 2600---

PLAYER_SPRITE_DATA
        .byte #%00000000;--
        .byte #%00000000;--
        .byte #%11111111;$84
        .byte #%11111111;$84
        .byte #%11111111;$F6
        .byte #%11111111;$F6
        .byte #%11111111;$F6
        .byte #%11111111;$20
        .byte #%00000000;$20
;---End Graphics Data---


;---Color Data from PlayerPal 2600---

PLAYER_COLOR_DATA
        .byte #$54;
        .byte #$84;
        .byte #$06;
        .byte #$06;
        .byte #$06;
        .byte #$FE;
        .byte #$FE;
        .byte #$0E;
        .byte #$0E;
;---End Color Data---
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Epilogue

        org $fffc
        .word Start     ; reset vector
        .word Start     ; BRK vector
