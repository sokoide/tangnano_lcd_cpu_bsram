// consts.svh

`ifndef CONSTS_SVH
`define CONSTS_SVH

// LCD
parameter int H_PixelValid = 16'd480;
parameter int H_BackPorch   = 16'd43;
parameter int H_FrontPorch  = 16'd4+16'd4;
parameter int PixelForHS    = H_BackPorch + H_PixelValid + H_FrontPorch;

parameter int V_PixelValid = 16'd272;
parameter int V_BackPorch   = 16'd12;
parameter int V_FrontPorch  = 16'd4+16'd4;
parameter int PixelForVS    = V_BackPorch + V_PixelValid + V_FrontPorch;

// VSync Period = (8+12) * (480+8+43) = 10620 cycles

`endif