function automatic logic [7:0] to_hexchar(input logic [3:0] nibble);
  if (nibble < 10) return 8'h30 + nibble;  // '0'〜'9'
  else return 8'h41 + (nibble - 10);  // 'A'〜'F'
endfunction

task automatic show_info_z00_block(input int counter);
  case (counter)
    `include "cpu_ifo_z00_auto_generated.sv"
  endcase
endtask

task automatic show_info_z01_block(input int counter);
  case (counter)
    `include "cpu_ifo_z01_auto_generated.sv"
  endcase
endtask

task automatic show_info_z02_block(input int counter);
  case (counter)
    `include "cpu_ifo_z02_auto_generated.sv"
  endcase
endtask

task automatic show_info_z03_block(input int counter);
  case (counter)
    `include "cpu_ifo_z03_auto_generated.sv"
  endcase
endtask

task automatic show_info_z04_block(input int counter);
  case (counter)
    `include "cpu_ifo_z04_auto_generated.sv"
  endcase
endtask

task automatic show_info_z05_block(input int counter);
  case (counter)
    `include "cpu_ifo_z05_auto_generated.sv"
  endcase
endtask

task automatic show_info_z06_block(input int counter);
  case (counter)
    `include "cpu_ifo_z06_auto_generated.sv"
  endcase
endtask

task automatic show_info_z07_block(input int counter);
  case (counter)
    `include "cpu_ifo_z07_auto_generated.sv"
  endcase
endtask
