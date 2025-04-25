`include "consts.svh"
module cpu (
    input logic rst_n,
    input logic clk,
    input logic [7:0] dout,  // RAM data which was read
    input logic vsync,  // 1 during LCD vsync
    input logic [7:0] boot_program[7680],  // Boot program, max size 0x200-0x1FFF (7680 bytes)
    input logic [15:0] boot_program_length,  // Boot program length
    output logic [7:0] din,  // RAM data to write
    output logic [14:0] ada,  // write RAM
    output logic cea,  // RAM write enable
    output logic ceb,  // RAM read enable
    output logic [14:0] adb,  // read RAM
    output logic [9:0] v_ada,  // write VRAM
    output logic v_cea,  // VRAM write enable
    output logic [7:0] v_din  // VRAM data to write
);

  `include "cpu_tasks.sv"


  // Internal registers.
  logic [15:0] pc;  // Program Counter
  logic [15:0] pc_plus1;
  logic [15:0] pc_plus2;
  logic [15:0] pc_plus3;
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
  logic [9:0] boot_idx;
  logic boot_write;
  logic vsync_meta, vsync_sync;
  logic [ 1:0] vsync_stage;
  logic [31:0] show_info_counter;

  typedef enum logic [3:0] {
    INIT,
    INIT_VRAM,
    INIT_RAM,
    HALT,
    FETCH_REQ,
    FETCH_RECV,
    DECODE_EXECUTE,
    WRITE_REQ,
    SHOW_INFO,
    SHOW_INFO2,
    CLEAR_VRAM,
    CLEAR_VRAM2
  } state_t;

  state_t state;
  state_t prev_state;
  state_t next_state;

  typedef enum logic [2:0] {
    FETCH_OPCODE,  // transition to FETCH_OPCODE, FETCH_OPERAND1 or FETCH_OPERAND1OF2,
    FETCH_DATA,
    FETCH_OPERAND1,  // final stage
    FETCH_OPERAND1OF2,  // transition to FETCH_OPERAND2
    FETCH_OPERAND2  // final stage
  } fetch_stage_t;

  fetch_stage_t fetch_stage;

  typedef enum logic [1:0] {
    SHOW_INFO_FETCH,
    SHOW_INFO_EXECUTE
  } show_info_stage_t;

  show_info_stage_t show_info_stage;

  // Sequential logic: use an asynchronous active-low rst_n.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // rst_n: clear selected registers and the flag.
      {ra, rx, ry}                                      <= 8'd0;
      {flg_c, flg_z, flg_i, flg_d, flg_b, flg_v, flg_n} <= 1'b0;
      pc                                                <= 16'h0200;
      pc_plus1                                          <= 16'h0000;
      pc_plus2                                          <= 16'h0000;
      pc_plus3                                          <= 16'h0000;
      sp                                                <= 8'hFF;
      ada                                               <= 15'h0000;
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
      next_state                                        <= INIT;
      char_code                                         <= 8'h20;  // ' '
      counter                                           <= 32'h0;
      boot_idx                                          <= 0;
      boot_write                                        <= 0;
      vsync_meta                                        <= 1'b0;
      vsync_sync                                        <= 1'b0;
      vsync_stage                                       <= 0;
      show_info_counter                                 <= 0;
    end else begin
      vsync_meta <= vsync;
      vsync_sync <= vsync_meta;
      begin
        counter <= (counter + 1) & 32'hFFFFFFFF;

        // --- case(state) ---
        case (state)
          INIT: begin
            v_cea <= 0;  // VRAM write disable
            boot_write <= 1;
            state <= INIT_RAM;
          end

          INIT_VRAM: begin
            v_cea <= 1;  // VRAM write enable
            // cea <= 1;  // RAM write enable
            v_din <= char_code;
            // din <= char_code;
            char_code <= (char_code < 8'h7F) ? (char_code + 1) & 8'hFF : 8'h20;

            if (v_ada <= COLUMNS * ROWS) begin
              v_ada <= v_ada + 1 & VRAMW;
              // shadow VRAM
              // ada   <= v_ada + 1 + SHADOW_VRAM_START & RAMW;
            end else begin
              v_cea <= 0;  // VRAM write disable
              state <= HALT;
            end
          end

          INIT_RAM: begin
            if (boot_write) begin
              boot_write <= 0;
              cea <= 1;  // RAM write enable
              ada <= PROGRAM_START + boot_idx & RAMW;
              din <= boot_program[boot_idx];
            end else begin
              cea <= 0;
              if (boot_idx == boot_program_length) begin
                v_cea <= 1;  // VRAM write enable
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end else begin
                boot_idx   <= boot_idx + 1 & 8'hFF;
                boot_write <= 1;
              end
            end
          end

          HALT: begin
            // Do nothing
          end

          FETCH_REQ: begin
            if (fetch_stage == FETCH_DATA) begin
              fetched_data_bytes <= fetched_data_bytes + 1'd1;
              state <= next_state;
            end else begin
              state <= FETCH_RECV;
              // timing improvement to avoid "adb <= pc + 1 & RAMW;" in the DECODE_EXECUTE state
              pc_plus1 <= pc + 16'd1 & RAMW;
              pc_plus2 <= pc + 16'd2 & RAMW;
              pc_plus3 <= pc + 16'd3 & RAMW;
            end
          end

          FETCH_RECV: begin
            case (fetch_stage)
              FETCH_OPCODE: begin
                opcode <= dout;
                fetched_data_bytes <= 0;
                written_data_bytes <= 0;
                cea <= 0;  // disable write

                case (dout)
                  // No operand instructions
                  8'hEA,  // NOP
                  8'h60,  // RTS
                  8'h48,  // PHA
                  8'h68,  // PLA
                  8'h08,  // PHP
                  8'h28,  // PLP
                  8'hE8,  // INX
                  8'hC8,  // INY
                  8'hCA,  // DEX
                  8'h88,  // DEY
                  8'h0A,  // ASL accumulator
                  8'h4A,  // LSR accumulator
                  8'h2A,  // ROL accumulator
                  8'h6A,  // ROR accumulator
                  8'hAA,  // TAX
                  8'hA8,  // TAY
                  8'h8A,  // TXA
                  8'h98,  // TYA
                  8'hBA,  // TSX
                  8'h9A,  // TXS
                  8'h18,  // CLC
                  8'hB8,  // CLV
                  8'h38,  // SEC
                  8'hCF,  // CVR
                  8'hEF:  // HLT
                  state <= DECODE_EXECUTE;

                  // Instructions with 1-byte operand
                  8'hA9,  // LDA immediate
                  8'hA5,  // LDA zero page
                  8'hB5,  // LDA zero page,X
                  8'hA2,  // LDX immediate
                  8'hA6,  // LDX zero page
                  8'hB6,  // LDX zero page,Y
                  8'hA0,  // LDY immediate
                  8'hA4,  // LDY zero page
                  8'hB4,  // LDY zero page,X
                  8'h85,  // STA zero page
                  8'h95,  // STA zero page,X
                  8'h81,  // STA (indirect,X)
                  8'h91,  // STA (indirect),Y
                  8'h86,  // STX zero page
                  8'h96,  // STX zero page,Y
                  8'h84,  // STY zero page
                  8'h94,  // STY zero page,X
                  8'hE6,  // INC zero page
                  8'hF6,  // INC zero page,X
                  8'hC6,  // DEC zero page
                  8'hD6,  // DEC zero page,X
                  8'h69,  // ADC immediate
                  8'h65,  // ADC zero page
                  8'h75,  // ADC zero page,X
                  8'h61,  // ADC (indirect,X)
                  8'h71,  // ADC (indirect),Y
                  8'hE9,  // SBC immediate
                  8'hE5,  // SBC zero page
                  8'hF5,  // SBC zero page,X
                  8'hE1,  // SBC (indirect,X)
                  8'hF1,  // SBC (indirect),Y
                  8'h29,  // AND immediate
                  8'h25,  // AND zero page
                  8'h35,  // AND zero page,X
                  8'h21,  // AND (indirect,X)
                  8'h31,  // AND (indirect),Y
                  8'h49,  // EOR immediate
                  8'h45,  // EOR zero page
                  8'h55,  // EOR zero page,X
                  8'h41,  // EOR (indirect,X)
                  8'h51,  // EOR (indirect),Y
                  8'h09,  // ORA immediate
                  8'h05,  // ORA zero page
                  8'h15,  // ORA zero page,X
                  8'h01,  // ORA (indirect,X)
                  8'h11,  // ORA (indirect),Y
                  8'h06,  // ASL zero page
                  8'h16,  // ASL zero page,X
                  8'h46,  // LSR zero page
                  8'h56,  // LSR zero page,X
                  8'h26,  // ROL zero page
                  8'h36,  // ROL zero page,X
                  8'h66,  // ROR zero page
                  8'h76,  // ROR zero page,X
                  8'h24,  // BIT zero page
                  8'hC9,  // CMP immediate
                  8'hC5,  // CMP zero page
                  8'hD5,  // CMP zero page,X
                  8'hC1,  // CMP (indirect,X)
                  8'hD1,  // CMP (indirect),Y
                  8'hE0,  // CPX immediate
                  8'hE4,  // CPX zero page
                  8'hC0,  // CPY immediate
                  8'hC4,  // CPY zero page
                  8'hF0,  // BEQ
                  8'h30,  // BMI
                  8'hD0,  // BNE
                  8'h10,  // BPL
                  8'h50,  // BVC
                  8'h70,  // BVS
                  8'h90,  // BCC
                  8'hB0,  // BCS
                  8'hFF:  // WVS custom instruction
                  begin
                    adb <= pc_plus1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1;
                    state <= FETCH_REQ;
                  end

                  // Instructions with 2-byte operand
                  default: begin
                    adb <= pc_plus1 & RAMW;
                    fetch_stage <= FETCH_OPERAND1OF2;
                    state <= FETCH_REQ;
                  end
                endcase
              end

              FETCH_OPERAND1: begin
                operands[7:0] <= dout;
                state <= DECODE_EXECUTE;
              end

              FETCH_OPERAND1OF2: begin
                // 2 byte operand will be stored as operands[15:0] in big endian
                // which is easier to calculate
                operands[7:0] <= dout;
                adb <= pc_plus2 & RAMW;
                fetch_stage <= FETCH_OPERAND2;
                state <= FETCH_REQ;
              end

              FETCH_OPERAND2: begin
                operands[15:8] <= dout;
                state <= DECODE_EXECUTE;
              end
            endcase
          end

          DECODE_EXECUTE: begin
            case (opcode)
              // NOP
              8'hEA: begin
                pc <= pc_plus1;
                adb <= pc_plus1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // JMP absolute
              8'h4C: begin
                automatic logic [15:0] addr = operands[15:0] & RAMW;
                pc <= addr;
                adb <= addr;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // JMP indirect
              8'h6C: begin
                case (fetched_data_bytes)
                  0: begin
                    adb <= operands[15:0] & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  1: begin
                    fetched_data[7:0] = dout;
                    adb <= (operands[15:0] + 1) & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
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
                    din   <= (pc_plus2) >> 8 & 8'hFF;
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
                    // operands is in big endian.
                    automatic logic [15:0] addr = operands[15:0] & RAMW;
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
                    next_state <= DECODE_EXECUTE;
                  end
                  1: begin
                    // fetch high byte of PC-1
                    fetched_data[7:0] = dout;
                    sp = sp + 1'd1;
                    adb <= STACK + sp;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
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
                pc <= pc_plus1;
                adb <= pc_plus1 & RAMW;
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
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus1;
                  adb <= pc_plus1 & RAMW;
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
                pc <= pc_plus1;
                adb <= pc_plus1 & RAMW;
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
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic dummy;
                  {flg_n, flg_v, dummy, flg_b, flg_d, flg_i, flg_z, flg_c} = dout;
                  pc <= pc_plus1;
                  adb <= pc_plus1 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDA immediate
              8'hA9: begin
                ra = operands[7:0];
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                pc <= pc_plus2;
                adb <= pc_plus2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // LDA zero page
              8'hA5: begin
                // fetch operands[7:0]'s value from memory and store it to ra.
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  ra <= dout;
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDA zero page, X
              8'hB5: begin
                // fetch operands[7:0] + rx's value from memory and store it to ra.
                if (fetched_data_bytes == 0) begin
                  adb <= (operands[7:0] + rx) & 8'hFF;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDA absolute
              8'hAD: begin
                // fetch operands[15:0]'s value from memory and store it to ra.
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDA absolute, X
              8'hBD: begin
                // fetch operands[15:0] + rx's value from memory and store it to ra.
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] + rx & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDA absolute, Y
              8'hB9: begin
                // fetch operands[15:0] + ry's value from memory and store it to ra.
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] + ry & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDA (indirect, X)
              8'hA1: begin
                // fetch operands[7:0] + rx and the next value from the zero page
                // (total 16bit) in litte endian.
                // then read an 8bit data pointed by the address.
                case (fetched_data_bytes)
                  0: begin
                    // fetch operands[7:0]
                    adb <= operands[7:0] + rx & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetched_data[7:0] = dout;
                    adb <= operands[7:0] + rx + 8'h01 & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  2: begin
                    // fetched_data[15:8] = dout;
                    // only RAM read is supported (VRAM is not)
                    automatic logic [15:0] addr = {dout, fetched_data[7:0]} & 16'hFFFF;
                    adb <= addr & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  3: begin
                    ra = dout;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus2;
                    adb <= pc_plus2 & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                  end
                endcase
              end
              // LDA (indirect), Y
              8'hB1: begin
                // fetch operands[7:0] and the next value from the zero page
                // (total 16bit) in litte endian.
                // then read an 8bit data pointed by the address+ry.
                case (fetched_data_bytes)
                  0: begin
                    // fetch operands[7:0]
                    adb <= operands[7:0] & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetched_data[7:0] = dout;
                    adb <= operands[7:0] + 8'h01 & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  2: begin
                    // fetched_data[15:8] = dout;
                    // only RAM read is supported (VRAM is not)
                    automatic logic [15:0] addr = {dout, fetched_data[7:0]} + ry & 16'hFFFF;
                    adb <= addr & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  3: begin
                    ra = dout;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus2;
                    adb <= pc_plus2 & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                  end
                endcase
              end
              // LDX immediate
              8'hA2: begin
                rx = operands[7:0];
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                pc <= pc_plus2;
                adb <= pc_plus2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // LDX zero page
              8'hA6: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  rx = dout;
                  flg_z = (rx == 8'h00);
                  flg_n = rx[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  next_state <= DECODE_EXECUTE;
                end else begin
                  rx = dout;
                  flg_z = (rx == 8'h00);
                  flg_n = rx[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDX absolute
              8'hAE: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  rx = dout;
                  flg_z = (rx == 8'h00);
                  flg_n = rx[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDX absolute, Y
              8'hBE: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] + ry & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  rx = dout;
                  flg_z = (rx == 8'h00);
                  flg_n = rx[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDY immediate
              8'hA0: begin
                ry = operands[7:0];
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                pc <= pc_plus2;
                adb <= pc_plus2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // LDY zero page
              8'hA4: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ry = dout;
                  flg_z = (ry == 8'h00);
                  flg_n = ry[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ry = dout;
                  flg_z = (ry == 8'h00);
                  flg_n = ry[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // LDY absolute
              8'hAC: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ry = dout;
                  flg_z = (ry == 8'h00);
                  flg_n = ry[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
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
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ry = dout;
                  flg_z = (ry == 8'h00);
                  flg_n = ry[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
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
                pc <= pc_plus2;
                adb <= pc_plus2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // STA zero page, X
              8'h95: begin
                // always RAM (zero page)
                ada <= operands[7:0] + rx & 8'hFF;
                din <= ra;
                cea <= 1;
                pc <= pc_plus2;
                adb <= pc_plus2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // STA absolute
              8'h8D: begin
                // check if it's RAM or VRAM
                automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                sta_write(addr, ra);
                pc <= pc_plus3;
                adb <= pc_plus3 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // STA absolute, X
              8'h9D: begin
                // check if it's RAM or VRAM
                automatic logic [15:0] addr = operands[15:0] + rx & 16'hFFFF;
                sta_write(addr, ra);
                pc <= pc_plus3;
                adb <= pc_plus3 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // STA absolute, Y
              8'h99: begin
                // check if it's RAM or VRAM
                automatic logic [15:0] addr = operands[15:0] + ry & 16'hFFFF;
                sta_write(addr, ra);
                pc <= pc_plus3;
                adb <= pc_plus3 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // STA (indirect, X)
              8'h81: begin
                // fetch operands[7:0] + rx and the next value from the zero page
                // (total 16bit) in litte endian.
                // then write an 8bit data pointed by the address.
                case (fetched_data_bytes)
                  0: begin
                    // fetch operands[7:0]
                    adb <= operands[7:0] + rx & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetched_data[7:0] = dout;
                    adb <= operands[7:0] + rx + 8'h01 & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  2: begin
                    // fetched_data[15:8] = dout;
                    // check if it's RAM or VRAM
                    automatic logic [15:0] addr = {dout, fetched_data[7:0]} & 16'hFFFF;
                    sta_write(addr, ra);
                    pc <= pc_plus2;
                    adb <= pc_plus2 & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                  end
                endcase
              end
              // STA (indirect), Y
              8'h91: begin
                // fetch operands[7:0] and the next value from the zero page
                // (total 16bit) in litte endian.
                // then write an 8bit data pointed by the address+ry.
                case (fetched_data_bytes)
                  0: begin
                    // fetch operands[7:0]
                    adb <= operands[7:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetched_data[7:0] = dout;
                    adb <= operands[7:0] + 8'h01 & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  2: begin
                    // fetched_data[15:8] = dout;
                    // check if it's RAM or VRAM
                    automatic logic [15:0] addr = {dout, fetched_data[7:0]} + ry & 16'hFFFF;
                    sta_write(addr, ra);
                    pc <= pc_plus2;
                    adb <= pc_plus2 & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                  end
                endcase
              end
              // STX zero page
              8'h86: begin
                ada <= operands[7:0];
                din <= rx;
                cea <= 1;
                pc <= pc_plus2;
                adb <= pc_plus2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // STX zero page, Y
              8'h96: begin
                ada <= operands[7:0] + ry & 8'hFF;
                din <= rx;
                cea <= 1;
                pc <= pc_plus2;
                adb <= pc_plus2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // STX absolute
              8'h8E: begin
                // check if it's RAM or VRAM
                automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                sta_write(addr, rx);
                pc <= pc_plus3;
                adb <= pc_plus3 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              //  STY zero page
              8'h84: begin
                ada <= operands[7:0];
                din <= ry;
                cea <= 1;
                pc <= pc_plus2;
                adb <= pc_plus2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              //  STY zero page, X
              8'h94: begin
                ada <= operands[7:0] + rx & 8'hFF;
                din <= ry;
                cea <= 1;
                pc <= pc_plus2;
                adb <= pc_plus2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // STY absolute
              8'h8C: begin
                // check if it's RAM or VRAM
                automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                sta_write(addr, ry);
                pc <= pc_plus3;
                adb <= pc_plus3 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // INC zero page
              8'hE6: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [7:0] result = dout + 8'd1;
                  ada <= operands[7:0];
                  din <= result;
                  cea <= 1;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [7:0] result = dout + 8'd1;
                  ada <= operands[7:0];
                  din <= result;
                  cea <= 1;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // INC absolute
              8'hEE: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  // VRAM is write only. INC for VRAM is not supported.
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [7:0] result = dout + 8'd1;
                  ada <= operands[15:0] & RAMW;
                  din <= result;
                  cea <= 1;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // INC absolute, X
              8'hFE: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] + rx & 16'hFFFF;
                  // VRAM is write only. INC for VRAM is not supported.
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [7:0] result = dout + 8'd1;
                  ada <= operands[15:0] & RAMW;
                  din <= result;
                  cea <= 1;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // INX
              8'hE8: begin
                rx = rx + 1 & 8'hFF;
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                pc <= pc_plus1;
                adb <= pc_plus1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // INY
              8'hC8: begin
                ry = ry + 1 & 8'hFF;
                flg_z = (ry == 8'h00);
                flg_n = ry[7];
                pc <= pc_plus1;
                adb <= pc_plus1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // DEC zero page
              8'hC6: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [7:0] result = dout - 8'd1;
                  ada <= operands[7:0];
                  din <= result;
                  cea <= 1;
                  flg_z = (result == 8'h00) ? 1'd1 : 1'd0;
                  flg_n = result[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [7:0] result = dout - 8'd1;
                  ada <= (operands[7:0] + rx) & 8'hFF;
                  din <= result;
                  cea <= 1;
                  flg_z = (result == 8'h00) ? 1'd1 : 1'd0;
                  flg_n = result[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // DEC absolute
              8'hCE: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [7:0] result = dout - 8'd1;
                  ada <= operands[15:0] & RAMW;
                  din <= result;
                  cea <= 1;
                  flg_z = (result == 8'h00) ? 1'd1 : 1'd0;
                  flg_n = result[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // DEC absolute, X
              8'hDE: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + rx) & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [7:0] result = dout - 8'd1;
                  ada <= (operands[15:0] + rx) & RAMW;
                  din <= result;
                  cea <= 1;
                  flg_z = (result == 8'h00) ? 1'd1 : 1'd0;
                  flg_n = result[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // DEX
              8'hCA: begin
                rx = rx - 1 & 8'hFF;
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                pc <= pc_plus1;
                adb <= pc_plus1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // DEY
              8'h88: begin
                ry = ry - 1 & 8'hFF;
                flg_z = (ry == 8'h00);
                flg_n = ry[7];
                pc <= pc_plus1;
                adb <= pc_plus1 & RAMW;
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

                pc <= pc_plus2;
                adb <= pc_plus2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // ADC zero page
              8'h65: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include carry
                  temp = ra + dout + (flg_c ? 1 : 0) & 9'h1FF;
                  flg_c = temp[8];
                  flg_v = (~(ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include carry
                  temp = ra + dout + (flg_c ? 1 : 0) & 9'h1FF;
                  flg_c = temp[8];
                  flg_v = (~(ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ADC absolute
              8'h6D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & RAMW;
                  adb <= addr;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include carry
                  temp = ra + dout + (flg_c ? 1 : 0) & 9'h1FF;
                  flg_c = temp[8];
                  flg_v = (~(ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ADC absolute, X
              8'h7D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] + rx & RAMW;
                  adb <= addr;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include carry
                  temp = ra + dout + (flg_c ? 1 : 0) & 9'h1FF;
                  flg_c = temp[8];
                  flg_v = (~(ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);

                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ADC absolute, Y
              8'h79: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] + ry & RAMW;
                  adb <= addr;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include carry
                  temp = ra + dout + (flg_c ? 1 : 0) & 9'h1FF;
                  flg_c = temp[8];
                  flg_v = (~(ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ADC (indirect, X)
              8'h61: begin
                case (fetched_data_bytes)
                  0: begin
                    // fetch operands[7:0]
                    adb <= operands[7:0] + rx & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetched_data[7:0] = dout;
                    adb <= operands[7:0] + rx + 8'h01 & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  2: begin
                    // fetched_data[15:8] = dout;
                    // only RAM read is supported (VRAM is not)
                    automatic logic [15:0] addr = {dout, fetched_data[7:0]} & 16'hFFFF;
                    adb <= addr & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  3: begin
                    automatic logic [8:0] temp;  // make it 9bit to include carry
                    temp = ra + dout + (flg_c ? 1 : 0) & 9'h1FF;
                    flg_c = temp[8];
                    flg_v = (~(ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                    ra = temp[7:0];

                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];

                    pc <= pc_plus2;
                    adb <= pc_plus2 & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                  end
                endcase
              end
              // ADC (indirect), Y
              8'h71: begin
                case (fetched_data_bytes)
                  0: begin
                    // fetch operands[7:0]
                    adb <= operands[7:0] & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetched_data[7:0] = dout;
                    adb <= operands[7:0] + 8'h01 & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  2: begin
                    // fetched_data[15:8] = dout;
                    // only RAM read is supported (VRAM is not)
                    automatic logic [15:0] addr = {dout, fetched_data[7:0]} + ry & 16'hFFFF;
                    adb <= addr & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  3: begin
                    automatic logic [8:0] temp;  // make it 9bit to include carry
                    temp = ra + dout + (flg_c ? 1 : 0) & 9'h1FF;
                    flg_c = temp[8];
                    flg_v = (~(ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                    ra = temp[7:0];

                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];

                    pc <= pc_plus2;
                    adb <= pc_plus3 & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                  end
                endcase
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

                pc <= pc_plus2;
                adb <= pc_plus2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // SBC zero page
              8'hE5: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include borrow
                  temp = ra - dout - (flg_c ? 0 : 1) & 9'h1FF;

                  flg_c = ~temp[8];  // Borrow flag (inverted carry)
                  flg_v = ((ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include borrow
                  temp = ra - dout - (flg_c ? 0 : 1) & 9'h1FF;

                  flg_c = ~temp[8];  // Borrow flag (inverted carry)
                  flg_v = ((ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // SBC absolute
              8'hED: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & RAMW;
                  adb <= addr;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include borrow
                  temp = ra - dout - (flg_c ? 0 : 1) & 9'h1FF;

                  flg_c = ~temp[8];  // Borrow flag (inverted carry)
                  flg_v = ((ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // SBC absolute, X
              8'hFD: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] + rx & RAMW;
                  adb <= addr;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include borrow
                  temp = ra - dout - (flg_c ? 0 : 1) & 9'h1FF;

                  flg_c = ~temp[8];  // Borrow flag (inverted carry)
                  flg_v = ((ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // SBC absolute, Y
              8'hF9: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] + ry & RAMW;
                  adb <= addr;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include borrow
                  temp = ra - dout - (flg_c ? 0 : 1) & 9'h1FF;

                  flg_c = ~temp[8];  // Borrow flag (inverted carry)
                  flg_v = ((ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // SBC (indirect, X)
              8'hE1: begin
                case (fetched_data_bytes)
                  0: begin
                    // fetch operands[7:0]
                    adb <= operands[7:0] + rx & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetched_data[7:0] = dout;
                    adb <= operands[7:0] + rx + 8'h01 & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  2: begin
                    // fetched_data[15:8] = dout;
                    // only RAM read is supported (VRAM is not)
                    automatic logic [15:0] addr = {dout, fetched_data[7:0]} & 16'hFFFF;
                    adb <= addr & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  3: begin
                    automatic logic [8:0] temp;  // make it 9bit to include borrow
                    temp = ra - dout - (flg_c ? 0 : 1) & 9'h1FF;

                    flg_c = ~temp[8];  // Borrow flag (inverted carry)
                    flg_v = ((ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                    ra = temp[7:0];

                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];

                    pc <= pc_plus2;
                    adb <= pc_plus2 & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                  end
                endcase
              end
              // SBC (indirect), Y
              8'hF1: begin
                case (fetched_data_bytes)
                  0: begin
                    // fetch operands[7:0]
                    adb <= operands[7:0] & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetched_data[7:0] = dout;
                    adb <= operands[7:0] + 8'h01 & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  2: begin
                    // fetched_data[15:8] = dout;
                    // only RAM read is supported (VRAM is not)
                    automatic logic [15:0] addr = {dout, fetched_data[7:0]} + ry & 16'hFFFF;
                    adb <= addr & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  3: begin
                    automatic logic [8:0] temp;  // make it 9bit to include borrow
                    temp = ra - dout - (flg_c ? 0 : 1) & 9'h1FF;

                    flg_c = ~temp[8];  // Borrow flag (inverted carry)
                    flg_v = ((ra[7] ^ dout[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                    ra = temp[7:0];

                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];

                    pc <= pc_plus2;
                    adb <= pc_plus2 & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                  end
                endcase
              end
              // AND immediate
              8'h29: begin
                ra = ra & operands[7:0];
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                pc <= pc_plus2;
                adb <= pc_plus2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // AND zero page
              8'h25: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = ra & dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = ra & dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // AND absolute
              8'h2D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = ra & dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // AND absolute, X
              8'h3D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] + rx & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = ra & dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // AND absolute, Y
              8'h39: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] + ry & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = ra & dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // AND (indirect, X)
              8'h21: begin
                case (fetched_data_bytes)
                  0: begin
                    // fetch operands[7:0]
                    adb <= operands[7:0] + rx & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetched_data[7:0] = dout;
                    adb <= operands[7:0] + rx + 8'h01 & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  2: begin
                    // fetched_data[15:8] = dout;
                    // only RAM read is supported (VRAM is not)
                    automatic logic [15:0] addr = {dout, fetched_data[7:0]} & 16'hFFFF;
                    adb <= addr & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  3: begin
                    ra = ra & dout;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus2;
                    adb <= pc_plus2 & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                  end
                endcase
              end
              // AND (indirect), Y
              8'h31: begin
                case (fetched_data_bytes)
                  0: begin
                    // fetch operands[7:0]
                    adb <= operands[7:0] & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetched_data[7:0] = dout;
                    adb <= operands[7:0] + 8'h01 & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  2: begin
                    // fetched_data[15:8] = dout;
                    // only RAM read is supported (VRAM is not)
                    automatic logic [15:0] addr = {dout, fetched_data[7:0]} + ry & 16'hFFFF;
                    adb <= addr & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  3: begin
                    ra = ra & dout;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus2;
                    adb <= pc_plus2 & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                  end
                endcase
              end
              // EOR immediate
              8'h49: begin
                ra = ra ^ operands[7:0];
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                pc <= pc_plus2;
                adb <= pc_plus2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // EOR zero page
              8'h45: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = ra ^ dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = ra ^ dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // EOR absolute
              8'h4D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = ra ^ dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // EOR absolute, X
              8'h5D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] + rx & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = ra ^ dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // EOR absolute, Y
              8'h59: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] + ry & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = ra ^ dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // EOR (indirect, X)
              8'h41: begin
                case (fetched_data_bytes)
                  0: begin
                    // fetch operands[7:0]
                    adb <= operands[7:0] + rx & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetched_data[7:0] = dout;
                    adb <= operands[7:0] + rx + 8'h01 & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  2: begin
                    // fetched_data[15:8] = dout;
                    // only RAM read is supported (VRAM is not)
                    automatic logic [15:0] addr = {dout, fetched_data[7:0]} & 16'hFFFF;
                    adb <= addr & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  3: begin
                    ra = ra ^ dout;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus2;
                    adb <= pc_plus2 & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                  end
                endcase
              end
              // EOR (indirect), Y
              8'h51: begin
                case (fetched_data_bytes)
                  0: begin
                    // fetch operands[7:0]
                    adb <= operands[7:0] & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetched_data[7:0] = dout;
                    adb <= operands[7:0] + 8'h01 & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  2: begin
                    // fetched_data[15:8] = dout;
                    // only RAM read is supported (VRAM is not)
                    automatic logic [15:0] addr = {dout, fetched_data[7:0]} + ry & 16'hFFFF;
                    adb <= addr & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  3: begin
                    ra = ra ^ dout;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus3;
                    adb <= pc_plus3 & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                  end
                endcase
              end
              // ORA immediate
              8'h09: begin
                ra = ra | operands[7:0];
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                pc <= pc_plus2;
                adb <= pc_plus2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // ORA zero page
              8'h05: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = ra | dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = ra | dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ORA absolute
              8'h0D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = ra | dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ORA absolute, X
              8'h1D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] + rx & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = ra | dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ORA absolute, Y
              8'h19: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] + ry & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  ra = ra | dout;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ORA (indirect, X)
              8'h01: begin
                case (fetched_data_bytes)
                  0: begin
                    // fetch operands[7:0]
                    adb <= operands[7:0] + rx & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetched_data[7:0] = dout;
                    adb <= operands[7:0] + rx + 8'h01 & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  2: begin
                    // fetched_data[15:8] = dout;
                    // only RAM read is supported (VRAM is not)
                    automatic logic [15:0] addr = {dout, fetched_data[7:0]} & 16'hFFFF;
                    adb <= addr & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  3: begin
                    ra = ra | dout;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus2;
                    adb <= pc_plus2 & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                  end
                endcase
              end
              // ORA (indirect), Y
              8'h11: begin
                case (fetched_data_bytes)
                  0: begin
                    // fetch operands[7:0]
                    adb <= operands[7:0] & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetched_data[7:0] = dout;
                    adb <= operands[7:0] + 8'h01 & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  2: begin
                    // fetched_data[15:8] = dout;
                    // only RAM read is supported (VRAM is not)
                    automatic logic [15:0] addr = {dout, fetched_data[7:0]} + ry & 16'hFFFF;
                    adb <= addr & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  3: begin
                    ra = ra | dout;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus2;
                    adb <= pc_plus2 & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                  end
                endcase
              end
              // ASL accumulator
              8'h0A: begin
                flg_c = ra[7];  // Capture the carry bit before shifting
                ra = ra << 1;
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                pc <= pc_plus1;
                adb <= pc_plus1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // ASL zero pabe
              8'h06: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  flg_c = dout[7];  // Capture the carry bit before shifting
                  ra = dout << 1;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  next_state <= DECODE_EXECUTE;
                end else begin
                  flg_c = dout[7];  // Capture the carry bit before shifting
                  ra = dout << 1;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ASL absolute
              8'h0E: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  flg_c = dout[7];  // Capture the carry bit before shifting
                  ra = dout << 1;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ASL absolute, X
              8'h1E: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + rx) & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  flg_c = dout[7];  // Capture the carry bit before shifting
                  ra = dout << 1;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
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
                pc <= pc_plus1;
                adb <= pc_plus1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // ROL zero page
              8'h26: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout[7];  // Capture the carry bit before shifting
                  din   = (dout << 1) | carry_in;
                  ada <= operands[7:0];
                  cea <= 1;
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout[7];  // Capture the carry bit before shifting
                  din   = (dout << 1) | carry_in;
                  ada <= (operands[7:0] + rx) & 8'hFF;
                  cea <= 1;
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ROL absolute
              8'h2E: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout[7];  // Capture the carry bit before shifting
                  din   = (dout << 1) | carry_in;
                  ada <= operands[15:0] & RAMW;
                  cea <= 1;
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ROL absolute, X
              8'h3E: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + rx) & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout[7];  // Capture the carry bit before shifting
                  din   = (dout << 1) | carry_in;
                  ada <= (operands[15:0] + rx) & RAMW;
                  cea <= 1;
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
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
                pc <= pc_plus1;
                adb <= pc_plus1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // ROR zero page
              8'h66: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout[0];  // Capture the carry bit before shifting
                  din   = (dout >> 1) | (carry_in << 7);
                  ada <= operands[7:0];
                  cea <= 1;
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout[0];  // Capture the carry bit before shifting
                  din   = (dout >> 1) | (carry_in << 7);
                  ada <= (operands[7:0] + rx) & 8'hFF;
                  cea <= 1;
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ROR absolute
              8'h6E: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout[0];  // Capture the carry bit before shifting
                  din   = (dout >> 1) | (carry_in << 7);
                  ada <= operands[15:0] & RAMW;
                  cea <= 1;
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // ROR absolute, X
              8'h7E: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + rx) & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout[0];  // Capture the carry bit before shifting
                  din   = (dout >> 1) | (carry_in << 7);
                  ada <= (operands[15:0] + rx) & RAMW;
                  cea <= 1;
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
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
                pc <= pc_plus2;
                adb <= pc_plus2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // BIT zero apge
              8'h24: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  flg_z = (ra & dout) == 1'd0 ? 1'd1 : 1'd0;
                  flg_n = dout[7];
                  flg_v = dout[6];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // BIT absolute
              8'h2C: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  flg_z = (ra & dout) == 1'd0 ? 1'd1 : 1'd0;
                  flg_n = dout[7];
                  flg_v = dout[6];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
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
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [7:0] result = ra - dout;
                  flg_c = ra >= dout ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [7:0] result = ra - dout;
                  flg_c = ra >= dout ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // CMP absolute
              8'hCD: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [7:0] result = ra - dout;
                  flg_c = ra >= dout ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // CMP absolute, X
              8'hDD: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] + rx & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [7:0] result = ra - dout;
                  flg_c = ra >= dout ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
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
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [7:0] result = ra - dout;
                  flg_c = ra >= dout ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // CMP (indirect, X)
              8'hC1: begin
                case (fetched_data_bytes)
                  0: begin
                    // fetch operands[7:0]
                    adb <= operands[7:0] + rx & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetched_data[7:0] = dout;
                    adb <= operands[7:0] + rx + 8'h01 & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  2: begin
                    // fetched_data[15:8] = dout;
                    // only RAM read is supported (VRAM is not)
                    automatic logic [15:0] addr = {dout, fetched_data[7:0]} & 16'hFFFF;
                    adb <= addr & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  3: begin
                    automatic logic [7:0] result = ra - dout;
                    flg_c = ra >= dout ? 1 : 0;
                    flg_z = (result == 8'h00);
                    flg_n = result[7];
                    pc <= pc_plus3;
                    adb <= pc_plus3 & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                  end
                endcase
              end
              // CMP (indirect), Y
              8'hD1: begin
                case (fetched_data_bytes)
                  0: begin
                    // fetch operands[7:0]
                    adb <= operands[7:0] & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetched_data[7:0] = dout;
                    adb <= operands[7:0] + 8'h01 & 8'hFF;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  2: begin
                    // fetched_data[15:8] = dout;
                    // only RAM read is supported (VRAM is not)
                    automatic logic [15:0] addr = {dout, fetched_data[7:0]} + ry & 16'hFFFF;
                    adb <= addr & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                  end
                  3: begin
                    automatic logic [7:0] result = ra - dout;
                    flg_c = ra >= dout ? 1 : 0;
                    flg_z = (result == 8'h00);
                    flg_n = result[7];
                    pc <= pc_plus3;
                    adb <= pc_plus3 & RAMW;
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                  end
                endcase
              end
              // CPX immediate; Compare X
              8'hE0: begin
                automatic logic [7:0] result = rx - operands[7:0];
                flg_c = rx >= operands[7:0] ? 1 : 0;
                flg_z = (result == 8'h00);
                flg_n = result[7];
                pc <= pc_plus2;
                adb <= pc_plus2 & RAMW;
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
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [7:0] result = rx - dout;
                  flg_c = rx >= dout ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                  state <= FETCH_REQ;
                end
              end
              // CPX absolute
              8'hEC: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [7:0] result = rx - dout;
                  flg_c = rx >= dout ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
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
                pc <= pc_plus2;
                adb <= pc_plus2 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // CPY zero page
              8'hC4: begin
                if (fetched_data_bytes == 0) begin
                  adb <= operands[7:0];
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [7:0] result = ry - dout;
                  flg_c = ry >= dout ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // CPY absolute
              8'hCC: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  adb <= addr & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= DECODE_EXECUTE;
                end else begin
                  automatic logic [7:0] result = ry - dout;
                  flg_c = ry >= dout ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end
              // TAX
              8'hAA: begin
                rx = ra;
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                pc <= pc_plus1;
                adb <= pc_plus1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // TAY
              8'hA8: begin
                ry = ra;
                flg_z = (ry == 8'h00);
                flg_n = ry[7];
                pc <= pc_plus1;
                adb <= pc_plus1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // TXA
              8'h8A: begin
                ra = rx;
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                pc <= pc_plus1;
                adb <= pc_plus1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // TYA
              8'h98: begin
                ra = ry;
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                pc <= pc_plus1;
                adb <= pc_plus1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // TSX
              8'hBA: begin
                rx = sp;
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                pc <= pc_plus1;
                adb <= pc_plus1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // TXS
              8'h9A: begin
                sp = rx;
                pc <= pc_plus1;
                adb <= pc_plus1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end

              // BEQ
              8'hF0: begin
                if (flg_z == 1) begin
                  // sign extend
                  s_imm8 = operands[7:0];
                  s_offset = s_imm8;
                  addr = pc_plus2 + s_offset & RAMW;
                  pc  <= addr;
                  adb <= addr;
                end else begin
                  pc  <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  addr = pc_plus2 + s_offset & RAMW;
                  pc  <= addr;
                  adb <= addr;
                end else begin
                  pc  <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  addr = pc_plus2 + s_offset & RAMW;
                  pc  <= addr;
                  adb <= addr;
                end else begin
                  pc  <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  addr = pc_plus2 + s_offset & RAMW;
                  pc  <= addr;
                  adb <= addr;
                end else begin
                  pc  <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  addr = pc_plus2 + s_offset & RAMW;
                  pc  <= addr;
                  adb <= addr;
                end else begin
                  pc  <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  addr = pc_plus2 + s_offset & RAMW;
                  pc  <= addr;
                  adb <= addr;
                end else begin
                  pc  <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  addr = pc_plus2 + s_offset & RAMW;
                  pc  <= addr;
                  adb <= addr;
                end else begin
                  pc  <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
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
                  addr = pc_plus2 + s_offset & RAMW;
                  pc  <= addr;
                  adb <= addr;
                end else begin
                  pc  <= pc_plus2;
                  adb <= pc_plus2 & RAMW;
                end
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // CLC
              8'h18: begin
                flg_c = 1'b0;
                pc <= pc_plus1;
                adb <= pc_plus1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // CLV
              8'hB8: begin
                flg_v = 1'b0;
                pc <= pc_plus1;
                adb <= pc_plus1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end
              // SEC
              8'h38: begin
                flg_c = 1'b1;
                pc <= pc_plus1;
                adb <= pc_plus1 & RAMW;
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end

              // custom instructions which is not available in 6502
              // CF
              8'hCF: begin
                state <= CLEAR_VRAM;
              end
              // DF
              8'hDF: begin
                if (operands[15:0] != 16'hFFFF) begin
                  show_info_counter <= 0;
                  prev_state <= DECODE_EXECUTE;
                  state <= SHOW_INFO;
                  show_info_stage <= SHOW_INFO_FETCH;
                end else begin
                  show_info_counter <= 0;
                  pc <= pc_plus3;
                  adb <= pc_plus3 & RAMW;
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_OPCODE;
                end
              end

              // HLT
              8'hEF: begin
                state <= HALT;
              end
              // WVS
              8'hFF: begin
                case (vsync_stage)
                  0: begin
                    // if vsync is 1, move to stage 1
                    // otherwise stage 2
                    if (vsync_sync == 1'b1) begin
                      vsync_stage <= 1;
                    end else begin
                      vsync_stage <= 2;
                    end
                  end
                  1: begin
                    // wait until vsync becomes 0
                    if (vsync_sync == 1'b0) begin
                      vsync_stage <= 2;
                    end
                  end
                  2: begin
                    // wait until vsync becomes 1
                    if (vsync_sync == 1'b1) begin
                      if (operands[7:0] == 0) begin
                        vsync_stage <= 0;
                        pc <= pc_plus2;
                        adb <= pc_plus2 & RAMW;
                        state <= FETCH_REQ;
                        fetch_stage <= FETCH_OPCODE;
                      end else begin
                        operands[7:0] = operands[7:0] - 1'b1;
                        vsync_stage   = 1;
                      end
                    end
                  end
                endcase
              end

              // TODO: support more instructions

              default: ;  // No operation.
            endcase
          end

          WRITE_REQ: begin
            written_data_bytes <= written_data_bytes + 1'd1;
            state <= DECODE_EXECUTE;
          end

          SHOW_INFO: begin : SHOW_INFO_BLOCK
            show_info_counter <= 0;
            state <= SHOW_INFO2;
          end

          SHOW_INFO2: begin : SHOW_INFO2_BLOCK
            case (show_info_stage)
              SHOW_INFO_FETCH: begin
                show_info_cmd   <= show_info_rom[show_info_counter];
                show_info_stage <= SHOW_INFO_EXECUTE;
              end

              SHOW_INFO_EXECUTE: begin
                automatic logic [15:0] tmp_addr;
                if (show_info_cmd.vram_write) begin
                  v_ada <= show_info_cmd.v_ada;
                  ada   <= show_info_cmd.v_ada + SHADOW_VRAM_START & RAMW;
                  cea   <= 1;
                  case (show_info_cmd.v_din_t)
                    0: begin  // immediate
                      v_din <= show_info_cmd.v_din;
                      din   <= show_info_cmd.v_din;
                    end
                    1: begin
                      case (show_info_cmd.v_din)
                        0: begin
                          v_din <= to_hexchar(dout[7:4]);
                          din   <= to_hexchar(dout[7:4]);
                        end
                        1: begin
                          v_din <= to_hexchar(dout[3:0]);
                          din   <= to_hexchar(dout[3:0]);
                        end
                        2, 3: begin
                          ;  // do nothing
                        end
                        default: begin
                          v_din <= dout[11-show_info_cmd.v_din] ? 8'h40 : 8'h20;
                          din   <= dout[11-show_info_cmd.v_din] ? 8'h40 : 8'h20;
                        end
                      endcase
                    end
                    2: begin
                      v_din <= show_info_cmd.v_din ? to_hexchar(ra[3:0]) : to_hexchar(ra[7:4]);
                      din   <= show_info_cmd.v_din ? to_hexchar(ra[3:0]) : to_hexchar(ra[7:4]);
                    end
                    3: begin
                      v_din <= show_info_cmd.v_din ? to_hexchar(rx[3:0]) : to_hexchar(rx[7:4]);
                      din   <= show_info_cmd.v_din ? to_hexchar(rx[3:0]) : to_hexchar(rx[7:4]);
                    end
                    4: begin
                      v_din <= show_info_cmd.v_din ? to_hexchar(ry[3:0]) : to_hexchar(ry[7:4]);
                      din   <= show_info_cmd.v_din ? to_hexchar(ry[3:0]) : to_hexchar(ry[7:4]);
                    end
                    5: begin
                      v_din <= show_info_cmd.v_din ? to_hexchar(sp[3:0]) : to_hexchar(sp[7:4]);
                      din   <= show_info_cmd.v_din ? to_hexchar(sp[3:0]) : to_hexchar(sp[7:4]);
                    end
                    6: begin
                      case (show_info_cmd.v_din)
                        0: begin  // 1st nibble
                          v_din <= to_hexchar(pc[15:12]);
                          din   <= to_hexchar(pc[15:12]);
                        end
                        1: begin  // 2nd nibble
                          v_din <= to_hexchar(pc[11:8]);
                          din   <= to_hexchar(pc[11:8]);
                        end
                        2: begin  // 3rd nibble
                          v_din <= to_hexchar(pc[7:4]);
                          din   <= to_hexchar(pc[7:4]);
                        end
                        3: begin  // 4th nibble
                          v_din <= to_hexchar(pc[3:0]);
                          din   <= to_hexchar(pc[3:0]);
                        end
                      endcase
                    end
                    7: begin  // operands (start memory address)
                      tmp_addr = operands + show_info_cmd.diff;
                      case (show_info_cmd.v_din)
                        0: begin  // 1st nibble
                          v_din <= to_hexchar(tmp_addr[15:12]);
                          din   <= to_hexchar(tmp_addr[15:12]);
                        end
                        1: begin  // 2nd nibble
                          v_din <= to_hexchar(tmp_addr[11:8]);
                          din   <= to_hexchar(tmp_addr[11:8]);
                        end
                        2: begin  // 3rd nibble
                          v_din <= to_hexchar(tmp_addr[7:4]);
                          din   <= to_hexchar(tmp_addr[7:4]);
                        end
                        3: begin  // 4th nibble
                          v_din <= to_hexchar(tmp_addr[3:0]);
                          din   <= to_hexchar(tmp_addr[3:0]);
                        end
                      endcase
                    end
                  endcase
                end
                if (show_info_cmd.mem_read) begin
                  if (show_info_cmd.v_din_t == 8) begin
                    adb <= show_info_cmd.v_ada;
                  end else begin
                    adb <= operands[15:0] + show_info_cmd.diff & RAMW;
                  end
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= SHOW_INFO2;
                end

                show_info_counter <= show_info_counter + 1;

                if (show_info_counter == 1020) begin
                  show_info_counter <= 0;
                  state <= prev_state;
                  operands[15:0] = 16'hFFFF;
                  disable SHOW_INFO2_BLOCK;  //break
                end else begin
                  show_info_stage <= SHOW_INFO_FETCH;
                end
              end
            endcase
          end

          CLEAR_VRAM: begin
            vram_write(0, 8'h20);
            state <= CLEAR_VRAM2;
          end

          CLEAR_VRAM2: begin
            if (v_ada <= COLUMNS * ROWS) begin
              v_ada <= v_ada + 1 & VRAMW;
              v_din <= 8'h20;  // ' '
              ada   <= v_ada + SHADOW_VRAM_START & RAMW;
              din   <= 8'h20;
              cea   <= 1;
            end else begin
              pc <= pc_plus1;
              adb <= pc_plus1 & RAMW;
              state <= FETCH_REQ;
              fetch_stage <= FETCH_OPCODE;
            end
          end

        endcase
      end
    end
  end

endmodule
