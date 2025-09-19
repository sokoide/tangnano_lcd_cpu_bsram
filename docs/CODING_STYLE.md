# Coding Style (SystemVerilog)

- Indentation: 2 spaces, no tabs. One module per file.
- Filenames and module names: `lower_snake_case` (e.g., `cpu_decoder.sv`).
- Constants/parameters/macros: `UPPER_SNAKE_CASE` (prefer `include/consts.svh`).
- Signals/variables: `lower_snake_case`.
- Testbenches: `tb_*.sv` naming.
- Avoid magic numbers; factor into parameters/localparams or `consts.svh`.
- Keep header comments: purpose, ports, timing, reset, CDC, assumptions.
- Do not edit generated/vendor sources:
  - `include/boot_program.sv`, `include/cpu_ifo_auto_generated.sv`
  - `src/gowin_*/`, `impl/pnr/*.vo`

Formatting tools (optional):
- `verible-verilog-format --inplace ...` for formatting
- `verilator --lint-only -Wall ...` for linting feedback
