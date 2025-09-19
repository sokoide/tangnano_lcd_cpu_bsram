              // INC zero page
              8'hE6: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[7:0]);
                end else begin
                  automatic logic [7:0] result = dout_r + 8'd1;
                  ada <= operands[7:0];
                  din <= result;
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  fetch_opcode(2);
                end
              end
              // INC zero page, X
              8'hF6: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data((operands[7:0] + rx) & 8'hFF);
                end else begin
                  automatic logic [7:0] result = dout_r + 8'd1;
                  ada <= operands[7:0];  // << Keep original address here
                  din <= result;
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  fetch_opcode(2);
                end
              end
              // INC absolute
              8'hEE: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[15:0] & RAMW);
                end else begin
                  automatic logic [7:0] result = dout_r + 8'd1;
                  ada <= operands[15:0] & RAMW;
                  din <= result;
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  fetch_opcode(3);
                end
              end
              // INC absolute, X
              8'hFE: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data((operands[15:0] + rx) & RAMW);
                end else begin
                  automatic logic [7:0] result = dout_r + 8'd1;
                  ada <= operands[15:0] & RAMW;  // << Keep original address here
                  din <= result;
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (result == 8'h00);
                  flg_n = result[7];
                  fetch_opcode(3);
                end
              end
              // INX
              8'hE8: begin
                rx = (rx + 1) & 8'hFF;
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                fetch_opcode(1);
              end
              // INY
              8'hC8: begin
                ry = (ry + 1) & 8'hFF;
                flg_z = (ry == 8'h00);
                flg_n = ry[7];
                fetch_opcode(1);
              end
              // DEC zero page
              8'hC6: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[7:0]);
                end else begin
                  automatic logic [7:0] result = dout_r - 8'd1;
                  ada <= operands[7:0];
                  din <= result;
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (result == 8'h00) ? 1'd1 : 1'd0;
                  flg_n = result[7];
                  fetch_opcode(2);
                end
              end
              // DEC zero page, X
              8'hD6: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data((operands[7:0] + rx) & 8'hFF);
                end else begin
                  automatic logic [7:0] result = dout_r - 8'd1;
                  ada <= (operands[7:0] + rx) & 8'hFF;
                  din <= result;
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (result == 8'h00) ? 1'd1 : 1'd0;
                  flg_n = result[7];
                  fetch_opcode(2);
                end
              end
              // DEC absolute
              8'hCE: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data(operands[15:0] & RAMW);
                end else begin
                  automatic logic [7:0] result = dout_r - 8'd1;
                  ada <= operands[15:0] & RAMW;
                  din <= result;
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (result == 8'h00) ? 1'd1 : 1'd0;
                  flg_n = result[7];
                  fetch_opcode(3);
                end
              end
              // DEC absolute, X
              8'hDE: begin
                if (fetched_data_bytes == 0) begin
                  fetch_data((operands[15:0] + rx) & RAMW);
                end else begin
                  automatic logic [7:0] result = dout_r - 8'd1;
                  ada <= (operands[15:0] + rx) & RAMW;
                  din <= result;
                  cea   = 1;  // Explicit RAM write
                  v_cea = 0;  // Not VRAM
                  flg_z = (result == 8'h00) ? 1'd1 : 1'd0;
                  flg_n = result[7];
                  fetch_opcode(3);
                end
              end
              // DEX
              8'hCA: begin
                rx = (rx - 1) & 8'hFF;
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                fetch_opcode(1);
              end
              // DEY
