""" Python script to convert ascii map files to playfield byte maps for the game.
    Needs to always output 192 lines with some buffer on top/bottom. Maps have a width of 20 and are reflected """

MAP_ROW_SIZE=32

# x is a base wall
# o is a wall only on the reflected side. can only be used in columns 2-4 (0-indexed)
#            cccc         cccxx              
MAP_DATA=['x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
		  'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
		  '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x']

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
	print 'PFData4'
	for row in map_data:
		print ' .byte #%' + ''.join(row[16:24]) 

	print ''
	print 'PFData5'
	for row in map_data:
		print ' .byte #%' + ''.join(row[24:32]) 

if __name__ == "__main__":
    main()
