// cpu_decoder.sv - 6502 Instruction Decoder
//
// This module handles instruction decoding for the 6502 CPU core.
// It determines instruction types, addressing modes, and execution parameters
// based on the 8-bit opcode input.
//
// Functionality:
// - Decodes all standard 6502 instructions plus custom extensions
// - Determines addressing modes (immediate, zero page, absolute, etc.)
// - Identifies instruction length (1-3 bytes)
// - Provides ALU operation codes and control signals
// - Handles custom instructions: CVR, IFO, HLT, WVS
//
`include "consts.svh"

module cpu_decoder (
    input logic [7:0] opcode,           // Instruction opcode to decode
    
    // Instruction Properties
    output logic [1:0] instr_length,    // Instruction length: 1, 2, or 3 bytes
    output logic [3:0] addr_mode,       // Addressing mode encoding
    output logic [3:0] alu_op,          // ALU operation code
    
    // Control Signals
    output logic is_branch,             // Instruction is a branch
    output logic is_jump,               // Instruction is a jump (JMP/JSR)
    output logic is_memory_op,          // Instruction accesses memory
    output logic is_stack_op,           // Instruction uses stack
    output logic is_custom_op,          // Custom instruction (CVR/IFO/HLT/WVS)
    
    // Register Operations
    output logic writes_a,              // Instruction writes to A register
    output logic writes_x,              // Instruction writes to X register  
    output logic writes_y,              // Instruction writes to Y register
    output logic writes_flags,          // Instruction modifies flags
    
    // Custom Instruction Details
    output logic [1:0] custom_op_type   // 0=CVR, 1=IFO, 2=HLT, 3=WVS
);

  // Addressing mode encodings
  localparam ADDR_IMPLIED     = 4'h0;
  localparam ADDR_IMMEDIATE   = 4'h1;
  localparam ADDR_ZERO_PAGE   = 4'h2;
  localparam ADDR_ZERO_PAGE_X = 4'h3;
  localparam ADDR_ZERO_PAGE_Y = 4'h4;
  localparam ADDR_ABSOLUTE    = 4'h5;
  localparam ADDR_ABSOLUTE_X  = 4'h6;
  localparam ADDR_ABSOLUTE_Y  = 4'h7;
  localparam ADDR_INDIRECT    = 4'h8;
  localparam ADDR_INDIRECT_X  = 4'h9;
  localparam ADDR_INDIRECT_Y  = 4'hA;
  localparam ADDR_RELATIVE    = 4'hB;
  localparam ADDR_ACCUMULATOR = 4'hC;

  // ALU operation encodings
  localparam ALU_NOP = 4'h0;
  localparam ALU_ADC = 4'h1;
  localparam ALU_SBC = 4'h2;
  localparam ALU_AND = 4'h3;
  localparam ALU_ORA = 4'h4;
  localparam ALU_EOR = 4'h5;
  localparam ALU_CMP = 4'h6;
  localparam ALU_ASL = 4'h7;
  localparam ALU_LSR = 4'h8;
  localparam ALU_ROL = 4'h9;
  localparam ALU_ROR = 4'hA;

  // Instruction decoding combinational logic
  always_comb begin
    // Default values
    instr_length = 2'b01;        // Default to 1 byte
    addr_mode = ADDR_IMPLIED;
    alu_op = ALU_NOP;
    is_branch = 1'b0;
    is_jump = 1'b0;
    is_memory_op = 1'b0;
    is_stack_op = 1'b0;
    is_custom_op = 1'b0;
    writes_a = 1'b0;
    writes_x = 1'b0;
    writes_y = 1'b0;
    writes_flags = 1'b0;
    custom_op_type = 2'b00;

    case (opcode)
      // Custom Instructions
      8'hCF: begin // CVR - Clear VRAM
        is_custom_op = 1'b1;
        custom_op_type = 2'b00;
        instr_length = 2'b01;    // 1 byte
      end
      
      8'hDF: begin // IFO - Info/Debug
        is_custom_op = 1'b1;
        custom_op_type = 2'b01;
        instr_length = 2'b11;    // 3 bytes (address operand)
        addr_mode = ADDR_ABSOLUTE;
      end
      
      8'hEF: begin // HLT - Halt
        is_custom_op = 1'b1;
        custom_op_type = 2'b10;
        instr_length = 2'b01;    // 1 byte
      end
      
      8'hFF: begin // WVS - Wait VSync
        is_custom_op = 1'b1;
        custom_op_type = 2'b11;
        instr_length = 2'b10;    // 2 bytes (count operand)
        addr_mode = ADDR_IMMEDIATE;
      end

      // Branch Instructions
      8'h10: begin // BPL
        is_branch = 1'b1;
        addr_mode = ADDR_RELATIVE;
        instr_length = 2'b10;    // 2 bytes
      end
      8'h30: begin // BMI
        is_branch = 1'b1;
        addr_mode = ADDR_RELATIVE;
        instr_length = 2'b10;
      end
      8'h50: begin // BVC
        is_branch = 1'b1;
        addr_mode = ADDR_RELATIVE;
        instr_length = 2'b10;
      end
      8'h70: begin // BVS
        is_branch = 1'b1;
        addr_mode = ADDR_RELATIVE;
        instr_length = 2'b10;
      end
      8'h90: begin // BCC
        is_branch = 1'b1;
        addr_mode = ADDR_RELATIVE;
        instr_length = 2'b10;
      end
      8'hB0: begin // BCS
        is_branch = 1'b1;
        addr_mode = ADDR_RELATIVE;
        instr_length = 2'b10;
      end
      8'hD0: begin // BNE
        is_branch = 1'b1;
        addr_mode = ADDR_RELATIVE;
        instr_length = 2'b10;
      end
      8'hF0: begin // BEQ
        is_branch = 1'b1;
        addr_mode = ADDR_RELATIVE;
        instr_length = 2'b10;
      end

      // Jump Instructions  
      8'h4C: begin // JMP absolute
        is_jump = 1'b1;
        addr_mode = ADDR_ABSOLUTE;
        instr_length = 2'b11;    // 3 bytes
      end
      8'h6C: begin // JMP indirect
        is_jump = 1'b1;
        addr_mode = ADDR_INDIRECT;
        instr_length = 2'b11;
      end
      8'h20: begin // JSR
        is_jump = 1'b1;
        is_stack_op = 1'b1;
        addr_mode = ADDR_ABSOLUTE;
        instr_length = 2'b11;
      end
      8'h60: begin // RTS
        is_jump = 1'b1;
        is_stack_op = 1'b1;
        instr_length = 2'b01;    // 1 byte
      end

      // Load/Store A Register
      8'hA9: begin // LDA immediate
        writes_a = 1'b1;
        writes_flags = 1'b1;
        addr_mode = ADDR_IMMEDIATE;
        instr_length = 2'b10;    // 2 bytes
      end
      8'hA5: begin // LDA zero page
        writes_a = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        addr_mode = ADDR_ZERO_PAGE;
        instr_length = 2'b10;
      end
      8'hB5: begin // LDA zero page,X
        writes_a = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        addr_mode = ADDR_ZERO_PAGE_X;
        instr_length = 2'b10;
      end
      8'hAD: begin // LDA absolute
        writes_a = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        addr_mode = ADDR_ABSOLUTE;
        instr_length = 2'b11;
      end
      8'hBD: begin // LDA absolute,X
        writes_a = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        addr_mode = ADDR_ABSOLUTE_X;
        instr_length = 2'b11;
      end
      8'hB9: begin // LDA absolute,Y
        writes_a = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        addr_mode = ADDR_ABSOLUTE_Y;
        instr_length = 2'b11;
      end
      8'hA1: begin // LDA (zero page,X)
        writes_a = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        addr_mode = ADDR_INDIRECT_X;
        instr_length = 2'b10;
      end
      8'hB1: begin // LDA (zero page),Y
        writes_a = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        addr_mode = ADDR_INDIRECT_Y;
        instr_length = 2'b10;
      end

      // Store A Register
      8'h85: begin // STA zero page
        is_memory_op = 1'b1;
        addr_mode = ADDR_ZERO_PAGE;
        instr_length = 2'b10;
      end
      8'h95: begin // STA zero page,X
        is_memory_op = 1'b1;
        addr_mode = ADDR_ZERO_PAGE_X;
        instr_length = 2'b10;
      end
      8'h8D: begin // STA absolute
        is_memory_op = 1'b1;
        addr_mode = ADDR_ABSOLUTE;
        instr_length = 2'b11;
      end
      8'h9D: begin // STA absolute,X
        is_memory_op = 1'b1;
        addr_mode = ADDR_ABSOLUTE_X;
        instr_length = 2'b11;
      end
      8'h99: begin // STA absolute,Y
        is_memory_op = 1'b1;
        addr_mode = ADDR_ABSOLUTE_Y;
        instr_length = 2'b11;
      end
      8'h81: begin // STA (zero page,X)
        is_memory_op = 1'b1;
        addr_mode = ADDR_INDIRECT_X;
        instr_length = 2'b10;
      end
      8'h91: begin // STA (zero page),Y
        is_memory_op = 1'b1;
        addr_mode = ADDR_INDIRECT_Y;
        instr_length = 2'b10;
      end

      // Load/Store X Register
      8'hA2: begin // LDX immediate
        writes_x = 1'b1;
        writes_flags = 1'b1;
        addr_mode = ADDR_IMMEDIATE;
        instr_length = 2'b10;
      end
      8'hA6: begin // LDX zero page
        writes_x = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        addr_mode = ADDR_ZERO_PAGE;
        instr_length = 2'b10;
      end
      8'hB6: begin // LDX zero page,Y
        writes_x = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        addr_mode = ADDR_ZERO_PAGE_Y;
        instr_length = 2'b10;
      end
      8'hAE: begin // LDX absolute
        writes_x = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        addr_mode = ADDR_ABSOLUTE;
        instr_length = 2'b11;
      end
      8'hBE: begin // LDX absolute,Y
        writes_x = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        addr_mode = ADDR_ABSOLUTE_Y;
        instr_length = 2'b11;
      end

      8'h86: begin // STX zero page
        is_memory_op = 1'b1;
        addr_mode = ADDR_ZERO_PAGE;
        instr_length = 2'b10;
      end
      8'h96: begin // STX zero page,Y
        is_memory_op = 1'b1;
        addr_mode = ADDR_ZERO_PAGE_Y;
        instr_length = 2'b10;
      end
      8'h8E: begin // STX absolute
        is_memory_op = 1'b1;
        addr_mode = ADDR_ABSOLUTE;
        instr_length = 2'b11;
      end

      // Load/Store Y Register
      8'hA0: begin // LDY immediate
        writes_y = 1'b1;
        writes_flags = 1'b1;
        addr_mode = ADDR_IMMEDIATE;
        instr_length = 2'b10;
      end
      8'hA4: begin // LDY zero page
        writes_y = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        addr_mode = ADDR_ZERO_PAGE;
        instr_length = 2'b10;
      end
      8'hB4: begin // LDY zero page,X
        writes_y = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        addr_mode = ADDR_ZERO_PAGE_X;
        instr_length = 2'b10;
      end
      8'hAC: begin // LDY absolute
        writes_y = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        addr_mode = ADDR_ABSOLUTE;
        instr_length = 2'b11;
      end
      8'hBC: begin // LDY absolute,X
        writes_y = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        addr_mode = ADDR_ABSOLUTE_X;
        instr_length = 2'b11;
      end

      8'h84: begin // STY zero page
        is_memory_op = 1'b1;
        addr_mode = ADDR_ZERO_PAGE;
        instr_length = 2'b10;
      end
      8'h94: begin // STY zero page,X
        is_memory_op = 1'b1;
        addr_mode = ADDR_ZERO_PAGE_X;
        instr_length = 2'b10;
      end
      8'h8C: begin // STY absolute
        is_memory_op = 1'b1;
        addr_mode = ADDR_ABSOLUTE;
        instr_length = 2'b11;
      end

      // Arithmetic - ADC
      8'h69: begin // ADC immediate
        writes_a = 1'b1;
        writes_flags = 1'b1;
        alu_op = ALU_ADC;
        addr_mode = ADDR_IMMEDIATE;
        instr_length = 2'b10;
      end
      8'h65: begin // ADC zero page
        writes_a = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        alu_op = ALU_ADC;
        addr_mode = ADDR_ZERO_PAGE;
        instr_length = 2'b10;
      end
      8'h75: begin // ADC zero page,X
        writes_a = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        alu_op = ALU_ADC;
        addr_mode = ADDR_ZERO_PAGE_X;
        instr_length = 2'b10;
      end
      8'h6D: begin // ADC absolute
        writes_a = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        alu_op = ALU_ADC;
        addr_mode = ADDR_ABSOLUTE;
        instr_length = 2'b11;
      end
      8'h7D: begin // ADC absolute,X
        writes_a = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        alu_op = ALU_ADC;
        addr_mode = ADDR_ABSOLUTE_X;
        instr_length = 2'b11;
      end
      8'h79: begin // ADC absolute,Y
        writes_a = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        alu_op = ALU_ADC;
        addr_mode = ADDR_ABSOLUTE_Y;
        instr_length = 2'b11;
      end
      8'h61: begin // ADC (zero page,X)
        writes_a = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        alu_op = ALU_ADC;
        addr_mode = ADDR_INDIRECT_X;
        instr_length = 2'b10;
      end
      8'h71: begin // ADC (zero page),Y
        writes_a = 1'b1;
        writes_flags = 1'b1;
        is_memory_op = 1'b1;
        alu_op = ALU_ADC;
        addr_mode = ADDR_INDIRECT_Y;
        instr_length = 2'b10;
      end

      // Register Transfer Instructions
      8'hAA: begin // TAX
        writes_x = 1'b1;
        writes_flags = 1'b1;
        instr_length = 2'b01;
      end
      8'h8A: begin // TXA
        writes_a = 1'b1;
        writes_flags = 1'b1;
        instr_length = 2'b01;
      end
      8'hA8: begin // TAY
        writes_y = 1'b1;
        writes_flags = 1'b1;
        instr_length = 2'b01;
      end
      8'h98: begin // TYA
        writes_a = 1'b1;
        writes_flags = 1'b1;
        instr_length = 2'b01;
      end
      8'hBA: begin // TSX
        writes_x = 1'b1;
        writes_flags = 1'b1;
        instr_length = 2'b01;
      end
      8'h9A: begin // TXS
        instr_length = 2'b01;
      end

      // Stack Instructions
      8'h48: begin // PHA
        is_stack_op = 1'b1;
        instr_length = 2'b01;
      end
      8'h68: begin // PLA
        writes_a = 1'b1;
        writes_flags = 1'b1;
        is_stack_op = 1'b1;
        instr_length = 2'b01;
      end
      8'h08: begin // PHP
        is_stack_op = 1'b1;
        instr_length = 2'b01;
      end
      8'h28: begin // PLP
        writes_flags = 1'b1;
        is_stack_op = 1'b1;
        instr_length = 2'b01;
      end

      // Increment/Decrement
      8'hE8: begin // INX
        writes_x = 1'b1;
        writes_flags = 1'b1;
        instr_length = 2'b01;
      end
      8'hCA: begin // DEX
        writes_x = 1'b1;
        writes_flags = 1'b1;
        instr_length = 2'b01;
      end
      8'hC8: begin // INY
        writes_y = 1'b1;
        writes_flags = 1'b1;
        instr_length = 2'b01;
      end
      8'h88: begin // DEY
        writes_y = 1'b1;
        writes_flags = 1'b1;
        instr_length = 2'b01;
      end

      // Flag Instructions
      8'h18: begin // CLC
        writes_flags = 1'b1;
        instr_length = 2'b01;
      end
      8'h38: begin // SEC
        writes_flags = 1'b1;
        instr_length = 2'b01;
      end
      8'hB8: begin // CLV
        writes_flags = 1'b1;
        instr_length = 2'b01;
      end

      // NOP
      8'hEA: begin // NOP
        instr_length = 2'b01;
      end

      // Default case for unimplemented instructions
      default: begin
        // Keep default values
      end
    endcase
  end

endmodule