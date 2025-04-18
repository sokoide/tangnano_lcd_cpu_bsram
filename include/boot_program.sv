// Simple 1) draw 'A' on top-left
// Program loaded and starts at 0x0200
logic [7:0] boot_program[256];

assign boot_program = '{
        0: 8'hA9,  // LDA #$AA
        1: 8'hAA,
        2: 8'h85,  // STA $02; store A register in 0x02
        3: 8'h02,
        4: 8'hE8,  // INX
        5: 8'hE8,  // INX
        6: 8'hC8,  // INY
        7: 8'hC8,  // INY
        8: 8'hC8,  // INY
        9: 8'hA9,  // LDA #$B0
        10: 8'hB0,
        11: 8'h18,  // CLC
        12: 8'h69,  // ADC #1
        13: 8'h01,
        14: 8'h85,  // STA $1D
        15: 8'h1D,
        16: 8'h69,  // ADC #1
        17: 8'h01,
        18: 8'h85,  // STA $1E
        19: 8'h1E,
        20: 8'h69,  // ADC #1
        21: 8'h01,
        22: 8'h85,  // STA $1F
        23: 8'h1F,
        24: 8'h85,  // STA $80
        25: 8'h80,
        26: 8'h85,  // STA $FF
        27: 8'hFF,
        28: 8'hDF,  // IFO $8000
        29: 8'h80,
        30: 8'h00,
        31: 8'hEF,  // HLT
        default: 8'hEA  // NOP
    };

parameter logic [7:0] boot_program_length = 32;
