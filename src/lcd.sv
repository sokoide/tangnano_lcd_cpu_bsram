`include "consts.svh"

module lcd (
    input logic       PixelClk,
    input logic       nRST,
    input logic [7:0] Character,

    output logic       LCD_DE,
    output logic [4:0] LCD_B,
    output logic [5:0] LCD_G,
    output logic [4:0] LCD_R
);

  // Horizontal and Vertical pixel counters
  logic [15:0] H_PixelCount;
  logic [15:0] V_PixelCount;

  // Sequential logic for pixel counters
  always_ff @(posedge PixelClk or negedge nRST) begin
    if (!nRST) begin
      V_PixelCount <= 16'd0;
      H_PixelCount <= 16'd0;
    end else if (H_PixelCount == PixelForHS) begin
      V_PixelCount <= V_PixelCount + 1'b1;
      H_PixelCount <= 16'd0;
    end else if (V_PixelCount == PixelForVS) begin
      V_PixelCount <= 16'd0;
      H_PixelCount <= 16'd0;
    end else begin
      H_PixelCount <= H_PixelCount + 1'b1;
    end
  end

  // SYNC-DE MODE
  assign LCD_DE = ((H_PixelCount >= H_BackPorch) &&
                   (H_PixelCount <= (H_Pixel_Valid + H_BackPorch)) &&
                   (V_PixelCount >= V_BackPorch) &&
                   (V_PixelCount <= (V_Pixel_Valid + V_BackPorch))) ? 1'b1 : 1'b0;

  // character display parameters
  localparam NUMBER_WIDTH = 8;
  localparam NUMBER_HEIGHT = 16;
  localparam START_X = 0;
  localparam START_Y = 0;

  // simple 8x16 font for digits 0-9
  logic [NUMBER_WIDTH-1:0] font[127:0][NUMBER_HEIGHT-1:0];
  always_comb begin
    // 0
    font[0][0]  = 8'b00111100;
    font[0][1]  = 8'b01000010;
    font[0][2]  = 8'b10000001;
    font[0][3]  = 8'b10000011;
    font[0][4]  = 8'b10000101;
    font[0][5]  = 8'b10001001;
    font[0][6]  = 8'b10010001;
    font[0][7]  = 8'b10100001;
    font[0][8]  = 8'b11000001;
    font[0][9]  = 8'b10000001;
    font[0][10] = 8'b10000001;
    font[0][11] = 8'b10000001;
    font[0][12] = 8'b01000010;
    font[0][13] = 8'b00111100;
    font[0][14] = 8'b00000000;
    font[0][15] = 8'b00000000;

    // 1
    font[1][0]  = 8'b00010000;
    font[1][1]  = 8'b00110000;
    font[1][2]  = 8'b01010000;
    font[1][3]  = 8'b00010000;
    font[1][4]  = 8'b00010000;
    font[1][5]  = 8'b00010000;
    font[1][6]  = 8'b00010000;
    font[1][7]  = 8'b00010000;
    font[1][8]  = 8'b00010000;
    font[1][9]  = 8'b00010000;
    font[1][10] = 8'b00010000;
    font[1][11] = 8'b00010000;
    font[1][12] = 8'b01111110;
    font[1][13] = 8'b00000000;
    font[1][14] = 8'b00000000;
    font[1][15] = 8'b00000000;

    // 2
    font[2][0]  = 8'b00111100;
    font[2][1]  = 8'b01000010;
    font[2][2]  = 8'b00000010;
    font[2][3]  = 8'b00000100;
    font[2][4]  = 8'b00001000;
    font[2][5]  = 8'b00010000;
    font[2][6]  = 8'b00100000;
    font[2][7]  = 8'b01000000;
    font[2][8]  = 8'b01000000;
    font[2][9]  = 8'b01000000;
    font[2][10] = 8'b01000000;
    font[2][11] = 8'b01000000;
    font[2][12] = 8'b01111110;
    font[2][13] = 8'b00000000;
    font[2][14] = 8'b00000000;
    font[2][15] = 8'b00000000;

    // 3
    font[3][0]  = 8'b00111100;
    font[3][1]  = 8'b01000010;
    font[3][2]  = 8'b00000010;
    font[3][3]  = 8'b00000100;
    font[3][4]  = 8'b00011000;
    font[3][5]  = 8'b00000100;
    font[3][6]  = 8'b00000010;
    font[3][7]  = 8'b00000010;
    font[3][8]  = 8'b00000010;
    font[3][9]  = 8'b00000010;
    font[3][10] = 8'b01000010;
    font[3][11] = 8'b00111100;
    font[3][12] = 8'b00000000;
    font[3][13] = 8'b00000000;
    font[3][14] = 8'b00000000;
    font[3][15] = 8'b00000000;

    // 4
    font[4][0]  = 8'b00000100;
    font[4][1]  = 8'b00001100;
    font[4][2]  = 8'b00010100;
    font[4][3]  = 8'b00100100;
    font[4][4]  = 8'b01000100;
    font[4][5]  = 8'b01111110;
    font[4][6]  = 8'b00000100;
    font[4][7]  = 8'b00000100;
    font[4][8]  = 8'b00000100;
    font[4][9]  = 8'b00000100;
    font[4][10] = 8'b00000100;
    font[4][11] = 8'b00000100;
    font[4][12] = 8'b00000000;
    font[4][13] = 8'b00000000;
    font[4][14] = 8'b00000000;
    font[4][15] = 8'b00000000;

    // 5
    font[5][0]  = 8'b01111110;
    font[5][1]  = 8'b01000000;
    font[5][2]  = 8'b01000000;
    font[5][3]  = 8'b01000000;
    font[5][4]  = 8'b01111100;
    font[5][5]  = 8'b00000010;
    font[5][6]  = 8'b00000010;
    font[5][7]  = 8'b00000010;
    font[5][8]  = 8'b00000010;
    font[5][9]  = 8'b00000010;
    font[5][10] = 8'b01000010;
    font[5][11] = 8'b00111100;
    font[5][12] = 8'b00000000;
    font[5][13] = 8'b00000000;
    font[5][14] = 8'b00000000;
    font[5][15] = 8'b00000000;

    // 6
    font[6][0]  = 8'b00011100;
    font[6][1]  = 8'b00100000;
    font[6][2]  = 8'b01000000;
    font[6][3]  = 8'b01000000;
    font[6][4]  = 8'b01111100;
    font[6][5]  = 8'b01000010;
    font[6][6]  = 8'b01000010;
    font[6][7]  = 8'b01000010;
    font[6][8]  = 8'b01000010;
    font[6][9]  = 8'b01000010;
    font[6][10] = 8'b00111100;
    font[6][11] = 8'b00000000;
    font[6][12] = 8'b00000000;
    font[6][13] = 8'b00000000;
    font[6][14] = 8'b00000000;
    font[6][15] = 8'b00000000;

    // 7
    font[7][0]  = 8'b01111110;
    font[7][1]  = 8'b00000010;
    font[7][2]  = 8'b00000100;
    font[7][3]  = 8'b00000100;
    font[7][4]  = 8'b00001000;
    font[7][5]  = 8'b00001000;
    font[7][6]  = 8'b00010000;
    font[7][7]  = 8'b00010000;
    font[7][8]  = 8'b00100000;
    font[7][9]  = 8'b00100000;
    font[7][10] = 8'b01000000;
    font[7][11] = 8'b00000000;
    font[7][12] = 8'b00000000;
    font[7][13] = 8'b00000000;
    font[7][14] = 8'b00000000;
    font[7][15] = 8'b00000000;

    // 8
    font[8][0]  = 8'b00111100;
    font[8][1]  = 8'b01000010;
    font[8][2]  = 8'b01000010;
    font[8][3]  = 8'b01000010;
    font[8][4]  = 8'b00111100;
    font[8][5]  = 8'b01000010;
    font[8][6]  = 8'b01000010;
    font[8][7]  = 8'b01000010;
    font[8][8]  = 8'b01000010;
    font[8][9]  = 8'b01000010;
    font[8][10] = 8'b00111100;
    font[8][11] = 8'b00000000;
    font[8][12] = 8'b00000000;
    font[8][13] = 8'b00000000;
    font[8][14] = 8'b00000000;
    font[8][15] = 8'b00000000;

    // 9
    font[9][0]  = 8'b00111100;
    font[9][1]  = 8'b01000010;
    font[9][2]  = 8'b01000010;
    font[9][3]  = 8'b01000010;
    font[9][4]  = 8'b01000010;
    font[9][5]  = 8'b01000010;
    font[9][6]  = 8'b00111110;
    font[9][7]  = 8'b00000010;
    font[9][8]  = 8'b00000010;
    font[9][9]  = 8'b00000100;
    font[9][10] = 8'b00111000;
    font[9][11] = 8'b00000000;
    font[9][12] = 8'b00000000;
    font[9][13] = 8'b00000000;
    font[9][14] = 8'b00000000;
    font[9][15] = 8'b00000000;
  end


  always_ff @(posedge PixelClk or negedge nRST) begin
    automatic logic [15:0] x = H_PixelCount - H_BackPorch;
    automatic logic [15:0] y = V_PixelCount - V_BackPorch;

    if (!nRST) begin
      LCD_R <= 5'b00000;
      LCD_G <= 6'b000000;
      LCD_B <= 5'b00000;
    end else if (LCD_DE) begin
      // draw the digit
      if ((x >= START_X) && (x < START_X + NUMBER_WIDTH) &&
          (y >= START_Y) && (y < START_Y + NUMBER_HEIGHT)) begin
        automatic logic [7:0] digit = Character;
        if (digit >= 0 && digit < 10) begin
          if (font[digit][y-START_Y][8-x+START_X] == 1'b1) begin
            LCD_R <= 5'b00000;  // green
            LCD_G <= 6'b111111;
            LCD_B <= 5'b00000;
          end else begin
            LCD_R <= 5'b00000;  // black
            LCD_G <= 6'b000000;
            LCD_B <= 5'b00000;
          end
        end else begin
          LCD_R <= 5'b11111;  // red (char is not 0, 1, 2)
          LCD_G <= 6'b000000;
          LCD_B <= 5'b00000;
        end
      end else begin
        LCD_R <= 5'b00000;  // black
        LCD_G <= 6'b000000;
        LCD_B <= 5'b00000;
      end
    end else begin
      LCD_R <= 5'b00000;
      LCD_G <= 6'b000000;
      LCD_B <= 5'b00000;
    end
  end

endmodule
