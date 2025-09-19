              // BEQ
              8'hF0: begin
                if (flg_z == 1) begin
                  // sign extend
                  s_imm8 = operands[7:0];
                  s_offset = s_imm8;
                  addr = (pc_plus2 + s_offset) & RAMW;
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
                  addr = (pc_plus2 + s_offset) & RAMW;
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
                  addr = (pc_plus2 + s_offset) & RAMW;
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
                  addr = (pc_plus2 + s_offset) & RAMW;
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
                  addr = (pc_plus2 + s_offset) & RAMW;
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
                  addr = (pc_plus2 + s_offset) & RAMW;
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
                  addr = (pc_plus2 + s_offset) & RAMW;
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
