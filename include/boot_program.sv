logic [7:0] boot_program[256];

assign boot_program = '{
        0: 8'hA9,
        1: 8'h41,
        2: 8'h85,
        3: 8'h01,
        4: 8'h8D,
        5: 8'h00,
        6: 8'hE0,
        7: 8'hFF,
        8: 8'h3A,
        9: 8'hDF,
        10: 8'h00,
        11: 8'h00,
        12: 8'hFF,
        13: 8'h3A,
        14: 8'hCF,
        15: 8'h4C,
        16: 8'h04,
        17: 8'h02,
        default: 8'hEA
    };
parameter logic[7:0] boot_program_length = 18;
