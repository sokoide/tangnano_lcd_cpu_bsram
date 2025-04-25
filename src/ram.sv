module ram (
    input logic MEMORY_CLK,
    // RAM
    output logic [7:0] dout,
    input logic cea,
    input logic ceb,
    input logic oce,
    input logic reseta,
    input logic resetb,
    input logic [14:0] ada,
    input logic [14:0] adb,
    input logic [7:0] din,
    // VRAM
    output logic [7:0] v_dout,
    input logic v_cea,
    input logic v_ceb,
    logic v_oce,
    input logic v_reseta,
    input logic v_resetb,
    input logic [9:0] v_ada,
    input logic [9:0] v_adb,
    input logic [7:0] v_din
);

  // RAM 32KB, address 32768, data width 8

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

  // Text VRAM, address 1024, data width 8

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
      .din(v_din),  //input [7:0] din, wirtten data
      .adb(v_adb)  //input [9:0] adb, for read
  );

endmodule
