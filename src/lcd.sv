// lcd.sv - LCD Controller for 480x272 Display
//
// This module generates the timing and pixel data for a 480x272 RGB LCD display.
// It implements a text-based display system with the following features:
// - 60 columns × 17 rows character display
// - 16×8 pixel characters from font ROM
// - Dual clock domain operation (LCD pixel clock and memory clock)
// - Hardware-accelerated character rendering pipeline
//
// The module operates by:
// 1. Generating horizontal and vertical sync timing
// 2. Calculating character positions based on pixel coordinates  
// 3. Fetching character codes from VRAM with proper timing offsets
// 4. Looking up font bitmaps and rendering pixels
//
`include "consts.svh"
module lcd (
    input logic       PixelClk,        // LCD pixel clock (9MHz)
    input logic       nRST,            // Active-low reset
    input logic [7:0] v_dout,          // VRAM read data (character codes)
    input logic [7:0] f_dout,          // Font ROM read data (pixel bitmap)

    output logic        LCD_DE,        // Data enable signal for LCD
    output logic [ 4:0] LCD_B,         // Blue color output (5-bit)
    output logic [ 5:0] LCD_G,         // Green color output (6-bit)  
    output logic [ 4:0] LCD_R,         // Red color output (5-bit)
    output logic [ 9:0] v_adb,         // VRAM read address
    output logic [11:0] f_ad,          // Font ROM address
    output logic        vsync          // Vertical sync for CPU synchronization
);

  logic vsync_reg;
  assign vsync = vsync_reg;

  // Horizontal and Vertical pixel counters
  logic [15:0] H_PixelCount;
  logic [15:0] V_PixelCount;

  // Sequential logic for pixel counters
  always_ff @(posedge PixelClk or negedge nRST) begin
    if (!nRST) begin
      vsync_reg <= 1'b0;
      V_PixelCount <= 16'd0;
      H_PixelCount <= 16'd0;
    end else if (H_PixelCount == PixelForHS) begin
      H_PixelCount <= 16'd0;
      V_PixelCount <= V_PixelCount + 1'b1;
      vsync_reg <= (V_PixelCount < V_BackPorch) || (V_PixelCount >= V_BackPorch + V_PixelValid);
    end else if (V_PixelCount == PixelForVS) begin
      V_PixelCount <= 16'd0;
      H_PixelCount <= 16'd0;
      vsync_reg <= 1'b1;
    end else begin
      H_PixelCount <= H_PixelCount + 1'b1;
    end
  end

  // VSync is registered to avoid timing violations in cross-clock domain paths
  // 
  // Without vsync_reg, the FPGA timing analyzer sees a problematic path:
  // PixelClk → combinational vsync → CPU clock domain flip-flops
  // This creates timing analysis issues as the signal crosses clock domains
  // without proper synchronization. The registered version provides clean
  // clock domain crossing behavior.
  //
  // Avoided combinational implementation:
  // assign vsync = (V_PixelCount < V_BackPorch) ||
  //                (V_PixelCount >= V_BackPorch + V_PixelValid);

  // SYNC-DE MODE
  assign LCD_DE = ((H_PixelCount >= H_BackPorch) &&
                   (H_PixelCount < H_PixelValid + H_BackPorch) &&
                   (V_PixelCount >= V_BackPorch) &&
                   (V_PixelCount < V_PixelValid + V_BackPorch)) ? 1'b1 : 1'b0;

  logic [7:0] char;
  logic [7:0] fontline;  // font bitmap for the current line (8 pixels)
  logic signed [15:0] x, y;
  logic active_area;

  always_comb begin
    automatic logic signed [31:0] x_full, y_full;
    x_full = H_PixelCount - H_BackPorch + CHAR_WIDTH;
    y_full = V_PixelCount - V_BackPorch;
    x = x_full[15:0];
    y = y_full[15:0];
    active_area = (-1 <= x && x < H_PixelValid + CHAR_WIDTH - 1 && 0 <= y && y < V_PixelValid);

  end

  always_ff @(posedge PixelClk or negedge nRST) begin
    // x could be minus (underflow) when H_PixelCount is smaller than H_BackPorch
    // so we need to use signed logic to avoid the underflow
    // then use +8 to calcurate the vram address
    // automatic logic active_area = (0 <= x && x < H_PixelValid + 8 && 0 <= y && y < V_PixelValid);
    if (!nRST) begin
      LCD_R <= 5'b00000;
      LCD_G <= 6'b000000;
      LCD_B <= 5'b00000;
    end else if (active_area) begin
      // Character rendering pipeline with precise timing offsets
      // Each stage is offset to account for memory access latency
      if (CHAR_FETCH_OFFSET_1 <= x && x < H_PixelValid + CHAR_FETCH_OFFSET_1 + CHAR_WIDTH && 0 <= y && y < V_PixelValid && (x - CHAR_FETCH_OFFSET_1) % CHAR_WIDTH == 0) begin
        // Stage 1: Calculate VRAM address for character lookup
        v_adb <= ((x / CHAR_WIDTH) + ((y / CHAR_HEIGHT) * COLUMNS)) & VRAMW;
      end else if (CHAR_FETCH_OFFSET_2 <= x && x < H_PixelValid + CHAR_FETCH_OFFSET_2 + CHAR_WIDTH && 0 <= y && y < V_PixelValid && (x - CHAR_FETCH_OFFSET_2) % CHAR_WIDTH == 0) begin
        // Stage 2: Capture character code from VRAM
        char <= v_dout;
      end else if (CHAR_FETCH_OFFSET_3 <= x && x < H_PixelValid + CHAR_FETCH_OFFSET_3 + CHAR_WIDTH && 0 <= y && y < V_PixelValid && (x - CHAR_FETCH_OFFSET_3) % CHAR_WIDTH == 0) begin
        // Stage 3: Calculate font ROM address
        f_ad <= char * CHAR_HEIGHT + (y % CHAR_HEIGHT);
      end else if (CHAR_FETCH_OFFSET_4 <= x && x < H_PixelValid + CHAR_FETCH_OFFSET_4 + CHAR_WIDTH && 0 <= y && y < V_PixelValid && (x - CHAR_FETCH_OFFSET_4) % CHAR_WIDTH == 0) begin
        // Stage 4: Capture font bitmap data
        fontline <= f_dout;
      end
      // get fontline

      // Render character pixels
      if (char >= CHAR_CODE_MIN && char <= CHAR_CODE_MAX) begin
        if (fontline[7-(x + CHAR_RENDER_OFFSET)%CHAR_WIDTH] == 1'b1) begin
          // Foreground pixel (green)
          LCD_R <= LCD_RED_ON;
          LCD_G <= LCD_GREEN_ON;
          LCD_B <= LCD_BLUE_ON;
        end else begin
          // Background pixel (black)
          LCD_R <= LCD_RED_OFF;
          LCD_G <= LCD_GREEN_OFF;
          LCD_B <= LCD_BLUE_OFF;
        end
      end else begin
        // Invalid character code (red)
        LCD_R <= LCD_RED_ERROR;
        LCD_G <= LCD_GREEN_ERROR;
        LCD_B <= LCD_BLUE_ERROR;
      end
    end else begin
      // Border area (yellow)
      LCD_R <= LCD_RED_BORDER;
      LCD_G <= LCD_GREEN_BORDER;
      LCD_B <= LCD_BLUE_BORDER;
    end
  end

endmodule
