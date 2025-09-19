package cpu_pkg;

  typedef enum logic [3:0] {
    INIT,
    INIT_VRAM,
    INIT_RAM,
    HALT,
    FETCH_REQ,
    FETCH_WAIT,
    FETCH_RECV,
    DECODE_EXECUTE,
    WRITE_REQ,
    SHOW_INFO,
    SHOW_INFO2,
    CLEAR_VRAM,
    CLEAR_VRAM2
  } cpu_state_e;

  typedef enum logic [2:0] {
    FETCH_OPCODE,
    FETCH_DATA,
    FETCH_OPERAND1,
    FETCH_OPERAND1OF2,
    FETCH_OPERAND2
  } fetch_stage_e;

  typedef enum logic [1:0] {
    SHOW_INFO_FETCH,
    SHOW_INFO_EXECUTE
  } show_info_stage_e;

  typedef struct packed {
    logic [9:0] v_ada;
    logic [3:0] v_din_t;
    logic [7:0] v_din;
    logic [7:0] diff;
    logic vram_write;
    logic mem_read;
  } show_info_cmd_t;

  function automatic logic [7:0] to_hexchar(input logic [3:0] nibble);
    if (nibble < 10) return 8'h30 + nibble;
    else return (8'h41 + (nibble - 10)) & 8'hFF;
  endfunction

endpackage : cpu_pkg
