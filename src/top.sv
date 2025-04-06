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
  // wire rst_n = !ResetButton;

  wire rst = !rst_n;

  // PLL ... make it by IP Generator -> Hard Module -> Clock -> rPLL -> clockin 27, clockout 9
  // (480+43+8) * (272+8+12) * 60Hz = 9.3MHz
  // 9MHz / (480+43+8) / (272+8+12) = 58.05Hz
  // 10MHz / (480+43+8) / (272+8+12) = 64.5Hz
  Gowin_rPLL9 rpll9_inst (
      .clkout(LCD_CLK),  //  9MHz
      .clkin (XTAL_IN)   //  27MHz
  );
  Gowin_rPLL54 rpll54_inst (
      .clkout(MEMORY_CLK),  //  9MHz
      .clkin(XTAL_IN)  //  27MHz
  );

  // RAM 8KB, address 8192, data width 8
  logic cea, ceb, oce;
  logic reseta, resetb;
  logic [12:0] ada, adb;
  logic [7:0] din;
  logic [7:0] dout;

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
  logic v_cea, v_ceb, v_oce;
  logic v_reseta, v_resetb;
  logic [9:0] v_ada, v_adb;
  logic [7:0] v_din;
  logic [7:0] v_dout;
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
  lcd lcd_inst (
      .PixelClk(LCD_CLK),
      .nRST    (rst_n),
      .v_dout  (v_dout),
      .f_dout(f_dout),

      .LCD_DE(LCD_DEN),
      .LCD_B (LCD_B),
      .LCD_G (LCD_G),
      .LCD_R (LCD_R),
      .v_adb (v_adb),
      .f_ad(f_ad)
  );


  //   Bootloader signals
  logic       boot_mode;  // 1 during boot, 0 after boot is done
  logic       boot_write;  // Internal signal to control when to write
  logic [7:0] boot_data;
  parameter int unsigned MAX_BOOT_DATA = 1024;

  // set the following initial test values in vram
  // 0x0000: 0x00
  // 0x0001: 0x01
  // 0x0002: 0x02
  // ...
  // 0x007F: 0x7F
  always_ff @(posedge MEMORY_CLK or negedge rst_n) begin
    if (!rst_n) begin
      v_ada    <= 10'h0;  // Start address for boot data
      v_cea    <= 0;  // disaable write
      v_reseta <= 0;
      v_resetb <= 0;
      v_ceb = 1;  // enable read
      v_oce = 1;  // enable output
      f_ce = 1;  // enable font read
      f_oce = 1;  // enable font output
      f_reset = 0;
      boot_mode  <= 1;
      boot_write <= 1;
      boot_data = 8'h0;
    end else if (boot_mode) begin
      if (boot_write) begin
        v_din <= boot_data;
        v_cea <= 1;  // enable write
        boot_write <= 0;  // Prevent immediate increment in the same cycle
      end else begin
        v_cea <= 0;  // disable write
        if (v_ada == 10'h3FF) begin
          boot_mode <= 0;  // End boot process after writing all data
        end else begin
          // boot_data <= v_ada[6:0];  // Set the data to be written
          boot_data <= (boot_data + 1) & 8'h7F;
          v_ada <= (v_ada + 1) & 10'h03FF;
          boot_write <= 1;  // Enable write for the next address
        end
      end
    end else begin
      v_cea <= 0;  // write disable
    end
  end

endmodule
