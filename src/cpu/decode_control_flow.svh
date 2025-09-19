              // NOP
              8'hEA: begin
                fetch_opcode(1);
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
                    fetch_data(operands[15:0] & RAMW);
                  end
                  1: begin
                    fetched_data[7:0] = dout_r;
                    fetch_data((operands[15:0] + 1) & RAMW);
                  end
                  2: begin
                    // relative data is already in little endian.
                    automatic logic [15:0] addr = {dout_r, fetched_data[7:0]} & RAMW;
                    fetched_data[15:8] = dout_r;
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
                    fetch_data(STACK + sp);
                  end
                  1: begin
                    // fetch high byte of PC-1
                    fetched_data[7:0] = dout_r;
                    sp = sp + 1'd1;
                    fetch_data(STACK + sp);
                  end
                  2: begin
                    fetched_data[15:8] = dout_r;
                    // fetched_data is in big endian.
                    pc <= (fetched_data + 1'd1) & RAMW;
                    adb <= (fetched_data + 1'd1) & RAMW;
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
                cea   = 1;  // Explicit RAM write
                v_cea = 0;
                fetch_opcode(1);
              end
              // PLA; pull accumulator
              8'h68: begin
                if (fetched_data_bytes == 0) begin
                  sp = sp + 1'd1;
                  fetch_data(STACK + sp);
                end else begin
                  ra = dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  fetch_opcode(1);
                end
              end
              // PHP; push processor status
              8'h08: begin
                ada <= STACK + sp;
                sp = sp - 1'd1;
                din <= {flg_n, flg_v, 1'b1, flg_b, flg_d, flg_i, flg_z, flg_c};
                cea   = 1;  // Explicit RAM write
                v_cea = 0;
                fetch_opcode(1);
              end
              // PLP; pull processor status
