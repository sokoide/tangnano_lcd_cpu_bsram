# Tang Nano LCD + 8bit CPU + BSRAM example

## About

* Tang Nano 9K or 20K + 043026-N6(ML) 4.3 inch 480x272 LCD module example
* Change Makefile, Select Device and update the `.cst` file for 20K
* The CPU is like 6502

## 043026-N6(ML) LCD spec

### Interface PIN connections

| Pin No. | Symbol | Function |
|---------|--------|----------|
| 1       | LEDK   | Back light power supply negative |
| 2       | LEDA   | Back light power supply positive |
| 3       | GND    | Ground |
| 4       | VCC    | Power supply |
| 5-12    | R0-R7  | Red Data |
| 13-20   | G0-G7  | Green Data |
| 21-28   | B0-B7  | Blue Data |
| 29      | GND    | Ground |
| 30      | CLK    | Clock signal |
| 31      | DISP   | Display on/off |
| 32      | HSYNC  | Horizontal sync input in RGB mode (short to GND if not used) |
| 33      | VSYNC  | Vertical sync input in RGB mode (short to GND if not used) |
| 34      | DE     | Data enable |
| 35      | NC     | No Connection |
| 36      | GND    | Ground |
| 37      | XR     | Touch panel X-right |
| 38      | YD     | Touch panel Y-bottom |
| 39      | XL     | Touch panel X-left |
| 40      | YU     | Touch panel Y-up |


### Parallel RGP Input Timing

| Item   | Symbol| Values (Min.) | Values (Typ.) | Values (Max.) | Unit  | Remark |
|--------|-------|---------------|---------------|---------------|-------|--------|
| DCLK Frequency | Fclk    | 8    | 9    | 12   | MHz  ||
| **Hsync**      |         |      |      |      |      ||
| Period time    | Th      | 485  | 531  | 589  | DCLK ||
| Display Period | Thdisp  | -    | 480- | -    | DCLK ||
| Back Porch     | Thbp    | 3    | 43   | 43   | DCLK ||
| Front Porch    | Thfp    | 2    | 4    | 75   | DCLK ||
| **Vsync**      |         |      |      |      |      ||
| Period time    | Tv      | 276  | 292  | 321  | H    ||
| Display Period | Tvdisp  | -    | 272  | -    | H    ||
| Back Porch     | Tvbp    | 2    | 12   | 12   | H    ||
| Front Porch    | Tvfp    | 2    | 4    | 37   | H    ||

### Sync Mode

![sync](./docs/lcd_sync.png)

### Sync DE Mode

![sync DE](./docs/lcd_sync_de.png)

## Example

![lcd](./docs/lcd.jpg)

## Implemented Instructions

* '+': implemented
* ' ': todo
* '-': not going to be implemented
* '*': special instruction not available in 6502

|     | 0x0 | 0x1 | 0x2 | 0x3 | 0x4 | 0x5 | 0x6 | 0x7 | 0x8 | 0x9 | 0xA | 0xB | 0xC | 0xD | 0xE | 0xF |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| 0x0 | BRK | ORA |     |     |     | ORA | ASL |     | PHP | ORA | ASL |     |     | ORA | ASL |     |
|     | impl| idx |     |     |     | zp  | zp  |     | impl| imm | acc |     |     | abs | abs |     |
|     | -   |     |     |     |     |     | +   |     |     |     | +   |     |     |     | +   |     |
| 0x1 | BPL | ORA |     |     |     | ORA | ASL |     | CLC | ORA |     |     |     | ORA | ASL |     |
|     | rel | idy |     |     |     | zpx | zpx |     | impl| aby |     |     |     | abx | abx |     |
|     | +   |     |     |     |     |     | +   |     | +   |     |     |     |     |     | +   |     |
| 0x2 | JSR | AND |     |     | BIT | AND | ROL |     | PLP | AND | ROL |     | BIT | AND | ROL |     |
|     | abs | idx |     |     | zp  | zp  | zp  |     | impl| imm | acc |     | abs | abs | abs |     |
|     |     |     |     |     | +   | +   |     |     |     | +   |     |     | +   | +   |     |     |
| 0x3 | BMI | AND |     |     |     | AND | ROL |     | SEC | AND |     |     |     | AND | ROL |     |
|     | rel | idy |     |     |     | zpx | zpx |     | impl| aby |     |     |     | abx | abx |     |
|     | +   |     |     |     |     | +   |     |     |     | +   |     |     |     | +   |     |     |
| 0x4 | RTI | EOR |     |     |     | EOR | LSR |     | PHA | EOR | LSR |     | JMP | EOR | LSR |     |
|     | impl| idx |     |     |     | zp  | zp  |     | impl| imm | acc |     | abs | abs | abs |     |
|     | -   |     |     |     |     | +   |     |     |     | +   |     |     | +   | +   |     |     |
| 0x5 | BVC | EOR |     |     |     | EOR | LSR |     | CLI | EOR |     |     |     | EOR | LSR |     |
|     | rel | idy |     |     |     | zpx | zpx |     | impl| aby |     |     |     | abx | abx |     |
|     | +   |     |     |     |     | +   |     |     | -   | +   |     |     |     | +   |     |     |
| 0x6 | RTS | ADC |     |     |     | ADC | ROR |     | PLA | ADC | ROR |     | JMP | ADC | ROR |     |
|     | impl| idx |     |     |     | zp  | zp  |     | impl| imm | acc |     | ind | abs | abs |     |
|     |     |     |     |     |     | +   |     |     |     | +   |     |     |     | +   |     |     |
| 0x7 | BVS | ADC |     |     |     | ADC | ROR |     | SEI | ADC |     |     |     | ADC | ROR |     |
|     | rel | idy |     |     |     | zpx | zpx |     | impl| aby |     |     |     | abx | abx |     |
|     | +   |     |     |     |     | +   |     |     |     | +   |     |     |     | +   |     |     |
| 0x8 |     | STA |     |     | STY | STA | STX |     | DEY |     | TXA |     | STY | STA | STX |     |
|     |     | idx |     |     | zp  | zp  | zp  |     | impl|     | impl|     | abs | abs | abs |     |
|     |     |     |     |     |     | +   |     |     | +   |     | +   |     |     | +   |     |     |
| 0x9 | BCC | STA |     |     | STY | STA | STX |     | TYA | STA | TXS |     |     | STA |     |     |
|     | rel | idy |     |     | zpx | zpx | zpy |     | impl| aby | impl|     |     | abx |     |     |
|     | +   |     |     |     |     | +   |     |     | +   | +   |     |     |     | +   |     |     |
| 0xA | LDY | LDA | LDX |     | LDY | LDA | LDX |     | TAY | LDA | TAX |     | LDY | LDA | LDX |     |
|     | imm | idx | imm |     | zp  | zp  | zp  |     | impl| imm | impl|     | abs | abs | abs |     |
|     | +   | +   |     |     | +   | +   | +   |     | +   | +   | +   |     | +   | +   | +   |     |
| 0xB | BCS | LDA |     |     | LDY | LDA | LDX |     | CLV | LDA | TSX |     | LDY | LDA | LDX |     |
|     | rel | idy |     |     | zpx | zpx | zpy |     | impl| aby | impl|     | abx | abx | aby |     |
|     | +   |     |     |     | +   | +   | +   |     |     | +   |     |     | +   | +   | +   |     |
| 0xC | CPY | CMP |     |     | CPY | CMP | DEC |     | INY | CMP | DEX |     | CPY | CMP | DEC |     |
|     | imm | idx |     |     | zp  | zp  | zp  |     | impl| imm | impl|     | abs | abs | abs |     |
|     | +   |     |     |     | +   | +   | +   |     | +   | +   | +   |     | +   | +   | +   |     |
| 0xD | BNE | CMP |     |     |     | CMP | DEC |     | CLD | CMP |     |     |     | CMP | DEC |     |
|     | rel | idy |     |     |     | zpx | zpx |     | impl| aby |     |     |     | abx | abx |     |
|     | +   |     |     |     |     | +   | +   |     | -   | +   |     |     |     | +   | +   |     |
| 0xE | CPX | SBC |     |     | CPX | SBC | INC |     | INX | SBC | NOP |     | CPX | SBC | INC |     |
|     | imm | idx |     |     | zp  | zp  | zp  |     | impl| imm | impl|     | abs | abs | abs |     |
|     | +   |     |     |     | +   |     |     |     | +   |     |+    |     | +   |     |     |     |
| 0xF | BEQ | SBC |     |     |     | SBC | INC |     | SED | SBC |     |     |     | SBC | INC |     |
|     | rel | idy |     |     |     | zpx | zpx |     | impl| aby |     |     |     | abx | abx |     |
|     | +   |     |     |     |     |     |     |     | -   |     |     |     |     |     |     |     |

## 6502 Addressing Modes - Legend

| Abbrev | Full Name    | Description                                                                 |
|--------|--------------|-----------------------------------------------------------------------------|
| impl   | Implied      | No operand needed. Used for instructions like `CLC`, `RTS`, `SEI`, etc.     |
| acc    | Accumulator  | Operates directly on the accumulator (A register), e.g., `ASL A`            |
| imm    | Immediate    | The operand is a constant value, e.g., `LDA #$01`                           |
| zp     | Zero Page    | Uses a one-byte address ($00–$FF), e.g., `LDA $10`                          |
| zpx    | Zero Page,X  | Zero page address plus the X register, e.g., `LDA $10,X`                    |
| zpy    | Zero Page,Y  | Zero page address plus the Y register, e.g., `LDX $10,Y`                    |
| abs    | Absolute     | Full 16-bit address, e.g., `LDA $1234`                                      |
| abx    | Absolute,X   | Absolute address plus X, e.g., `LDA $1234,X`                                |
| aby    | Absolute,Y   | Absolute address plus Y, e.g., `LDA $1234,Y`                                |
| ind    | Indirect     | Used only with `JMP`, jumps to the address stored at the given address, e.g., `JMP ($1234)` |
| idx    | (Indirect,X) | Indirect address from zero page plus X, e.g., `LDA ($10,X)`                 |
| idy    | (Indirect),Y | Indirect address from zero page, then add Y, e.g., `LDA ($10),Y`            |
| rel    | Relative     | Offset relative to the program counter (used for branches), e.g., `BEQ $10`|


## Memory Map

```text
Total 8KB RAM:
0x0000-0x00FF: Zero Page (256B)
0x0100-0x01FF: Stack (256B)
0x0200-0x3FFF: RAM (7.5KB)

Total 1KB VRAM (SDPB):
0xE000-0xE3FF: Text VRAM (1KB)
```

## Font ROM

```text
Total 4KB Font ROM (pROM):
0xF000-0xFFFF: Font ROM (4KB)
  16x8 ‎ = 128bits = 16bytes / char
  16 bytes x 256 chars ‎ =  4KB
```