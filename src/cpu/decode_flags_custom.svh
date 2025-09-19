              // CLC
              8'h18: begin
                flg_c = 1'b0;
                fetch_opcode(1);
              end
              // CLV
              8'hB8: begin
                flg_v = 1'b0;
                fetch_opcode(1);
              end
              // SEC
              8'h38: begin
                flg_c = 1'b1;
                fetch_opcode(1);
              end

              // custom instructions which is not available in 6502
              // CVR: clear VRAM
              8'hCF: begin
                state <= CLEAR_VRAM;
              end
              // IFO: show registers and memory at $0000-$007F
              8'hDF: begin
                if (operands[15:0] != 16'hFFFF) begin
                  show_info_counter <= 0;
                  prev_state <= DECODE_EXECUTE;
                  state <= SHOW_INFO;
                  show_info_stage <= SHOW_INFO_FETCH;
                end else begin
                  show_info_counter <= 0;
                  fetch_opcode(3);
                end
              end

              // HLT: halt
              8'hEF: begin
                state <= HALT;
              end
              // WVS: wait for vsync
              8'hFF: begin
                case (vsync_stage)
                  0: begin
                    // if vsync is 1, move to stage 1
                    // otherwise stage 2
                    if (vsync_sync == 1'b1) begin
                      vsync_stage <= 1;
                    end else begin
                      vsync_stage <= 2;
                    end
                  end
                  1: begin
                    // wait until vsync becomes 0
                    if (vsync_sync == 1'b0) begin
                      vsync_stage <= 2;
                    end
                  end
                  2: begin
                    // wait until vsync becomes 1
                    if (vsync_sync == 1'b1) begin
                      if (operands[7:0] == 0) begin
                        vsync_stage <= 0;
                        fetch_opcode(2);
                      end else begin
                        operands[7:0] = operands[7:0] - 1'b1;
                        vsync_stage   = 1;
                      end
                    end
                  end
                endcase
              end
