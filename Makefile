SRC=src/top.sv src/lcd.sv src/gowin_rpll/gowin_rpll.v impl/pnr/lcd_cpu_bsram.vo
TEST=src/tb_lcd.sv

export BASE=lcd_cpu_bsram
PROJ=$(BASE).gprj
# Tang Nano 20K
# DEVICE=GW2AR-18C
# Tang Nano 9K
DEVICE=GW1NR-9C

FS=$(PWD)/impl/pnr/$(BASE).fs

GWSH=/Applications/GowinEDA.app/Contents/Resources/Gowin_EDA/IDE/bin/gw_sh
PRG=/Applications/GowinEDA.app/Contents/Resources/Gowin_EDA/Programmer/bin/programmer_cli

export PATH

.PHONY: clean wave synthesize download

synthesize: $(SRC)
	$(GWSH) proj.tcl

$(FS): synthesize

# operation_index
# /Applications/GowinEDA.app/Contents/Resources/Gowin_EDA/Programmer/bin/programmer_cli -h
#  --operation_index <int>, --run <int>, -r <int>
# 0: Read Device Codes;
# 1: Reprogram;
# 2: SRAM Program;
# 3: SRAM Read;
# 4: SRAM Program and Verify;
# 5: embFlash Erase,Program;
# ...
download: $(FS)
	# SRAM
	$(PRG) --device $(DEVICE) --fsFile $(FS) --operation_index 2

wave:
	gtkwave ./waveform.vcd

clean:
	rm -rf obj_dir waveform.*
