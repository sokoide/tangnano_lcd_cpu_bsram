          FETCH_REQ: begin
            if (fetch_stage == FETCH_OPCODE) begin
              // use dout (no latch)
              state <= FETCH_RECV;
            end else begin
              // use dout_r
              state <= FETCH_WAIT;
            end
            // timing improvement to avoid "adb <= (pc + 1) & RAMW;" in the DECODE_EXECUTE state
            pc_plus1 <= (pc + 16'd1) & RAMW;
            pc_plus2 <= (pc + 16'd2) & RAMW;
            pc_plus3 <= (pc + 16'd3) & RAMW;
          end

          FETCH_WAIT: begin
            if (fetch_stage == FETCH_DATA) begin
              fetched_data_bytes <= fetched_data_bytes + 1'd1;
              state <= next_state;
            end else begin
              state <= FETCH_RECV;
            end
          end

          FETCH_RECV: begin
            unique case (fetch_stage)
              FETCH_OPCODE: begin
                // use dout instead of dout_r (1 clock faster)
                opcode <= dout;
                fetched_data_bytes <= 0;
                written_data_bytes <= 0;
                cea <= 0;  // disable RAM write
                v_cea <= 0;  // disable VRAM write

                // use dout instead of dout_r (1 clock faster)
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

              default: begin
                ;  // shouldn't come here. do nothing
              end
            endcase
          end

