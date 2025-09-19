              // ASL accumulator
              8'h0A: begin
                flg_c = ra[7];  // Capture the carry bit before shifting
                ra = ra << 1;
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                fetch_opcode(1);
              end
              // ASL zero page
              8'h06: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[7:0]);
                end else begin
                  flg_c = dout_r[7];
                  din   = dout_r << 1;
                  ada <= operands[7:0];
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  fetch_opcode(2);
                end
              end
              // ASL zero page, X
              8'h16: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data((operands[7:0] + rx) & 8'hFF);
                end else begin
                  flg_c = dout_r[7];
                  din   = dout_r << 1;
                  ada <= (operands[7:0] + rx) & 8'hFF;
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  fetch_opcode(2);
                end
              end
              // ASL absolute
              8'h0E: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  flg_c = dout_r[7];
                  din   = dout_r << 1;
                  ada <= operands[15:0] & RAMW;
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  fetch_opcode(3);
                end
              end
              // ASL absolute, X
              8'h1E: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + rx) & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  flg_c = dout_r[7];
                  din   = dout_r << 1;
                  ada <= (operands[15:0] + rx) & RAMW;
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  fetch_opcode(3);
                end
              end
              // LSR accumulator
              8'h4A: begin
                flg_c = ra[0];
                ra = ra >> 1;
                flg_z = (ra == 8'h00);
                flg_n = 1'b0;
                fetch_opcode(1);
              end
              // LSR zero page
              8'h46: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[7:0]);
                end else begin
                  flg_c = dout_r[0];  // Capture the carry bit before shifting
                  din   = dout_r >> 1;
                  ada <= operands[7:0];
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (din == 8'h00);
                  flg_n = 1'b0;  // The result of LSR always clears the negative flag
                  fetch_opcode(2);
                end
              end
              // LSR zero page, X
              8'h56: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data((operands[7:0] + rx) & 8'hFF);
                end else begin
                  flg_c = dout_r[0];  // Capture the carry bit before shifting
                  din   = dout_r >> 1;
                  ada <= (operands[7:0] + rx) & 8'hFF;
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (din == 8'h00);
                  flg_n = 1'b0;  // The result of LSR always clears the negative flag
                  fetch_opcode(2);
                end
              end
              // LSR absolute
              8'h4E: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  flg_c = dout_r[0];  // Capture the carry bit before shifting
                  din   = dout_r >> 1;
                  ada <= operands[15:0] & RAMW;
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (din == 8'h00);
                  flg_n = 1'b0;  // The result of LSR always clears the negative flag
                  fetch_opcode(3);
                end
              end
              // LSR absolute, X
              8'h5E: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + rx) & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  flg_c = dout_r[0];  // Capture the carry bit before shifting
                  din   = dout_r >> 1;
                  ada <= (operands[15:0] + rx) & RAMW;
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (din == 8'h00);
                  flg_n = 1'b0;  // The result of LSR always clears the negative flag
                  fetch_opcode(3);
                end
              end
              // ROL accumulator
              8'h2A: begin
                automatic logic carry_in = flg_c;
                flg_c = ra[7];  // Capture the carry bit before shifting
                ra = (ra << 1) | carry_in;
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                fetch_opcode(1);
              end
              // ROL zero page
              8'h26: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[7:0]);
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout_r[7];  // Capture the carry bit before shifting
                  din   = (dout_r << 1) | carry_in;
                  ada <= operands[7:0];
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  fetch_opcode(2);
                end
              end
              // ROL zero page, X
              8'h36: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data((operands[7:0] + rx) & 8'hFF);
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout_r[7];  // Capture the carry bit before shifting
                  din   = (dout_r << 1) | carry_in;
                  ada <= (operands[7:0] + rx) & 8'hFF;
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  fetch_opcode(2);
                end
              end
              // ROL absolute
              8'h2E: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout_r[7];  // Capture the carry bit before shifting
                  din   = (dout_r << 1) | carry_in;
                  ada <= operands[15:0] & RAMW;
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  fetch_opcode(3);
                end
              end
              // ROL absolute, X
              8'h3E: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = (operands[15:0] + rx) & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout_r[7];  // Capture the carry bit before shifting
                  din   = (dout_r << 1) | carry_in;
                  ada <= (operands[15:0] + rx) & RAMW;
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  fetch_opcode(3);
                end
              end
              // ROR accumulator
              8'h6A: begin
                automatic logic carry_in = flg_c;
                flg_c = ra[0];  // Capture the carry bit before shifting
                ra = (ra >> 1) | (carry_in << 7);
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                fetch_opcode(1);
              end
              // ROR zero page
              8'h66: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[7:0]);
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout_r[0];  // Capture the carry bit before shifting
                  din   = (dout_r >> 1) | (carry_in << 7);
                  ada <= operands[7:0];
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  fetch_opcode(2);
                end
              end
              // ROR zero page, X
              8'h76: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data((operands[7:0] + rx) & 8'hFF);
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout_r[0];  // Capture the carry bit before shifting
                  din   = (dout_r >> 1) | (carry_in << 7);
                  ada <= (operands[7:0] + rx) & 8'hFF;
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  fetch_opcode(2);
                end
              end
              // ROR absolute
              8'h6E: begin
                if (fetched_data_bytes == 0) begin
                  automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                  fetch_data(addr & RAMW);
                end else begin
                  automatic logic carry_in = flg_c;
                  flg_c = dout_r[0];  // Capture the carry bit before shifting
                  din   = (dout_r >> 1) | (carry_in << 7);
                  ada <= operands[15:0] & RAMW;
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (din == 8'h00);
                  flg_n = din[7];
                  fetch_opcode(3);
                end
              end
              // ROR absolute, X
