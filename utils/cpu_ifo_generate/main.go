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

func write_show_info_rom(f *os.File, counter *int, v_ada int, v_din_t int, v_din int, diff int, vram_write int, mem_read int) {
	buf := fmt.Sprintf("show_info_rom[%d] = '{ v_ada: 10'd%d, v_din_t: %d, v_din: 8'h%02X, diff: 8'h%02X, vram_write: %d, mem_read: %d};\n",
		*counter, v_ada, v_din_t, v_din, diff, vram_write, mem_read)
	f.WriteString(buf)
	*counter++
}

func write_string(f *os.File, counter *int, x int, y int, str string) {
	f.WriteString(fmt.Sprintf("// %s\n", str))
	for _, char := range str {
		// buf = fmt.Sprintf("show_info_rom[%d] = '{ v_ada: 10'd%d, v_din_t: 2, v_din: 8'd%d, diff: 8'h0, vram_write: 1, mem_read: 0};\n",
		// 	*counter, 60*y+x, char)
		// f.WriteString(buf)
		write_show_info_rom(f, counter, 60*y+x, 2, int(char), 0, 1, 0)
		x++
	}
}

func gen() {
	var f *os.File
	var err error

	base := 0
	mul := 1
	counter := 0
	y := 0
	var prefetch int = 0

	f, err = reopen()
	chkerr(err)

	write_string(f, &counter, 0, y, "Registers)")
	y++
	write_string(f, &counter, 0, y, "A :0x")
	y++
	write_string(f, &counter, 0, y, "X :0x")
	y++
	write_string(f, &counter, 0, y, "Y :0x")
	y++
	write_string(f, &counter, 0, y, "PC:0x")
	y++
	write_string(f, &counter, 0, y, "SP:0x")
	y++

	f.WriteString("// Memory dump\n")
	for i := base + 540*mul; i < base+1000*mul; i++ {
		ada := (i - base) / mul
		switch (i - base) % (60 * mul) {

		case 2 * mul:
			write_show_info_rom(f, &counter, 0, 0, 0, prefetch, 0, 1)
			counter++
		case 4 * mul, 6 * mul, 8 * mul, 10 * mul, 13 * mul, 15 * mul, 17 * mul, 19 * mul, 23 * mul, 25 * mul, 27 * mul, 29 * mul, 32 * mul, 34 * mul, 36 * mul, 38 * mul:
			write_show_info_rom(f, &counter, ada, 0, 0, 0, 1, 0)
		case 5 * mul, 7 * mul, 9 * mul, 11 * mul, 14 * mul, 16 * mul, 18 * mul, 20 * mul, 24 * mul, 26 * mul, 28 * mul, 30 * mul, 33 * mul, 35 * mul, 37 * mul:
			prefetch += 1
			write_show_info_rom(f, &counter, ada, 1, 0, prefetch, 1, 1)
		case 39 * mul:
			write_show_info_rom(f, &counter, ada, 1, 0, 0, 1, 0)
			prefetch += 1
		}
	}
	f.Close()
}

func main() {
	gen()
}
