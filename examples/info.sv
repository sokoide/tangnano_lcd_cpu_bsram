// INFO
logic [7:0] boot_program[256];

assign boot_program = '{
        0: 8'hA9,  // LDA #$41
        1: 8'h41,
        2: 8'h85,  // STA $01; store A register in 0x02
        3: 8'h02,
        4: 8'hE8,  // INX
        5: 8'hDF,  // IFO
        6: 8'h00,
        7: 8'hEF   // HLT
        default: 8'hEA  // NOP
    };

parameter logic [7:0] boot_program_length = 7;
