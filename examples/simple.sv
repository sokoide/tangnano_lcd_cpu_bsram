  logic [7:0] boot_program[9];

  initial begin
    // // JSR
    // boot_program[0]  = 8'hBA;  // TSX
    // boot_program[1]  = 8'h20;  // JSR foo ($0209)
    // boot_program[2]  = 8'h09;
    // boot_program[3]  = 8'h02;
    // boot_program[4]  = 8'hA9;  // LDA #$02
    // boot_program[5]  = 8'h02;
    // boot_program[6]  = 8'h18;  // CLC
    // boot_program[7]  = 8'h90;  // BCC -2; PC+2-2=loop here
    // boot_program[8]  = 8'hFE;
    // boot_program[9]  = 8'hA9;  // foo function, lda $2A
    // boot_program[10] = 8'h2A;
    // boot_program[11] = 8'h60;  // RTS

    // // JMP Indirect)
    // boot_program[0]  = 8'hA9;  // LDA #$05
    // boot_program[1]  = 8'h05;
    // boot_program[2]  = 8'h8D;  // STA $0300; 0x0300 <- 05
    // boot_program[3]  = 8'h00;
    // boot_program[4]  = 8'h03;
    // boot_program[5]  = 8'hA9;  // LDA #$02
    // boot_program[6]  = 8'h02;
    // boot_program[7]  = 8'h8D;  // STA $0301; 0x0301 <- 02
    // boot_program[8]  = 8'h01;
    // boot_program[9]  = 8'h03;
    // boot_program[10] = 8'h6C;  // JMP ($0300); jump to 0205
    // boot_program[11] = 8'h00;
    // boot_program[12] = 8'h03;

    // // Simple 3)
    // // copy 0x00-0x7F to 0xE000-0xE07F (VRAM)
    // boot_program[0]  = 8'hA0;  // LDY #$00
    // boot_program[1]  = 8'h00;
    // boot_program[2]  = 8'hA2;  // LDX #$00
    // boot_program[3]  = 8'h00;
    // boot_program[4]  = 8'h8A;  // TXA (A=X)
    // boot_program[5]  = 8'h99;  // STA $E000, Y
    // boot_program[6]  = 8'h00;
    // boot_program[7]  = 8'hE0;
    // boot_program[8]  = 8'hE8;  // INX
    // boot_program[9]  = 8'hC8;  // INY
    // boot_program[10] = 8'hC0;  // CPY #$7F
    // boot_program[11] = 8'h7F;  //
    // boot_program[12] = 8'hD0;  // BNE -10;  PC+2-10=4 (F6=-10)
    // boot_program[13] = 8'hF6;
    // boot_program[14] = 8'h18;  // CLC
    // boot_program[15] = 8'h90;  // BCC -2; PC+2-2=here
    // boot_program[16] = 8'hFE;  //

    // Simple 2) draw 'B' on top-left using zero page
    // // address 00 <- 0x00
    // // address 01 <- 0xE0
    // boot_program[0]  = 8'hA9;  // LDA #$00
    // boot_program[1]  = 8'h00;
    // boot_program[2]  = 8'h85;  // STA $00
    // boot_program[3]  = 8'h00;
    // boot_program[4]  = 8'hA9;  // LDA #$E0
    // boot_program[5]  = 8'hE0;
    // boot_program[6]  = 8'h85;  // STA $01
    // boot_program[7]  = 8'h01;
    // boot_program[8]  = 8'hA9;  // LDA 0x42; A register <- 'B'
    // boot_program[9]  = 8'h42;
    // boot_program[10] = 8'h8D;  // STA $E000 ; store 'B' at top-left of VRAM
    // boot_program[11] = 8'h00;
    // boot_program[12] = 8'hE0;
    // boot_program[13] = 8'h4C;  // JMP $020D (infinite loop)
    // boot_program[14] = 8'h0D;
    // boot_program[15] = 8'h02;

    // Simple 1) draw 'A' on top-left
    // Program loaded and starts at 0x0200
    // 0x0200 -0x0201
    boot_program[0] = 8'hA9;  // LDA 0x41 ; ra register <= 'A'
    boot_program[1] = 8'h41;
    // 0x0202 - 0x0204
    boot_program[2] = 8'h8D;  // STA $E000 ; store 'A' at top-left of VRAM
    boot_program[3] = 8'h00;
    boot_program[4] = 8'hE0;
    // 0x0205-0x0207
    boot_program[5] = 8'h4C;  // JMP $0205 (infinite loop)
    boot_program[6] = 8'h05;
    boot_program[7] = 8'h02;
    // 0x0208 .. never reaches here
    boot_program[8] = 8'hEA;  // NOP
  end