DASM_BIN_PATH=../../dasm/bin/dasm
DASM_INCLUDE_PATH=../../dasm/machines/atari2600/
ROM_PATH=/mnt/d/games/atari2600
PYTHON_BIN_PATH=/usr/bin/python
ROM_NAME=moosewar.bin

moosewar: 
	$(DASM_BIN_PATH) moosewar.asm -s$(ROM_PATH)/moosewar.sym -l$(ROM_PATH)/moosewar.lst -I$(DASM_INCLUDE_PATH) -I. -f3 -v5 -o$(ROM_PATH)/$(ROM_NAME)