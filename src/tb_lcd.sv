module tb_lcd;
  lcd dut ();

  initial begin
    clk = 0;
    @(posedge clk);  // wait for 1 clock cycle before starting the test
    $finish;
  end
endmodule
