              // ADC immediate
              8'h69: begin
                automatic logic [8:0] temp;  // make it 9bit to include carry
                // in ADC, +1 if flg_c is 1
                temp = (ra + dout_r + (flg_c ? 1 : 0)) & 9'h1FF;
                flg_c = temp[8];
                flg_v = (~(ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                ra = temp[7:0];

                flg_z = (ra == 8'h00);
                flg_n = ra[7];

                fetch_opcode(2);
              end
              // ADC zero page
              8'h65: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[7:0]);
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include carry
                  temp = ra + dout_r + (flg_c ? 1 : 0) & 9'h1FF;
                  flg_c = temp[8];
                  flg_v = (~(ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  fetch_opcode(2);
                end
              end
              // ADC zero page, X
              8'h75: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data((operands[7:0] + rx) & 8'hFF);
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include carry
                  temp = ra + dout_r + (flg_c ? 1 : 0) & 9'h1FF;
                  flg_c = temp[8];
                  flg_v = (~(ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  fetch_opcode(2);
                end
              end
              // ADC absolute
              8'h6D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & RAMW;
                  fetch_data(addr);
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include carry
                  temp = ra + dout_r + (flg_c ? 1 : 0) & 9'h1FF;
                  flg_c = temp[8];
                  flg_v = (~(ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  fetch_opcode(3);
                end
              end
              // ADC absolute, X
              8'h7D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + rx) & RAMW;
                  fetch_data(addr);
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include carry
                  temp = ra + dout_r + (flg_c ? 1 : 0) & 9'h1FF;
                  flg_c = temp[8];
                  flg_v = (~(ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  fetch_opcode(3);
                end
              end
              // ADC absolute, Y
              8'h79: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + ry) & RAMW;
                  fetch_data(addr);
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include carry
                  temp = (ra + dout_r + (flg_c ? 1 : 0)) & 9'h1FF;
                  flg_c = temp[8];
                  flg_v = (~(ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  fetch_opcode(3);
                end
              end
              // ADC (indirect, X)
              8'h61: begin
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
                    automatic logic [8:0] temp;  // make it 9bit to include carry
                    temp = (ra + dout_r + (flg_c ? 1 : 0)) & 9'h1FF;
                    flg_c = temp[8];
                    flg_v = (~(ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                    ra = temp[7:0];

                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];

                    fetch_opcode(2);
                  end
                endcase
              end
              // ADC (indirect), Y
              8'h71: begin
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
                    automatic logic [8:0] temp;  // make it 9bit to include carry
                    temp = (ra + dout_r + (flg_c ? 1 : 0)) & 9'h1FF;
                    flg_c = temp[8];
                    flg_v = (~(ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                    ra = temp[7:0];

                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];

                    fetch_opcode(2);
                  end
                endcase
              end
              // SBC immediate
              8'hE9: begin
                automatic logic [8:0] temp;  // make it 9bit to include borrow
                // in SBC, -1 if flg_c is 0 (clear)
                temp = (ra - dout_r - (flg_c ? 0 : 1)) & 9'h1FF;

                flg_c = ~temp[8];  // Borrow flag (inverted carry)
                flg_v = ((ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                ra = temp[7:0];

                flg_z = (ra == 8'h00);
                flg_n = ra[7];

                fetch_opcode(2);
              end
              // SBC zero page
              8'hE5: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[7:0]);
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include borrow
                  temp = (ra - dout_r - (flg_c ? 0 : 1)) & 9'h1FF;

                  flg_c = ~temp[8];  // Borrow flag (inverted carry)
                  flg_v = ((ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  fetch_opcode(2);
                end
              end
              // SBC zero page, X
              8'hF5: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data((operands[7:0] + rx) & 8'hFF);
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include borrow
                  temp = (ra - dout_r - (flg_c ? 0 : 1)) & 9'h1FF;

                  flg_c = ~temp[8];  // Borrow flag (inverted carry)
                  flg_v = ((ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  fetch_opcode(2);
                end
              end
              // SBC absolute
              8'hED: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & RAMW;
                  fetch_data(addr);
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include borrow
                  temp = ra - dout_r - (flg_c ? 0 : 1) & 9'h1FF;

                  flg_c = ~temp[8];  // Borrow flag (inverted carry)
                  flg_v = ((ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  fetch_opcode(3);
                end
              end
              // SBC absolute, X
              8'hFD: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + rx) & RAMW;
                  fetch_data(addr);
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include borrow
                  temp = (ra - dout_r - (flg_c ? 0 : 1)) & 9'h1FF;

                  flg_c = ~temp[8];  // Borrow flag (inverted carry)
                  flg_v = ((ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  fetch_opcode(3);
                end
              end
              // SBC absolute, Y
              8'hF9: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + ry) & RAMW;
                  fetch_data(addr);
                end else begin
                  automatic logic [8:0] temp;  // make it 9bit to include borrow
                  temp = ra - dout_r - (flg_c ? 0 : 1) & 9'h1FF;

                  flg_c = ~temp[8];  // Borrow flag (inverted carry)
                  flg_v = ((ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                  ra = temp[7:0];

                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];

                  fetch_opcode(3);
                end
              end
              // SBC (indirect, X)
              8'hE1: begin
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
                    automatic logic [8:0] temp;  // make it 9bit to include borrow
                    temp = (ra - dout_r - (flg_c ? 0 : 1)) & 9'h1FF;

                    flg_c = ~temp[8];  // Borrow flag (inverted carry)
                    flg_v = ((ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;

                    ra = temp[7:0];

                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];

                    fetch_opcode(2);
                  end
                endcase
              end
              // SBC (indirect), Y
