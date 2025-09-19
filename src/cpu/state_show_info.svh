          SHOW_INFO: begin : SHOW_INFO_BLOCK
            show_info_counter <= 0;
            state <= SHOW_INFO2;
          end

          SHOW_INFO2: begin : SHOW_INFO2_BLOCK
            case (show_info_stage)
              SHOW_INFO_FETCH: begin
                show_info_cmd <= show_info_rom[show_info_counter];
                show_info_stage <= SHOW_INFO_EXECUTE;
                v_cea <= 0;
                cea <= 0;
              end

              SHOW_INFO_EXECUTE: begin
                automatic logic [15:0] tmp_addr;
                if (show_info_cmd.vram_write) begin
                  v_ada <= show_info_cmd.v_ada;
                  v_cea <= 1;
                  ada   <= (show_info_cmd.v_ada + SHADOW_VRAM_START) & RAMW;
                  cea   <= 1;

                  case (show_info_cmd.v_din_t)
                    0: begin  // immediate
                      v_din <= show_info_cmd.v_din;
                      din   <= show_info_cmd.v_din;
                    end
                    1: begin
                      case (show_info_cmd.v_din)
                        0: begin
                          v_din <= to_hexchar(dout_r[7:4]);
                          din   <= to_hexchar(dout_r[7:4]);
                        end
                        1: begin
                          v_din <= to_hexchar(dout_r[3:0]);
                          din   <= to_hexchar(dout_r[3:0]);
                        end
                        2, 3: begin
                          ;  // do nothing
                        end
                        default: begin
                          v_din <= dout_r[11-show_info_cmd.v_din] ? 8'h40 : 8'h20;
                          din   <= dout_r[11-show_info_cmd.v_din] ? 8'h40 : 8'h20;
                        end
                      endcase
                    end
                    2: begin
                      v_din <= show_info_cmd.v_din ? to_hexchar(ra[3:0]) : to_hexchar(ra[7:4]);
                      din   <= show_info_cmd.v_din ? to_hexchar(ra[3:0]) : to_hexchar(ra[7:4]);
                    end
                    3: begin
                      v_din <= show_info_cmd.v_din ? to_hexchar(rx[3:0]) : to_hexchar(rx[7:4]);
                      din   <= show_info_cmd.v_din ? to_hexchar(rx[3:0]) : to_hexchar(rx[7:4]);
                    end
                    4: begin
                      v_din <= show_info_cmd.v_din ? to_hexchar(ry[3:0]) : to_hexchar(ry[7:4]);
                      din   <= show_info_cmd.v_din ? to_hexchar(ry[3:0]) : to_hexchar(ry[7:4]);
                    end
                    5: begin
                      v_din <= show_info_cmd.v_din ? to_hexchar(sp[3:0]) : to_hexchar(sp[7:4]);
                      din   <= show_info_cmd.v_din ? to_hexchar(sp[3:0]) : to_hexchar(sp[7:4]);
                    end
                    6: begin
                      case (show_info_cmd.v_din)
                        0: begin  // 1st nibble
                          v_din <= to_hexchar(pc[15:12]);
                          din   <= to_hexchar(pc[15:12]);
                        end
                        1: begin  // 2nd nibble
                          v_din <= to_hexchar(pc[11:8]);
                          din   <= to_hexchar(pc[11:8]);
                        end
                        2: begin  // 3rd nibble
                          v_din <= to_hexchar(pc[7:4]);
                          din   <= to_hexchar(pc[7:4]);
                        end
                        3: begin  // 4th nibble
                          v_din <= to_hexchar(pc[3:0]);
                          din   <= to_hexchar(pc[3:0]);
                        end
                      endcase
                    end
                    7: begin  // operands (start memory address)
                      tmp_addr = operands + show_info_cmd.diff;
                      case (show_info_cmd.v_din)
                        0: begin  // 1st nibble
                          v_din <= to_hexchar(tmp_addr[15:12]);
                          din   <= to_hexchar(tmp_addr[15:12]);
                        end
                        1: begin  // 2nd nibble
                          v_din <= to_hexchar(tmp_addr[11:8]);
                          din   <= to_hexchar(tmp_addr[11:8]);
                        end
                        2: begin  // 3rd nibble
                          v_din <= to_hexchar(tmp_addr[7:4]);
                          din   <= to_hexchar(tmp_addr[7:4]);
                        end
                        3: begin  // 4th nibble
                          v_din <= to_hexchar(tmp_addr[3:0]);
                          din   <= to_hexchar(tmp_addr[3:0]);
                        end
                      endcase
                    end
                  endcase
                end
                if (show_info_cmd.mem_read) begin
                  if (show_info_cmd.v_din_t == 8) begin
                    adb <= show_info_cmd.v_ada;
                  end else begin
                    adb <= (operands[15:0] + show_info_cmd.diff) & RAMW;
                  end
                  state <= FETCH_REQ;
                  fetch_stage <= FETCH_DATA;
                  next_state <= SHOW_INFO2;
                end

                show_info_counter <= show_info_counter + 1;

                if (show_info_counter == 1020) begin
                  show_info_counter <= 0;
                  state <= prev_state;
                  operands[15:0] = 16'hFFFF;
                  v_cea <= 0;
                  cea   <= 0;
                  disable SHOW_INFO2_BLOCK;  //break
                end else begin
                  show_info_stage <= SHOW_INFO_FETCH;
                end
              end
            endcase
          end

