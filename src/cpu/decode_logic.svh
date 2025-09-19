              // AND immediate
              8'h29: begin
                ra = ra & operands[7:0];
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                fetch_opcode(2);
              end
              // AND zero page
              8'h25: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[7:0]);
                end else begin
                  ra = ra & dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  fetch_opcode(2);
                end
              end
              // AND zero page, X
              8'h35: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data((operands[7:0] + rx) & 8'hFF);
                end else begin
                  ra = ra & dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  fetch_opcode(2);
                end
              end
              // AND absolute
              8'h2D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  ra = ra & dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  fetch_opcode(3);
                end
              end
              // AND absolute, X
              8'h3D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + rx) & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  ra = ra & dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  fetch_opcode(3);
                end
              end
              // AND absolute, Y
              8'h39: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + ry) & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  ra = ra & dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  fetch_opcode(3);
                end
              end
              // AND (indirect, X)
              8'h21: begin
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
                    ra = ra & dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_opcode(2);
                  end
                endcase
              end
              // AND (indirect), Y
              8'h31: begin
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
                    ra = ra & dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_opcode(2);
                  end
                endcase
              end
              // EOR immediate
              8'h49: begin
                ra = ra ^ operands[7:0];
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                fetch_opcode(2);
              end
              // EOR zero page
              8'h45: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[7:0]);
                end else begin
                  ra = ra ^ dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  fetch_opcode(2);
                end
              end
              // EOR zero page, X
              8'h55: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data((operands[7:0] + rx) & 8'hFF);
                end else begin
                  ra = ra ^ dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  fetch_opcode(2);
                end
              end
              // EOR absolute
              8'h4D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  ra = ra ^ dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  fetch_opcode(3);
                end
              end
              // EOR absolute, X
              8'h5D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + rx) & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  ra = ra ^ dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  fetch_opcode(3);
                end
              end
              // EOR absolute, Y
              8'h59: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + ry) & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  ra = ra ^ dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  fetch_opcode(3);
                end
              end
              // EOR (indirect, X)
              8'h41: begin
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
                    ra = ra ^ dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_opcode(2);
                  end
                endcase
              end
              // EOR (indirect), Y
              8'h51: begin
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
                    ra = ra ^ dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_opcode(2);
                  end
                endcase
              end
              // ORA immediate
              8'h09: begin
                ra = ra | operands[7:0];
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                fetch_opcode(2);
              end
              // ORA zero page
              8'h05: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[7:0]);
                end else begin
                  ra = ra | dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  fetch_opcode(2);
                end
              end
              // ORA zero page, X
              8'h15: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data((operands[7:0] + rx) & 8'hFF);
                end else begin
                  ra = ra | dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  fetch_opcode(2);
                end
              end
              // ORA absolute
              8'h0D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  ra = ra | dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  fetch_opcode(3);
                end
              end
              // ORA absolute, X
              8'h1D: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + rx) & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  ra = ra | dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  fetch_opcode(3);
                end
              end
              // ORA absolute, Y
              8'h19: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + ry) & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  ra = ra | dout_r;
                  flg_z = (ra == 8'h00);
                  flg_n = ra[7];
                  fetch_opcode(3);
                end
              end
              // ORA (indirect, X)
              8'h01: begin
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
                    ra = ra | dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_opcode(2);
                  end
                endcase
              end
              // ORA (indirect), Y
