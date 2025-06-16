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

`endif
