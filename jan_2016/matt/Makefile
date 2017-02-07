DASM_BIN_PATH=../../../dasm/bin/dasm
DASM_INCLUDE_PATH=../../../dasm/machines/atari2600/
ROM_PATH=/mnt/d/games/atari2600
PYTHON_BIN_PATH=/usr/bin/python
ROM_NAME='the_friend_ship.bin'

ogam_jan_2016: 
	cat main.asm > the_friend_ship.asm
	$(PYTHON_BIN_PATH) mapmaker.py >> the_friend_ship.asm
	cat footer.asm >> the_friend_ship.asm
	$(DASM_BIN_PATH) the_friend_ship.asm -s$(ROM_PATH)/the_friend_ship.sym -l$(ROM_PATH)/the_friend_ship.lst -I$(DASM_INCLUDE_PATH) -I. -f3 -v5 -o$(ROM_PATH)/$(ROM_NAME)