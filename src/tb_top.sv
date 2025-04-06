module tb_top;
  logic clk;
  logic rst_n;

  // 20ns clock (#10 means 10ns) == 50MHz
  always #10 clk = ~clk;

  wire  rst = !rst_n;

  // BSRAM 8KB, address 8192, data width 8
  logic cea, ceb, oce;
  logic reseta, resetb;
  logic [12:0] ada, adb;
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
      .oce(oce),  //input oce, timing when the read value is reflected on dout
      .ada(ada),  //input [12:0] ada, for write
      .din(din),  //input [7:0] din, written data
      .adb(adb)  //input [12:0] adb, for read
  );

  // Bootloader signals
  logic [15:0] boot_addr;
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
      boot_addr  <= 0;
      boot_mode  <= 1;
      boot_write <= 1;
      cea        <= 0;  // disaable write
      reseta     <= 0;
      ada        <= 13'h0;
    end else if (boot_mode) begin
      if (boot_write) begin
        din <= boot_data[boot_addr];
        cea <= 1;  // enable write
        boot_write <= 0;  // Prevent immediate increment in the same cycle
      end else begin
        cea <= 0;  // disable write
        if (boot_addr == BootDataLength) begin
          boot_mode <= 0;  // End boot process after writing all data
        end else begin
          boot_addr  <= (boot_addr + 1) & 11'h7FF;
          boot_write <= 1;  // Enable write for the next address
        end
      end
    end else begin
      cea <= 0;  // write disable
    end
  end

  // Multiplexer for the memory address.
  // assign mem_addr = boot_mode ? boot_addr : cpu_pc;
  assign ada = boot_mode ? boot_addr : boot_addr;

  initial begin
    $display("=== Test Started ===");
    clk   = 0;

    rst_n = 0;  // active
    @(posedge clk);  // wait for 1 clock cycle
    rst_n = 1;  // release

    // repeat(10) @(posedge clk); is same as #200;
    #100;

    $display("=== Test End ===");
    $finish;
  end

endmodule
