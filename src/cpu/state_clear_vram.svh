          CLEAR_VRAM: begin
            vram_write(0, 8'h20);
            state <= CLEAR_VRAM2;
          end

          CLEAR_VRAM2: begin
            if (v_ada <= COLUMNS * ROWS) begin
              v_ada <= (v_ada + 1) & VRAMW;
              v_din <= 8'h20;  // ' '
              v_cea <= 1;
              ada   <= (v_ada + SHADOW_VRAM_START) & RAMW;
              din   <= 8'h20;
              cea   <= 1;
            end else begin
              pc <= pc_plus1;
              adb <= pc_plus1 & RAMW;
              state <= FETCH_REQ;
              fetch_stage <= FETCH_OPCODE;
              v_cea <= 0;
              cea <= 0;
            end
          end

