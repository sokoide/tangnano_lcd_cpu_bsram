              // LDA immediate
              8'hA9: begin
                ra = operands[7:0];
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                fetch_opcode(2);
              end
              // LDA zero page
              8'hA5: begin
                // fetch operands[7:0]'s value from memory and store it to ra.
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[7:0]);
                end else begin
                  ra = dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  ra <= dout_r;
                  fetch_opcode(2);
                end
              end
              // LDA zero page, X
              8'hB5: begin
                // fetch operands[7:0] + rx's value from memory and store it to ra.
                if (fetched_data_bytes == 0) begin
                  fetch_data((operands[7:0] + rx) & 8'hFF);
                end else begin
                  ra = dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  fetch_opcode(2);
                end
              end
              // LDA absolute
              8'hAD: begin
                // fetch operands[15:0]'s value from memory and store it to ra.
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  ra = dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  fetch_opcode(3);
                end
              end
              // LDA absolute, X
              8'hBD: begin
                // fetch operands[15:0] + rx's value from memory and store it to ra.
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + rx) & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  ra = dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  fetch_opcode(3);
                end
              end
              // LDA absolute, Y
              8'hB9: begin
                // fetch operands[15:0] + ry's value from memory and store it to ra.
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + ry) & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  ra = dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  fetch_opcode(3);
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
                    fetch_data((operands[7:0] + rx) & 8'hFF);
                  end
                  1: begin
                    // fetch operands[7:0]+1
                    fetch_data((operands[7:0] + rx + 8'h01) & 8'hFF);
                  end
                  2: begin
                    // fetched_data[15:8] = dout_r;
                    // only RAM read is supported (VRAM is not)
                    automatic logic [15:0] addr = {dout_r, fetched_data[7:0]} & 16'hFFFF;
                    fetch_data(addr & RAMW);
                  end
                  3: begin
                    ra = dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_opcode(2);
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
                    ra = dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_opcode(2);
                  end
                endcase
              end
              // LDX immediate
              8'hA2: begin
                rx = operands[7:0];
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                fetch_opcode(2);
              end
              // LDX zero page
              8'hA6: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[7:0]);
                end else begin
                  rx = dout_r;
                  flg_z = (rx == 8'h00);
                  flg_n = rx[7];
                  fetch_opcode(2);
                end
              end
              // LDX zero page, Y
              8'hB6: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data((operands[7:0] + ry) & 8'hFF);
                end else begin
                  rx = dout_r;
                  flg_z = (rx == 8'h00);
                  flg_n = rx[7];
                  fetch_opcode(2);
                end
              end
              // LDX absolute
              8'hAE: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  rx = dout_r;
                  flg_z = (rx == 8'h00);
                  flg_n = rx[7];
                  fetch_opcode(3);
                end
              end
              // LDX absolute, Y
              8'hBE: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + ry) & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  rx = dout_r;
                  flg_z = (rx == 8'h00);
                  flg_n = rx[7];
                  fetch_opcode(3);
                end
              end
              // LDY immediate
              8'hA0: begin
                ry = operands[7:0];
                flg_z = (ry == 8'h00);
                flg_n = ry[7];
                fetch_opcode(2);
              end
              // LDY zero page
              8'hA4: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[7:0]);
                end else begin
                  ry = dout_r;
                  flg_z = (ry == 8'h00);
                  flg_n = ry[7];
                  fetch_opcode(2);
                end
              end
              // LDY zero page, X
              8'hB4: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data((operands[7:0] + rx) & 8'hFF);
                end else begin
                  ry = dout_r;
                  flg_z = (ry == 8'h00);
                  flg_n = ry[7];
                  fetch_opcode(2);
                end
              end
              // LDY absolute
              8'hAC: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  ry = dout_r;
                  flg_z = (ry == 8'h00);
                  flg_n = ry[7];
                  fetch_opcode(3);
                end
              end
              // LDY abosolute, X
