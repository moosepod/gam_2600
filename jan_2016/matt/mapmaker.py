""" Python script to convert ascii map files to playfield byte maps for the game.
    Needs to always output 192 lines with some buffer on top/bottom. Maps have a width of 20 and are reflected """

TOTAL_HEIGHT=192
SCOREBOARD_HEIGHT=12
BORDER_WIDTH=10

MAP_ROW_SIZE=20

# x is a base wall
# o is a wall only on the reflected side. can only be used in columns 2-4 (0-indexed)
MAP_DATA=['x..o...x..',
		  'x..x.x...x',
		  'x..xxxxxxx',
		  'x.........',
		  'xxxxxxxx.x',
		  'x......x.x',
		  'x.xxxxxx.x',
		  'x.........']

def parse_map_data(data):
	rows = []
	for line in data:
		row = []
		rows.append(row)
		cells = line.replace('.','0').replace('x','1').replace('o','0')
		row.extend((cells[1],cells[1],cells[0],cells[0]))
		row.extend((cells[2],cells[2],cells[3],cells[3],cells[4],cells[4],cells[5],cells[5]))
		row.extend((cells[9],cells[9],cells[8],cells[8],cells[7],cells[7],cells[6],cells[6]))
		cells = line.replace('.','0').replace('x','1').replace('o','1')
		row.extend((cells[2],cells[2],cells[3],cells[3],cells[4],cells[4],cells[5],cells[5]))
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
		print ' .byte #%11111111'
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
	for i in range(0,BORDER_WIDTH):
		print ' .byte #%11111111'
	for row in map_data:
		for i in range(0,MAP_ROW_SIZE):
			print ' .byte #%' + ''.join(row[20:28])
	for i in range(0,BORDER_WIDTH):
		print ' .byte #%11111111'
	for i in range(0,SCOREBOARD_HEIGHT):
		print ' .byte #%00000000'


if __name__ == "__main__":
    main()
