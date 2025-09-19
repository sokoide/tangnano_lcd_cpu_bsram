          INIT: begin
            v_cea <= 0;  // VRAM write disable
            boot_write <= 1;
            state <= INIT_RAM;
          end

          INIT_VRAM: begin
            v_cea <= 1;  // VRAM write enable
            // cea <= 1;  // RAM write enable
            v_din <= char_code;
            // din <= char_code;
            char_code <= (char_code < 8'h7F) ? (char_code + 1) & 8'hFF : 8'h20;

            if (v_ada <= COLUMNS * ROWS) begin
              v_ada <= (v_ada + 1) & VRAMW;
              // shadow VRAM
              // ada   <= v_ada + 1 + SHADOW_VRAM_START & RAMW;
            end else begin
              v_cea <= 0;  // VRAM write disable
              state <= HALT;
            end
          end

          INIT_RAM: begin
            if (boot_write) begin
              boot_write <= 0;
              cea <= 1;  // RAM write enable
              ada <= (PROGRAM_START + boot_idx) & RAMW;
              din <= boot_program[boot_idx];
            end else begin
              cea <= 0;
              if (boot_idx == boot_program_length) begin
                v_cea <= 1;  // VRAM write enable
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
              end else begin
                boot_idx   <= (boot_idx + 1) & RAMW;
                boot_write <= 1;
              end
            end
          end

          HALT: begin
            // Do nothing
          end

