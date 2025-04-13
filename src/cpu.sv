`include "consts.svh"

module cpu (
    input  logic        rst_n,
    input  logic        clk,
    input  logic [ 7:0] dout,   // RAM data which was read
    output logic [ 7:0] din,    // RAM data to write
    output logic [12:0] ada,    // write RAM
    output logic        cea,    // RAM write enable
    output logic        ceb,    // RAM read enable
    output logic [12:0] adb,    // read RAM
    output logic [ 9:0] v_ada,  // write VRAM
    output logic        v_cea,  // VRAM write enable
    output logic [ 7:0] v_din   // VRAM data to write
);

  // Internal registers.
  logic [15:0] pc;  // Program Counter
  logic [7:0] ra;  // A Register
  logic [7:0] rx;  // X Register
  logic [7:0] ry;  // Y Register
  logic [7:0] sp;  // Stack Pointer
  logic flg_c;  // carry flag
  logic flg_z;  // zero flag
  logic flg_i;  // interrupt disable (not used)
  logic flg_d;  // desimal mode flag (not used)
  logic flg_b;  // break command (not used)
  logic flg_v;  // overflow flag
  logic flg_n;  // negative flag
  logic [15:0] addr;
  logic signed [15:0] s_offset;
  logic signed [7:0] s_imm8;

  // Internal states
  logic [7:0] opcode;
  logic [15:0] operands;
  logic [2:0] fetched_data_bytes;
  logic [15:0] fetched_data;
  logic [2:0] written_data_bytes;
  logic [7:0] char_code;
  logic [31:0] counter;
  logic [7:0] boot_idx;
  logic boot_write;

  typedef enum logic [3:0] {
    INIT,
    INIT_VRAM,
    INIT_RAM,
    WAIT_64K_CLKS,
    HALT,
    FETCH_REQ,
    FETCH_RECV,
    DECODE_EXECUTE,
    WRITE_REQ
  } state_t;

  state_t state;
  state_t prev_state;

  typedef enum logic [2:0] {
    FETCH_OPCODE,  // transition to FETCH_OPCODE, FETCH_OPERAND1 or FETCH_OPERAND1OF2,
    FETCH_DATA,
    FETCH_OPERAND1,  // final stage
    FETCH_OPERAND1OF2,  // transition to FETCH_OPERAND2
    FETCH_OPERAND2  // final stage
  } fetch_stage_t;

  fetch_stage_t fetch_stage;

  // program to load at startup
  // make sure to set the size boot_progarm[X]
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
    boot_program[9]  = 8'h9D;  // STA $E00, X
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
    // // Program loaded and starts at 0x0200
    // // 0x0200 -0x0201
    // boot_program[0] = 8'hA9;  // LDA 0x41 ; ra register <= 'A'
    // boot_program[1] = 8'h41;
    // // 0x0202 - 0x0204
    // boot_program[2] = 8'h8D;  // STA $E000 ; store 'A' at top-left of VRAM
    // boot_program[3] = 8'h00;
    // boot_program[4] = 8'hE0;
    // // 0x0205-0x0207
    // boot_program[5] = 8'h4C;  // JMP $0205 (infinite loop)
    // boot_program[6] = 8'h05;
    // boot_program[7] = 8'h02;
    // // 0x0208 .. never reaches here
    // boot_program[8] = 8'hEA;  // NOP
  end

  localparam int unsigned BootProgramLength = $bits(boot_program) / $bits(boot_program[0]);

  // Sequential logic: use an asynchronous active-low rst_n.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // rst_n: clear selected registers and the flag.
      {ra, rx, ry}                                      <= 8'd0;
      {flg_c, flg_z, flg_i, flg_d, flg_b, flg_v, flg_n} <= 1'b0;
      pc                                                <= 16'h0200;
      sp                                                <= 8'hFF;
      ada                                               <= 13'h0000;
      ceb                                               <= 1'b1;
      din                                               <= 8'h0;
      adb                                               <= PROGRAM_START;
      v_ada                                             <= 10'h0000;
      v_cea                                             <= 0;
      v_din                                             <= 8'h0;
      opcode                                            <= 8'h0;
      operands                                          <= 16'h0000;
      fetched_data_bytes                                <= 0;
      written_data_bytes                                <= 0;
      fetched_data                                      <= 16'h0000;
      state                                             <= INIT;
      prev_state                                        <= INIT;
      char_code                                         <= 8'h20;  // ' '
      counter                                           <= 32'h0;
      boot_idx                                          <= 0;
      boot_write                                        <= 0;
    end else begin
      begin
        counter <= (counter + 1) & 32'hFFFFFFFF;

        // --- case(state) ---
        case (state)
          INIT: begin
            v_cea <= 0;  // VRAM write disable
            boot_write <= 1;
            state <= INIT_RAM;
            // call INIT_VRAM for VRAM testing
            // state <= INIT_VRAM;
          end

          INIT_VRAM: begin
            if (v_ada <= COLUMNS * ROWS) begin
              v_ada <= v_ada + 1 & VRAMW;
            end else begin
              v_cea <= 0;  // VRAM write disable
              state <= HALT;
            end
            // v_cea is always enabled
            v_cea <= 1;  // VRAM write enable
            v_din <= char_code;
            char_code <= (char_code < 8'h7F) ? (char_code + 1) & 8'hFF : 8'h20;
            // prev_state <= INIT_VRAM;
            // state <= WAIT_64K_CLKS;
          end

          INIT_RAM: begin
            if (boot_write) begin
              boot_write <= 0;
              cea <= 1;  // write enable
              ada <= PROGRAM_START + boot_idx & RAMW;
              din <= boot_program[boot_idx];
            end else begin
              cea <= 0;
              if (boot_idx == BootProgramLength) begin
                v_cea <= 1;  // VRAM write enable
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end else begin
                boot_idx   <= boot_idx + 1 & 8'hFF;
                boot_write <= 1;
              end
            end
          end

          WAIT_64K_CLKS: begin
            if ((counter & 16'hFFFF) == 0) begin
              state <= prev_state;
            end
          end

          HALT: begin
            ;  // do nothing
          end

          FETCH_REQ: begin
            state <= FETCH_RECV;
            if (fetch_stage == FETCH_DATA) begin
              fetched_data_bytes <= fetched_data_bytes + 1'd1;
              state <= DECODE_EXECUTE;
            end
          end

          FETCH_RECV: begin
            // --- case (fetch_stage) ---
            case (fetch_stage)
              FETCH_OPCODE: begin
                opcode <= dout;
                fetched_data_bytes <= 0;
                written_data_bytes <= 0;
                cea <= 0;  // disable write
                case (dout)
                  // NOP
                  8'hEA: begin
                    state <= DECODE_EXECUTE;
                  end
                  // JMP immediate
                  8'h4C: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // JMP indirect
                  8'h6C: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // JSR absolute
                  8'h20: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // RTS
                  8'h60: begin
                    state <= DECODE_EXECUTE;
                  end
                  // PHA; push accumulator
                  8'h48: begin
                    state <= DECODE_EXECUTE;
                  end
                  // PLA; pull accumulator
                  8'h68: begin
                    state <= DECODE_EXECUTE;
                  end
                  // PHP; push processor status
                  8'h08: begin
                    state <= DECODE_EXECUTE;
                  end
                  // PLP; pull processor status
                  8'h28: begin
                    state <= DECODE_EXECUTE;
                  end
                  // LDA immediate
                  8'hA9: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LDA zero page
                  8'hA5: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LDA zero page, X
                  8'hB5: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LDA absolute
                  8'hAD: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // LDA absolute, X
                  8'hBD: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // LDA absolute, Y
                  8'hB9: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // TODO: LDA (indirect, X)
                  // 8'hA1: begin
                  // end
                  // TODO: LDA (indirect), Y
                  // 8'hB1: begin
                  // end
                  // LDX immediate
                  8'hA2: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LDX zero page
                  8'hA6: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LDX zero page, Y
                  8'hB6: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LDX absolute
                  8'hAE: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // LDX absolute, Y
                  8'hBE: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // LDY immediate
                  8'hA0: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LDY zero page
                  8'hA4: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LDY zero page, X
                  8'hB4: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LDY absolute
                  8'hAC: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // LDY absolute, X
                  8'hBC: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // STA zero page
                  8'h85: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // STA zero page, X
                  8'h95: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // STA absolute
                  8'h8D: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // STA absolute, X
                  8'h9D: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // STA absolute, Y
                  8'h99: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // STA (indirext, X)
                  8'h81: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // STA (indirext), Y
                  8'h91: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // STX zero page
                  8'h86: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // STX zero page, Y
                  8'h96: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // STX absolute
                  8'h8E: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // STY zero page
                  8'h84: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // STY zero page, X
                  8'h94: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // STY absolute
                  8'h8C: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // INC zero page
                  8'hE6: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // INC zero page, X
                  8'hF6: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // INC absolute
                  8'hEE: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // INC absolute, X
                  8'hFE: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // INX
                  8'hE8: begin
                    state <= DECODE_EXECUTE;
                  end
                  // INY
                  8'hC8: begin
                    state <= DECODE_EXECUTE;
                  end
                  // DEC zero page
                  8'hC6: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // DEC zero page, X
                  8'hD6: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // DEC absolute
                  8'hCE: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // DEC absolute, X
                  8'hDE: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // DEX
                  8'hCA: begin
                    state <= DECODE_EXECUTE;
                  end
                  // DEY
                  8'h88: begin
                    state <= DECODE_EXECUTE;
                  end
                  // ADC immediate
                  8'h69: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // ADC zero page
                  8'h65: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // ADC zero page, X
                  8'h75: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // ADC absolute
                  8'h6D: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // ADC absolute, X
                  8'h7D: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // ADC absolute, Y
                  8'h79: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // ADC (indirect, X)
                  8'h61: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // ADC (indirect), Y
                  8'h71: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // SBC immediate
                  8'hE9: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // SBC zero page
                  8'hE5: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // SBC zero page, X
                  8'hF5: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // SBC absolute
                  8'hED: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // SBC absolute, X
                  8'hFD: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // SBC absolute, Y
                  8'hF9: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // SBC (indirect, X)
                  8'hE1: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // SBC (indirect), Y
                  8'hF1: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // AND immediate
                  8'h29: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // AND zero page
                  8'h25: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // AND zero page, X
                  8'h35: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // AND absolute
                  8'h2D: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // AND absolute, X
                  8'h3D: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // AND absolute, Y
                  8'h39: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // AND (indirect, X)
                  8'h21: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // AND (indirect), Y
                  8'h31: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // EOR immediate
                  8'h49: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // EOR zero page
                  8'h45: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // EOR zero page, X
                  8'h55: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // EOR absolute
                  8'h4D: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // EOR absolute, X
                  8'h5D: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // EOR absolute, Y
                  8'h59: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // EOR (indirect, X)
                  8'h41: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // EOR (indirect), Y
                  8'h51: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // ORA immediate; logical inclusive OR
                  8'h09: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // ORA zero page
                  8'h05: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // ORA zero page, X
                  8'h15: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // ORA absolute
                  8'h0D: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // ORA absolute, X
                  8'h1D: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // ORA absolute, Y
                  8'h19: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // ORA (indirect, X)
                  8'h01: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // ORA (indirect), Y
                  8'h11: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // ASL accumulator; Arithmetic Shift Left
                  // Arithmetic == keep the sign flag
                  8'h0A: begin
                    state <= DECODE_EXECUTE;
                  end
                  // ASL zero page
                  8'h06: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // ASL zero page, X
                  8'h16: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // ASL absolute
                  8'h0E: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // ASL absolute, X
                  8'h1E: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // LSR accumulator; Logical Shift Right
                  // Logical == simple shift (don't keep the sign flag)
                  8'h4A: begin
                    state <= DECODE_EXECUTE;
                  end
                  // LSR zero page
                  8'h46: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LSR zero page, X
                  8'h56: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LSR absolute
                  8'h4E: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // LSR absolute, X
                  8'h5E: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // ROL accumulator; Rotate Left
                  8'h2A: begin
                    state <= DECODE_EXECUTE;
                  end
                  // ROL zero page
                  8'h26: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // ROL zero page, X
                  8'h36: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // ROL absolute
                  8'h2E: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // ROL absolute, X
                  8'h3E: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // ROR accumulator; Rotate Right
                  8'h6A: begin
                    state <= DECODE_EXECUTE;
                  end
                  // ROR zero page
                  8'h66: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // ROR zero page, X
                  8'h76: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // ROR absolute
                  8'h6E: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // ROR absolute, X
                  8'h7E: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // BIT zero page; bit test
                  8'h24: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // BIT bsolute
                  8'h2C: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // CMP immediate
                  8'hC9: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // CMP zero page
                  8'hC5: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // CMP zero page, X
                  8'hD5: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // CMP absolute
                  8'hCD: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // CMP absolute, X
                  8'hDD: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // CMP absolute, Y
                  8'hD9: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // CMP (indirect, X)
                  8'hC1: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // CMP (indirect), Y
                  8'hD1: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // CPX immediate
                  8'hE0: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // CPX zero page
                  8'hE4: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // CPX absolute
                  8'hEC: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // CPY immediate
                  8'hC0: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // CPY zero page
                  8'hC4: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // CPY absolute
                  8'hCC: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // TAX
                  8'hAA: begin
                    state <= DECODE_EXECUTE;
                  end
                  // TAY
                  8'hA8: begin
                    state <= DECODE_EXECUTE;
                  end
                  // TXA
                  8'h8A: begin
                    state <= DECODE_EXECUTE;
                  end
                  // TYA
                  8'h98: begin
                    state <= DECODE_EXECUTE;
                  end
                  // TSX
                  8'hBA: begin
                    state <= DECODE_EXECUTE;
                  end
                  // TXS
                  8'h9A: begin
                    state <= DECODE_EXECUTE;
                  end
                  // BEQ
                  8'hF0: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // BMI
                  8'h30: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // BNE
                  8'hD0: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // BPL
                  8'h10: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // BVC
                  8'h50: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // BVS
                  8'h70: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // BCC
                  8'h90: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // BCS
                  8'hB0: begin
                    adb <= pc + 1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // CLC
                  8'h18: begin
                    state <= DECODE_EXECUTE;
                  end
                  // CLV
                  8'hB8: begin
                    state <= DECODE_EXECUTE;
                  end
                  // SEC
                  8'h38: begin
                    state <= DECODE_EXECUTE;
                  end


                  // TODO: support more instructions

                  default: ;  // No operation.
                endcase
              end

              FETCH_OPERAND1: begin
                operands[7:0] <= dout;
                state <= DECODE_EXECUTE;
              end

              FETCH_OPERAND1OF2: begin
                operands[15:8] <= dout;
                adb <= pc + 2 & RAMW;
                fetch_stage <= FETCH_OPERAND2;
                state <= FETCH_REQ;
              end

              FETCH_OPERAND2: begin
                operands[7:0] <= dout;
                state <= DECODE_EXECUTE;
              end
              // --- end of case(fetch_stage) ---
            endcase
          end

          DECODE_EXECUTE: begin
            case (opcode)
              // NOP
              8'hEA: begin
                pc <= pc + 1 & RAMW;
                adb <= pc + 1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // JMP absolute
              8'h4C: begin
                automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & RAMW;
                pc <= addr;
                adb <= addr;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // JMP indirect
              8'h6C: begin
                case (fetched_data_bytes)
                  0: begin
                    adb <= {operands[7:0], operands[15:8]} & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                  end
                  1: begin
                    fetched_data[7:0] = dout;
                    adb <= ({operands[7:0], operands[15:8]} + 1) & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                  end
                  2: begin
                    // relative data is already in little endian.
                    automatic logic [15:0] addr = {dout, fetched_data[7:0]} & RAMW;
                    fetched_data[15:8] = dout;
                    pc <= addr;
                    adb <= addr;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                  end
                endcase
              end
              // JSR absolute
              8'h20: begin
                // push the current PC+2 into stack in high, low byte order
                // and change PC to the absolute address
                case (written_data_bytes)
                  0: begin
                    // always RAM (stack)
                    // push high byte of PC+2
                    ada <= STACK + sp;
                    sp = sp - 1'd1;
                    din   <= (pc + 2 & RAMW) >> 8 & 8'hFF;
                    cea   <= 1;
                    state <= WRITE_REQ;
                  end
                  1: begin
                    // always RAM (stack)
                    // push high byte of PC+2
                    ada <= STACK + sp;
                    sp = sp - 1'd1;
                    din   <= pc + 2 & 8'hFF;
                    cea   <= 1;
                    state <= WRITE_REQ;
                  end
                  2: begin
                    // you can do this step in 1, but followed 6502.
                    // operands is in little endian.
                    automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & RAMW;
                    pc <= addr;
                    adb <= addr;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                  end
                endcase
              end
              // RTS
              8'h60: begin
                // pop low and high bytes and +1
                // set it to PC
                case (fetched_data_bytes)
                  0: begin
                    // fetch low byte of PC-1
                    sp = sp + 1'd1;
                    adb <= STACK + sp;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                  end
                  1: begin
                    // fetch high byte of PC-1
                    fetched_data[7:0] = dout;
                    sp = sp + 1'd1;
                    adb <= STACK + sp;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                  end
                  2: begin
                    fetched_data[15:8] = dout;
                    // fetched_data is in big endian.
                    pc <= fetched_data + 1'd1 & RAMW;
                    adb <= fetched_data + 1'd1 & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                  end
                endcase
              end
              // PHA; push accumulator
              8'h48: begin
                ada <= STACK + sp;
                sp = sp - 1'd1;
                din <= ra;
                cea <= 1;
                pc <= pc + 1 & RAMW;
                adb <= pc + 1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // PLA; pull accumulator
              8'h68: begin
                if (fetched_data_bytes == 0) begin
                  sp = sp + 1'd1;
                  adb <= STACK + sp;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 1 & RAMW;
                  adb <= pc + 1 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // PHP; push processor status
              8'h08: begin
                ada <= STACK + sp;
                sp = sp - 1'd1;
                din <= {flg_n, flg_v, 1'b1, flg_b, flg_d, flg_i, flg_z, flg_c};
                cea <= 1;
                pc <= pc + 1 & RAMW;
                adb <= pc + 1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // PLP; pull processor status
              8'h28: begin
                if (fetched_data_bytes == 0) begin
                  sp = sp + 1'd1;
                  adb <= STACK + sp;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic dummy;
                  {flg_n, flg_v, dummy, flg_b, flg_d, flg_i, flg_z, flg_c} = dout;
                  pc <= pc + 1 & RAMW;
                  adb <= pc + 1 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDA immediate
              8'hA9: begin
                ra = operands[7:0];
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // LDA zero page
              8'hA5: begin
                // fetch operand[7:0]'s value from memory and store it to ra.
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  ra <= dout;
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDA zero page, X
              8'hB5: begin
                // fetch operand[7:0] + rx's value from memory and store it to ra.
                if (fetched_data_bytes == 0) begin
                  adb <= (operands[7:0] + rx) & 8'hFF;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDA absolute
              8'hAD: begin
                // fetch operand[15:0]'s value from memory and store it to ra.
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDA absolute, X
              8'hBD: begin
                // fetch operand[15:0] + rx's value from memory and store it to ra.
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} + rx & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDA absolute, Y
              8'hB9: begin
                // fetch operand[15:0] + ry's value from memory and store it to ra.
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} + ry & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // TODO: LDA (indirect, X)
              8'hA1: begin
                // fetch operand[7:0] + rx's and the next value from the zero page
                // (total 16bit) in little endian.
                // then read an 8bit data pointed by the address.
              end
              // TODO: LDA (indirect), Y
              8'hB1: begin
                // fetch operand[7:0] and the next value from the zero page
                // (total 16bit) in litte endian.
                // then read an 8bit data pointed by the address+ry.
              end
              // LDX immediate
              8'hA2: begin
                rx = operands[7:0];
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // LDX zero page
              8'hA6: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  rx = dout;
                  flg_z = (rx == 8'h00);
                  flg_n = rx[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDX zero page, Y
              8'hB6: begin
                if (fetched_data_bytes == 0) begin
                  adb <= (operands[7:0] + ry) & 8'hFF;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  rx = dout;
                  flg_z = (rx == 8'h00);
                  flg_n = rx[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDX absolute
              8'hAE: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  rx = dout;
                  flg_z = (rx == 8'h00);
                  flg_n = rx[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDX absolute, Y
              8'hBE: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} + ry & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  rx = dout;
                  flg_z = (rx == 8'h00);
                  flg_n = rx[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDY immediate
              8'hA0: begin
                ry = operands[7:0];
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // LDY zero page
              8'hA4: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ry = dout;
                  flg_z = (ry == 8'h00);
                  flg_n = ry[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDY zero page, X
              8'hB4: begin
                if (fetched_data_bytes == 0) begin
                  adb <= (operands[7:0] + rx) & 8'hFF;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ry = dout;
                  flg_z = (ry == 8'h00);
                  flg_n = ry[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDY absolute
              8'hAC: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ry = dout;
                  flg_z = (ry == 8'h00);
                  flg_n = ry[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDY abosolute, X
              8'hBC: begin
                if (fetched_data_bytes == 0) begin
                  adb = operands[15:0] + rx & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ry = dout;
                  flg_z = (ry == 8'h00);
                  flg_n = ry[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // STA zero page
              8'h85: begin
                // always RAM (zero page)
                ada <= operands[7:0];
                din <= ra;
                cea <= 1;
                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // STA zero page, X
              8'h95: begin
                // always RAM (zero page)
                ada <= operands[7:0] + rx & 8'hFF;
                din <= ra;
                cea <= 1;
                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // STA absolute
              8'h8D: begin
                // check if it's RAM or VRAM
                automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & 16'hFFFF;
                if (addr >= VRAM_START) begin
                  v_ada <= addr - VRAM_START & VRAMW;
                  v_din <= ra;
                end else begin
                  ada <= addr & RAMW;
                  din <= ra;
                  cea <= 1;
                end
                pc <= pc + 3 & RAMW;
                adb <= pc + 3 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // STA absolute, X
              8'h9D: begin
                // check if it's RAM or VRAM
                automatic logic [15:0] addr = {operands[7:0], operands[15:8]} + rx & 16'hFFFF;
                if (addr >= VRAM_START) begin
                  v_ada <= addr - VRAM_START & VRAMW;
                  v_din <= ra;
                end else begin
                  ada <= addr & RAMW;
                  din <= ra;
                  cea <= 1;
                end
                pc <= pc + 3 & RAMW;
                adb <= pc + 3 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // STA absolute, Y
              8'h99: begin
                // check if it's RAM or VRAM
                automatic logic [15:0] addr = {operands[7:0], operands[15:8]} + ry & 16'hFFFF;
                if (addr >= VRAM_START) begin
                  v_ada <= addr - VRAM_START & VRAMW;
                  v_din <= ra;
                end else begin
                  ada <= addr & RAMW;
                  din <= ra;
                  cea <= 1;
                end
                pc <= pc + 3 & RAMW;
                adb <= pc + 3 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // TODO: STA (indirect, X)
              8'h81: begin
              end
              // TODO: STA (indirect), Y
              8'h91: begin
              end
              // STX zero page
              8'h86: begin
                ada <= operands[7:0];
                din <= rx;
                cea <= 1;
                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // STX zero page, Y
              8'h96: begin
                ada <= operands[7:0] + ry & 8'hFF;
                din <= rx;
                cea <= 1;
                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // STX absolute
              8'h8E: begin
                // check if it's RAM or VRAM
                automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & 16'hFFFF;
                if (addr >= VRAM_START) begin
                  v_ada <= addr - VRAM_START & VRAMW;
                  v_din <= rx;
                end else begin
                  ada <= addr & RAMW;
                  din <= rx;
                  cea <= 1;
                end
                pc <= pc + 3 & RAMW;
                adb <= pc + 3 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              //  STY zero page
              8'h84: begin
                ada <= operands[7:0];
                din <= ry;
                cea <= 1;
                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              //  STY zero page, X
              8'h94: begin
                ada <= operands[7:0] + rx & 8'hFF;
                din <= ry;
                cea <= 1;
                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // STY absolute
              8'h8C: begin
                // check if it's RAM or VRAM
                automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & 16'hFFFF;
                if (addr >= VRAM_START) begin
                  v_ada <= addr - VRAM_START & VRAMW;
                  v_din <= ry;
                end else begin
                  ada <= addr & RAMW;
                  din <= ry;
                  cea <= 1;
                end
                pc <= pc + 3 & RAMW;
                adb <= pc + 3 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // INC zero page
              8'hE6: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [7:0] result = dout + 8'd1;
                  ada <= operands[7:0];
                  din <= result;
                  cea <= 1;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // INC zero page, X
              8'hF6: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0] + rx & 8'hFF;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [7:0] result = dout + 8'd1;
                  ada <= operands[7:0];
                  din <= result;
                  cea <= 1;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // INC absolute
              8'hEE: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & 16'hFFFF;
                  // VRAM is write only. INC for VRAM is not supported.
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [7:0] result = dout + 8'd1;
                  ada <= {operands[7:0], operands[15:8]} & RAMW;
                  din <= result;
                  cea <= 1;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // INC absolute, X
              8'hFE: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} + rx & 16'hFFFF;
                  // VRAM is write only. INC for VRAM is not supported.
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [7:0] result = dout + 8'd1;
                  ada <= {operands[7:0], operands[15:8]} & RAMW;
                  din <= result;
                  cea <= 1;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // INX
              8'hE8: begin
                rx = rx + 1 & 8'hFF;
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                pc <= pc + 1 & RAMW;
                adb <= pc + 1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // INY
              8'hC8: begin
                ry = ry + 1 & 8'hFF;
                flg_z = (ry == 8'h00);
                flg_n = ry[7];
                pc <= pc + 1 & RAMW;
                adb <= pc + 1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // DEC zero page
              8'hC6: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [7:0] result = dout - 8'd1;
                  ada <= operands[7:0];
                  din <= result;
                  cea <= 1;
                  flg_z = (result == 8'h00) ? 1'd1 : 1'd0;
                  flg_n = result[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // DEC zero page, X
              8'hD6: begin
                if (fetched_data_bytes == 0) begin
                  adb <= (operands[7:0] + rx) & 8'hFF;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [7:0] result = dout - 8'd1;
                  ada <= (operands[7:0] + rx) & 8'hFF;
                  din <= result;
                  cea <= 1;
                  flg_z = (result == 8'h00) ? 1'd1 : 1'd0;
                  flg_n = result[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // DEC absolute
              8'hCE: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [7:0] result = dout - 8'd1;
                  ada <= {operands[7:0], operands[15:8]} & RAMW;
                  din <= result;
                  cea <= 1;
                  flg_z = (result == 8'h00) ? 1'd1 : 1'd0;
                  flg_n = result[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // DEC absolute, X
              8'hDE: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = ({operands[7:0], operands[15:8]} + rx) & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [7:0] result = dout - 8'd1;
                  ada <= ({operands[7:0], operands[15:8]} + rx) & RAMW;
                  din <= result;
                  cea <= 1;
                  flg_z = (result == 8'h00) ? 1'd1 : 1'd0;
                  flg_n = result[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // DEX
              8'hCA: begin
                rx = rx - 1 & 8'hFF;
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                pc <= pc + 1 & RAMW;
                adb <= pc + 1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // DEY
              8'h88: begin
                ry = ry - 1 & 8'hFF;
                flg_z = (ry == 8'h00);
                flg_n = ry[7];
                pc <= pc + 1 & RAMW;
                adb <= pc + 1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // ADC immediate
              8'h69: begin
                automatic logic [8:0] temp;  // make it 9bit to include carry
                // in ADC, +1 if flg_c is 1
                temp = ra + dout + (flg_c ? 1 : 0) & 9'h1FF;
                flg_c = temp[8];
                flg_v = (~(ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                ra = temp[7:0];

                flg_z = (ra == 8'h00);
                flg_n = ra[7];

                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // ADC zero page
              8'h65: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include carry
                  temp = ra + dout + (flg_c ? 1 : 0) & 9'h1FF;
                  flg_c = temp[8];
                  flg_v = (~(ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ADC zero page, X
              8'h75: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0] + rx & 8'hFF;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include carry
                  temp = ra + dout + (flg_c ? 1 : 0) & 9'h1FF;
                  flg_c = temp[8];
                  flg_v = (~(ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ADC absolute
              8'h6D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & RAMW;
                  adb <= addr;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include carry
                  temp = ra + dout + (flg_c ? 1 : 0) & 9'h1FF;
                  flg_c = temp[8];
                  flg_v = (~(ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ADC absolute, X
              8'h7D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} + rx & RAMW;
                  adb <= addr;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include carry
                  temp = ra + dout + (flg_c ? 1 : 0) & 9'h1FF;
                  flg_c = temp[8];
                  flg_v = (~(ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);

                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ADC absolute, Y
              8'h79: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} + ry & RAMW;
                  adb <= addr;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include carry
                  temp = ra + dout + (flg_c ? 1 : 0) & 9'h1FF;
                  flg_c = temp[8];
                  flg_v = (~(ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // TODO: ADC (indirect, X)
              8'h61: begin
              end
              // TODO: ADC (indirect), Y
              8'h71: begin
              end
              // SBC immediate
              8'hE9: begin
                automatic logic [8:0] temp;  // make it 9bit to include borrow
                // in SBC, -1 if flg_c is 0 (clear)
                temp = ra - dout - (flg_c ? 0 : 1) & 9'h1FF;

                flg_c = ~temp[8];  // Borrow flag (inverted carry)
                flg_v = ((ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                ra = temp[7:0];

                flg_z = (ra == 8'h00);
                flg_n = ra[7];

                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // SBC zero page
              8'hE5: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include borrow
                  temp = ra - dout - (flg_c ? 0 : 1) & 9'h1FF;

                  flg_c = ~temp[8];  // Borrow flag (inverted carry)
                  flg_v = ((ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // SBC zero page, X
              8'hF5: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0] + rx & 8'hFF;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include borrow
                  temp = ra - dout - (flg_c ? 0 : 1) & 9'h1FF;

                  flg_c = ~temp[8];  // Borrow flag (inverted carry)
                  flg_v = ((ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // SBC absolute
              8'hED: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & RAMW;
                  adb <= addr;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include borrow
                  temp = ra - dout - (flg_c ? 0 : 1) & 9'h1FF;

                  flg_c = ~temp[8];  // Borrow flag (inverted carry)
                  flg_v = ((ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // SBC absolute, X
              8'hFD: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} + rx & RAMW;
                  adb <= addr;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include borrow
                  temp = ra - dout - (flg_c ? 0 : 1) & 9'h1FF;

                  flg_c = ~temp[8];  // Borrow flag (inverted carry)
                  flg_v = ((ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // SBC absolute, Y
              8'hF9: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} + ry & RAMW;
                  adb <= addr;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include borrow
                  temp = ra - dout - (flg_c ? 0 : 1) & 9'h1FF;

                  flg_c = ~temp[8];  // Borrow flag (inverted carry)
                  flg_v = ((ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // SBC (indirect, X)
              8'hE1: begin
                // TODO: Implement SBC (indirect, X)
              end
              // SBC (indirect), Y
              8'hF1: begin
                // TODO: Implement SBC (indirect), Y
              end
              // AND immediate
              8'h29: begin
                ra = ra & operands[7:0];
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // AND zero page
              8'h25: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = ra & dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // AND zero page, X
              8'h35: begin
                if (fetched_data_bytes == 0) begin
                  adb <= (operands[7:0] + rx) & 8'hFF;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = ra & dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // AND absolute
              8'h2D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = ra & dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // AND absolute, X
              8'h3D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} + rx & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = ra & dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // AND absolute, Y
              8'h39: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} + ry & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = ra & dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // TODO: AND (indirect, X)
              8'h21: begin
              end
              // TODO: AND (indirect), Y
              8'h31: begin
              end
              // EOR immediate
              8'h49: begin
                ra = ra ^ operands[7:0];
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // EOR zero page
              8'h45: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = ra ^ dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // EOR zero page, X
              8'h55: begin
                if (fetched_data_bytes == 0) begin
                  adb <= (operands[7:0] + rx) & 8'hFF;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = ra ^ dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // EOR absolute
              8'h4D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = ra ^ dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // EOR absolute, X
              8'h5D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} + rx & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = ra ^ dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // EOR absolute, Y
              8'h59: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} + ry & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = ra ^ dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // TODO: EOR (indirect, X)
              8'h41: begin
              end
              // TODO: EOR (indirect), Y
              8'h51: begin
              end
              // ORA immediate
              8'h09: begin
                ra = ra | operands[7:0];
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // ORA zero page
              8'h05: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = ra | dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ORA zero page, X
              8'h15: begin
                if (fetched_data_bytes == 0) begin
                  adb <= (operands[7:0] + rx) & 8'hFF;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = ra | dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ORA absolute
              8'h0D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = ra | dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ORA absolute, X
              8'h1D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} + rx & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = ra | dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ORA absolute, Y
              8'h19: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} + ry & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = ra | dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ORA (indirect, X)
              8'h01: begin
                // TODO: Implement ORA (indirect, X)
              end
              // ORA (indirect), Y
              8'h11: begin
                // TODO: Implement ORA (indirect), Y
              end
              // ASL accumulator
              8'h0A: begin
                flg_c = ra[7];  // Capture the carry bit before shifting
                ra = ra << 1;
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                pc <= pc + 1 & RAMW;
                adb <= pc + 1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // ASL zero pabe
              8'h06: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  flg_c = dout[7];  // Capture the carry bit before shifting
                  ra = dout << 1;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ASL zero page, X
              8'h16: begin
                if (fetched_data_bytes == 0) begin
                  adb <= (operands[7:0] + rx) & 8'hFF;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  flg_c = dout[7];  // Capture the carry bit before shifting
                  ra = dout << 1;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ASL absolute
              8'h0E: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  flg_c = dout[7];  // Capture the carry bit before shifting
                  ra = dout << 1;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ASL absolute, X
              8'h1E: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = ({operands[7:0], operands[15:8]} + rx) & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  flg_c = dout[7];  // Capture the carry bit before shifting
                  ra = dout << 1;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ROL accumulator
              8'h2A: begin
                automatic logic carry_in = flg_c;
                flg_c = ra[7];  // Capture the carry bit before shifting
                ra = (ra << 1) | carry_in;
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                pc <= pc + 1 & RAMW;
                adb <= pc + 1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // ROL zero page
              8'h26: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout[7];  // Capture the carry bit before shifting
                  din   = (dout << 1) | carry_in;
                  ada <= operands[7:0];
                  cea <= 1;
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ROL zero page, X
              8'h36: begin
                if (fetched_data_bytes == 0) begin
                  adb <= (operands[7:0] + rx) & 8'hFF;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout[7];  // Capture the carry bit before shifting
                  din   = (dout << 1) | carry_in;
                  ada <= (operands[7:0] + rx) & 8'hFF;
                  cea <= 1;
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ROL absolute
              8'h2E: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout[7];  // Capture the carry bit before shifting
                  din   = (dout << 1) | carry_in;
                  ada <= {operands[7:0], operands[15:8]} & RAMW;
                  cea <= 1;
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ROL absolute, X
              8'h3E: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = ({operands[7:0], operands[15:8]} + rx) & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout[7];  // Capture the carry bit before shifting
                  din   = (dout << 1) | carry_in;
                  ada <= ({operands[7:0], operands[15:8]} + rx) & RAMW;
                  cea <= 1;
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ROR accumulator
              8'h6A: begin
                automatic logic carry_in = flg_c;
                flg_c = ra[0];  // Capture the carry bit before shifting
                ra = (ra >> 1) | (carry_in << 7);
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                pc <= pc + 1 & RAMW;
                adb <= pc + 1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // ROR zero page
              8'h66: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout[0];  // Capture the carry bit before shifting
                  din   = (dout >> 1) | (carry_in << 7);
                  ada <= operands[7:0];
                  cea <= 1;
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ROR zero page, X
              8'h76: begin
                if (fetched_data_bytes == 0) begin
                  adb <= (operands[7:0] + rx) & 8'hFF;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout[0];  // Capture the carry bit before shifting
                  din   = (dout >> 1) | (carry_in << 7);
                  ada <= (operands[7:0] + rx) & 8'hFF;
                  cea <= 1;
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ROR absolute
              8'h6E: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout[0];  // Capture the carry bit before shifting
                  din   = (dout >> 1) | (carry_in << 7);
                  ada <= {operands[7:0], operands[15:8]} & RAMW;
                  cea <= 1;
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ROR absolute, X
              8'h7E: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = ({operands[7:0], operands[15:8]} + rx) & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout[0];  // Capture the carry bit before shifting
                  din   = (dout >> 1) | (carry_in << 7);
                  ada <= ({operands[7:0], operands[15:8]} + rx) & RAMW;
                  cea <= 1;
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // CMP immediate; Compare
              8'hC9: begin
                automatic logic [7:0] result = ra - operands[7:0];
                flg_c = ra >= operands[7:0] ? 1 : 0;
                flg_z = (result == 8'h00);
                flg_n = result[7];
                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // BIT zero apge
              8'h24: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  flg_z = (ra & dout) == 1'd0 ? 1'd1 : 1'd0;
                  flg_n = dout[7];
                  flg_v = dout[6];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // BIT absolute
              8'h2C: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  flg_z = (ra & dout) == 1'd0 ? 1'd1 : 1'd0;
                  flg_n = dout[7];
                  flg_v = dout[6];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // CMP zero page
              8'hC5: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [7:0] result = ra - dout;
                  flg_c = ra >= dout ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // CMP zero page, X
              8'hD5: begin
                if (fetched_data_bytes == 0) begin
                  adb <= (operands[7:0] + rx) & 8'hFF;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [7:0] result = ra - dout;
                  flg_c = ra >= dout ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // CMP absolute
              8'hCD: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [7:0] result = ra - dout;
                  flg_c = ra >= dout ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // CMP absolute, X
              8'hDD: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} + rx & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [7:0] result = ra - dout;
                  flg_c = ra >= dout ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // CMP absolute, Y
              8'hD9: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[15:0] + ry & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [7:0] result = ra - dout;
                  flg_c = ra >= dout ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // TODO: CMP (indirect, X)
              8'hC1: begin
              end
              // TODO: CMP (indirect), Y
              8'hD1: begin
              end
              // CPX immediate; Compare X
              8'hE0: begin
                automatic logic [7:0] result = rx - operands[7:0];
                flg_c = rx >= operands[7:0] ? 1 : 0;
                flg_z = (result == 8'h00);
                flg_n = result[7];
                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
                state <= FETCH_REQ;
              end
              // CPX zero page
              8'hE4: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  state <= FETCH_REQ;
                end else begin
                  automatic logic [7:0] result = rx - dout;
                  flg_c = rx >= dout ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                  state <= FETCH_REQ;
                end
              end
              // CPX absolute
              8'hEC: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [7:0] result = rx - dout;
                  flg_c = rx >= dout ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // CPY immediate; Compare Y
              8'hC0: begin
                automatic logic [7:0] result = ry - operands[7:0];
                flg_c = ry >= operands[7:0] ? 1 : 0;
                flg_z = (result == 8'h00);
                flg_n = result[7];
                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // CPY zero page
              8'hC4: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [7:0] result = ry - dout;
                  flg_c = ry >= dout ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // CPY absolute
              8'hCC: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = {operands[7:0], operands[15:8]} & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  automatic logic [7:0] result = ry - dout;
                  flg_c = ry >= dout ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // TAX
              8'hAA: begin
                rx = ra;
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                pc <= pc + 1 & RAMW;
                adb <= pc + 1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // TAY
              8'hA8: begin
                ry = ra;
                flg_z = (ry == 8'h00);
                flg_n = ry[7];
                pc <= pc + 1 & RAMW;
                adb <= pc + 1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // TXA
              8'h8A: begin
                ra = rx;
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                pc <= pc + 1 & RAMW;
                adb <= pc + 1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // TYA
              8'h98: begin
                ra = ry;
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                pc <= pc + 1 & RAMW;
                adb <= pc + 1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // TSX
              8'hBA: begin
                rx = sp;
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                pc <= pc + 1 & RAMW;
                adb <= pc + 1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // TXS
              8'h9A: begin
                sp = rx;
                pc <= pc + 1 & RAMW;
                adb <= pc + 1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end

              // BEQ
              8'hF0: begin
                if (flg_z == 1) begin
                  // sign extend
                  s_imm8 = operands[7:0];
                  s_offset = s_imm8;
                  addr = (pc + 16'd2 + s_offset) & RAMW;
                  pc  <= addr;
                  adb <= addr;
                end else begin
                  pc  <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                end
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // BMI
              8'h30: begin
                if (flg_n == 1) begin
                  // sign extend
                  s_imm8 = operands[7:0];
                  s_offset = s_imm8;
                  addr = (pc + 16'd2 + s_offset) & RAMW;
                  pc  <= addr;
                  adb <= addr;
                end else begin
                  pc  <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                end
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // BNE
              8'hD0: begin
                if (flg_z == 0) begin
                  // sign extend
                  s_imm8 = operands[7:0];
                  s_offset = s_imm8;
                  addr = (pc + 16'd2 + s_offset) & RAMW;
                  pc  <= addr;
                  adb <= addr;
                end else begin
                  pc  <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                end
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // BPL
              8'h10: begin
                if (flg_n == 0) begin
                  // sign extend
                  s_imm8 = operands[7:0];
                  s_offset = s_imm8;
                  addr = (pc + 16'd2 + s_offset) & RAMW;
                  pc  <= addr;
                  adb <= addr;
                end else begin
                  pc  <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                end
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // BVC
              8'h50: begin
                if (flg_v == 0) begin
                  // sign extend
                  s_imm8 = operands[7:0];
                  s_offset = s_imm8;
                  addr = (pc + 16'd2 + s_offset) & RAMW;
                  pc  <= addr;
                  adb <= addr;
                end else begin
                  pc  <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                end
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // BVS
              8'h70: begin
                if (flg_v == 1) begin
                  // sign extend
                  s_imm8 = operands[7:0];
                  s_offset = s_imm8;
                  addr = (pc + 16'd2 + s_offset) & RAMW;
                  pc  <= addr;
                  adb <= addr;
                end else begin
                  pc  <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                end
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // BCC
              8'h90: begin
                if (flg_c == 0) begin
                  // sign extend
                  s_imm8 = operands[7:0];
                  s_offset = s_imm8;
                  addr = (pc + 16'd2 + s_offset) & RAMW;
                  pc  <= addr;
                  adb <= addr;
                end else begin
                  pc  <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                end
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // BCS
              8'hB0: begin
                if (flg_c == 1) begin
                  // sign extend
                  s_imm8 = operands[7:0];
                  s_offset = s_imm8;
                  addr = (pc + 16'd2 + s_offset) & RAMW;
                  pc  <= addr;
                  adb <= addr;
                end else begin
                  pc  <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                end
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // CLC
              8'h18: begin
                flg_c = 1'b0;
                pc <= pc + 1 & RAMW;
                adb <= pc + 1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // CLV
              8'hB8: begin
                flg_v = 1'b0;
                pc <= pc + 1 & RAMW;
                adb <= pc + 1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // SEC
              8'h38: begin
                flg_c = 1'b1;
                pc <= pc + 1 & RAMW;
                adb <= pc + 1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end

              // TODO: support more instructions

              default: ;  // No operation.
            endcase
          end

          WRITE_REQ: begin
            written_data_bytes <= written_data_bytes + 1'd1;
            state <= DECODE_EXECUTE;
          end
          // --- end of case(state) ---
        endcase
      end
    end
  end

endmodule
