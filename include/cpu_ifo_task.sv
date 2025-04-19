typedef struct packed {
  logic [9:0]  v_ada;       // write addr
  // v_din_t: type of v_din
  // 0: to_hexchar(dout[7:4])
  // 1: to_hexchar(dout[3:0])
  // 2: use v_din value
  // 3: A register
  // 4: X register
  // 5: Y register
  // 6: SP
  // 7: PC
  // 8: operands (start memory address)
  logic [3:0]  v_din_t;
  // v_din: value (if v_din_t is 2) or index of v_din
  // 0: 1st nibble (e.g. high nibble of register A)
  // 1: 2nd nibble (e.g. low nibble of register A)
  // 2: 3rd nibble
  // 3: 4th nibble
  logic [7:0]  v_din;
  logic [7:0] diff;    // read addr: number to add operands[15:0]
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
