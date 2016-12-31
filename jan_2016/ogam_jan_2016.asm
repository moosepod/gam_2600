        processor 6502
        include "vcs.h"
        include "macro.h"

;;;;; An Atari 2600 game! See http://8bitworkshop.com/

;;;;; Todos!
;;;;; Add sub-positioning horizontal
;;;;; add square playfield with collision detection
;;;;; add multi-line sprites

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Variables segment

        seg.u Variables
        org $80

Temp            .byte
Player_X          .byte ; X position of ball sprint
Player_Y           .byte ; Y position of ball sprite

PLAYER_MAX_Y    equ  #188   ; Max Y position for ball sprite
PLAYER_MIN_Y    equ  #1    ; Min Y position for ball sprite
PLAYER_MAX_X    equ  #152   ; Max X position for ball sprite
PLAYER_MIN_X    equ  #1    ; Min X position for ball sprite
PLAYER_START_X  equ #9
PLAYER_START_Y  equ #80
PLAYER_SPRITE   equ #$FF   ; Sprite (1 line) for our ball
PLAYER_COLOR    equ #$60 ; Color for ball

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

; 37 lines of underscan total
        ; Check joysticks
        jsr CheckJoystick
        sta WSYNC

        ldx 34
PreLoop dex
        sta WSYNC
        bne PreLoop

        ; Wait for scanline after setting up loop 
        lda PLAYER_COLOR
        sta COLUP0
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

; 192 lines of frame total

; Loop until we hit the vertical positoin we want for the ball
        ldx Player_Y
VLoop   dex
        sta WSYNC
        bne VLoop

        ; Draw the ball
        lda #PLAYER_SPRITE
        sta GRP0
        sta WSYNC
        
        ; Wait for next scanline then clear the sprite
        sta WSYNC
        lda #0        
        clc
        sta GRP0

        ; Close out the remaining scanlines, which will be 192-Ball Y-1 (since we waited an extra WSYNC above)
        lda #190
        clc
        sbc Player_Y
VWait   sbc 1
        sta WSYNC
        bne VWait
     
; 30 lines of overscan
        ldx 30
PostLoop 
        dex
        sta WSYNC
        bne PostLoop

; go to next frame
        jmp NextFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Subroutines
;;;

; This subroutine checks the player one joystick and moves the player accordingly
CheckJoystick
        ldx Player_X
        lda SWCHA
        and #$80 ; 1000000
        beq .SkipMoveRight  ; checks bit 7 set
        cpx #PLAYER_MIN_X ; Check bounds
        beq .SkipMoveLeft
        dex
.SkipMoveRight
        lda SWCHA
        and #$40 ; 0100000
        beq .SkipMoveLeft ; checks bit 6 set
        cpx #PLAYER_MAX_X ; Check bounds
        beq .SkipMoveLeft
        inx
.SkipMoveLeft
        stx Player_X

        ; Now we repeat the process but with a SWCHA that is shifted left twice, so down is 
        ; bit 7 and up is bit 6
        ldx Player_Y
	lda SWCHA
        and #$20 ; 00100000
        beq .SkipMoveDown  ; checks bit 5 set
        cpx #PLAYER_MIN_Y ; Check bounds
        beq .SkipMoveUp
        dex
.SkipMoveDown
        lda SWCHA
        and #$10 ; 00010000
        beq .SkipMoveUp ; checks bit 4 set
        cpx #PLAYER_MAX_Y ; Check bounds
        beq .SkipMoveUp
        inx
.SkipMoveUp
        stx Player_Y

        rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Epilogue

        org $fffc
        .word Start     ; reset vector
        .word Start     ; BRK vector
