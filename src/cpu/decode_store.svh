              // STA zero page
              8'h85: begin
                // always RAM (zero page)
                ada <= operands[7:0];
                din <= ra;
                cea   = 1;  // Explicit RAM write
                v_cea = 0;  // Not VRAM
                fetch_opcode(2);
              end
              // STA zero page, X
              8'h95: begin
                // always RAM (zero page)
                ada <= (operands[7:0] + rx) & 8'hFF;
                din <= ra;
                cea   = 1;  // Explicit RAM write
                v_cea = 0;  // Not VRAM
                fetch_opcode(2);
              end
              // STA absolute
              8'h8D: begin
                // check if it's RAM or VRAM
                automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                sta_write(addr, ra);  // Sets ada/din/v_ada/v_din and write_to_vram flag
                cea   = 1;  // Assert RAM write (for shadow or regular RAM)
                v_cea = write_to_vram;  // Assert VRAM write based on flag
                fetch_opcode(3);
              end
              // STA absolute, X
              8'h9D: begin
                // check if it's RAM or VRAM
                automatic logic [15:0] addr = (operands[15:0] + rx) & 16'hFFFF;
                sta_write(addr, ra);  // Sets ada/din/v_ada/v_din and write_to_vram flag
                cea   = 1;  // Assert RAM write
                v_cea = write_to_vram;  // Assert VRAM write based on flag
                fetch_opcode(3);
              end
              // STA absolute, Y
              8'h99: begin
                // check if it's RAM or VRAM
                automatic logic [15:0] addr = (operands[15:0] + ry) & 16'hFFFF;
                sta_write(addr, ra);  // Sets ada/din/v_ada/v_din and write_to_vram flag
                cea   = 1;  // Assert RAM write
                v_cea = write_to_vram;  // Assert VRAM write based on flag
                fetch_opcode(3);
              end
              // STA (indirect, X)
              8'h81: begin
                // fetch operands[7:0] + rx and the next value from the zero page
                // (total 16bit) in litte endian.
                // then write an 8bit data pointed by the address.
                case (fetched_data_bytes)
                  0: begin
                    // fetch operands[7:0]
                    fetch_data((operands[7:0] + rx) & 8'hFF);
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetched_data[7:0] = dout_r;
                    fetch_data((operands[7:0] + rx + 8'h01) & 8'hFF);
                  end
                  2: begin
                    // fetched_data[15:8] = dout_r;
                    // check if it's RAM or VRAM
                    automatic logic [15:0] addr = {dout_r, fetched_data[7:0]} & 16'hFFFF;
                    sta_write(addr, ra);  // Sets ada/din/v_ada/v_din and write_to_vram flag
                    cea   = 1;  // Assert RAM write
                    v_cea = write_to_vram;  // Assert VRAM write based on flag
                    fetch_opcode(2);
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
                    fetch_data(operands[7:0]);
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetched_data[7:0] = dout_r;
                    fetch_data(operands[7:0] + 8'h01 & 8'hFF);
                  end
                  2: begin
                    // fetched_data[15:8] = dout_r;
                    // check if it's RAM or VRAM
                    automatic logic [15:0] addr = ({dout_r, fetched_data[7:0]} + ry) & 16'hFFFF;
                    sta_write(addr, ra);  // Sets ada/din/v_ada/v_din and write_to_vram flag
                    cea   = 1;  // Assert RAM write
                    v_cea = write_to_vram;  // Assert VRAM write based on flag
                    fetch_opcode(2);
                  end
                endcase
              end
              // STX zero page
              8'h86: begin
                ada <= operands[7:0];
                din <= rx;
                cea   = 1;  // Explicit RAM write
                v_cea = 0;  // Not VRAM
                fetch_opcode(2);
              end
              // STX zero page, Y
              8'h96: begin
                ada <= (operands[7:0] + ry) & 8'hFF;
                din <= rx;
                cea   = 1;  // Explicit RAM write
                v_cea = 0;  // Not VRAM
                fetch_opcode(2);
              end
              // STX absolute
              8'h8E: begin
                // check if it's RAM or VRAM
                automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                sta_write(addr, rx);  // Use sta_write, sets flag & signals
                cea   = 1;  // Assert RAM write
                v_cea = write_to_vram;  // Assert VRAM write based on flag
                fetch_opcode(3);
              end
              //  STY zero page
              8'h84: begin
                ada <= operands[7:0];
                din <= ry;
                cea   = 1;  // Explicit RAM write
                v_cea = 0;  // Not VRAM
                fetch_opcode(2);
              end
              //  STY zero page, X
              8'h94: begin
                ada <= (operands[7:0] + rx) & 8'hFF;
                din <= ry;
                cea   = 1;  // Explicit RAM write
                v_cea = 0;  // Not VRAM
                fetch_opcode(2);
              end
              // STY absolute
