// cpu_memory.sv - 6502 Memory Interface and Address Generation
//
// This module handles all memory operations for the 6502 CPU including:
// - Address calculation for all addressing modes
// - Memory read/write control logic
// - VRAM interface for video memory operations
// - Stack pointer management
// - Boot program loading during initialization
//
// Memory Map:
// - 0x0000-0x00FF: Zero Page (256B)
// - 0x0100-0x01FF: Stack (256B)
// - 0x0200-0x7BFF: Program RAM (30.5KB)
// - 0x7C00-0x7FFF: Shadow VRAM (1KB, read-only)
// - 0xE000-0xE3FF: Text VRAM (1KB, write-only)
//
`include "consts.svh"

module cpu_memory (
    input logic clk,
    input logic rst_n,
    
    // Address Mode and Control
    input logic [3:0] addr_mode,        // Addressing mode from decoder
    input logic [15:0] base_addr,       // Base address (PC or operand)
    input logic [7:0] index_x,          // X register for indexed addressing
    input logic [7:0] index_y,          // Y register for indexed addressing
    input logic [7:0] stack_ptr,        // Stack pointer
    input logic is_memory_op,           // Memory operation required
    input logic is_write,               // Write operation (vs read)
    input logic is_vram_write,          // Write to VRAM region
    
    // Memory Data
    input logic [7:0] write_data,       // Data to write to memory
    input logic [7:0] ram_read_data,    // Data read from RAM
    output logic [7:0] memory_data,     // Memory data to CPU
    
    // Memory Interface
    output logic [14:0] ram_write_addr, // RAM write address
    output logic [14:0] ram_read_addr,  // RAM read address
    output logic [7:0] ram_write_data,  // RAM write data
    output logic ram_write_en,          // RAM write enable
    output logic ram_read_en,           // RAM read enable
    
    // VRAM Interface
    output logic [9:0] vram_write_addr, // VRAM write address
    output logic [7:0] vram_write_data, // VRAM write data
    output logic vram_write_en,         // VRAM write enable
    
    // Boot Program Loading
    input logic boot_mode,              // Boot program loading mode
    input logic [7:0] boot_data,        // Boot program data
    input logic [14:0] boot_addr,       // Boot program address
    input logic boot_write_en           // Boot program write enable
);

  // Addressing mode constants (matching cpu_decoder.sv)
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
  localparam ADDR_STACK       = 4'hD;

  // Internal signals
  logic [15:0] effective_addr;         // Calculated effective address
  logic [15:0] indexed_addr;           // Address after index calculation
  logic is_vram_region;                // Address is in VRAM region
  logic is_shadow_vram_region;         // Address is in Shadow VRAM region
  logic is_zero_page;                  // Address is in zero page
  logic page_crossed;                  // Page boundary crossed (for timing)

  // Address calculation combinational logic
  always_comb begin
    // Default values
    effective_addr = base_addr;
    indexed_addr = base_addr;
    page_crossed = 1'b0;
    
    case (addr_mode)
      ADDR_IMPLIED: begin
        effective_addr = 16'h0000;     // No address needed
      end
      
      ADDR_IMMEDIATE: begin
        effective_addr = base_addr;     // Use PC+1 for immediate
      end
      
      ADDR_ZERO_PAGE: begin
        effective_addr = {8'h00, base_addr[7:0]};
      end
      
      ADDR_ZERO_PAGE_X: begin
        indexed_addr = {8'h00, base_addr[7:0]} + {8'h00, index_x};
        effective_addr = {8'h00, indexed_addr[7:0]}; // Wrap in zero page
      end
      
      ADDR_ZERO_PAGE_Y: begin
        indexed_addr = {8'h00, base_addr[7:0]} + {8'h00, index_y};
        effective_addr = {8'h00, indexed_addr[7:0]}; // Wrap in zero page
      end
      
      ADDR_ABSOLUTE: begin
        effective_addr = base_addr;
      end
      
      ADDR_ABSOLUTE_X: begin
        indexed_addr = base_addr + {8'h00, index_x};
        effective_addr = indexed_addr;
        page_crossed = (base_addr[15:8] != indexed_addr[15:8]);
      end
      
      ADDR_ABSOLUTE_Y: begin
        indexed_addr = base_addr + {8'h00, index_y};
        effective_addr = indexed_addr;
        page_crossed = (base_addr[15:8] != indexed_addr[15:8]);
      end
      
      ADDR_INDIRECT_X: begin
        // (base_addr + X), address wraps in zero page
        indexed_addr = {8'h00, (base_addr[7:0] + index_x)};
        effective_addr = indexed_addr;  // Will need indirect lookup
      end
      
      ADDR_INDIRECT_Y: begin
        // (base_addr) + Y, base_addr points to zero page location
        effective_addr = base_addr;     // Will need indirect lookup + Y
      end
      
      ADDR_RELATIVE: begin
        // Sign-extend the relative offset
        effective_addr = base_addr + {{8{base_addr[7]}}, base_addr[7:0]};
      end
      
      ADDR_STACK: begin
        effective_addr = STACK + {8'h00, stack_ptr};
      end
      
      default: begin
        effective_addr = base_addr;
      end
    endcase
  end

  // Memory region detection
  always_comb begin
    is_zero_page = (effective_addr[15:8] == 8'h00);
    is_vram_region = (effective_addr >= VRAM_START) && (effective_addr < (VRAM_START + 16'h0400));
    is_shadow_vram_region = (effective_addr >= SHADOW_VRAM_START) && (effective_addr < (SHADOW_VRAM_START + 16'h0400));
  end

  // Memory interface control
  always_comb begin
    // Default values
    ram_write_addr = 15'h0000;
    ram_read_addr = 15'h0000;
    ram_write_data = write_data;
    ram_write_en = 1'b0;
    ram_read_en = 1'b0;
    vram_write_addr = 10'h000;
    vram_write_data = write_data;
    vram_write_en = 1'b0;
    memory_data = ram_read_data;

    // Boot program loading takes priority
    if (boot_mode && boot_write_en) begin
      ram_write_addr = boot_addr;
      ram_write_data = boot_data;
      ram_write_en = 1'b1;
      ram_read_en = 1'b0;
    end
    // Normal memory operations
    else if (is_memory_op) begin
      if (is_write) begin
        // Write operations
        if (is_vram_region && is_vram_write) begin
          // Write to VRAM
          vram_write_addr = effective_addr[9:0];
          vram_write_data = write_data;
          vram_write_en = 1'b1;
        end else if (!is_vram_region && !is_shadow_vram_region) begin
          // Write to regular RAM (not VRAM or Shadow VRAM)
          ram_write_addr = effective_addr[14:0];
          ram_write_data = write_data;
          ram_write_en = 1'b1;
        end
        // Note: Writes to Shadow VRAM region are ignored (read-only)
      end else begin
        // Read operations
        if (is_shadow_vram_region) begin
          // Read from Shadow VRAM (mapped to VRAM)
          ram_read_addr = effective_addr[14:0];
          ram_read_en = 1'b1;
        end else if (!is_vram_region) begin
          // Read from regular RAM (not VRAM region)
          ram_read_addr = effective_addr[14:0];
          ram_read_en = 1'b1;
        end
        // Note: Reads from VRAM region (0xE000-0xE3FF) return 0 (write-only)
      end
    end
  end

  // Stack operations helper functions
  function automatic logic [15:0] stack_push_addr(input logic [7:0] sp);
    return STACK + {8'h00, sp};
  endfunction

  function automatic logic [15:0] stack_pull_addr(input logic [7:0] sp);
    return STACK + {8'h00, sp + 8'h01};
  endfunction

  // Address validation for debugging
  function automatic logic is_valid_address(input logic [15:0] addr);
    // Check if address is within valid memory ranges
    return ((addr <= 16'h7FFF) ||                           // RAM regions
            (addr >= SHADOW_VRAM_START && addr < SHADOW_VRAM_START + 16'h0400) || // Shadow VRAM
            (addr >= VRAM_START && addr < VRAM_START + 16'h0400));               // VRAM
  endfunction

endmodule