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

	counter := 10

	for i := base + 540*mul; i < base+1000*mul; i++ {
		ada := (i - base) / mul
		switch (i - base) % (60 * mul) {

		case 2 * mul:
			buf = fmt.Sprintf("show_info_rom[%d] = '{ v_ada: 10'd0, v_din_t: 0, v_din: 0, adb_diff: 8'h%02X, vram_write: 0, mem_read: 1};\n",
				counter, prefetch)
			f.WriteString(buf)
			counter++
		case 4 * mul, 6 * mul, 8 * mul, 10 * mul, 13 * mul, 15 * mul, 17 * mul, 19 * mul, 23 * mul, 25 * mul, 27 * mul, 29 * mul, 32 * mul, 34 * mul, 36 * mul, 38 * mul:
			buf = fmt.Sprintf("show_info_rom[%d] = '{ v_ada: 10'd%d, v_din_t: 0, v_din: 0, adb_diff: 8'h00, vram_write: 1, mem_read: 0};\n",
				counter, ada)
			f.WriteString(buf)
			counter++
		case 5 * mul, 7 * mul, 9 * mul, 11 * mul, 14 * mul, 16 * mul, 18 * mul, 20 * mul, 24 * mul, 26 * mul, 28 * mul, 30 * mul, 33 * mul, 35 * mul, 37 * mul:
			prefetch += 1
			buf = fmt.Sprintf("show_info_rom[%d] = '{ v_ada: 10'd%d, v_din_t: 1, v_din: 0, adb_diff: 8'h%02X, vram_write: 1, mem_read: 1};\n",
				counter, ada, prefetch)
			f.WriteString(buf)
			counter++
		case 39 * mul:
			buf = fmt.Sprintf("show_info_rom[%d] = '{ v_ada: 10'd%d, v_din_t: 1, v_din: 0, adb_diff: 8'h00, vram_write: 1, mem_read: 0};\n",
				counter, ada)
			f.WriteString(buf)
			counter++
			prefetch += 1
		}
	}
	f.Close()
}

func main() {
	gen()
}
