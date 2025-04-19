package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"strconv"

	log "github.com/sirupsen/logrus"
)

// types
type options struct {
	hexFilePath string
	svFilePath  string
}

type hexLine struct {
	length     uint64
	addr       [2]byte
	recordType int
	data       []byte
	checksum   byte
}

// global vars
var o options

// fuctions
func chkerr(err error) {
	if err != nil {
		log.Panic(err)
	}
}

func init() {
	flag.StringVar(&o.hexFilePath, "hexfile", o.hexFilePath, "input hex file path")
	flag.StringVar(&o.svFilePath, "svfile", o.svFilePath, "output sv file path")
	flag.Parse()
}

func readHexLine(line string) *hexLine {
	var err error
	var r hexLine
	var u64 uint64

	r.length, err = strconv.ParseUint(line[1:3], 16, 8)
	chkerr(err)

	u64, err = strconv.ParseUint(line[3:7], 16, 16)
	chkerr(err)
	r.addr[0] = byte((u64 & 0x0000FF00) >> 8)
	r.addr[1] = byte(u64 & 0x000000FF)

	u64, err = strconv.ParseUint(line[7:9], 16, 8)
	chkerr(err)
	r.recordType = int(u64)

	r.data = make([]byte, r.length)
	var i uint64
	for i = 0; i < r.length; i++ {
		u64, err = strconv.ParseUint(line[9+i*2:9+i*2+2], 16, 8)
		chkerr(err)
		log.Debugf("%02x", u64)
		r.data[i] = byte(u64)
	}

	return &r
}

func processHexLine(outfile *os.File, r *hexLine, idx int) int {
	if r.recordType != 0 {
		return idx
	}

	for i := 0; i < int(r.length); i++ {
		outfile.WriteString(fmt.Sprintf("        %d: 8'h%02X,\n", idx, r.data[i]))
		idx++
	}
	return idx
}

func main() {
	var err error
	var infile *os.File
	var outfile *os.File

	log.Info("started")
	log.Infof("o: %+v", o)

	infile, err = os.Open(o.hexFilePath)
	chkerr(err)
	defer infile.Close()

	outfile, err = os.Create(o.svFilePath)
	chkerr(err)
	defer outfile.Close()

	scanner := bufio.NewScanner(infile)

	var r *hexLine
	var idx int = 0

	outfile.WriteString(`logic [7:0] boot_program[256];

assign boot_program = '{
`)

	for scanner.Scan() {
		line := scanner.Text()
		log.Infof(line)
		r = readHexLine(line)
		log.Infof("hexLine: %+v", r)
		idx = processHexLine(outfile, r, idx)
	}

	if err := scanner.Err(); err != nil {
		log.Errorf("scanner err: %s", err)
	}

	outfile.WriteString("        default: 8'hEA\n")
	outfile.WriteString("    };\n")
	outfile.WriteString(fmt.Sprintf("parameter logic[7:0] boot_program_length = %d;\n", idx))
}
