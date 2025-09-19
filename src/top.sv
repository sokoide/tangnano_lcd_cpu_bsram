// top.sv - System Integration Module
//
// This module integrates all components of the Tang Nano LCD + 6502 CPU system:
// - Clock generation (PLLs for LCD and CPU/memory domains)
// - Memory subsystem (RAM, VRAM, Font ROM)
// - LCD controller for 480x272 display
// - 6502 CPU core with custom instructions
// - Clock domain crossing synchronization
//
// The system operates with dual clock domains:
// - 9MHz for LCD pixel timing
// - 40.5MHz for CPU and memory operations
//
// Board Configuration:
// - Tang Nano 9K: rst_n = ResetButton (active high button)
// - Tang Nano 20K: rst_n = !ResetButton (active low button)
//
module top (
    // Clock and Reset
    input logic ResetButton,            // Board reset button (polarity depends on board variant)
    input logic XTAL_IN,                // 27MHz crystal oscillator input

    // LCD Interface
    output logic       LCD_CLK,         // LCD pixel clock output (9MHz)
    output logic       LCD_DEN,         // LCD data enable
    output logic [4:0] LCD_R,           // LCD red channel (5-bit)
    output logic [5:0] LCD_G,           // LCD green channel (6-bit)
    output logic [4:0] LCD_B,           // LCD blue channel (5-bit)

    // Debug/Test Outputs
    output logic MEMORY_CLK             // Memory clock output for debugging (40.5MHz)
);

  // Board-specific reset polarity configuration
  // Tang Nano 9K: Button is active high
  wire rst_n = ResetButton;
  // Tang Nano 20K: Button is active low (uncomment line below for 20K)
  // wire rst_n = !ResetButton;

  wire rst = !rst_n;

  // Clock Generation via Phase-Locked Loops (PLLs)
  // LCD timing: (480+43+8) * (272+8+12) * 58.05Hz ≈ 9MHz
  // CPU/Memory: Higher frequency for processing performance
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

  // Clock Domain Crossing (CDC) Synchronization for VRAM Read Address
  //
  // The v_adb signal crosses from the LCD pixel clock domain (9MHz) to the
  // memory clock domain (40.5MHz). A two-stage synchronizer prevents
  // metastability and ensures reliable data transfer between domains.
  //
  logic [9:0] v_adb_sync1;      // First synchronizer stage
  logic [9:0] v_adb_sync2;      // Second synchronizer stage (stable output)

  // Two-stage synchronizer running in the memory clock domain
  always_ff @(posedge MEMORY_CLK or negedge rst_n) begin
    if (!rst_n) begin
      v_adb_sync1 <= 10'd0;      // Clear on reset
      v_adb_sync2 <= 10'd0;
    end else begin
      v_adb_sync1 <= lcd_inst.v_adb;  // Capture LCD domain signal
      v_adb_sync2 <= v_adb_sync1;     // Stabilize through second register
    end
  end

  // Memory Interface Signals

  // Main RAM (32KB) Interface
  logic [7:0] dout;               // RAM read data
  logic cea, ceb, oce;            // RAM control signals
  logic reseta, resetb;           // RAM reset signals
  logic [14:0] ada, adb;          // RAM addresses (write/read)
  logic [7:0] din;                // RAM write data

  // Video RAM (1KB) Interface
  logic [7:0] v_dout;             // VRAM read data
  logic v_cea, v_ceb, v_oce;      // VRAM control signals
  logic v_reseta, v_resetb;       // VRAM reset signals
  logic [9:0] v_ada, v_adb;       // VRAM addresses (write/read)
  logic [7:0] v_din;              // VRAM write data

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

  // Initialize control signals
  always_ff @(posedge MEMORY_CLK or negedge rst_n) begin
    if (!rst_n) begin
      // RAM control signals
      reseta <= 1'b0;
      resetb <= 1'b0;
      oce <= 1'b0;        // RAM output not reflected initially

      // VRAM control signals
      v_reseta <= 1'b0;
      v_resetb <= 1'b0;
      v_ceb <= 1'b1;      // Enable VRAM read
      v_oce <= 1'b0;      // VRAM output not reflected initially

      // Font ROM control signals
      f_ce <= 1'b1;       // Enable font ROM
      f_oce <= 1'b1;      // Enable font ROM output
      f_reset <= 1'b0;
    end
  end

endmodule
