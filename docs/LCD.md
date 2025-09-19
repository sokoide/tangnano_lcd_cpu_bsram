## 043026-N6(ML) LCD spec

### Interface PIN connections

| Pin No. | Symbol | Function                                                     |
| ------- | ------ | ------------------------------------------------------------ |
| 1       | LEDK   | Back light power supply negative                             |
| 2       | LEDA   | Back light power supply positive                             |
| 3       | GND    | Ground                                                       |
| 4       | VCC    | Power supply                                                 |
| 5-12    | R0-R7  | Red Data                                                     |
| 13-20   | G0-G7  | Green Data                                                   |
| 21-28   | B0-B7  | Blue Data                                                    |
| 29      | GND    | Ground                                                       |
| 30      | CLK    | Clock signal                                                 |
| 31      | DISP   | Display on/off                                               |
| 32      | HSYNC  | Horizontal sync input in RGB mode (short to GND if not used) |
| 33      | VSYNC  | Vertical sync input in RGB mode (short to GND if not used)   |
| 34      | DE     | Data enable                                                  |
| 35      | NC     | No Connection                                                |
| 36      | GND    | Ground                                                       |
| 37      | XR     | Touch panel X-right                                          |
| 38      | YD     | Touch panel Y-bottom                                         |
| 39      | XL     | Touch panel X-left                                           |
| 40      | YU     | Touch panel Y-up                                             |

### Parallel RGP Input Timing

| Item           | Symbol | Values (Min.) | Values (Typ.) | Values (Max.) | Unit | Remark |
| -------------- | ------ | ------------- | ------------- | ------------- | ---- | ------ |
| DCLK Frequency | Fclk   | 8             | 9             | 12            | MHz  |        |
| **Hsync**      |        |               |               |               |      |        |
| Period time    | Th     | 485           | 531           | 589           | DCLK |        |
| Display Period | Thdisp | -             | 480-          | -             | DCLK |        |
| Back Porch     | Thbp   | 3             | 43            | 43            | DCLK |        |
| Front Porch    | Thfp   | 2             | 4             | 75            | DCLK |        |
| **Vsync**      |        |               |               |               |      |        |
| Period time    | Tv     | 276           | 292           | 321           | H    |        |
| Display Period | Tvdisp | -             | 272           | -             | H    |        |
| Back Porch     | Tvbp   | 2             | 12            | 12            | H    |        |
| Front Porch    | Tvfp   | 2             | 4             | 37            | H    |        |

### Sync Mode

![sync](./lcd_sync.png)

### Sync DE Mode

![sync DE](./lcd_sync_de.png)

## Example

![lcd](./lcd.jpg)
