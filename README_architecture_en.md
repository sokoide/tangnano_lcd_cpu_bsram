# 6502 CPU Core Architecture

This project implements a 6502 CPU core with custom extensions on Tang Nano 9K/20K (GOWIN) FPGAs. The design integrates a text LCD controller and on-chip RAM/VRAM.

## System Overview

Clocking and subsystems:
- 27 MHz crystal input → two PLLs
  - rPLL9: 9 MHz for the LCD controller
  - rPLL40: 40.5 MHz for CPU, RAM, and VRAM

Data paths:
- CPU subsystem (40.5 MHz): 6502 core, 32 KB SDPB RAM, boot program ROM (generated include)
- Display subsystem (9 MHz): LCD controller, 1 KB VRAM (SDPB), 4 KB font PROM
- The CPU writes text codes to VRAM; the LCD controller reads VRAM and PROM to render 480×272 characters (60×17)

## Execution Pipeline

Instruction flow is staged for clarity and timing closure:
1. FETCH_OPCODE: fetch opcode, precompute `pc+1/2/3` for next accesses
2. FETCH_OPERAND1/2: fetch immediate/operand bytes as needed
3. DECODE_EXECUTE: decode and execute, including memory cycles and custom ops

The state machine is explicit; multi-cycle operations advance via a byte counter and latch memory reads.

## Memory Architecture

Logical map (CPU view):
- 0x0000–0x00FF: Zero Page (256 B)
- 0x0100–0x01FF: Stack (256 B)
- 0x0200–0x7BFF: Program RAM (≈30.5 KB)
- 0x7C00–0x7FFF: Shadow VRAM (1 KB, read-only to CPU)
- 0xE000–0xE3FF: Text VRAM (1 KB, write-only from CPU)
- Font PROM is accessed by the LCD controller only (not CPU-mapped)

Text layout: 60 columns × 17 rows, each character 8×16 pixels; nominal refresh ≈58 Hz at 9 MHz with porch totals.

## Custom Instructions

Additional opcodes extend convenience for display and debug:
- CVR (0xCF): Clear VRAM — hardware-accelerated VRAM clear
- IFO (0xDF): Info/Debug — dump registers and memory window
- HLT (0xEF): Halt — stop CPU execution, LCD continues
- WVS (0xFF): Wait VSync — wait N VSYNC periods for display sync

## Build Notes (Makefile)

- Default build: `make` (BOARD=9k)
- Build for 20K: `make BOARD=20k`
- Device override: `make DEVICE=GW2AR-18C`
- Program SRAM: `make download`
- Optional QC: `make lint` (Verilator), `make format` (Verible)
- When switching boards, also update `lcd_cpu_bsram.gprj` (device/constraints) and reset polarity in `src/top.sv`.

Tool paths:
- macOS defaults are embedded; override per call if needed:
  `make GWSH=/path/to/gw_sh PRG=/path/to/programmer_cli`
- Linux typical paths: `/opt/GowinEDA/IDE/bin/gw_sh`, `/opt/GowinEDA/Programmer/bin/programmer_cli`
