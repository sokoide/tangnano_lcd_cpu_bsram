module top (
    input logic ResetButton,
    input logic XTAL_IN,

    output logic       LCD_CLK,
    output logic       LCD_DEN,
    output logic [4:0] LCD_R,
    output logic [5:0] LCD_G,
    output logic [4:0] LCD_B,

    output logic MEMORY_CLK
);

  // Tang Nano 9K:
  wire rst_n = ResetButton;
  // Tang Nano 20K:
  //   wire rst_n = !ResetButton;

  wire rst = !rst_n;

  // PLL ... make it by IP Generator -> Hard Module -> Clock -> rPLL -> clockin 27, clockout 9
  // (480+43+8) * (272+8+12) * 60Hz = 9.3MHz
  // 9MHz / (480+43+8) / (272+8+12) = 58.05Hz
  // 10MHz / (480+43+8) / (272+8+12) = 64.5Hz
  Gowin_rPLL9 rpll9_inst (
      .clkout(LCD_CLK),  //  9MHz
      .clkin (XTAL_IN)   //  27MHz
  );
  Gowin_rPLL40 rpll40_inst (
      .clkout(MEMORY_CLK),  //  40.5MHz
      .clkin (XTAL_IN)      //  27MHz
  );

  // pROM for font
  // 16bytes/char x 256 chars = 4KB
  logic f_ce, f_oce, f_reset;
  logic [ 7:0] f_dout;
  logic [11:0] f_ad;
  Gowin_pROM_font prom_font_inst (
      .dout(f_dout),  //output [7:0] dout
      .clk(MEMORY_CLK),  //input clk
      .oce(f_oce),  //input oce
      .ce(f_ce),  //input ce
      .reset(f_reset),  //input reset
      .ad(f_ad)  //input [11:0] ad
  );

  // LCD
  logic vsync;

  lcd lcd_inst (
      .PixelClk(LCD_CLK),
      .nRST    (rst_n),
      .v_dout  (v_dout),
      .f_dout  (f_dout),

      .LCD_DE(LCD_DEN),
      .LCD_B (LCD_B),
      .LCD_G (LCD_G),
      .LCD_R (LCD_R),
      .v_adb (v_adb),
      .f_ad  (f_ad),
      .vsync (vsync)
  );

  // --- VRAM Read Address Clock Domain Crossing (CDC) Synchronization ---
  // v_adb 信号 (PixelClk ドメインから MEMORY_CLK ドメインへ) を同期化する
  logic [9:0] v_adb_sync1;  // 第1段レジスタ
  logic [9:0] v_adb_sync2;  // 第2段レジスタ (同期化された信号)

  // MEMORY_CLK ドメインで動作する同期化レジスタチェーン
  always_ff @(posedge MEMORY_CLK or negedge rst_n) begin
    if (!rst_n) begin
      v_adb_sync1 <= 10'd0;  // リセット時は0クリア
      v_adb_sync2 <= 10'd0;
    end else begin
      v_adb_sync1 <= lcd_inst.v_adb; // PixelClk ドメインからの信号を MEMORY_CLK で捕捉
      v_adb_sync2 <= v_adb_sync1;   // 捕捉した信号をもう一段レジスタに通し、安定化
    end
  end
  // --- End of CDC Synchronization ---

  // RAM
  logic cea, ceb, oce;
  logic reseta, resetb;
  logic [14:0] ada, adb;
  logic [7:0] din;
  logic [7:0] dout;
  logic v_cea, v_ceb, v_oce;
  logic v_reseta, v_resetb;
  logic [9:0] v_ada, v_adb;
  logic [7:0] v_din;
  logic [7:0] v_dout;

  ram ram_inst (
      // common
      .MEMORY_CLK(MEMORY_CLK),
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
      .v_adb(v_adb_sync2),
      .v_din(v_din)
  );

  // Boot program instance
  `include "boot_program.sv"

  // CPU instance
  cpu cpu_inst (
      .rst_n(rst_n),
      .clk(MEMORY_CLK),
      .dout(dout),
      .vsync(vsync),
      .boot_program(boot_program),
      .boot_program_length(boot_program_length),
      .din(din),
      .ada(ada),
      .cea(cea),
      .ceb(ceb),
      .adb(adb),
      .v_ada(v_ada),
      .v_cea(v_cea),
      .v_din(v_din)
  );

  always_ff @(posedge MEMORY_CLK or negedge rst_n) begin
    if (!rst_n) begin
      reseta <= 0;
      resetb <= 0;
      oce <= 0;  // dout is not reflected
      v_reseta <= 0;
      v_resetb <= 0;
      v_ceb = 1;  // enable read
      v_oce = 0;  // v_dout is not reflected
      f_ce = 1;  // enable font read
      f_oce = 1;  // enable font output
      f_reset = 0;
    end
  end

endmodule
