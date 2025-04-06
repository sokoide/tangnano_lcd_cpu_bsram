module top (
    input logic ResetButton,
    input logic XTAL_IN,

    output logic       LCD_CLK,
    output logic       LCD_DEN,
    output logic [4:0] LCD_R,
    output logic [5:0] LCD_G,
    output logic [4:0] LCD_B,

    output logic       MEMORY_CLK
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


//   Bootloader signals
  logic        boot_mode;  // 1 during boot, 0 after boot is done
  logic        boot_write;  // Internal signal to control when to write
  logic [ 7:0] boot_data;
  parameter int unsigned MAX_BOOT_DATA = 127;

// set the following initial test values
// 0x200: 0x00
// 0x201: 0x01
// 0x202: 0x02
// ...
// 0x27F: 0x7F
  always_ff @(posedge MEMORY_CLK or negedge rst_n) begin
    if (!rst_n) begin
      ada        <= 13'h0200;  // Start address for boot data
      boot_mode  <= 1;
      boot_write <= 1;
      cea        <= 0;  // disaable write
      reseta     <= 0;
      boot_data = 8'h00;
    end else if (boot_mode) begin
      if (boot_write) begin
        din <= boot_data;
        cea <= 1;  // enable write
        boot_write <= 0;  // Prevent immediate increment in the same cycle
      end else begin
        cea <= 0;  // disable write
        if (boot_data == MAX_BOOT_DATA) begin
          boot_mode <= 0;  // End boot process after writing all data
        end else begin
          boot_data <= boot_data + 1;
          ada <= (ada + 1) & 13'h1FFF;
          boot_write <= 1;  // Enable write for the next address
        end
      end
    end else begin
      cea <= 0;  // write disable
    end
  end

endmodule
