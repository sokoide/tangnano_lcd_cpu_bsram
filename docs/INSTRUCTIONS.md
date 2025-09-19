## Implemented Instructions

- **+**: implemented
  - All 6502 instructions except for the followings
- **-**: not going to be implemented
  - break, interrupt related oned
- **!**: custom instruction which is not available in 6502
  - `0xCF` CVR: Clear VRAM
    - CF: (no operand) clear VRAM
  - `0xDF` IFO: Info ... show registers and memory
    - DF 0000: show registers and 0x0000-0x007F
    - DF 8000: show registers and 0x0080-0x00FF
    - DF 8010: show registers and 0x1080-0x10FF
  - `0xEF` HLT: Halt ... stop the CPU
    - EF: (no operand) stop the CPU. LCD controller continues running
  - `0xFF` WVS: Wait For VSync ... wait until the next vsync timing of the LCD
    - FF 00: wait for vsync once (~1/58 sec)
    - FF 05: wait for vsync 6 times (~6/58 sec)
    - FF 3A: wait for vsync 58 times (~1 sec)

|     | 0x0  | 0x1 | 0x2 | 0x3 | 0x4 | 0x5 | 0x6 | 0x7 | 0x8  | 0x9 | 0xA  | 0xB | 0xC | 0xD | 0xE | 0xF  |
| --- | ---- | --- | --- | --- | --- | --- | --- | --- | ---- | --- | ---- | --- | --- | --- | --- | ---- |
| 0x0 | BRK  | ORA |     |     |     | ORA | ASL |     | PHP  | ORA | ASL  |     |     | ORA | ASL |      |
|     | impl | idx |     |     |     | zp  | zp  |     | impl | imm | acc  |     |     | abs | abs |      |
|     | -    | +   |     |     |     | +   | +   |     | +    | +   | +    |     |     | +   | +   |      |
| 0x1 | BPL  | ORA |     |     |     | ORA | ASL |     | CLC  | ORA |      |     |     | ORA | ASL |      |
|     | rel  | idy |     |     |     | zpx | zpx |     | impl | aby |      |     |     | abx | abx |      |
|     | +    | +   |     |     |     | +   | +   |     | +    | +   |      |     |     | +   | +   |      |
| 0x2 | JSR  | AND |     |     | BIT | AND | ROL |     | PLP  | AND | ROL  |     | BIT | AND | ROL |      |
|     | abs  | idx |     |     | zp  | zp  | zp  |     | impl | imm | acc  |     | abs | abs | abs |      |
|     | +    | +   |     |     | +   | +   | +   |     | +    | +   | +    |     | +   | +   | +   |      |
| 0x3 | BMI  | AND |     |     |     | AND | ROL |     | SEC  | AND |      |     |     | AND | ROL |      |
|     | rel  | idy |     |     |     | zpx | zpx |     | impl | aby |      |     |     | abx | abx |      |
|     | +    | +   |     |     |     | +   | +   |     | +    | +   |      |     |     | +   | +   |      |
| 0x4 | RTI  | EOR |     |     |     | EOR | LSR |     | PHA  | EOR | LSR  |     | JMP | EOR | LSR |      |
|     | impl | idx |     |     |     | zp  | zp  |     | impl | imm | acc  |     | abs | abs | abs |      |
|     | -    | +   |     |     |     | +   | +   |     | +    | +   | +    |     | +   | +   | +   |      |
| 0x5 | BVC  | EOR |     |     |     | EOR | LSR |     | CLI  | EOR |      |     |     | EOR | LSR |      |
|     | rel  | idy |     |     |     | zpx | zpx |     | impl | aby |      |     |     | abx | abx |      |
|     | +    | +   |     |     |     | +   | +   |     | -    | +   |      |     |     | +   | +   |      |
| 0x6 | RTS  | ADC |     |     |     | ADC | ROR |     | PLA  | ADC | ROR  |     | JMP | ADC | ROR |      |
|     | impl | idx |     |     |     | zp  | zp  |     | impl | imm | acc  |     | ind | abs | abs |      |
|     | +    | +   |     |     |     | +   | +   |     | +    | +   | +    |     | +   | +   | +   |      |
| 0x7 | BVS  | ADC |     |     |     | ADC | ROR |     | SEI  | ADC |      |     |     | ADC | ROR |      |
|     | rel  | idy |     |     |     | zpx | zpx |     | impl | aby |      |     |     | abx | abx |      |
|     | +    | +   |     |     |     | +   | +   |     | -    | +   |      |     |     | +   | +   |      |
| 0x8 |      | STA |     |     | STY | STA | STX |     | DEY  |     | TXA  |     | STY | STA | STX |      |
|     |      | idx |     |     | zp  | zp  | zp  |     | impl |     | impl |     | abs | abs | abs |      |
|     |      | +   |     |     | +   | +   | +   |     | +    |     | +    |     | +   | +   | +   |      |
| 0x9 | BCC  | STA |     |     | STY | STA | STX |     | TYA  | STA | TXS  |     |     | STA |     |      |
|     | rel  | idy |     |     | zpx | zpx | zpy |     | impl | aby | impl |     |     | abx |     |      |
|     | +    | +   |     |     | +   | +   | +   |     | +    | +   | +    |     |     | +   |     |      |
| 0xA | LDY  | LDA | LDX |     | LDY | LDA | LDX |     | TAY  | LDA | TAX  |     | LDY | LDA | LDX |      |
|     | imm  | idx | imm |     | zp  | zp  | zp  |     | impl | imm | impl |     | abs | abs | abs |      |
|     | +    | +   | +   |     | +   | +   | +   |     | +    | +   | +    |     | +   | +   | +   |      |
| 0xB | BCS  | LDA |     |     | LDY | LDA | LDX |     | CLV  | LDA | TSX  |     | LDY | LDA | LDX |      |
|     | rel  | idy |     |     | zpx | zpx | zpy |     | impl | aby | impl |     | abx | abx | aby |      |
|     | +    | +   |     |     | +   | +   | +   |     | +    | +   | +    |     | +   | +   | +   |      |
| 0xC | CPY  | CMP |     |     | CPY | CMP | DEC |     | INY  | CMP | DEX  |     | CPY | CMP | DEC | CVR  |
|     | imm  | idx |     |     | zp  | zp  | zp  |     | impl | imm | impl |     | abs | abs | abs | impl |
|     | +    | +   |     |     | +   | +   | +   |     | +    | +   | +    |     | +   | +   | +   | !    |
| 0xD | BNE  | CMP |     |     |     | CMP | DEC |     | CLD  | CMP |      |     |     | CMP | DEC | IFO  |
|     | rel  | idy |     |     |     | zpx | zpx |     | impl | aby |      |     |     | abx | abx | abs  |
|     | +    | +   |     |     |     | +   | +   |     | -    | +   |      |     |     | +   | +   | !    |
| 0xE | CPX  | SBC |     |     | CPX | SBC | INC |     | INX  | SBC | NOP  |     | CPX | SBC | INC | HLT  |
|     | imm  | idx |     |     | zp  | zp  | zp  |     | impl | imm | impl |     | abs | abs | abs | impl |
|     | +    | +   |     |     | +   | +   | +   |     | +    | +   | +    |     | +   | +   | +   | !    |
| 0xF | BEQ  | SBC |     |     |     | SBC | INC |     | SED  | SBC |      |     |     | SBC | INC | WVS  |
|     | rel  | idy |     |     |     | zpx | zpx |     | impl | aby |      |     |     | abx | abx | imm  |
|     | +    | +   |     |     |     | +   | +   |     | -    | +   |      |     |     | +   | +   | !    |

## 6502 Addressing Modes - Legend

| Abbrev | Full Name    | Description                                                                                 |
| ------ | ------------ | ------------------------------------------------------------------------------------------- |
| impl   | Implied      | No operand needed. Used for instructions like `CLC`, `RTS`, `SEI`, etc.                     |
| acc    | Accumulator  | Operates directly on the accumulator (A register), e.g., `ASL A`                            |
| imm    | Immediate    | The operand is a constant value, e.g., `LDA #$01`                                           |
| zp     | Zero Page    | Uses a one-byte address ($00–$FF), e.g., `LDA $10`                                          |
| zpx    | Zero Page,X  | Zero page address plus the X register, e.g., `LDA $10,X`                                    |
| zpy    | Zero Page,Y  | Zero page address plus the Y register, e.g., `LDX $10,Y`                                    |
| abs    | Absolute     | Full 16-bit address, e.g., `LDA $1234`                                                      |
| abx    | Absolute,X   | Absolute address plus X, e.g., `LDA $1234,X`                                                |
| aby    | Absolute,Y   | Absolute address plus Y, e.g., `LDA $1234,Y`                                                |
| ind    | Indirect     | Used only with `JMP`, jumps to the address stored at the given address, e.g., `JMP ($1234)` |
| idx    | (Indirect,X) | Indirect address from zero page plus X, e.g., `LDA ($10,X)`                                 |
| idy    | (Indirect),Y | Indirect address from zero page, then add Y, e.g., `LDA ($10),Y`                            |
| rel    | Relative     | Offset relative to the program counter (used for branches), e.g., `BEQ $10`                 |
