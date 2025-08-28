// ram.sv - Memory Interface Wrapper
// 
// This module provides a clean abstraction layer over Gowin IP cores for:
// - 32KB SDPB RAM for CPU main memory
// - 1KB SDPB VRAM for video text display
//
// The module hides the complexity of dual-port memory interfaces and provides
// consistent naming conventions for both memory types.
//
module ram (
    input logic MEMORY_CLK,
    
    // Main RAM Interface (32KB)
    output logic [7:0] dout,        // RAM read data
    input logic cea,                // RAM write enable
    input logic ceb,                // RAM read enable
    input logic oce,                // RAM output clock enable
    input logic reseta,             // RAM write port reset
    input logic resetb,             // RAM read port reset
    input logic [14:0] ada,         // RAM write address
    input logic [14:0] adb,         // RAM read address
    input logic [7:0] din,          // RAM write data
    
    // Video RAM Interface (1KB)  
    output logic [7:0] v_dout,      // VRAM read data
    input logic v_cea,              // VRAM write enable
    input logic v_ceb,              // VRAM read enable
    input logic v_oce,              // VRAM output clock enable
    input logic v_reseta,           // VRAM write port reset
    input logic v_resetb,           // VRAM read port reset
    input logic [9:0] v_ada,        // VRAM write address
    input logic [9:0] v_adb,        // VRAM read address
    input logic [7:0] v_din         // VRAM write data
);

  // RAM 32KB, address 32768, data width 8, bypass

  Gowin_SDPB ram_inst (
      .dout(dout),  //output [7:0] dout, read data
      .clka(MEMORY_CLK),  //input clka
      .cea(cea),  //input cea, write enable
      .reseta(reseta),  //input reseta
      .clkb(MEMORY_CLK),  //input clkb
      .ceb(ceb),  //input ceb, read enable
      .resetb(resetb),  //input resetb
      .oce(oce),  //input oce, timing when the read value is reflected on dout
      .ada(ada),  //input [12:0] ada, for write
      .din(din),  //input [7:0] din, written data
      .adb(adb)  //input [12:0] adb, for read
  );

  // Text VRAM, address 1024, data width 8, bypass

  Gowin_SDPB_vram vram_inst (
      .dout(v_dout),  //output [7:0] dout, read data
      .clka(MEMORY_CLK),  //input clka
      .cea(v_cea),  //input cea, write enable
      .reseta(v_reseta),  //input reseta
      .clkb(MEMORY_CLK),  //input clkb
      .ceb(v_ceb),  //input ceb, read enable
      .resetb(v_resetb),  //input resetb
      .oce(v_oce),  //input oce, timing when the read value is reflected on dout
      .ada(v_ada),  //input [9:0] ada, for write
      .din(v_din),  //input [7:0] din, written data
      .adb(v_adb)  //input [9:0] adb, for read
  );

endmodule
