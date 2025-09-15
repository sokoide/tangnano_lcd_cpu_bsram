# Repository Guidelines

## Project Structure & Module Organization
- `src/`: SystemVerilog sources (`top.sv`, `lcd.sv`, `cpu*.sv`, `ram.sv`) and testbenches `tb_*.sv`. Vendor IP lives under `src/gowin_*`.
- `include/`: Shared headers and generated files (`consts.svh`, `boot_program.sv` [generated], `cpu_ifo_auto_generated.sv` [generated], `cpu_tasks.sv`).
- `examples/`: 6502 assembly programs and Makefile that generates `include/boot_program.sv`.
- `utils/`: Helper tools (e.g., `utils/hex_fpga/` Go converter).
- `impl/pnr/`: Build outputs (e.g., `lcd_cpu_bsram.fs`, `lcd_cpu_bsram.vo`).
- Docs: `DEVELOPER.md`, architecture notes in `docs/` and `README*`.

## Build, Test, and Development Commands
- `make` — Run Gowin flow via `proj.tcl`; emits `impl/pnr/lcd_cpu_bsram.fs`.
- `make download` — Program Tang Nano (SRAM) via `programmer_cli`.
- `make clean` — Remove local build artifacts.
- `cd examples && make` — Assemble 6502 program and regenerate `include/boot_program.sv`.
- `make wave` — Open `gtkwave` on `waveform.vcd` (produce VCD in your simulator first).
- Board variant: update `DEVICE` in `Makefile`, device/constraints in `lcd_cpu_bsram.gprj`, and reset polarity in `src/top.sv`.

## Coding Style & Naming Conventions
- SystemVerilog: 2-space indent, no tabs; one module per file; keep concise header comments.
- Names: files/modules `lower_snake_case`; constants/parameters `UPPER_SNAKE_CASE`; signals `lower_snake_case`; testbenches `tb_*.sv`.
- Avoid magic numbers—use `include/consts.svh`. Keep interfaces and timing explicit.
- Do not edit generated/vendor files: `include/boot_program.sv`, `include/cpu_ifo_auto_generated.sv`, `src/gowin_*/`.

## Testing Guidelines
- Testbenches: `tb_cpu.sv`, `tb_lcd.sv`, `tb_top.sv`. Run with your SV simulator; emit `waveform.vcd` for inspection and `make wave`.
- Aim for coverage of CPU instruction paths, memory, and LCD timing. Add minimal repros under `examples/` when fixing bugs.

## Commit & Pull Request Guidelines
- Commit style: Conventional prefixes (`feat`, `fix`, `refactor`, `docs`, `remove`, `update`, `improve`).
- PRs must include: clear description (what/why), affected modules, testing evidence (VCD snapshot or hardware notes/logs), and reproduction steps. Link related issues.

## Configuration Tips
- Gowin EDA paths in `Makefile` (`GWSH`, `PRG`) target macOS defaults. Adjust environment or paths if installed elsewhere.
