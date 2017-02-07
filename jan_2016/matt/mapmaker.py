""" Python script to convert ascii map files to playfield byte maps for the game.
    Needs to always output 192 lines with some buffer on top/bottom. Maps have a width of 20 and are reflected """

MAP_ROW_SIZE=32

# x is a base wall
# o is a wall only on the reflected side. can only be used in columns 2-4 (0-indexed)
#            cccc         cccxx      

# Test pattern -- will form a checkerboard       
# MAP_DATA=['x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
# 		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
# 		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
# 		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
# 		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
# 		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
# 		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
# 		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
# 		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
# 		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
# 		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
# 		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
# 		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
# 		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
# 		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
# 		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
# 		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
# 		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
# 		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
# 		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
# 		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
# 		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
# 		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
# 		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x']

# Template for making our own mazes
# MAP_DATA=['xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
# 		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx']	

MAP_DATA=['x.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
		  'x.x............................x',
		  'x.x.xxxxxxxxxxxxxxxxxxxxxxxxxx.x',
		  'x.x.x.......................xx.x',
		  'x.x.x.xxxxxxxxxxxxxxxxxxxxx.xx.x',
		  'x.x.x.xx.................xx.xx.x',
		  'x.x.x.xx.xxxxxxxxxxxxxxx.xx.xx.x',
		  'x.x.x.xx.x............xx.xx.xx.x',
		  'x.x.x.xx.x.xxxxxxxxxx.xx.xx.xx.x',
		  'x.x.x.xx.x.x........x.xx.xx.xx.x',
		  'x.x.x.xx.x.x.xxxxxx.x.xx.xx.xx.x',
		  'x.x.x.xx.x.x.xxxx.x.x.xx.xx.xx.x',
		  'x.x.x.xx.x.x......x.x.xx.xx.xx.x',
		  'x.x.x.xx.x.xxxxxxxx.x.xx.xx.xx.x',
		  'x.x.x.xx.x..........x.xx.xx.xx.x',
		  'x.x.x.xx.xxxxxxxxxxxx.xx.xx.xx.x',
		  'x.x.x.xx..............xx.xx.xx.x',
		  'x.x.x.xxxxxxxxxxxxxxxxxx.xx.xx.x',
		  'x.x.x....................xx.xx.x',
		  'x.x.xxxxxxxxxxxxxxxxxxxxxxx.xx.x',
		  'x.x.........................xx.x',
		  'x.xxxxxxxxxxxxxxxxxxxxxxxxxxxx.x',
		  'x..............................x',
		  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx']	

def parse_map_data(data):
	rows = []
	for line in data:
		row = []
		rows.append(row)
		cells = line.replace('.','0').replace('x','1')
		row.extend(cells[0:8])
		row.extend(reversed(list(cells[8:16])))
		row.extend(cells[16:24])
		row.extend(reversed(list(cells[24:32])))
	return rows

def main():
	map_data = parse_map_data(MAP_DATA)
	map_data.reverse() # byte order should be opposite of visual ordering 
	print ''
	print 'PFData1'
	for row in map_data:
		print ' .byte #%' + ''.join(row[0:8]) 

	print ''
	print 'PFData2'
	for row in map_data:
		print ' .byte #%' + ''.join(row[8:16]) 

	print ''
	print 'PFData5'
	for row in map_data:
		print ' .byte #%' + ''.join(row[16:24]) 

	print ''
	print 'PFData4'
	for row in map_data:
		print ' .byte #%' + ''.join(row[24:32]) 

if __name__ == "__main__":
    main()
