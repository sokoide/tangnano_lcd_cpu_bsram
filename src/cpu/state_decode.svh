          DECODE_EXECUTE: begin
            cea = 0;
            v_cea = 0;
            write_to_vram = 0;  // Clear flag unless set by sta_write below

            case (opcode)
              `include "cpu/decode_control_flow.svh"
              `include "cpu/decode_load_store.svh"
              `include "cpu/decode_store.svh"
              `include "cpu/decode_inc_dec.svh"
              `include "cpu/decode_adc_sbc.svh"
              `include "cpu/decode_logic.svh"
              `include "cpu/decode_shifts.svh"
              `include "cpu/decode_compare.svh"
              `include "cpu/decode_transfers.svh"
              `include "cpu/decode_branches.svh"
              `include "cpu/decode_flags_custom.svh"
              // support more instructions here

              default: ;  // No operation.
            endcase
          end

