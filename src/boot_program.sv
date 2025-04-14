logic [7:0] boot_program[256];

assign boot_program = '{
        0: 8'hA0,
        1: 8'h00,
        2: 8'h8D,
        3: 8'h00,
        4: 8'hE0,
        5: 8'h4C,
        6: 8'h05,
        7: 8'h02,
        0: 8'hA0,  // LDY #0
        1: 8'h00,
        2: 8'hA2,  // LDX #0
        3: 8'h00,
        4: 8'hB9,  // loop: LDA message, Y
        5: 8'h13,
        6: 8'h02,
        7: 8'hF0,  // BEQ done
        8: 8'h07,
        9: 8'h9D,  // STA $E000, X, $E000 is a top-left corder of text VRAM
        10: 8'h00,
        11: 8'hE0,
        12: 8'hC8,  // INY
        13: 8'hE8,  // INX
        14: 8'hD0,  // BNE loop
        15: 8'hF4,
        16: 8'h4C,  // done: JMP done (infinite loop)
        17: 8'h10,
        18: 8'h12,
        19: 8'h48,  // message: Hello World!, 0
        20: 8'h65,  // 'H'
        21: 8'h6C,  // 'e'
        22: 8'h6C,  // 'l'
        23: 8'h6F,  // 'l'
        24: 8'h20,  // ...
        25: 8'h57,
        26: 8'h6F,
        27: 8'h72,
        28: 8'h6C,
        29: 8'h64,
        30: 8'h21,
        31: 8'h00,  // 0 terminator
        default: 8'hEA  // NOP
    };

parameter logic [7:0] boot_program_length = 32;
