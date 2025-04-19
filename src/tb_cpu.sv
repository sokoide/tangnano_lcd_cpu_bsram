module tb_cpu;
  logic clk;
  logic rst_n;

  // RAM
  logic cea, ceb, oce;
  logic reseta, resetb;
  logic [12:0] ada, adb;
  logic [7:0] din;
  logic [7:0] dout;
  logic v_cea, v_ceb, v_oce;
  logic v_reseta, v_resetb;
  logic [9:0] v_ada, v_adb;
  logic [7:0] v_din;
  logic [7:0] v_dout;
  logic vsync;

  // Boot program instance
  `include "boot_program.sv"

  cpu dut (
      .rst_n(rst_n),
      .clk  (clk),
      .dout (dout),
      .vsync(vsync),
      .boot_program(boot_program),
      .boot_program_length(boot_program_length),
      .din  (din),
      .ada  (ada),
      .cea  (cea),
      .ceb  (ceb),
      .adb  (adb),
      .v_ada(v_ada),
      .v_cea(v_cea),
      .v_din(v_din)
  );

  // 20ns clock (#10 means 10ns) == 50MHz
  always #10 clk = ~clk;

  // 10ns vsync
  always #50 vsync = ~vsync;

  ram ram_inst (
      // common
      .MEMORY_CLK(clk),
      // regular RAM
      .dout(dout),
      .cea(cea),
      .ceb(ceb),
      .oce(oce),
      .reseta(reseta),
      .resetb(resetb),
      .ada(ada),
      .adb(adb),
      .din(din),
      // VRAM
      .v_dout(v_dout),
      .v_cea(v_cea),
      .v_ceb(v_ceb),
      .v_oce(v_oce),
      .v_reseta(v_reseta),
      .v_resetb(v_resetb),
      .v_ada(v_ada),
      .v_adb(v_adb),
      .v_din(v_din)
  );

  initial begin
    $display("=== Test Started ===");
    clk = 0;
    vsync = 0;

    reseta   <= 0;
    resetb   <= 0;
    v_reseta <= 0;
    v_resetb <= 0;

    rst_n = 0;  // active
    @(posedge clk);  // wait for 1 clock cycle
    rst_n = 1;  // release

    // repeat(1) @(posedge clk); is same as #2; because 1 clock on->off is 2 cycles
    repeat (4000) @(posedge clk);

    $display("=== Test End ===");
    $finish;
  end
endmodule
