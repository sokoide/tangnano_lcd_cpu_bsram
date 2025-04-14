// JSR
logic [7:0] boot_program[256];

assign boot_program = '{
        0: 8'hBA,  // TSX
        1: 8'h20,  // JSR foo ($0209)
        2: 8'h09,
        3: 8'h02,
        4: 8'hA9,  // LDA #$02
        5: 8'h02,
        6: 8'h18,  // CLC
        7: 8'h90,  // BCC -2, PC+2-2=loop here
        8: 8'hFE,
        9: 8'hA9,  // foo function, lda $2A
        10: 8'h2A,
        11: 8'h60,  // RTS
        default: 8'hEA  // NOP
    };
parameter logic [7:0] boot_program_length = 12;
