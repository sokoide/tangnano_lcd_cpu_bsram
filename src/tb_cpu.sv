module tb_cpu;
  cpu dut ();

  logic clk;
  logic rst_n;

  // 20ns clock (#10 means 10ns) == 50MHz
  always #10 clk = ~clk;

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
