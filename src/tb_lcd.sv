module tb_lcd;
  logic clk;
  logic rst_n;
  logic [7:0] v_dout;
  logic [7:0] f_dout;
  logic LCD_DEN;
  logic [4:0] LCD_B;
  logic [5:0] LCD_G;
  logic [4:0] LCD_R;
  logic [9:0] v_adb;
  logic [11:0] f_ad;
  logic vsync;

  lcd dut (
      .PixelClk (clk),
      .nRST     (rst_n),
      .v_dout (v_dout),
      .f_dout (f_dout),

      .LCD_DE(LCD_DEN),
      .LCD_B (LCD_B),
      .LCD_G (LCD_G),
      .LCD_R (LCD_R),
      .v_adb(v_adb),
      .f_ad(f_ad),
      .vsync(vsync)
  );

  // 20ns clock (#10 means 10ns)
  always #10 clk = ~clk;

  initial begin
    $display("=== Test Started ===");
    clk  = 0;

    rst_n = 0;  // active
    @(posedge clk);  // wait for 1 clock cycle
    rst_n = 1;  // release

    repeat (500*300*10) @(posedge clk);

    $display("=== Test End ===");
    $finish;
  end

endmodule
