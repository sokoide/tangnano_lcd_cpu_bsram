// consts.svh

`ifndef CONSTS_SVH
`define CONSTS_SVH

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