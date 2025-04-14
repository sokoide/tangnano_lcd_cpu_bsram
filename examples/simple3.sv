// Simple 3)
// copy 0x00-0x7F to 0xE000-0xE07F (VRAM)
logic [7:0] boot_program[256];

assign boot_program = '{
        0: 8'hA0,  // LDY #$00
        1: 8'h00,
        2: 8'hA2,  // LDX #$00
        3: 8'h00,
        4: 8'h8A,  // TXA (A=X)
        5: 8'h99,  // STA $E000, Y
        6: 8'h00,
        7: 8'hE0,
        8: 8'hE8,  // INX
        9: 8'hC8,  // INY
        10: 8'hC0,  // CPY #$7F
        11: 8'h7F,  //
        12: 8'hD0,  // BNE -10,  PC+2-10=4 (F6=-10)
        13: 8'hF6,
        14: 8'h18,  // CLC
        15: 8'h90,  // BCC -2, PC+2-2=here
        16: 8'hFE,  //
        default: 8'hEA  // NOP
    };
parameter logic [7:0] boot_program_length = 17;
