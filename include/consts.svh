// consts.svh

`ifndef CONSTS_SVH
`define CONSTS_SVH

// RAM
localparam int RAMW = 13'b1_1111_1111_1111;
localparam int VRAMW = 10'b11_1111_1111;
localparam int VRAM_START = 16'hE000;
localparam int STACK = 16'h0100; // stack: 0x100-0x1FF, referenced by STACK+sp
localparam int PROGRAM_START = 16'h0200;


// LCD
localparam int COLUMNS = 60;
localparam int ROWS = 17;

localparam int H_PixelValid = 16'd480;
localparam int H_BackPorch   = 16'd43;
localparam int H_FrontPorch  = 16'd4+16'd4;
localparam int PixelForHS    = H_BackPorch + H_PixelValid + H_FrontPorch;

localparam int V_PixelValid = 16'd272;
localparam int V_BackPorch   = 16'd12;
localparam int V_FrontPorch  = 16'd4+16'd4;
localparam int PixelForVS    = V_BackPorch + V_PixelValid + V_FrontPorch;

// VSync Period = (8+12) * (480+8+43) = 10620 cycles

`endif
