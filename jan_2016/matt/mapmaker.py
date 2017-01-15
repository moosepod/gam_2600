""" Python script to convert ascii map files to playfield byte maps for the game.
    Needs to always output 192 lines with some buffer on top/bottom. Maps have a width of 20 and are reflected """

TOTAL_HEIGHT=192
SCOREBOARD_HEIGHT=12
BORDER_WIDTH=10

MAP_ROW_SIZE=20

# x is a base wall
# o is a wall only on the reflected side. can only be used in columns 2-4 (0-indexed)
#            cccc         cccxx              
MAP_DATA=['x....xxx....xxxxx..x',
		  'xxxx.....xx.......xx',
		  'x..xxxxxxxxxxxxxx..x',
		  'x...x....xx.....xx.x',
		  'x.x.x.xx.xx.xxx.xx.x',
		  'x.x....x.xx.x...xx.x',
		  'x.xxxxxx.xx.xxx....x',
		  'x..x..........xxxxxx'] 

# This pattern can be used for checking the alignment of the async playfield
# MAP_DATA=['x.xxxxx.x.x.x.....x.',
# 		  '.xxxxxxx.x.x.x.....x',
# 		  'x.xxxxx.x.x.x.....x.',
# 		  '.xxxxxxx.x.x.x.....x',
# 		  'x.xxxxx.x.x.x.....x.',
# 		  '.xxxxxxx.x.x.x.....x',
# 		  'x.xxxxx.x.x.x.....x.',
# 		  '.xxxxxxx.x.x.x.....x',
# 		  ]

def parse_map_data(data):
	rows = []
	for line in data:
		row = []
		rows.append(row)
		cells = line.replace('.','0').replace('x','1')
		row.extend((cells[1],cells[1],cells[0],cells[0]))
		row.extend((cells[2],cells[2],cells[3],cells[3],cells[4],cells[4],cells[5],cells[5]))
		row.extend((cells[9],cells[9],cells[8],cells[8],cells[7],cells[7],cells[6],cells[6]))
		row.extend((cells[17],cells[17],cells[16],cells[16],cells[15],cells[15],cells[14],cells[14]))
	return rows

def main():
	map_data = parse_map_data(MAP_DATA)
	map_data.reverse() # byte order should be opposite of visual ordering 
	print 
	print "PFData0"
	for i in range(0,BORDER_WIDTH):
		print ' .byte #%11110000'
	for row in map_data:
		for i in range(0,MAP_ROW_SIZE):
			print ' .byte #%' + ''.join(row[0:4]) + '0000'
	for i in range(0,BORDER_WIDTH):
		print ' .byte #%11110000'
	for i in range(0,SCOREBOARD_HEIGHT):
		print ' .byte #%00000000'

	print ''
	print "PFData1"
	for i in range(0,BORDER_WIDTH):
		print ' .byte #%00111111'
	for row in map_data:
		for i in range(0,MAP_ROW_SIZE):
			print ' .byte #%' + ''.join(row[4:12])
	for i in range(0,BORDER_WIDTH):
		print ' .byte #%11111111'
	for i in range(0,SCOREBOARD_HEIGHT):
		print ' .byte #%00000000'

	print ''
	print "PFData2"
	for i in range(0,BORDER_WIDTH):
		print ' .byte #%11111111'
	for row in map_data:
		for i in range(0,MAP_ROW_SIZE):
			print ' .byte #%' + ''.join(row[12:20]	)
	for i in range(0,BORDER_WIDTH):
		print ' .byte #%11111111'
	for i in range(0,SCOREBOARD_HEIGHT):
		print ' .byte #%00000000'

	print ''
	print "PFData3"
	for i in range(0,BORDER_WIDTH-1): # not sure why but this needs to be one row shorter here and one longer at end
		print ' .byte #%11111111'
	for row in map_data:
		for i in range(0,MAP_ROW_SIZE):
			print ' .byte #%' + ''.join(row[20:28])
	for i in range(0,BORDER_WIDTH):
		print ' .byte #%11111111'
	for i in range(0,SCOREBOARD_HEIGHT+1):
		print ' .byte #%00000000'


if __name__ == "__main__":
    main()
