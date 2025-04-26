typedef struct packed {
  // write addr
  logic [9:0] v_ada;

  // v_din_t: type of v_din
  // 0: use v_din value
  // 1: use dout value
  // 2: A register
  // 3: X register
  // 4: Y register
  // 5: SP
  // 6: PC
  // 7: operands (start memory address)
  // 8: read specifiled address by v_ada. you can't read & write at the same time if you select this
  logic [3:0] v_din_t;

  // v_din: char code to display (if v_din_t is 0) or how to show v_din_t below
  // 0x0: 1st nibble (e.g. high nibble of register A)
  // 0x1: 2nd nibble (e.g. low nibble of register A)
  // 0x2: 3rd nibble
  // 0x3: 4th nibble
  // 0x4: '@' if 7th bit is 1, ' ' otherwise
  // 0x5: '@' if 6th bit is 1, ' ' otherwize
  // 0x6: '@' if 5th bit is 1, ' ' otherwize
  // 0x7: '@' if 4th bit is 1, ' ' otherwize
  // 0x8: '@' if 3rd bit is 1, ' ' otherwize
  // 0x9: '@' if 2nd bit is 1, ' ' otherwize
  // 0xA: '@' if 1st bit is 1, ' ' otherwize
  // 0xB: '@' if 0th bit is 1, ' ' otherwize
  logic [7:0] v_din;

  // diff: number to add operands[15:0]
  logic [7:0] diff;
  logic        vram_write;
  logic        mem_read;
} show_info_cmd_t;

show_info_cmd_t show_info_cmd;

localparam show_info_cmd_t show_info_rom [1024] =
  '{
  `include "cpu_ifo_auto_generated.sv"
  }
;

function automatic logic [7:0] to_hexchar(input logic [3:0] nibble);
  if (nibble < 10) return 8'h30 + nibble;  // '0'〜'9'
  else return 8'h41 + (nibble - 10) & 8'hFF;  // 'A'〜'F'
endfunction

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

task automatic sta_write(input logic [15:0] addr, input logic [7:0] data);
  if (addr >= VRAM_START) begin
    v_ada <= addr - VRAM_START & VRAMW;
    v_din <= data;
    ada   <= addr - VRAM_START + SHADOW_VRAM_START & RAMW;
    din   <= data;
    cea <= 1;
  end else begin
    ada <= addr & RAMW;
    din <= data;
    cea <= 1;
  end
endtask

task automatic vram_write(input logic [15:0] addr, input logic [7:0] data);
    v_ada <= addr & VRAMW;
    v_din <= data;
    ada   <= addr + SHADOW_VRAM_START & RAMW;
    din   <= data;
    cea <= 1;
endtask
