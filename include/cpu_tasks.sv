show_info_cmd_t show_info_cmd;

localparam show_info_cmd_t show_info_rom [1024] =
  '{
  `include "cpu_ifo_auto_generated.sv"
  }
;

task automatic fetch_opcode(input logic [1:0] pc_offset);
  unique case (pc_offset)
    1: begin
      pc <= pc_plus1;
      adb <= pc_plus1 & RAMW;
    end
    2: begin
      pc <= pc_plus2;
      adb <= pc_plus2 & RAMW;
    end
    default: begin
      pc <= pc_plus3;
      adb <= pc_plus3 & RAMW;
    end
  endcase
  state <= FETCH_REQ;
  fetch_stage <= FETCH_OPCODE;
endtask

task automatic fetch_data(input logic [14:0] in_adb);
  adb <= in_adb;
  state <= FETCH_REQ;
  fetch_stage <= FETCH_DATA;
  next_state <= DECODE_EXECUTE;
endtask

task automatic sta_write(input logic [15:0] addr, input logic [7:0] data);
  // Check if the address falls within the VRAM range
  // VRAM size is COLUMNS * ROWS bytes
  if (addr >= VRAM_START && addr < VRAM_START + (COLUMNS * ROWS)) begin
    // VRAM write + Shadow VRAM write
    v_ada <= (addr - VRAM_START) & VRAMW;
    v_din <= data;
    ada   <= (addr - VRAM_START + SHADOW_VRAM_START) & RAMW;
    din   <= data;
    write_to_vram = 1'b1;
  end else begin
    // Regular RAM write
    ada <= addr & RAMW;
    din <= data;
    write_to_vram = 1'b0;
  end
endtask

task automatic vram_write(input logic [15:0] addr, input logic [7:0] data);
  v_ada <= addr & VRAMW;
  v_din <= data;
  v_cea <= 1;
  ada   <= (addr + SHADOW_VRAM_START) & RAMW;
  din   <= data;
  cea <= 1;
endtask
