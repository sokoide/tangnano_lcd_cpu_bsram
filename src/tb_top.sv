module tb_top;
  // for TB
  GSR GSR (.GSRI(1'b1));

  logic clk;
  logic rst_n;

  // 20ns clock (#10 means 10ns) == 50MHz
  always #10 clk = ~clk;

  wire rst = !rst_n;

  // BSRAM 8KB, address 8192, data width 8
  logic cea, ceb, oce;
  logic reseta, resetb;
  logic [14:0] ada, adb;
  logic [7:0] din;
  logic [7:0] dout;


  Gowin_SDPB dut (
      .dout(dout),  //output [7:0] dout, read data
      .clka(clk),  //input clka
      .cea(cea),  //input cea, write enable
      .reseta(rst),  //input reseta
      .clkb(clk),  //input clkb
      .ceb(ceb),  //input ceb, read enable
      .resetb(rst),  //input resetb
      .oce(oce),  //input oce, if 1, dout is udated at the next clock
      .ada(ada),  //input [12:0] ada, for write
      .din(din),  //input [7:0] din, written data
      .adb(adb)  //input [12:0] adb, for read
  );

  // Bootloader signals
  logic [12:0] boot_idx;
  logic        boot_mode;  // 1 during boot, 0 after boot is done
  logic        boot_write;  // Internal signal to control when to write
  logic [ 7:0] boot_data                                               [4];
  localparam int unsigned BootDataLength = $bits(boot_data) / $bits(boot_data[0]);

  initial begin
    boot_data[0] = 8'h06;
    boot_data[1] = 8'h07;
    boot_data[2] = 8'h08;
    boot_data[3] = 8'h09;
  end

  // Boot process management
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      boot_idx   <= 0;
      ada        <= 13'h0200;  // Start address for boot data
      boot_mode  <= 1;
      boot_write <= 1;
      cea        <= 0;  // disaable write
      reseta     <= 0;
    end else if (boot_mode) begin
      if (boot_write) begin
        din <= boot_data[boot_idx];
        cea <= 1;  // enable write
        boot_write <= 0;  // Prevent immediate increment in the same cycle
      end else begin
        cea <= 0;  // disable write
        if (boot_idx == BootDataLength) begin
          boot_mode <= 0;  // End boot process after writing all data
        end else begin
          boot_idx <= (boot_idx + 1) & 13'h1FFF;
          ada <= (ada + 1) & 13'h1FFF;
          boot_write <= 1;  // Enable write for the next address
        end
      end
    end else begin
      cea <= 0;  // write disable
    end
  end

  initial begin
    $display("=== Test Started ===");
    clk   = 0;

    rst_n = 0;  // active
    @(posedge clk);  // wait for 1 clock cycle
    rst_n = 1;  // release

    repeat (10) @(posedge clk);  // same as #200;

    // 0x06, 7, 8, 9 must be written at 0x0200-0x203
    adb = 13'h0200;
    ceb = 1;  // enable read
    oce = 1;  // enable output

    repeat (1) @(posedge clk);
    repeat (1) @(posedge clk);
    if (dout !== 8'h06) begin
      $display("❌ ERROR: Expected 0x06 at 0x%04x, got %02x", adb, dout);
    end else begin
      $display("✅ PASS: 0x%04x contains %02x", adb, dout);
    end

    check_dout(13'h0200, 8'h06);
    check_dout(13'h0201, 8'h07);
    check_dout(13'h0202, 8'h08);
    check_dout(13'h0203, 8'h09);

    $display("=== Test End ===");
    $finish;
  end

  task check_dout(input [12:0] addr, input [7:0] expected);
    begin
      adb = addr;
      ceb = 1;
      oce = 1;

      @(posedge clk);  // reserve
      @(posedge clk);  // update dout

      if (dout !== expected) begin
        $display("❌ ERROR: Addr 0x%04x expected %02x, got %02x", addr, expected, dout);
      end else begin
        $display("✅ PASS:  Addr 0x%04x = %02x", addr, dout);
      end
    end
  endtask
endmodule
