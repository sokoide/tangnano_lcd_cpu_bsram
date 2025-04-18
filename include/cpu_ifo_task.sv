typedef struct packed {
  logic [9:0]  v_ada;       // write addr
  logic [1:0]  v_din_t;     // 0:to_hexchar(dout[7:4]), 1:to_hexchar(dout[3:0]), 2: use v_din
  logic [7:0]  v_din;
  logic [13:0] adb_diff;    // read addr: number to add operands[15:0]
  logic        vram_write;
  logic        mem_read;
} show_info_cmd_t;

show_info_cmd_t show_info_rom[1024];
show_info_cmd_t show_info_cmd;

initial begin
  // Registers)
  show_info_rom[0] = '{v_ada: 10'd0, v_din_t: 2, v_din: 8'h52, adb_diff: 8'h00, vram_write: 1, mem_read: 0};
  show_info_rom[1] = '{v_ada: 10'd1, v_din_t: 2, v_din: 8'h65, adb_diff: 8'h00, vram_write: 1, mem_read: 0};
  show_info_rom[2] = '{v_ada: 10'd2, v_din_t: 2, v_din: 8'h67, adb_diff: 8'h00, vram_write: 1, mem_read: 0};
  show_info_rom[3] = '{v_ada: 10'd3, v_din_t: 2, v_din: 8'h69, adb_diff: 8'h00, vram_write: 1, mem_read: 0};
  show_info_rom[4] = '{v_ada: 10'd4, v_din_t: 2, v_din: 8'h73, adb_diff: 8'h00, vram_write: 1, mem_read: 0};
  show_info_rom[5] = '{v_ada: 10'd5, v_din_t: 2, v_din: 8'h74, adb_diff: 8'h00, vram_write: 1, mem_read: 0};
  show_info_rom[6] = '{v_ada: 10'd6, v_din_t: 2, v_din: 8'h65, adb_diff: 8'h00, vram_write: 1, mem_read: 0};
  show_info_rom[7] = '{v_ada: 10'd7, v_din_t: 2, v_din: 8'h72, adb_diff: 8'h00, vram_write: 1, mem_read: 0};
  show_info_rom[8] = '{v_ada: 10'd8, v_din_t: 2, v_din: 8'h73, adb_diff: 8'h00, vram_write: 1, mem_read: 0};
  show_info_rom[9] = '{v_ada: 10'd9, v_din_t: 2, v_din: 8'h29, adb_diff: 8'h00, vram_write: 1, mem_read: 0};
  `include "cpu_ifo_auto_generated.sv"
end


function automatic logic [7:0] to_hexchar(input logic [3:0] nibble);
  if (nibble < 10) return 8'h30 + nibble;  // '0'〜'9'
  else return 8'h41 + (nibble - 10);  // 'A'〜'F'
endfunction
