              // TAX
              8'hAA: begin
                rx = ra;
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                fetch_opcode(1);
              end
              // TAY
              8'hA8: begin
                ry = ra;
                flg_z = (ry == 8'h00);
                flg_n = ry[7];
                fetch_opcode(1);
              end
              // TXA
              8'h8A: begin
                ra = rx;
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                fetch_opcode(1);
              end
              // TYA
              8'h98: begin
                ra = ry;
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                fetch_opcode(1);
              end
              // TSX
              8'hBA: begin
                rx = sp;
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                fetch_opcode(1);
              end
              // TXS
