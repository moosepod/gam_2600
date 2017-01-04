""" Python script to convert ascii map files to playfield byte maps for the game.
    Needs to always output 192 lines with some buffer on top/bottom. Maps have a width of 20 and are reflected """

TOTAL_HEIGHT=192
SCOREBOARD_HEIGHT=11
BORDER_WIDTH=10

def main():
	print "PFData0"
	for i in range(0,BORDER_WIDTH):
		print ' .byte #%11110000'
	for i in range(0,TOTAL_HEIGHT-SCOREBOARD_HEIGHT-BORDER_WIDTH-BORDER_WIDTH):
		print ' .byte #%00010000'
	for i in range(0,BORDER_WIDTH):
		print ' .byte #%11110000'
	for i in range(0,SCOREBOARD_HEIGHT):
		print ' .byte #%00000000'

	print ''
	print "PFData1"
	for i in range(0,BORDER_WIDTH):
		print ' .byte #%11111111'
	for i in range(0,TOTAL_HEIGHT-SCOREBOARD_HEIGHT-BORDER_WIDTH-BORDER_WIDTH):
		print ' .byte #%00000000'
	for i in range(0,BORDER_WIDTH):
		print ' .byte #%11111111'
	for i in range(0,SCOREBOARD_HEIGHT):
		print ' .byte #%00000000'

	print ''
	print "PFData2"
	for i in range(0,BORDER_WIDTH):
		print ' .byte #%11111111'
	for i in range(0,TOTAL_HEIGHT-SCOREBOARD_HEIGHT-BORDER_WIDTH-BORDER_WIDTH):
		print ' .byte #%00000000'
	for i in range(0,BORDER_WIDTH):
		print ' .byte #%11111111'
	for i in range(0,SCOREBOARD_HEIGHT):
		print ' .byte #%00000000'



if __name__ == "__main__":
    main()
