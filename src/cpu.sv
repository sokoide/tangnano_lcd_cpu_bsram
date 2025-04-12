`include "consts.svh"

module cpu (
`ifdef DEBUG_MODE
`endif
    input  logic        rst_n,
    input  logic        clk,
    input  logic [ 7:0] dout,   // RAM data which was read
    output logic [ 7:0] din,    // RAM data to write
    output logic [12:0] ada,    // write RAM
    output logic        cea,    // RAM write enable
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

  // Internal states
  logic [7:0] opcode;
  logic [15:0] operands;
  logic data_available;
  logic [7:0] char_code;
  logic [31:0] counter;

  typedef enum logic [2:0] {
    INIT,
    WAIT_64K_CLKS,
    HALT,
    FETCH_REQ,
    WAIT1,
    FETCH_RECV,
    DECODE_EXECUTE
  } state_t;

  state_t state;

  typedef enum logic [2:0] {
    FETCH_OPCODE,  // transition to FETCH_OPCODE, FETCH_OPERAND1 or FETCH_OPERAND1OF2,
    FETCH_DATA,
    FETCH_OPERAND1,  // final stage
    FETCH_OPERAND1OF2,  // transition to FETCH_OPERAND2
    FETCH_OPERAND2  // final stage
  } fetch_stage_t;

  fetch_stage_t fetch_stage;

`ifdef DEBUG_MODE
  // Assign debug output for testing
  // assign debug_regs = regs;
`endif

  // Sequential logic: use an asynchronous active-low rst_n.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // rst_n: clear selected registers and the flag.
      {ra, rx, ry}                                      <= 8'd0;
      {flg_c, flg_z, flg_i, flg_d, flg_b, flg_v, flg_n} <= 1'b0;
      pc                                                <= 16'h0200;
      sp                                                <= 8'hFF;
      ada                                               <= 13'h0200;
      adb                                               <= 13'h0200;
      v_ada                                             <= 10'h0000;
      v_cea                                             <= 0;
      v_din                                             <= 8'h0;
      opcode                                            <= 8'd0;
      state                                             <= INIT;
      char_code                                         <= 8'h20;  // ' '
      counter                                           <= 32'h0;
    end else begin
      begin
        counter <= (counter + 1) & 32'hFFFFFFFF;

        // --- case(state) ---
        case (state)
          INIT: begin
            if (v_ada <= COLUMNS * ROWS) begin
              v_ada <= v_ada + 1 & VRAMW;
            end else begin
              v_ada <= 10'h0000;
              // v_cea <= 0;
              // state <= HALT;
            end
            v_cea <= 1;
            v_din <= char_code;
            char_code <= (char_code < 8'h7F) ? (char_code + 1) & 8'hFF : 8'h20;
            state <= WAIT_64K_CLKS;
          end

          WAIT_64K_CLKS: begin
            if ((counter & 16'hFFFF) == 0) begin
              state <= INIT;
            end
          end

          HALT: begin
            ;  // do nothing
          end

          FETCH_REQ: begin
            state <= WAIT1;
          end

          WAIT1: begin
            state <= FETCH_RECV;
            if (fetch_stage == FETCH_DATA) begin
              data_available <= 1;
              state <= DECODE_EXECUTE;
            end

          end

          FETCH_RECV: begin
            // --- case (fetch_stage) ---
            case (fetch_stage)
              FETCH_OPCODE: begin
                opcode <= dout;
                data_available <= 0;
                cea <= 0; // disable write
                case (dout)
                  // JMP immediate
                  8'h4C: begin
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // LDA immediate
                  8'hA9: begin
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LDA zero page
                  8'hA5: begin
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LDA zero page, X
                  8'hB5: begin
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LDA absolute
                  8'hAD: begin
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // LDA absolute, X
                  8'hBD: begin
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // LDA absolute, Y
                  8'hB9: begin
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
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LDX zero page
                  8'hA6: begin
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LDX zero page, Y
                  8'hAA: begin
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LDX absolute
                  8'hAE: begin
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // LDX absolute, Y
                  8'hBE: begin
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // LDY immediate
                  8'hA0: begin
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LDY zero page
                  8'hA4: begin
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LDY zero page, X
                  8'hB4: begin
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // LDY absolute
                  8'hAC: begin
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // LDY absolute, X
                  8'hBC: begin
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // STA zero page
                  8'h85: begin
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // STA zero page, X
                  8'h95: begin
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end
                  // STA absolute
                  8'h8D: begin
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // STA absolute, X
                  8'h9D: begin
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // STA absolute, Y
                  8'h99: begin
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                  // TODO: STA (indirext, X)
                  // TODO: STA (indirext), Y

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
              // JMP absolute
              8'h4C: begin
                pc <= {operands[15:8], operands[7:0]};
                adb <= {operands[15:8], operands[7:0]} & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // LDA immediate
              8'hA9: begin
                ra = operands[7:0];
                flg_z = (ra == 0 ? 1 : 0);
                flg_n = (ra[7] == 1 ? 1 : 0);
                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // LDA zero page
              8'hA5: begin
                // fetch operand[7:0]'s value from memory and store it to ra.
                if (data_available == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = dout;
                  flg_z = (ra == 0 ? 1 : 0);
                  flg_n = (ra[7] == 1 ? 1 : 0);
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
                if (data_available == 0) begin
                  adb <= (operands[7:0] + rx) & 8'hFF;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = dout;
                  flg_z = (ra == 0 ? 1 : 0);
                  flg_n = (ra[7] == 1 ? 1 : 0);
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDA absolute
              8'hAD: begin
                // fetch operand[15:0]'s value from memory and store it to ra.
                if (data_available == 0) begin
                  adb <= operands[15:0] & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = dout;
                  flg_z = (ra == 0 ? 1 : 0);
                  flg_n = (ra[7] == 1 ? 1 : 0);
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDA absolute, X
              8'hBD: begin
                // fetch operand[15:0] + rx's value from memory and store it to ra.
                if (data_available == 0) begin
                  adb <= operands[15:0] + rx & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = dout;
                  flg_z = (ra == 0 ? 1 : 0);
                  flg_n = (ra[7] == 1 ? 1 : 0);
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDA absolute, Y
              8'hB9: begin
                // fetch operand[15:0] + ry's value from memory and store it to ra.
                if (data_available == 0) begin
                  adb <= operands[15:0] + ry & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ra = dout;
                  flg_z = (ra == 0 ? 1 : 0);
                  flg_n = (ra[7] == 1 ? 1 : 0);
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // TODO: LDA (indirect, X)
              // 8'hA1: begin
              // fetch operand[7:0] + rx's and the next value from the zero page
              // in little endian.
              // then read an 8bit data pointed by the address.
              // end
              // TODO: LDA (indirect), Y
              // 8'hB1: begin
              // fetch operand[7:0] and the next value from the zero page
              // in litte endian.
              // then read an 8bit data pointed by the address+ry.
              // end
              // LDX immediate
              8'hA2: begin
                rx = operands[7:0];
                flg_z = (rx == 0 ? 1 : 0);
                flg_n = (rx[7] == 1 ? 1 : 0);
                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // LDX zero page
              8'hA6: begin
                if (data_available == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  rx = dout;
                  flg_z = (rx == 0 ? 1 : 0);
                  flg_n = (rx[7] == 1 ? 1 : 0);
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDX zero page, Y
              8'hAA: begin
                if (data_available == 0) begin
                  adb <= (operands[7:0] + ry) & 8'hFF;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  rx = dout;
                  flg_z = (rx == 0 ? 1 : 0);
                  flg_n = (rx[7] == 1 ? 1 : 0);
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDX absolute
              8'hAE: begin
                if (data_available == 0) begin
                  adb <= operands[15:0] & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  rx = dout;
                  flg_z = (rx == 0 ? 1 : 0);
                  flg_n = (rx[7] == 1 ? 1 : 0);
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDX absolute, Y
              8'hBE: begin
                if (data_available == 0) begin
                  adb <= operands[15:0] + ry & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  rx = dout;
                  flg_z = (rx == 0 ? 1 : 0);
                  flg_n = (rx[7] == 1 ? 1 : 0);
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDY immediate
              8'hA0: begin
                ry = operands[7:0];
                flg_z = (ra == 0 ? 1 : 0);
                flg_n = (ra[7] == 1 ? 1 : 0);
                pc <= pc + 2 & RAMW;
                adb <= pc + 2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // LDY zero page
              8'hA4: begin
                if (data_available == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ry = dout;
                  flg_z = (ry == 0 ? 1 : 0);
                  flg_n = (ry[7] == 1 ? 1 : 0);
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDY zero page, X
              8'hB4: begin
                if (data_available == 0) begin
                  adb <= (operands[7:0] + rx) & 8'hFF;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ry = dout;
                  flg_z = (ry == 0 ? 1 : 0);
                  flg_n = (ry[7] == 1 ? 1 : 0);
                  pc <= pc + 2 & RAMW;
                  adb <= pc + 2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDY absolute
              8'hAC: begin
                if (data_available == 0) begin
                  adb <= operands[15:0] & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ry = dout;
                  flg_z = (ry == 0 ? 1 : 0);
                  flg_n = (ry[7] == 1 ? 1 : 0);
                  pc <= pc + 3 & RAMW;
                  adb <= pc + 3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDY abosolute, X
              8'hBC: begin
                if (data_available == 0) begin
                  adb = operands[15:0] + rx & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                end else begin
                  ry = dout;
                  flg_z = (ry == 0 ? 1 : 0);
                  flg_n = (ry[7] == 1 ? 1 : 0);
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
                fetch_stage <= FETCH_OPCODE;
              end
              // STA absolute
              8'h8D: begin
                // check if it's RAM or VRAM
                automatic logic[15:0] addr = operands[15:0] & RAMW;
                if (addr >= VRAM_START) begin
                  v_ada <= addr - VRAM_START;
                  v_din <= ra;
                  v_cea <= 1;
                end else begin
                  ada <= addr;
                  din <= ra;
                  cea <= 1;
                end
                pc <= pc + 3 & RAMW;
                adb <= pc + 3 & RAMW;
                fetch_stage <= FETCH_OPCODE;
              end
              // STA absolute, X
              8'h9D: begin
                // check if it's RAM or VRAM
                automatic logic[15:0] addr = operands[15:0] + rx & RAMW;
                if (addr >= VRAM_START) begin
                  v_ada <= addr - VRAM_START;
                  v_din <= ra;
                  v_cea <= 1;
                end else begin
                  ada <= addr;
                  din <= ra;
                  cea <= 1;
                end
                pc <= pc + 3 & RAMW;
                adb <= pc + 3 & RAMW;
                fetch_stage <= FETCH_OPCODE;
              end
              // STA absolute, Y
              8'h99: begin
                // check if it's RAM or VRAM
                automatic logic[15:0] addr = operands[15:0] + ry & RAMW;
                if (addr >= VRAM_START) begin
                  v_ada <= addr - VRAM_START;
                  v_din <= ra;
                  v_cea <= 1;
                end else begin
                  ada <= addr;
                  din <= ra;
                  cea <= 1;
                end
                pc <= pc + 3 & RAMW;
                adb <= pc + 3 & RAMW;
                fetch_stage <= FETCH_OPCODE;
              end

              // TODO: support more instructions

              default: ;  // No operation.
            endcase
            state <= FETCH_REQ;
          end
          // --- end of case(state) ---
        endcase
      end
    end
  end

endmodule
