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

func main() {
	f, err := os.OpenFile("Sweet16.f8", os.O_RDONLY, 0644)
	chkerr(err)
	defer f.Close()

	var idx int = 0
	for {
		by := make([]byte, 16)
		_, err = f.Read(by)
		if err != nil {
			if err.Error() != "EOF" {
				chkerr(err)
			}
			break
		}

		fmt.Fprintf(os.Stderr, "addr: 0x%08x code: %d, char: %c\n", idx*2, idx, rune(idx))
		// fmt.Printf("// char: %c\n", rune(idx))
		fmt.Printf("# code: %d\n", idx)
		for i := 0; i < 16; i++ {
			b := by[i]
			// fmt.Printf("font[%d][%d] = 8'h%x;\n", idx, i, b)
			fmt.Printf("%02x\n", b)
			for j := 7; j >= 0; j-- {
				if (b>>j)&1 == 1 {
					fmt.Fprintf(os.Stderr, "*")
				} else {
					fmt.Fprintf(os.Stderr, " ")
				}
			}
		}
		idx++
		if idx*4 >= 0x200 {
			break
		}
	}
}
