`include "consts.svh"
module lcd (
    input logic       PixelClk,
    input logic       nRST,
    input logic [7:0] v_dout,
    input logic [7:0] f_dout,

    output logic        LCD_DE,
    output logic [ 4:0] LCD_B,
    output logic [ 5:0] LCD_G,
    output logic [ 4:0] LCD_R,
    output logic [ 9:0] v_adb,
    output logic [11:0] f_ad,
    output logic        vsync
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

  // if you do this w/o using vsync_reg, the FPGA timing report may see
  // it a timing voloation because
  // これは combinational logic です。
  // V_PixelCount は PixelClk ドメインで動いています。
  // vsync は combinational なため、そのまま cpu に渡すと、タイミング解析では「PixelClk → vsync → CPUクロックのFF」 というパスが解析されます。
  // 結果として、再びタイミング違反として報告される or 非同期パスにならないとツールに誤解される。
  // Don't do this:
  // assign vsync = (V_PixelCount < V_BackPorch) ||
  //              (V_PixelCount >= V_BackPorch + V_PixelValid);

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
    x_full = H_PixelCount - H_BackPorch + 16'd8;
    y_full = V_PixelCount - V_BackPorch;
    x = x_full[15:0];
    y = y_full[15:0];
    active_area = (-1 <= x && x < H_PixelValid + 8 - 1 && 0 <= y && y < V_PixelValid);

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
      // get char code
      if (-5 <= x && x < H_PixelValid -5 + 8 && 0 <= y && y < V_PixelValid && (x+5) % 8 == 0) begin
        v_adb <= (x) / 8 + (y / 16) * 60 & VRAMW;
      end else if (-4 <= x && x < H_PixelValid -4 + 8 && 0 <= y && y < V_PixelValid && (x+4) % 8 == 0) begin
        char <= v_dout;
      end else if (-3 <= x && x < H_PixelValid -3 + 8 && 0 <= y && y < V_PixelValid && (x+3) % 8 == 0) begin
        f_ad <= char * 16 + (y % 16);
      end else if (-2 <= x && x < H_PixelValid -2 + 8 && 0 <= y && y < V_PixelValid && (x+2) % 8 == 0) begin
        fontline <= f_dout;
      end
      // get fontline

      // draw the char
      if (char >= 0 && char <= 127) begin
        if (fontline[7-(x+1)%8] == 1'b1) begin
          LCD_R <= 5'b00000;  // green, foreground
          LCD_G <= 6'b111111;
          LCD_B <= 5'b00000;
        end else begin
          LCD_R <= 5'b00000;  // black, background
          LCD_G <= 6'b000000;
          LCD_B <= 5'b00000;
        end
      end else begin
        LCD_R <= 5'b11111;  // red (char is not defined)
        LCD_G <= 6'b000000;
        LCD_B <= 5'b00000;
      end
    end else begin
      LCD_R <= 5'b11111;  // yellow
      LCD_G <= 6'b111111;
      LCD_B <= 5'b00000;
    end
  end

endmodule
