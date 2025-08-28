// tb_cpu_modules.sv - Testbench for Individual CPU Modules
//
// This testbench verifies the functionality of the split CPU modules:
// - cpu_decoder: Instruction decoding logic
// - cpu_alu: Arithmetic Logic Unit  
// - cpu_memory: Memory interface and address generation
//
// Each module is tested independently to ensure correct behavior
// before integration into the main CPU core.
//
`include "consts.svh"

module tb_cpu_modules;

  // Common test signals
  logic clk;
  logic rst_n;
  integer test_case;
  integer error_count;
  logic test_passed;

  // Clock generation
  always #10 clk = ~clk;

  //============================================================================
  // CPU Decoder Tests
  //============================================================================
  
  // Decoder test signals
  logic [7:0] opcode;
  logic [1:0] instr_length;
  logic [3:0] addr_mode;
  logic [3:0] alu_op;
  logic is_branch, is_jump, is_memory_op, is_stack_op, is_custom_op;
  logic writes_a, writes_x, writes_y, writes_flags;
  logic [1:0] custom_op_type;

  // Instantiate decoder
  cpu_decoder decoder_dut (
    .opcode(opcode),
    .instr_length(instr_length),
    .addr_mode(addr_mode),
    .alu_op(alu_op),
    .is_branch(is_branch),
    .is_jump(is_jump),
    .is_memory_op(is_memory_op),
    .is_stack_op(is_stack_op),
    .is_custom_op(is_custom_op),
    .writes_a(writes_a),
    .writes_x(writes_x),
    .writes_y(writes_y),
    .writes_flags(writes_flags),
    .custom_op_type(custom_op_type)
  );

  // Decoder test task
  task test_decoder();
    $display("=== CPU Decoder Tests ===");
    
    // Test 1: LDA immediate (0xA9)
    opcode = 8'hA9;
    #1;
    if (instr_length == 2'b10 && writes_a && writes_flags && !is_memory_op) begin
      $display("  PASS: LDA immediate decoding correct");
    end else begin
      $display("  FAIL: LDA immediate decoding incorrect");
      error_count++;
    end

    // Test 2: STA absolute (0x8D)  
    opcode = 8'h8D;
    #1;
    if (instr_length == 2'b11 && is_memory_op && !writes_a) begin
      $display("  PASS: STA absolute decoding correct");
    end else begin
      $display("  FAIL: STA absolute decoding incorrect");
      error_count++;
    end

    // Test 3: JMP absolute (0x4C)
    opcode = 8'h4C;
    #1;
    if (instr_length == 2'b11 && is_jump && !is_branch) begin
      $display("  PASS: JMP absolute decoding correct");
    end else begin
      $display("  FAIL: JMP absolute decoding incorrect");  
      error_count++;
    end

    // Test 4: BEQ relative (0xF0)
    opcode = 8'hF0;
    #1;
    if (instr_length == 2'b10 && is_branch && !is_jump) begin
      $display("  PASS: BEQ relative decoding correct");
    end else begin
      $display("  FAIL: BEQ relative decoding incorrect");
      error_count++;
    end

    // Test 5: Custom instruction CVR (0xCF)
    opcode = 8'hCF;
    #1;
    if (is_custom_op && custom_op_type == 2'b00 && instr_length == 2'b01) begin
      $display("  PASS: CVR custom instruction decoding correct");
    end else begin
      $display("  FAIL: CVR custom instruction decoding incorrect");
      error_count++;
    end

    // Test 6: Custom instruction WVS (0xFF)
    opcode = 8'hFF;
    #1;
    if (is_custom_op && custom_op_type == 2'b11 && instr_length == 2'b10) begin
      $display("  PASS: WVS custom instruction decoding correct");
    end else begin
      $display("  FAIL: WVS custom instruction decoding incorrect");
      error_count++;
    end

    $display("  Decoder tests completed");
  endtask

  //============================================================================
  // CPU ALU Tests
  //============================================================================

  // ALU test signals
  logic [3:0] alu_op_test;
  logic [7:0] operand_a, operand_b;
  logic carry_in;
  logic [7:0] result;
  logic carry_out, zero_flag, negative_flag, overflow_flag;

  // Instantiate ALU
  cpu_alu alu_dut (
    .alu_op(alu_op_test),
    .operand_a(operand_a),
    .operand_b(operand_b),
    .carry_in(carry_in),
    .result(result),
    .carry_out(carry_out),
    .zero_flag(zero_flag),
    .negative_flag(negative_flag),
    .overflow_flag(overflow_flag)
  );

  // ALU test task
  task test_alu();
    $display("=== CPU ALU Tests ===");
    
    // Test 1: ADC operation
    alu_op_test = 4'h1; // ALU_ADC
    operand_a = 8'h50;
    operand_b = 8'h30;
    carry_in = 1'b0;
    #1;
    if (result == 8'h80 && !carry_out && negative_flag && !zero_flag) begin
      $display("  PASS: ADC operation correct (0x50 + 0x30 = 0x80)");
    end else begin
      $display("  FAIL: ADC operation incorrect, got 0x%02X, carry=%b, flags: Z=%b N=%b", 
               result, carry_out, zero_flag, negative_flag);
      error_count++;
    end

    // Test 2: ADC with carry and overflow
    operand_a = 8'h7F;
    operand_b = 8'h01;
    carry_in = 1'b0;
    #1;
    if (result == 8'h80 && overflow_flag && negative_flag) begin
      $display("  PASS: ADC overflow detection correct (0x7F + 0x01 = 0x80, V=1)");
    end else begin
      $display("  FAIL: ADC overflow detection incorrect, V=%b", overflow_flag);
      error_count++;
    end

    // Test 3: SBC operation
    alu_op_test = 4'h2; // ALU_SBC
    operand_a = 8'h80;
    operand_b = 8'h01;
    carry_in = 1'b1; // No borrow
    #1;
    if (result == 8'h7F && carry_out && !negative_flag) begin
      $display("  PASS: SBC operation correct (0x80 - 0x01 = 0x7F)");
    end else begin
      $display("  FAIL: SBC operation incorrect, got 0x%02X, carry=%b", result, carry_out);
      error_count++;
    end

    // Test 4: AND operation
    alu_op_test = 4'h3; // ALU_AND
    operand_a = 8'hF0;
    operand_b = 8'h0F;
    #1;
    if (result == 8'h00 && zero_flag && !negative_flag) begin
      $display("  PASS: AND operation correct (0xF0 & 0x0F = 0x00, Z=1)");
    end else begin
      $display("  FAIL: AND operation incorrect, got 0x%02X, Z=%b", result, zero_flag);
      error_count++;
    end

    // Test 5: ASL operation
    alu_op_test = 4'h7; // ALU_ASL
    operand_a = 8'hC0;
    #1;
    if (result == 8'h80 && carry_out && negative_flag) begin
      $display("  PASS: ASL operation correct (0xC0 << 1 = 0x80, C=1)");
    end else begin
      $display("  FAIL: ASL operation incorrect, got 0x%02X, C=%b", result, carry_out);
      error_count++;
    end

    // Test 6: CMP operation
    alu_op_test = 4'h6; // ALU_CMP
    operand_a = 8'h50;
    operand_b = 8'h30;
    #1;
    if (result == 8'h50 && carry_out && !zero_flag) begin // A >= B, so carry set
      $display("  PASS: CMP operation correct (0x50 vs 0x30, C=1)");
    end else begin
      $display("  FAIL: CMP operation incorrect, result=0x%02X, C=%b, Z=%b", 
               result, carry_out, zero_flag);
      error_count++;
    end

    $display("  ALU tests completed");
  endtask

  //============================================================================
  // CPU Memory Tests  
  //============================================================================

  // Memory test signals
  logic [3:0] addr_mode_test;
  logic [15:0] base_addr;
  logic [7:0] index_x, index_y, stack_ptr;
  logic is_memory_op_test, is_write, is_vram_write;
  logic [7:0] write_data, ram_read_data, memory_data;
  logic [14:0] ram_write_addr, ram_read_addr;
  logic [7:0] ram_write_data;
  logic ram_write_en, ram_read_en;
  logic [9:0] vram_write_addr;
  logic [7:0] vram_write_data;
  logic vram_write_en;
  logic boot_mode, boot_write_en;
  logic [7:0] boot_data;
  logic [14:0] boot_addr;

  // Instantiate memory interface
  cpu_memory memory_dut (
    .clk(clk),
    .rst_n(rst_n),
    .addr_mode(addr_mode_test),
    .base_addr(base_addr),
    .index_x(index_x),
    .index_y(index_y),
    .stack_ptr(stack_ptr),
    .is_memory_op(is_memory_op_test),
    .is_write(is_write),
    .is_vram_write(is_vram_write),
    .write_data(write_data),
    .ram_read_data(ram_read_data),
    .memory_data(memory_data),
    .ram_write_addr(ram_write_addr),
    .ram_read_addr(ram_read_addr),
    .ram_write_data(ram_write_data),
    .ram_write_en(ram_write_en),
    .ram_read_en(ram_read_en),
    .vram_write_addr(vram_write_addr),
    .vram_write_data(vram_write_data),
    .vram_write_en(vram_write_en),
    .boot_mode(boot_mode),
    .boot_data(boot_data),
    .boot_addr(boot_addr),
    .boot_write_en(boot_write_en)
  );

  // Memory test task
  task test_memory();
    $display("=== CPU Memory Interface Tests ===");
    
    // Initialize
    boot_mode = 1'b0;
    boot_write_en = 1'b0;
    ram_read_data = 8'h00;
    
    // Test 1: Zero page addressing
    addr_mode_test = 4'h2; // ADDR_ZERO_PAGE
    base_addr = 16'h0080;
    index_x = 8'h00;
    is_memory_op_test = 1'b1;
    is_write = 1'b0;
    is_vram_write = 1'b0;
    #1;
    if (ram_read_addr[15:8] == 8'h00 && ram_read_addr[7:0] == 8'h80 && ram_read_en) begin
      $display("  PASS: Zero page addressing correct (0x0080)");
    end else begin
      $display("  FAIL: Zero page addressing incorrect, addr=0x%04X", ram_read_addr);
      error_count++;
    end

    // Test 2: Absolute addressing with X index
    addr_mode_test = 4'h6; // ADDR_ABSOLUTE_X
    base_addr = 16'h3000;
    index_x = 8'h10;
    #1;
    if (ram_read_addr == 16'h3010 && ram_read_en) begin
      $display("  PASS: Absolute,X addressing correct (0x3000 + 0x10 = 0x3010)");
    end else begin
      $display("  FAIL: Absolute,X addressing incorrect, addr=0x%04X", ram_read_addr);
      error_count++;
    end

    // Test 3: VRAM write operation
    addr_mode_test = 4'h5; // ADDR_ABSOLUTE
    base_addr = VRAM_START + 16'h0100; // VRAM region
    is_write = 1'b1;
    is_vram_write = 1'b1;
    write_data = 8'h41; // 'A'
    #1;
    if (vram_write_addr == 10'h100 && vram_write_data == 8'h41 && vram_write_en) begin
      $display("  PASS: VRAM write operation correct (addr=0x100, data='A')");
    end else begin
      $display("  FAIL: VRAM write operation incorrect, addr=0x%03X, data=0x%02X, en=%b", 
               vram_write_addr, vram_write_data, vram_write_en);
      error_count++;
    end

    // Test 4: Boot program loading
    boot_mode = 1'b1;
    boot_addr = 15'h0200;
    boot_data = 8'hA9; // LDA immediate opcode
    boot_write_en = 1'b1;
    is_memory_op_test = 1'b0; // Boot takes priority
    #1;
    if (ram_write_addr == 15'h0200 && ram_write_data == 8'hA9 && ram_write_en) begin
      $display("  PASS: Boot program loading correct");
    end else begin
      $display("  FAIL: Boot program loading incorrect");
      error_count++;
    end

    $display("  Memory interface tests completed");
  endtask

  //============================================================================
  // Main Test Sequence
  //============================================================================

  initial begin
    $display("=== CPU Modules Test Suite ===");
    $display("Testing individual CPU modules before integration");
    
    // Initialize
    clk = 0;
    rst_n = 0;
    test_case = 0;
    error_count = 0;
    
    // Reset
    @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // Run tests
    test_decoder();
    test_alu();
    test_memory();

    // Results
    $display("=== Module Test Results ===");
    $display("Total errors: %0d", error_count);
    
    if (error_count == 0) begin
      $display("*** ALL MODULE TESTS PASSED ***");
    end else begin
      $display("*** %0d MODULE TESTS FAILED ***", error_count);
    end
    
    $finish;
  end

  // Timeout
  initial begin
    #100000; // 100us timeout
    $display("ERROR: Module test timeout");
    $finish;
  end

endmodule