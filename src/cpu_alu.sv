// cpu_alu.sv - 6502 Arithmetic Logic Unit
//
// This module implements the arithmetic and logic operations for the 6502 CPU.
// It handles all mathematical operations, comparisons, shifts, and rotates
// while maintaining proper flag calculations.
//
// Operations Supported:
// - Arithmetic: ADC (add with carry), SBC (subtract with carry)
// - Logic: AND, ORA (OR), EOR (exclusive OR)
// - Comparison: CMP, CPX, CPY
// - Shifts: ASL (arithmetic shift left), LSR (logical shift right)
// - Rotates: ROL (rotate left), ROR (rotate right)
// - Increment/Decrement: INC, DEC
// - Flag operations: bit tests and conditional operations
//
`include "consts.svh"

module cpu_alu (
    // Inputs
    input logic [3:0] alu_op,           // ALU operation code
    input logic [7:0] operand_a,        // First operand (usually A register)
    input logic [7:0] operand_b,        // Second operand (memory/immediate)
    input logic carry_in,               // Input carry flag
    
    // Outputs  
    output logic [7:0] result,          // ALU result
    output logic carry_out,             // Output carry flag
    output logic zero_flag,             // Zero flag (result == 0)
    output logic negative_flag,         // Negative flag (bit 7 of result)
    output logic overflow_flag          // Overflow flag (signed arithmetic)
);

  // ALU operation codes (matching cpu_decoder.sv)
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
  localparam ALU_INC = 4'hB;
  localparam ALU_DEC = 4'hC;
  localparam ALU_BIT = 4'hD;

  // Intermediate calculation signals
  logic [8:0] add_result;              // 9-bit for carry detection
  logic [8:0] sub_result;              // 9-bit for borrow detection
  logic [7:0] logic_result;
  logic [7:0] shift_result;
  logic shift_carry;
  
  // Overflow detection for signed arithmetic
  logic add_overflow, sub_overflow;

  // Combinational ALU logic
  always_comb begin
    // Default values
    result = operand_a;
    carry_out = carry_in;
    zero_flag = 1'b0;
    negative_flag = 1'b0; 
    overflow_flag = 1'b0;
    
    // Intermediate calculations
    add_result = {1'b0, operand_a} + {1'b0, operand_b} + {8'h00, carry_in};
    sub_result = {1'b0, operand_a} - {1'b0, operand_b} - {8'h00, ~carry_in};
    
    // Overflow detection for signed arithmetic
    add_overflow = (~operand_a[7] & ~operand_b[7] & add_result[7]) |
                   (operand_a[7] & operand_b[7] & ~add_result[7]);
    sub_overflow = (~operand_a[7] & operand_b[7] & sub_result[7]) |
                   (operand_a[7] & ~operand_b[7] & ~sub_result[7]);

    case (alu_op)
      ALU_ADC: begin // Add with Carry
        result = add_result[7:0];
        carry_out = add_result[8];
        overflow_flag = add_overflow;
        zero_flag = (add_result[7:0] == 8'h00);
        negative_flag = add_result[7];
      end

      ALU_SBC: begin // Subtract with Carry (Borrow)
        result = sub_result[7:0];
        carry_out = ~sub_result[8];    // Inverted for 6502 SBC semantics
        overflow_flag = sub_overflow;
        zero_flag = (sub_result[7:0] == 8'h00);
        negative_flag = sub_result[7];
      end

      ALU_AND: begin // Logical AND
        logic_result = operand_a & operand_b;
        result = logic_result;
        zero_flag = (logic_result == 8'h00);
        negative_flag = logic_result[7];
        // Carry unchanged for logical operations
      end

      ALU_ORA: begin // Logical OR
        logic_result = operand_a | operand_b;
        result = logic_result;
        zero_flag = (logic_result == 8'h00);
        negative_flag = logic_result[7];
      end

      ALU_EOR: begin // Exclusive OR
        logic_result = operand_a ^ operand_b;
        result = logic_result;
        zero_flag = (logic_result == 8'h00);
        negative_flag = logic_result[7];
      end

      ALU_CMP: begin // Compare (A - operand)
        result = operand_a;           // CMP doesn't change A register
        carry_out = (operand_a >= operand_b);
        zero_flag = (operand_a == operand_b);
        negative_flag = sub_result[7];
      end

      ALU_ASL: begin // Arithmetic Shift Left
        shift_result = {operand_a[6:0], 1'b0};
        shift_carry = operand_a[7];
        result = shift_result;
        carry_out = shift_carry;
        zero_flag = (shift_result == 8'h00);
        negative_flag = shift_result[7];
      end

      ALU_LSR: begin // Logical Shift Right
        shift_result = {1'b0, operand_a[7:1]};
        shift_carry = operand_a[0];
        result = shift_result;
        carry_out = shift_carry;
        zero_flag = (shift_result == 8'h00);
        negative_flag = shift_result[7];    // Always 0 after LSR
      end

      ALU_ROL: begin // Rotate Left through Carry
        shift_result = {operand_a[6:0], carry_in};
        shift_carry = operand_a[7];
        result = shift_result;
        carry_out = shift_carry;
        zero_flag = (shift_result == 8'h00);
        negative_flag = shift_result[7];
      end

      ALU_ROR: begin // Rotate Right through Carry
        shift_result = {carry_in, operand_a[7:1]};
        shift_carry = operand_a[0];
        result = shift_result;
        carry_out = shift_carry;
        zero_flag = (shift_result == 8'h00);
        negative_flag = shift_result[7];
      end

      ALU_INC: begin // Increment
        result = operand_a + 8'h01;
        zero_flag = (result == 8'h00);
        negative_flag = result[7];
        // Carry flag unchanged for INC/DEC
      end

      ALU_DEC: begin // Decrement
        result = operand_a - 8'h01;
        zero_flag = (result == 8'h00);
        negative_flag = result[7];
      end

      ALU_BIT: begin // Bit Test (BIT instruction)
        logic_result = operand_a & operand_b;
        result = operand_a;           // BIT doesn't change A register
        zero_flag = (logic_result == 8'h00);
        negative_flag = operand_b[7]; // N flag = bit 7 of memory
        overflow_flag = operand_b[6]; // V flag = bit 6 of memory
      end

      ALU_NOP: begin // No Operation
        result = operand_a;
        // All flags unchanged
        zero_flag = (operand_a == 8'h00);
        negative_flag = operand_a[7];
      end

      default: begin // Default case
        result = operand_a;
        zero_flag = (operand_a == 8'h00);
        negative_flag = operand_a[7];
      end
    endcase
  end

endmodule