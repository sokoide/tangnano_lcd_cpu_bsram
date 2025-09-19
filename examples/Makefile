# Prerequisites
#  Mac) brew install srecord cc65 golang
#  WSL / Linux) sudo apt install srecord cc65 golang

# SRCS = simple.s
# SRCS = simple2.s
# SRCS = simple3.s
# SRCS = simple4.s
SRCS = simple5.s
# SRCS = hello_world.s
# SRCS = hello_world_scroll.s

# target System Verilogy file path which is included by src/top.sv
SV = ../include/boot_program.sv

HEX = example.hex
HEX_FPGA_DIR = ../utils/hex_fpga
HEX_FPGA = $(HEX_FPGA_DIR)/hex_fpga
HEX_FPGA_SRCS = $(HEX_FPGA_DIR)/main.go
TARGET = example.bin
OBJS=$(SRCS:.s=.o)
LST=example.lst

CC = cc65
LD = ld65
AS = ca65
DA = da65
OD = od65
CFG = baremetal.cfg

.PHONY: all disass od clean

all: sv
	cat $(LST)

$(TARGET): $(OBJS)
	$(LD) -C $(CFG) -o $@ $<

%.o: %.s
	$(AS) -l $(LST) -o $@ $<

sv: $(HEX) $(HEX_FPGA)
	$(HEX_FPGA) -hexfile $(HEX) -svfile $(SV)
	@echo "$(SV) file written"

$(HEX_FPGA): $(HEX_FPGA_SRCS)
	cd $(HEX_FPGA_DIR); go clean; go mod tidy; go build

$(HEX): $(TARGET)
	srec_cat $(TARGET) -binary -offset 0x0200 -o $(HEX) -Intel

disass: $(TARGET)
	$(DA) $<

od: $(OBJS)
	$(OD) --dump-all $<

clean:
	rm -rf tags $(OBJS) $(TARGET) *.hex *.lst
