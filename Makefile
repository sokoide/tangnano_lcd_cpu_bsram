SRCS= \
	include/consts.svh \
	include/boot_program.sv \
	include/cpu_ifo_auto_generated.sv \
	include/cpu_tasks.sv \
	src/top.sv \
	src/lcd.sv \
	src/ram.sv \
	src/cpu.sv \
	src/cpu_decoder.sv \
	src/cpu_alu.sv \
	src/cpu_memory.sv \
	src/gowin_sdpb/gowin_sdpb.v \
	src/gowin_sdpb/gowin_sdpb_vram.v \
	src/gowin_prom/gowin_prom_font.v \
	impl/pnr/lcd_cpu_bsram.vo

# src/gowin_rpll_9K/gowin_rpll9.v \
# src/gowin_rpll_9K/gowin_rpll40.v \

export BASE=lcd_cpu_bsram
PROJ=$(BASE).gprj

#--------------------------------------------------
# Board selection and device mapping
#   Override on command line: `make BOARD=20k`
#   Or set DEVICE directly:   `make DEVICE=GW2AR-18C`
#--------------------------------------------------
BOARD ?= 9k
ifeq ($(origin DEVICE), undefined)
  ifeq ($(BOARD),9k)
    DEVICE := GW1NR-9C
  else ifeq ($(BOARD),20k)
    DEVICE := GW2AR-18C
  else
    $(error Unknown BOARD '$(BOARD)'; use 9k or 20k, or set DEVICE explicitly)
  endif
endif

FS=$(PWD)/impl/pnr/$(BASE).fs

# Tool paths (override if installed elsewhere)
GWSH ?= /Applications/GowinEDA.app/Contents/Resources/Gowin_EDA/IDE/bin/gw_sh
PRG  ?= /Applications/GowinEDA.app/Contents/Resources/Gowin_EDA/Programmer/bin/programmer_cli

export PATH

.PHONY: clean wave download help lint format format-check tools-check

$(FS): $(SRCS) tools-check
	$(GWSH) proj.tcl

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

#--------------------------------------------------
# Helpers
#--------------------------------------------------
help:
	@echo "Targets:"
	@echo "  make                - Build FPGA bitstream ($(FS))"
	@echo "  make download       - Program Tang Nano SRAM (DEVICE=$(DEVICE))"
	@echo "  make clean          - Remove build artifacts"
	@echo "  make lint           - Verilator lint (excludes vendor IP)"
	@echo "  make format         - Verible format (in-place)"
	@echo "  make wave           - Open waveform.vcd in GTKWave"
	@echo "Variables:"
	@echo "  BOARD=9k|20k        - Select board (maps DEVICE if DEVICE unset)"
	@echo "  DEVICE=...          - Override explicit device code"
	@echo "Note: Also update lcd_cpu_bsram.gprj and src/top.sv for board switch."

# Tool availability check (portable): accepts absolute path or PATH lookup
tools-check:
	@# Check gw_sh
	@if [ -x "$(GWSH)" ] || command -v "$$(basename "$(GWSH)")" >/dev/null 2>&1; then \
	  : ; \
	else \
	  echo "[ERROR] gw_sh not found. Set GWSH=/path/to/gw_sh" >&2; exit 1; \
	fi
	@# Check programmer_cli
	@if [ -x "$(PRG)" ] || command -v "$$(basename "$(PRG)")" >/dev/null 2>&1; then \
	  : ; \
	else \
	  echo "[ERROR] programmer_cli not found. Set PRG=/path/to/programmer_cli" >&2; exit 1; \
	fi

# Lint (exclude vendor IP and generated verilog outputs)
LINT_SRCS := $(filter-out src/gowin_% impl/pnr/%,$(SRCS))
lint:
	@if command -v verilator >/dev/null 2>&1; then \
	  echo "[lint] verilator --lint-only -Wall $(LINT_SRCS)"; \
	  verilator --lint-only -Wall $(LINT_SRCS); \
	else \
	  echo "[WARN] verilator not found. Install Verilator or skip lint."; \
	fi

# Format SystemVerilog (in-place) excluding vendor IP
FORMAT_FILES := $(shell find src include -type f \( -name '*.sv' -o -name '*.svh' \) ! -path 'src/gowin_*/*')
format:
	@if command -v verible-verilog-format >/dev/null 2>&1; then \
	  verible-verilog-format --inplace $(FORMAT_FILES); \
	else \
	  echo "[WARN] verible-verilog-format not found. Install Verible or skip format."; \
	fi
