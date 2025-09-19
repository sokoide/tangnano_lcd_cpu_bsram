          WRITE_REQ: begin  // JSR stack push uses this
            written_data_bytes <= written_data_bytes + 1'd1;
            // cea/v_cea were asserted in DECODE_EXECUTE before entering WRITE_REQ
            // De-assert them when moving back to DECODE_EXECUTE or FETCH
            cea   = 0;
            v_cea = 0;
            state <= DECODE_EXECUTE;
          end

