// consts.svh

`ifndef CONSTS_SVH
`define CONSTS_SVH

// RAM
localparam int RAMW = 15'b111_1111_1111_1111;
localparam int VRAMW = 10'b11_1111_1111;
localparam int VRAM_START = 16'hE000;
localparam int SHADOW_VRAM_START = 16'h7C00;
localparam int STACK = 16'h0100; // stack: 0x100-0x1FF, referenced by STACK+sp
localparam int PROGRAM_START = 16'h0200;


// LCD Display Parameters
localparam int CHAR_WIDTH = 8;   // pixels per character
localparam int CHAR_HEIGHT = 16; // pixels per character  
localparam int COLUMNS = 60;     // characters per row (480/8)
localparam int ROWS = 17;        // character rows (272/16)

// LCD Timing Parameters (for 480x272 display)
localparam int H_PixelValid = 480;
localparam int H_BackPorch  = 43;
localparam int H_FrontPorch = 8;   // 4+4 simplified
localparam int PixelForHS   = H_BackPorch + H_PixelValid + H_FrontPorch;

localparam int V_PixelValid = 272;
localparam int V_BackPorch  = 12;
localparam int V_FrontPorch = 8;   // 4+4 simplified  
localparam int PixelForVS   = V_BackPorch + V_PixelValid + V_FrontPorch;

// VSync Period = (8+12) * (480+8+43) = 10620 cycles

// LCD Character Positioning Offsets
// These constants are used in lcd.sv for precise character timing
localparam int CHAR_FETCH_OFFSET_1 = -5;  // VRAM address calculation timing
localparam int CHAR_FETCH_OFFSET_2 = -4;  // Character data fetch timing
localparam int CHAR_FETCH_OFFSET_3 = -3;  // Font address calculation timing
localparam int CHAR_FETCH_OFFSET_4 = -2;  // Font data fetch timing
localparam int CHAR_RENDER_OFFSET = 1;   // Character rendering offset

// LCD Color Definitions (RGB565 format)
localparam logic [4:0] LCD_RED_OFF = 5'b00000;
localparam logic [5:0] LCD_GREEN_OFF = 6'b000000; 
localparam logic [4:0] LCD_BLUE_OFF = 5'b00000;

localparam logic [4:0] LCD_RED_ON = 5'b00000;
localparam logic [5:0] LCD_GREEN_ON = 6'b111111;
localparam logic [4:0] LCD_BLUE_ON = 5'b00000;

localparam logic [4:0] LCD_RED_ERROR = 5'b11111;
localparam logic [5:0] LCD_GREEN_ERROR = 6'b000000;
localparam logic [4:0] LCD_BLUE_ERROR = 5'b00000;

localparam logic [4:0] LCD_RED_BORDER = 5'b11111;
localparam logic [5:0] LCD_GREEN_BORDER = 6'b111111;
localparam logic [4:0] LCD_BLUE_BORDER = 5'b00000;

// Character code limits
localparam int CHAR_CODE_MIN = 0;
localparam int CHAR_CODE_MAX = 127;

`endif
