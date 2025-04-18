typedef struct packed {
  logic [9:0]  v_ada;       // write addr
  logic        v_din_t;     // 0:to_hexchar(dout[7:4]), 1:to_hexchar(dout[3:0])
  logic [13:0] adb_diff;    // read addr: number to add operands[15:0]
  logic        vram_write;
  logic        mem_read;
} show_info_cmd_t;

show_info_cmd_t show_info_rom[1024];
show_info_cmd_t show_info_cmd;

initial begin
  `include "cpu_ifo_auto_generated.sv"
end


function automatic logic [7:0] to_hexchar(input logic [3:0] nibble);
  if (nibble < 10) return 8'h30 + nibble;  // '0'〜'9'
  else return 8'h41 + (nibble - 10);  // 'A'〜'F'
endfunction
