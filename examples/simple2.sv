// Simple 2) draw 'B' on top-left using zero page
logic [7:0] boot_program[256];

assign boot_program = '{
        // address 00 <- 0x00
        // address 01 <- 0xE0
        0:
        8'hA9,  // LDA #$00
        1: 8'h00,
        2: 8'h85,  // STA $00
        3: 8'h00,
        4: 8'hA9,  // LDA #$E0
        5: 8'hE0,
        6: 8'h85,  // STA $01
        7: 8'h01,
        8: 8'hA9,  // LDA 0x42, A register <- 'B'
        9: 8'h42,
        10: 8'h8D,  // STA $E000 , store 'B' at top-left of VRAM
        11: 8'h00,
        12: 8'hE0,
        13: 8'h4C,  // JMP $020D (infinite loop)
        14: 8'h0D,
        15: 8'h02,
        default: 8'hEA  // NOP
    };
parameter logic [7:0] boot_program_length = 16;
