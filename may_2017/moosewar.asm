        processor 6502
        include "vcs.h"
        include "macro.h"
        include "xmacro.h"

;;;;; All of the following were helpful in building this game:
;;;;; An Atari 2600 game! See http://8bitworkshop.com/
;;;;; Making Games for the Atari 2600 by Steven Hugg
;;;;;
;;;;; Scoreboard code and xmacro.h from there

;;;;; This is a 2600 template file. It draws a background color and
;;;;; that is it. Note that there are black areas in the overscan/underscan if
;;;;; run on stella. this is normal.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Variables segment

        seg.u Variables
        org $80

Score0	byte	; BCD score of player 0
Score1	byte	; BCD score of player 1
FontBuf	ds 10	; 2x5 array of playfield bytes
Temp	byte

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Code segment

        seg Code
        org $f000
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Start
    CLEAN_START
	lda #$00
	sta Score0
	lda #$00
	sta Score1
	
NextFrame
	VERTICAL_SYNC

; 37 lines BLANK
	TIMER_SETUP 37
	
	lda Score0
    ldx #0
	jsr GetBCDBitmap
	lda Score1
    ldx #5
	jsr GetBCDBitmap

;;; 192 lines total. First 40 are scoreboard
    TIMER_WAIT	
	TIMER_SETUP 50

; First, we'll draw the scoreboard.
; Put the playfield into score mode (bit 2) which gives
; two different colors for the left/right side of
; the playfield (given by COLUP0 and COLUP1).
	lda #%00010010	; score mode + 2 pixel ball
	sta CTRLPF
	lda #$48
	sta COLUP0	; set color for left
	lda #$a8
	sta COLUP1	; set color for right
; Now we draw all four digits.
	ldy #0		; Y will contain the frame Y coordinate
ScanLoop1a
	sta WSYNC
	tya
	lsr		; divide Y by two for double-height lines
	tax		; -> X
	lda FontBuf+0,x
	sta PF1		; set left score bitmap
	SLEEP 28
	lda FontBuf+5,x
	sta PF1		; set right score bitmap
	iny
	cpy #10
	bcc ScanLoop1a

; Clear the playfield
	lda #0
	sta WSYNC
	sta PF1

    TIMER_WAIT	

; Draw the card decks. 

	lda #%00000011	; score mode + reflect playfield
	sta CTRLPF

	; top of cards
	TIMER_SETUP 10
	lda #$41
	sta COLUPF

	lda PFData0
	sta PF0

	lda PFDataFlipped1
	sta PF1

	lda PFDataFlippedEnd2
	sta PF2

    TIMER_WAIT

	; middle of cards
	TIMER_SETUP 80

	lda PFDataFlippedMiddle2
	sta PF2

    TIMER_WAIT

	; bottom of cards
	TIMER_SETUP 10

	lda PFDataFlippedEnd2
	sta PF2

    TIMER_WAIT

; Remaining lines -- 192-50-100
	TIMER_SETUP 32
	lda #%00
	sta PF0
	sta PF1
	sta PF2
	TIMER_WAIT

; 30 lines overscan
	TIMER_SETUP 30
    TIMER_WAIT	

    jmp NextFrame

; Fetches bitmap data for two digits of a
; BCD-encoded number, storing it in addresses
; FontBuf+x to FontBuf+4+x.
GetBCDBitmap subroutine
; First fetch the bytes for the 1st digit
	pha		; save original BCD number
        and #$0F	; mask out the least significant digit
        sta Temp
        asl
        asl
        adc Temp	; multiply by 5
        tay		; -> Y
        lda #5
        sta Temp	; count down from 5
.loop1
        lda DigitsBitmap,y
        and #$0F	; mask out leftmost digit
        sta FontBuf,x	; store leftmost digit
        iny
        inx
        dec Temp
        bne .loop1
; Now do the 2nd digit
        pla		; restore original BCD number
        lsr
        lsr
        lsr
        lsr		; shift right by 4 (in BCD, divide by 10)
        sta Temp
        asl
        asl
        adc Temp	; multiply by 5
        tay		; -> Y
        dex
        dex
        dex
        dex
        dex		; subtract 5 from X (reset to original)
        lda #5
        sta Temp	; count down from 5
.loop2
        lda DigitsBitmap,y
        and #$F0	; mask out leftmost digit
        ora FontBuf,x	; combine left and right digits
        sta FontBuf,x	; store combined digits
        iny
        inx
        dec Temp
        bne .loop2
	rts

	org $FF00

;;; Playfield data for cards

; Before game starts
PFData0
        .byte #%11100000

PFData1
        .byte #%11111000

PFData2
        .byte #%00000000

; For flipped cards

PFDataFlipped1
        .byte #%11111001


; For flipped cards, top/bottom

PFDataFlippedEnd2
        .byte #%01111111

; For flipped cards, middle
PFDataFlippedMiddle2
        .byte #%01000000

; Bitmap pattern for digits
DigitsBitmap
	.byte $0E ; |    XXX |
	.byte $0A ; |    X X |
	.byte $0A ; |    X X |
	.byte $0A ; |    X X |
	.byte $0E ; |    XXX |
	
	.byte $22 ; |  X   X | 
	.byte $22 ; |  X   X | 
	.byte $22 ; |  X   X | 
	.byte $22 ; |  X   X | 
	.byte $22 ; |  X   X | 
	
	.byte $EE ; |XXX XXX | 
	.byte $22 ; |  X   X | 
	.byte $EE ; |XXX XXX | 
	.byte $88 ; |X   X   | 
	.byte $EE ; |XXX XXX | 
	
	.byte $EE ; |XXX XXX | 
	.byte $22 ; |  X   X | 
	.byte $66 ; | XX  XX | 
	.byte $22 ; |  X   X | 
	.byte $EE ; |XXX XXX | 

	.byte $AA ; |X X X X | 
	.byte $AA ; |X X X X | 
	.byte $EE ; |XXX XXX | 
	.byte $22 ; |  X   X | 
	.byte $22 ; |  X   X | 

	.byte $EE ; |XXX XXX | 
	.byte $88 ; |X   X   | 
	.byte $EE ; |XXX XXX | 
	.byte $22 ; |  X   X | 
	.byte $EE ; |XXX XXX | 
	
	.byte $EE ; |XXX XXX | 
	.byte $88 ; |X   X   | 
	.byte $EE ; |XXX XXX | 
	.byte $AA ; |X X X X | 
	.byte $EE ; |XXX XXX | 
	
	.byte $EE ; |XXX XXX | 
	.byte $22 ; |  X   X | 
	.byte $22 ; |  X   X | 
	.byte $22 ; |  X   X | 
	.byte $22 ; |  X   X | 
	
	.byte $EE ; |XXX XXX | 
	.byte $AA ; |X X X X | 
	.byte $EE ; |XXX XXX | 
	.byte $AA ; |X X X X | 
	.byte $EE ; |XXX XXX | 
	
	.byte $EE ; |XXX XXX | 
	.byte $AA ; |X X X X | 
	.byte $EE ; |XXX XXX | 
	.byte $22 ; |  X   X | 
	.byte $EE ; |XXX XXX | 	

; Epilogue
	org $fffc

	.word Start
	.word Start