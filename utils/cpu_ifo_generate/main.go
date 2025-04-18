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

func reopen() (*os.File, error) {
	return os.Create(fmt.Sprintf("../../include/cpu_ifo_auto_generated.sv"))
}

func gen() {
	var f *os.File
	var err error

	base := 0
	mul := 1
	var prefetch int = 0
	var buf string

	f, err = reopen()
	chkerr(err)

	for i := base + 540*mul; i < base+1000*mul; i++ {
		ada := (i - base) / mul
		switch (i - base) % (60 * mul) {

		case 2 * mul:
			// buf = fmt.Sprintf("%d: begin adb <= operands[15:0] + 8'h%02X & RAMW; state <= FETCH_REQ; fetch_stage <= FETCH_DATA; next_state <= SHOW_INFO_Z%02X; end\n",
			// i, prefetch, z)
			buf = fmt.Sprintf("show_info_rom[%d] = '{ v_ada: 10'd0, v_din_t: 0, adb_diff: 8'h%02X, vram_write: 0, mem_read: 1};\n",
				i, prefetch)
			f.WriteString(buf)
		case 4 * mul, 6 * mul, 8 * mul, 10 * mul, 13 * mul, 15 * mul, 17 * mul, 19 * mul, 23 * mul, 25 * mul, 27 * mul, 29 * mul, 32 * mul, 34 * mul, 36 * mul, 38 * mul:
			// buf = fmt.Sprintf("%d: begin v_ada <= %d; v_din <= to_hexchar(dout[7:4]); end\n",
			// 	i, ada)
			buf = fmt.Sprintf("show_info_rom[%d] = '{ v_ada: 10'd%d, v_din_t: 0, adb_diff: 8'h00, vram_write: 1, mem_read: 0};\n",
				i, ada)
			f.WriteString(buf)
		case 5 * mul, 7 * mul, 9 * mul, 11 * mul, 14 * mul, 16 * mul, 18 * mul, 20 * mul, 24 * mul, 26 * mul, 28 * mul, 30 * mul, 33 * mul, 35 * mul, 37 * mul:
			// buf = fmt.Sprintf("%d: begin v_ada <= %d; v_din <= to_hexchar(dout[3:0]); ",
			// 	i, ada)
			// f.WriteString(buf)
			prefetch += 1
			// buf = fmt.Sprintf(" adb <= operands[15:0] + 8'h%02X & RAMW; state <= FETCH_REQ; fetch_stage <= FETCH_DATA; next_state <= SHOW_INFO_Z%02X; end\n",
			buf = fmt.Sprintf("show_info_rom[%d] = '{ v_ada: 10'd%d, v_din_t: 1, adb_diff: 8'h%02X, vram_write: 1, mem_read: 1};\n",
				i, ada, prefetch)
			f.WriteString(buf)
		case 39 * mul:
			// buf = fmt.Sprintf("%d: begin v_ada <= %d; v_din <= to_hexchar(dout[3:0]); end\n",
			// 	i, ada)
			buf = fmt.Sprintf("show_info_rom[%d] = '{ v_ada: 10'd%d, v_din_t: 1, adb_diff: 8'h00, vram_write: 1, mem_read: 0};\n",
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
