// Simple 1) draw 'A' on top-left
// Program loaded and starts at 0x0200
logic [7:0] boot_program[256];

assign boot_program = '{
        0: 8'hA9,  // LDA #$41
        1: 8'h41,
        2: 8'h8D,  // STA $E000; store 'A' at to-left of VRAM
        3: 8'h00,
        4: 8'hE0,
        5: 8'h4C,  // JMP $0205 (infinite loop)
        6: 8'h05,
        7: 8'h02,
        default: 8'hEA // NOP
    };

parameter logic [7:0] boot_program_length = 9;