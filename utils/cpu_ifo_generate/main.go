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
	y++
	y++
	write_string(f, &counter, 0, y, "Address 0x")
	write_show_info_rom(f, &counter, 60*y+10, 8, 0, 0, 1, 0)
	write_show_info_rom(f, &counter, 60*y+11, 8, 1, 0, 1, 0)
	write_show_info_rom(f, &counter, 60*y+12, 8, 2, 0, 1, 0)
	write_show_info_rom(f, &counter, 60*y+13, 8, 3, 0, 1, 0)
	write_string(f, &counter, 14, y, "-")

	f.WriteString("// Memory dump\n")
	dx := 9 // first position to write the data
	for i := 540; i < 60*17; i++ {
		ada := i
		switch i % 60 {
		case 0: // base address
			write_string(f, &counter, 0, i/60, "0x:")
		case 2:
			write_show_info_rom(f, &counter, ada, 8, 0, 0x10*(i/60-9), 1, 0)
		case 3:
			write_show_info_rom(f, &counter, ada, 8, 1, 0x10*(i/60-9), 1, 0)
		case 4:
			write_show_info_rom(f, &counter, ada, 8, 2, 0x10*(i/60-9), 1, 0)
		case 5:
			write_show_info_rom(f, &counter, ada, 8, 3, 0x10*(i/60-9), 1, 0)
		case 6:
			write_string(f, &counter, 6, i/60, ":")
		case 8: // prefetch
			write_show_info_rom(f, &counter, 0, 0, 0, prefetch, 0, 1)
		case dx, dx + 2, dx + 4, dx + 6, dx + 9, dx + 11, dx + 13, dx + 15, dx + 19, dx + 21, dx + 23, dx + 25, dx + 28, dx + 30, dx + 32, dx + 34: // write high nibble
			write_show_info_rom(f, &counter, ada, 0, 0, 0, 1, 0)
		case dx + 1, dx + 3, dx + 5, dx + 7, dx + 10, dx + 12, dx + 14, dx + 16, dx + 20, dx + 22, dx + 24, dx + 26, dx + 29, dx + 31, dx + 33: // write low nibble and prefetch
			prefetch += 1
			write_show_info_rom(f, &counter, ada, 1, 0, prefetch, 1, 1)
		case dx + 35: // write low nibble
			write_show_info_rom(f, &counter, ada, 1, 0, 0, 1, 0)
			prefetch += 1
		}
	}
	f.Close()
}

func main() {
	gen()
}
