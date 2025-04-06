module tb_cpu;
  cpu dut ();

  logic clk;
  logic rst_n;

  // 20ns clock (#10 means 10ns) == 50MHz
  always #10 clk = ~clk;

  // initial begin
  //   // initial setup
  //   cea    = 0;
  //   reseta = 1;
  //   ada    = 13'h0;
  //   din    = 8'h0;

  //   // input reset
  //   #5 reseta = 0;

  //   // setup for write, write 0x06 at 0x200
  //   ada = 13'h0200;
  //   din = 8'h06;
  //   cea = 1;

  //   // write 1 cycle
  //   #5 clk = 1;
  //   #5 clk = 0;

  //   // write disable
  //   cea = 0;
  // end

  initial begin
    $display("=== Test Started ===");
    clk   = 0;

    rst_n = 0;  // active
    @(posedge clk);  // wait for 1 clock cycle
    rst_n = 1;  // release

    // repeat(10) @(posedge clk); is same as #200;
    #100;

    $display("=== Test End ===");
    $finish;
  end
endmodule
