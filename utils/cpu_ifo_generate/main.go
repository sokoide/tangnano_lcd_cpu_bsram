package main

import (
	"fmt"
	"os"
)

func chkerr(err error) {
	if err != nil {
		panic(err)
	}
}

func reopen(z int) (*os.File, error) {
	return os.Create(fmt.Sprintf("../../include/cpu_ifo_z%02d_auto_generated.sv", z))
}

func gen() {
	var f *os.File
	var err error

	base := 0
	mul := 1
	var prefetch int = 0
	var buf string
	var z int = 0

	f, err = reopen(z)
	chkerr(err)

	for i := base + 360*mul; i < base+820*mul; i++ {
		ada := (i - base) / mul
		tmp := (i-base)/mul/60 - 6
		if z != tmp {
			z = tmp
			f.Close()
			f, err = reopen(z)
			chkerr(err)
		}
		switch (i - base) % (60 * mul) {

		case 2 * mul:
			// read 0x00 + prefetch
			// 			buf = fmt.Sprintf(`            end else if (show_info_counter == %d) begin
			//               // read 0x%02X
			//               adb <= 8'h%02X;
			//               state <= FETCH_REQ;
			//               fetch_stage <= FETCH_DATA;
			//               next_state <= SHOW_INFO_Z%02X;
			// `, i, prefetch, prefetch, z)
			buf = fmt.Sprintf("%d: begin adb <= 8'h%02X; state <= FETCH_REQ; fetch_stage <= FETCH_DATA; next_state <= SHOW_INFO_Z%02X; end\n",
				i, prefetch, z)
			f.WriteString(buf)
		case 4 * mul, 6 * mul, 8 * mul, 10 * mul, 13 * mul, 15 * mul, 17 * mul, 19 * mul, 23 * mul, 25 * mul, 27 * mul, 29 * mul, 32 * mul, 34 * mul, 36 * mul, 38 * mul:
			// write 1st byte of dout
			// 			buf = fmt.Sprintf(`            end else if (show_info_counter == %d) begin
			//               v_ada <= %d;
			//               v_din <= dout[7:4] < 10 ? dout[7:4] + 8'h30 : dout[7:4] + 8'h41 - 8'd10;
			// `,
			// i, ada)
			buf = fmt.Sprintf("%d: begin v_ada <= %d; v_din <= to_hexchar(dout[7:4]); end\n",
				i, ada)
			f.WriteString(buf)
		case 5 * mul, 7 * mul, 9 * mul, 11 * mul, 14 * mul, 16 * mul, 18 * mul, 20 * mul, 24 * mul, 26 * mul, 28 * mul, 30 * mul, 33 * mul, 35 * mul, 37 * mul:
			// write 2nd byte of dout
			// 			buf = fmt.Sprintf(`            end else if (show_info_counter == %d) begin
			//               v_ada <= %d;
			//               v_din <= dout[3:0] < 10 ? dout[3:0] + 8'h30 : dout[3:0] + 8'h41 - 8'd10;
			// `,
			// 				i, ada)
			buf = fmt.Sprintf("%d: begin v_ada <= %d; v_din <= to_hexchar(dout[3:0]); ",
				i, ada)
			f.WriteString(buf)
			prefetch += 1
			// 			buf = fmt.Sprintf(`            // read 0x%02X
			//               adb <= 8'h%02X;
			//               state <= FETCH_REQ;
			//               fetch_stage <= FETCH_DATA;
			//               next_state <= SHOW_INFO_Z%02X;
			// `, prefetch, prefetch, z)
			buf = fmt.Sprintf(" adb <= 8'h%02X; state <= FETCH_REQ; fetch_stage <= FETCH_DATA; next_state <= SHOW_INFO_Z%02X; end\n",
				prefetch, z)
			f.WriteString(buf)
		// case 5*mul + 1, 7*mul + 1, 9*mul + 1, 11*mul + 1, 14*mul + 1, 16*mul + 1, 18*mul + 1, 20*mul + 1, 24*mul + 1, 26*mul + 1, 28*mul + 1, 30*mul + 1, 33*mul + 1, 35*mul + 1, 37*mul + 1:
		// 	// read 0x00 + prefetch
		// 	buf = fmt.Sprintf(`            end else if (show_info_counter == %d) begin
		//       // read 0x%02X
		//       adb <= 8'h%02X;
		//       state <= FETCH_REQ;
		//       fetch_stage <= FETCH_DATA;
		//       next_state <= SHOW_INFO_Z%02X;
		// `, i, prefetch, prefetch, z)
		// f.WriteString(buf)
		case 39 * mul:
			// write 2nd byte of dout
			// 			buf = fmt.Sprintf(`            end else if (show_info_counter == %d) begin
			//               v_ada <= %d;
			//               v_din <= dout[3:0] < 10 ? dout[3:0] + 8'h30 : dout[3:0] + 8'h41 - 8'd10;
			// `,
			// i, ada)
			buf = fmt.Sprintf("%d: begin v_ada <= %d; v_din <= to_hexchar(dout[3:0]); end\n",
				i, ada)
			f.WriteString(buf)
			prefetch += 1
		}
	}
	f.Close()
}

func main() {
	gen()
}
