              // CMP immediate; Compare
              8'hC9: begin
                automatic logic [7:0] result = ra - operands[7:0];
                flg_c = ra >= operands[7:0] ? 1 : 0;
                flg_z = (result == 8'h00);
                flg_n = result[7];
                fetch_opcode(2);
              end
              // BIT zero apge
              8'h24: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[7:0]);
                end else begin
                  flg_z = (ra & dout_r) == 1'd0 ? 1'd1 : 1'd0;
                  flg_n = dout_r[7];
                  flg_v = dout_r[6];
                  fetch_opcode(2);
                end
              end
              // BIT absolute
              8'h2C: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  flg_z = (ra & dout_r) == 1'd0 ? 1'd1 : 1'd0;
                  flg_n = dout_r[7];
                  flg_v = dout_r[6];
                  fetch_opcode(3);
                end
              end
              // CMP zero page
              8'hC5: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[7:0]);
                end else begin
                  automatic logic [7:0] result = ra - dout_r;
                  flg_c = ra >= dout_r ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  fetch_opcode(2);
                end
              end
              // CMP zero page, X
              8'hD5: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data((operands[7:0] + rx) & 8'hFF);
                end else begin
                  automatic logic [7:0] result = ra - dout_r;
                  flg_c = ra >= dout_r ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  fetch_opcode(2);
                end
              end
              // CMP absolute
              8'hCD: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  automatic logic [7:0] result = ra - dout_r;
                  flg_c = ra >= dout_r ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  fetch_opcode(3);
                end
              end
              // CMP absolute, X
              8'hDD: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + rx) & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  automatic logic [7:0] result = ra - dout_r;
                  flg_c = ra >= dout_r ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  fetch_opcode(3);
                end
              end
              // CMP absolute, Y
              8'hD9: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data((operands[15:0] + ry) & RAMW);
                end else begin
                  automatic logic [7:0] result = ra - dout_r;
                  flg_c = ra >= dout_r ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  fetch_opcode(3);
                end
              end
              // CMP (indirect, X)
              8'hC1: begin
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
                    // only RAM read is supported (VRAM is not)
                    automatic logic [15:0] addr = {dout_r, fetched_data[7:0]} & 16'hFFFF;
                    fetch_data(addr & RAMW);
                  end
                  3: begin
                    automatic logic [7:0] result = ra - dout_r;
                    flg_c = ra >= dout_r ? 1 : 0;
                    flg_z = (result == 8'h00);
                    flg_n = result[7];
                    fetch_opcode(2);
                  end
                endcase
              end
              // CMP (indirect), Y
              8'hD1: begin
                case (fetched_data_bytes)
                  0: begin
                    // fetch operands[7:0]
                    fetch_data(operands[7:0] & 8'hFF);
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetched_data[7:0] = dout_r;
                    fetch_data((operands[7:0] + 8'h01) & 8'hFF);
                  end
                  2: begin
                    // fetched_data[15:8] = dout_r;
                    // only RAM read is supported (VRAM is not)
                    automatic logic [15:0] addr = ({dout_r, fetched_data[7:0]} + ry) & 16'hFFFF;
                    fetch_data(addr & RAMW);
                  end
                  3: begin
                    automatic logic [7:0] result = ra - dout_r;
                    flg_c = ra >= dout_r ? 1 : 0;
                    flg_z = (result == 8'h00);
                    flg_n = result[7];
                    fetch_opcode(2);
                  end
                endcase
              end
              // CPX immediate; Compare X
              8'hE0: begin
                automatic logic [7:0] result = rx - operands[7:0];
                flg_c = rx >= operands[7:0] ? 1 : 0;
                flg_z = (result == 8'h00);
                flg_n = result[7];
                fetch_opcode(2);
              end
              // CPX zero page
              8'hE4: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[7:0]);
                end else begin
                  automatic logic [7:0] result = rx - dout_r;
                  flg_c = rx >= dout_r ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  fetch_opcode(2);
                end
              end
              // CPX absolute
              8'hEC: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  automatic logic [7:0] result = rx - dout_r;
                  flg_c = rx >= dout_r ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  fetch_opcode(3);
                end
              end
              // CPY immediate; Compare Y
              8'hC0: begin
                automatic logic [7:0] result = ry - operands[7:0];
                flg_c = ry >= operands[7:0] ? 1 : 0;
                flg_z = (result == 8'h00);
                flg_n = result[7];
                fetch_opcode(2);
              end
              // CPY zero page
              8'hC4: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[7:0]);
                end else begin
                  automatic logic [7:0] result = ry - dout_r;
                  flg_c = ry >= dout_r ? 1 : 0;
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  fetch_opcode(2);
                end
              end
              // CPY absolute
