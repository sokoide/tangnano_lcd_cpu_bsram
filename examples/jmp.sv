// // JMP Indirect)
logic [7:0] boot_program[256];

assign boot_program = '{
        0: 8'hA9,  // LDA #$05
        1: 8'h05,
        2: 8'h8D,  // STA $0300, 0x0300 <- 05
        3: 8'h00,
        4: 8'h03,
        5: 8'hA9,  // LDA #$02
        6: 8'h02,
        7: 8'h8D,  // STA $0301, 0x0301 <- 02
        8: 8'h01,
        9: 8'h03,
        10: 8'h6C,  // JMP ($0300), jump to 0205
        11: 8'h00,
        12: 8'h03,
        default: 8'hEA  // NOP
    };
parameter logic [7:0] boot_program_length = 13;
