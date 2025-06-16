# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Tang Nano 9K/20K FPGA project implementing a 6502 CPU with LCD controller and BSRAM. It displays text on a 480x272 LCD module using a custom 6502 CPU implementation in SystemVerilog.

**Key Components:**
- 6502 CPU core (`src/cpu.sv`) with most standard instructions plus custom extensions
- LCD controller (`src/lcd.sv`) for 480x272 display timing
- Text-based VRAM system with font ROM
- Assembly program pipeline using cc65 toolchain

## Build Commands

### FPGA Synthesis and Programming
```bash
# Build FPGA bitstream
make

# Download to Tang Nano (SRAM programming)
make download

# Clean build artifacts
make clean
```

### Assembly Programs
```bash
cd examples
# Prerequisites: brew install srecord cc65 (or apt install on Linux)

# Build assembly program and generate SystemVerilog include
make clean
make

# Edit examples/Makefile SRCS variable to choose program:
# SRCS = simple.s        # Basic example
# SRCS = hello_world.s   # Hello world with scrolling
# etc.
```

## Architecture

### Memory Map
- `0x0000-0x00FF`: Zero Page (256B)
- `0x0100-0x01FF`: Stack (256B) 
- `0x0200-0x7BFF`: RAM (30.5KB) - Program starts at 0x0200
- `0x7C00-0x7FFF`: Shadow VRAM (1KB) - CPU-readable copy of VRAM
- `0xE000-0xE3FF`: Text VRAM (1KB) - Write-only for CPU
- `0xF000-0xFFFF`: Font ROM (4KB) - Not CPU accessible, used by LCD controller

### Custom 6502 Instructions
- `0xCF`: CVR - Clear VRAM
- `0xDF`: IFO - Info (show registers and memory for debugging)
- `0xEF`: HLT - Halt CPU
- `0xFF`: WVS - Wait for VSync

### Text Display
- 60 columns × 17 rows text mode
- 16×8 pixel font characters
- Font data from Sweet16Font (boost licensed)

## Development Workflow

1. **Assembly Development**: Edit `.s` files in `examples/`, modify `examples/Makefile` SRCS variable
2. **Auto-generation**: Assembly programs are converted to SystemVerilog via `utils/hex_fpga/` tool
3. **FPGA Build**: `include/boot_program.sv` is auto-generated and included in synthesis
4. **Device Configuration**: Toggle between Tang Nano 9K/20K by editing `Makefile`, `.gprj`, and `src/top.sv`

## Testing

**Simulation**: Use DSIM Studio on Linux/Windows x64 (not macOS):
- Open `lcd_cpu_bsram.dpf` project
- Run "library configuration" then `tb_cpu` simulation
- Testbenches: `tb_cpu.sv`, `tb_lcd.sv`, `tb_top.sv`

## Device Variants

**Tang Nano 9K vs 20K**: Three files need modification:
1. `Makefile`: DEVICE variable
2. `lcd_cpu_bsram.gprj`: Device and constraint file selection  
3. `src/top.sv`: Reset button polarity (`rst_n = ResetButton` vs `rst_n = !ResetButton`)

## Key Files

- `src/cpu.sv`: 6502 CPU implementation with custom instructions
- `src/lcd.sv`: LCD timing controller
- `src/top.sv`: Top-level module with PLL and interconnects
- `include/boot_program.sv`: Auto-generated from assembly programs
- `include/consts.svh`: Memory map and LCD timing constants