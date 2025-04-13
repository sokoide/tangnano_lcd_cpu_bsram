logic [7:0] boot_program[32];

initial begin
  // Hello World
  boot_program[0]  = 8'hA0;  // LDY #0
  boot_program[1]  = 8'h00;
  boot_program[2]  = 8'hA2;  // LDX #0
  boot_program[3]  = 8'h00;
  boot_program[4]  = 8'hB9;  // loop: LDA message, Y
  boot_program[5]  = 8'h13;
  boot_program[6]  = 8'h02;
  boot_program[7]  = 8'hF0;  // BEQ done
  boot_program[8]  = 8'h07;
  boot_program[9]  = 8'h9D;  // STA $E000, X; $E000 is a top-left corder of text VRAM
  boot_program[10] = 8'h00;
  boot_program[11] = 8'hE0;
  boot_program[12] = 8'hC8;  // INY
  boot_program[13] = 8'hE8;  // INX
  boot_program[14] = 8'hD0;  // BNE loop
  boot_program[15] = 8'hF4;
  boot_program[16] = 8'h4C;  // done: JMP done (infinite loop)
  boot_program[17] = 8'h10;
  boot_program[18] = 8'h12;
  boot_program[19] = 8'h48;  // message: Hello World!, 0
  boot_program[20] = 8'h65;  // 'H'
  boot_program[21] = 8'h6C;  // 'e'
  boot_program[22] = 8'h6C;  // 'l'
  boot_program[23] = 8'h6F;  // 'l'
  boot_program[24] = 8'h20;  // ...
  boot_program[25] = 8'h57;
  boot_program[26] = 8'h6F;
  boot_program[27] = 8'h72;
  boot_program[28] = 8'h6C;
  boot_program[29] = 8'h64;
  boot_program[30] = 8'h21;
  boot_program[31] = 8'h00;  // 0 terminator
end
