module top (
    input  logic         Reset_Button,
    input  logic         XTAL_IN,

    output logic         LCD_CLK,
    output logic         LCD_DEN,
    output logic [4:0]   LCD_R,
    output logic [5:0]   LCD_G,
    output logic [4:0]   LCD_B
);
    // Tang Nano 9K:
    logic rst_n = Reset_Button;
    // Tang Nano 20K:
    // logic rst_n = !Reset_Button;

    // PLL ... make it by IP Generator -> Hard Module -> Clock -> rPLL -> clockin 27, clockout 9
    // (480+43+8) * (272+8+12) * 60Hz = 9.3MHz
    // 9MHz / (480+43+8) / (272+8+12) = 58.05Hz
    // 10MHz / (480+43+8) / (272+8+12) = 64.5Hz
    Gowin_rPLL rpll_inst (
        .clkout (LCD_CLK), //  9MHz
        .clkin  (XTAL_IN)  //  27MHz
    );

    // LCD
    logic [7:0] char = 8'd7;

    lcd lcd_inst (
        .PixelClk  (LCD_CLK),
        .nRST      (rst_n),
        .Character (char),

        .LCD_DE    (LCD_DEN),
        .LCD_B     (LCD_B),
        .LCD_G     (LCD_G),
        .LCD_R     (LCD_R)
    );
endmodule
