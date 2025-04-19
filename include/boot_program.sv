logic [7:0] boot_program[256];

assign boot_program = '{
        0: 8'hA9,
        1: 8'h41,
        2: 8'h8D,
        3: 8'h00,
        4: 8'hE0,
        5: 8'hEF,
        default: 8'hEA
    };
parameter logic[7:0] boot_program_length = 6;
