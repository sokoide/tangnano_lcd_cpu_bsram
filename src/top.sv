module top (
    input logic Reset_Button,
    input logic XTAL_IN,

    output logic       LCD_CLK,
    output logic       LCD_DEN,
    output logic [4:0] LCD_R,
    output logic [5:0] LCD_G,
    output logic [4:0] LCD_B
);
  // Tang Nano 9K:
  logic rst_n = Reset_Button;
  // Tang Nano 20K:
  // logic rst_n = !Reset_Button;

  wire  rst = !rst_n;

  // PLL ... make it by IP Generator -> Hard Module -> Clock -> rPLL -> clockin 27, clockout 9
  // (480+43+8) * (272+8+12) * 60Hz = 9.3MHz
  // 9MHz / (480+43+8) / (272+8+12) = 58.05Hz
  // 10MHz / (480+43+8) / (272+8+12) = 64.5Hz
  Gowin_rPLL rpll_inst (
      .clkout(LCD_CLK),  //  9MHz
      .clkin (XTAL_IN)   //  27MHz
  );

  // BSRAM 8KB, address 8192, data width 8
  logic cea, ceb, oce;
  logic reseta, resetb;
  logic [12:0] ada, adb;
  logic [7:0] din;
  logic [7:0] dout;


  Gowin_SDPB bsram_inst (
      .dout(dout),  //output [7:0] dout, read data
      .clka(clk),  //input clka
      .cea(cea),  //input cea, write enable
      .reseta(reseta),  //input reseta
      .clkb(clk),  //input clkb
      .ceb(ceb),  //input ceb, read enable
      .resetb(resetb),  //input resetb
      .oce(oce),  //input oce, timing when the read value is reflected on dout
      .ada(ada),  //input [12:0] ada, for write
      .din(din),  //input [7:0] din, written data
      .adb(adb)  //input [12:0] adb, for read
  );
  initial begin
    // 初期化
    cea    = 0;
    reseta = 1;
    ada    = 13'h0;
    din    = 8'h0;

    // リセット解除
    #5 reseta = 0;

    // 書き込みセットアップ
    ada = 13'h0200;
    din = 8'h06;
    cea = 1;

    // 書き込みクロック1サイクル
    #5 clk = 1;
    #5 clk = 0;

    // 無効化
    cea = 0;
  end


  // LCD
  logic [7:0] char = 8'd7;

  lcd lcd_inst (
      .PixelClk (LCD_CLK),
      .nRST     (rst_n),
      .Character(char),

      .LCD_DE(LCD_DEN),
      .LCD_B (LCD_B),
      .LCD_G (LCD_G),
      .LCD_R (LCD_R)
  );
endmodule
