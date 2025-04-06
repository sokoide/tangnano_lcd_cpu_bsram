// consts.svh

`ifndef CONSTS_SVH
`define CONSTS_SVH

// VRAM
parameter int VRAM_WIDTH = 480/4;
parameter int VRAM_HEIGHT = 272/4;

// LCD
parameter int H_Pixel_Valid = 16'd480;
parameter int H_FrontPorch  = 16'd4+16'd4;
parameter int H_BackPorch   = 16'd43;
parameter int PixelForHS    = H_Pixel_Valid + H_FrontPorch + H_BackPorch;

parameter int V_Pixel_Valid = 16'd272;
parameter int V_FrontPorch  = 16'd4+16'd4;
parameter int V_BackPorch   = 16'd12;
parameter int PixelForVS    = V_Pixel_Valid + V_FrontPorch + V_BackPorch;

// VSync Period = (4+12) * (480+4+43) = 8432 cycles

`endif