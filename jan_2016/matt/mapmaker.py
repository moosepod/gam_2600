""" Python script to convert ascii map files to playfield byte maps for the game.
    Needs to always output 192 lines with some buffer on top/bottom. Maps have a width of 20 and are reflected """

import random

MAP_ROW_SIZE=32

# x is a base wall
# o is a wall only on the reflected side. can only be used in columns 2-4 (0-indexed)
#            cccc         cccxx      

# Test pattern -- will form a checkerboard       
# MAP_DATA=['x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
#         '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
#         'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
#         '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
#         'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
#         '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
#         'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
#         '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
#         'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
#         '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
#         'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
#         '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
#         'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
#         '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
#         'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
#         '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
#         'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
#         '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
#         'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
#         '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
#         'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
#         '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x',
#         'x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.',
#         '.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x.x']

# Template for making our own mazes
# MAP_DATA=['xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
#         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx']   

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
MAP_DATA=[
          'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
          'x.....x...............x.........x',
          'xxxxx.x.xxxxxxxxxxxxx.x.xxxxx.x.x',
          'x...x...x.x.........x.x.x.....x.x',
          'x.x.xxxxx.x.xxxxx.x.x.xxx.xxxxx.x',
          'x.x.........x.....x.x...x...x...x',
          'x.xxxxxxxxxxx.xxxxx.xxx.x.x.x.xxx',
          'x.......x.....x...x.x.x.x.x.x.x.x',
          'x.xxxxx.x.xxxxx.x.x.x.x.xxx.x.x.x',
          'x.x...x.x.....x.x.....x.....x...x',
          'x.x.x.xxxxxxx.x.xxxxx.xxxxxxxxx.x',
          'x.x.x.........x.x...x.x...x.....x',
          'xxx.x.xxxxxxx.xxx.x.xxx.x.x.xxxxx',
          'x...x.x...x...x...x.....x.x.....x',
          'x.xxx.x.x.xxxxx.xxxxxxxxx.xxxxx.x',
          'x.x...x.x.x.....x.....x...x...x.x',
          'x.xxxxx.x.x.xxxxx.xxx.x.xxx.x.x.x',
          'x.....x.x.x...x.....x.x...x.x...x',
          'x.xxx.x.x.xxx.xxxxx.x.xxx.x.xxxxx',
          'x.x.x...x...x...x...x.x...x.x...x',
          'x.x.xxxxx.xxxxx.x.xxx.x.xxx.x.xxx',
          'x.x...x...x...x...x.x.x.x...x...x',
          'x.x.x.x.xxx.x.xxxxx.x.x.x.xxxxx.x',
          'x...x.x.....x.........x.........x',
          'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
]

NORTH=0
EAST=1
SOUTH=2
WEST=3

def pick_direction(cell,rows,cols):
    """ Pick a random (valid) direction for the provided cell in the range """
    while True:
        direction = random.randint(0,3)
        if cell[0] == 0 and direction == WEST:
            continue 
        if cell[1] == 0 and direction == NORTH:
            continue 
        if cell[0] == cols-1 and direction == EAST:
            continue 
        if cell[1] == rows-1 and direction == SOUTH:
            continue 
        return direction

class Cell(object):
    def __init__(self,point):
        self.neighbors = [None,None,None,None]
        self.walls = [True,True,True,True]
        self.visited = False
        self.point = point

    def pick_random(self):
        candidates = [n for n in self.neighbors if n and not n.visited]
        if not candidates:
            return None
        neighbor = random.choice(candidates)

        # Remove wall to neighbor, reciprically 
        self.walls[self.neighbors.index(neighbor)] = False 
        neighbor.walls[neighbor.neighbors.index(self)] = False

        return neighbor

    def __repr__(self):
        return unicode(self.point)

def generate_map_cells(rows,cols):
    """ Use depth-first search algorithm https://en.wikipedia.org/wiki/Maze_generation_algorithm """
    matrix = []
    for y in range(0,rows):
        row = []
        matrix.append(row)
        for x in range(0,cols):
            row.append(Cell((y,x)))
    for y,row in enumerate(matrix):
        for x,cell in enumerate(row):
            if x > 0:
                cell.neighbors[WEST] = matrix[y][x-1]
            if x < cols-1:
                cell.neighbors[EAST] = matrix[y][x+1]
            if y > 0:
                cell.neighbors[NORTH] = matrix[y-1][x]
            if y < rows-1:
                cell.neighbors[SOUTH] = matrix[y+1][x]

    cell = matrix[0][0]
    counter = 10000
    stack = []
    while cell and counter:
        counter -= 1
        cell.visited = True
        cell = cell.pick_random()
        if not cell:
            if not stack:
                break
            cell = stack.pop()
        else:
            stack.append(cell)

    return matrix

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

def generate_map_data():
    data = []
    m = generate_map_cells(12,16)
    for i, row in enumerate(m):
        cols = []
        for cell in row:
            cols.append('x')
            if cell.walls[NORTH]:
                cols.append('x')
            else:
                cols.append('.')
        cols.append('x')
        data.append(''.join(cols))
        cols = []
        for cell in row:
            if cell.walls[WEST]:
                cols.append('x')
            else:
                cols.append('.')
            if cell.visited:
                cols.append('.')
            else:
                cols.append('x')
        cols.append('x')
        data.append(''.join(cols))
        cols = []
    for cell in row:
        cols.append('x')
        cols.append('x')
    cols.append('x')
    data.append(''.join(cols))
    return data

def main():
    map_data = parse_map_data(generate_map_data())
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

    
