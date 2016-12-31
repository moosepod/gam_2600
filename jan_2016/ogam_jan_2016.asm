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
Player_Y           .byte ; Y position of player sprite

PLAYER_MAX_Y    equ  #182   ; Max Y position for player sprite
PLAYER_MIN_Y    equ  #1    ; Min Y position for player sprite
PLAYER_MAX_X    equ  #148   ; Max X position for player sprite
PLAYER_MIN_X    equ  #3    ; Min X position for player sprite
PLAYER_START_X  equ #9
PLAYER_START_Y  equ #80
PLAYER_SPRITE   equ #$FF   ; Sprite (1 line) for our ball
PLAYER_COLOR    equ #$60 ; Color for ball
PLAYER_SPRITE_HEIGHT equ #7 ; this is really 1 less than the sprite height

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

        ldx 32
PreLoop dex
        sta WSYNC
        bne PreLoop

       
        ;;; Setup for horizontal positioning 
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

        ;; Setup first line of playfield
        lda #$ff 
        sta COLUPF
        sta PF0
        sta PF1
        sta PF2

; 192 lines of frame total
        ;; draw first line (playfield only) then reset playfield
        lda #$10 
        sta PF0
        lda #0
        sta PF1
        sta PF2
        
; Loop until we hit the vertical position we want for the ball
        ldx Player_Y
VLoop   dex
        sta WSYNC
        bne VLoop

        ; Setup for sprite drawing
        ldy #PLAYER_SPRITE_HEIGHT  ; sprite data index
SpriteLoop
        lda PLAYER_SPRITE_DATA,y
        sta GRP0
        lda PLAYER_COLOR_DATA,y
        sta COLUP0
        sta WSYNC
        dey
        bne SpriteLoop
       
        ; Wait for next scanline then clear the sprite
        sta WSYNC
        lda #0        
        clc
        sta GRP0

        ; Close out the remaining scanlines, which will be 192-sprite height-one line for playfield top)
        lda #192
        sbc #PLAYER_SPRITE_HEIGHT
        clc
        sbc Player_Y
VWait   sbc 1
        sta WSYNC
        bne VWait
        
        ;; Draw bottom line of playfield
        lda #$01
        sta CTRLPF
        lda #$ff 
        sta COLUPF
        sta PF0
        sta PF1
        sta PF2
     
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sprite data
;---Graphics Data from PlayerPal 2600---

PLAYER_SPRITE_DATA
        .byte #%00010100;$84
        .byte #%00111110;$84
        .byte #%00000000;$F6
        .byte #%00000000;$F6
        .byte #%00001000;$F6
        .byte #%00000000;$20
        .byte #%00100010;$20
        .byte #%00000000;--
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
;---End Color Data---
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Epilogue

        org $fffc
        .word Start     ; reset vector
        .word Start     ; BRK vector
