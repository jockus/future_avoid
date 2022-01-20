package mod_extract

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:path"

indent : int
builder : strings.Builder
print_indent :: proc() {
	for i in 0..<indent do fmt.sbprintf(&builder, "	")
}
print :: proc(format : string, args : ..any) {
	print_indent()
	fmt.sbprintf(&builder, format, ..args)
}
Instrument :: struct {
	pitch1 : u16,
	pitch2 : u16,
	a : u8,
	d : u8,
	s : u8,
	r : u8,
	volume : u8,
	note_pitch : bool,
}

main :: proc() {
	mod, ok := os.read_entire_file(os.args[1])
	if !ok {
		fmt.printf("Can't find file '%v'\n", os.args[1])
		os.exit(1)
	}

	instr, ok2 := os.read_entire_file(os.args[2])
	if !ok {
		fmt.printf("Can't find file '%v'\n", os.args[2])
		os.exit(1)
	}

	builder = strings.make_builder()

	print("package main\n")
	name := path.name(os.args[1])
	print("%v_mod := Mod{{\n", name)
	indent += 1

	print("[]Instrument{{\n")
	indent += 1

	// Parse instrument file
	inst_lines := strings.split(string(instr), "\n")
	for line in inst_lines {
		if strings.index(line, "\"") != -1 do continue
		if len(line) < 8 do continue

		num := strings.split(line, " ")
		assert(len(num) == 8)
		pitch1 := strconv.atoi(num[0])
		pitch2 := strconv.atoi(num[1])
		a := strconv.atoi(num[2])
		d := strconv.atoi(num[3])
		s := strconv.atoi(num[4])
		r := strconv.atoi(num[5])
		volume := strconv.atoi(num[6])
		use_note := strconv.atoi(num[7])
		print("{{%v, %v, %v, %v, %v, %v, %v, %v},\n", 
			pitch1,
			pitch2,
			a,
			d,
			s,
			r,
			volume,
			use_note == 0 ? "false" : "true")
	}
	indent -= 1
	print("},\n")

	// Parse mod
	// https://www.ocf.berkeley.edu/~eek/index.html/tiny_examples/ptmod/ap12.html
	song_length := int(mod[950])
	song : []u8 = mod[952:952+song_length]
	print("[]Pattern{{\n")
	indent += 1
	for pattern in song {
		pattern : []u8 = mod[1084 + int(pattern) * 1024: 1084 + int(pattern) * 1024 + 1024]

		print("Pattern{{{{\n")
		indent += 1

		extract :: proc(data : []u8) -> (instrument, freq, sample : int) {
			instrument = int((data[0] & 0b11110000) >> 4)
			freq = int((u16(data[0])& 0b00001111) << 8 | u16(data[1]))
			sample = int((data[2] & 0b11110000) >> 4)
			return	
		}
		line_break : int
		for i in 0..<64 {
			print_indent()
			fmt.sbprintf(&builder, "{{")
			for channel in 0..<4 {
				offset := i * 4 * 4 + channel * 4
				instrument, period, sample := extract(pattern[offset:offset+4])
				if period > 0 && period not_in period_to_frequency {
					fmt.println("Can't find period!")
					fmt.println(period)
					os.exit(1)
				}
				fmt.sbprintf(&builder, "{{%v, %v},", period > 0 ? u16(period_to_frequency[period]) : 0, sample)
			}
			fmt.sbprintf(&builder, "},\n")
		}

		indent -= 1
		print("}},}},\n")
	}
	indent -= 1
	print("},\n")

	indent -= 1
	print("}")
	// fmt.println(strings.to_string(builder))
	os.write_entire_file(fmt.tprintf("src/%v_mod.odin", name), builder.buf[:])
}

period_to_frequency := map[int]f32{
1712  = 65.41	,
1616  = 69.30	,
1525  = 73.42	,
1440  = 77.78	,
1357  = 82.41	,
1281  = 87.31	,
1209  = 92.50	,
1141  = 98.00	,
1077  = 103.83	,
1017  = 110.00	,
961   = 116.54	,
907   = 123.47	,

856  = 130.81	,
808  = 138.59	,
762  = 146.83	,
720  = 155.56	,
678  = 164.81	,
640  = 174.61	,
604  = 185.00	,
570  = 196.00	,
538  = 207.65	,
508  = 220.00	,
480  = 233.08	,
453  = 246.94	,

428  = 261.63	,
404  = 277.18	,
381  = 293.66	,
360  = 311.13	,
339  = 329.63	,
320  = 349.23	,
302  = 369.99	,
285  = 392.00	,
269  = 415.30	,
254  = 440.00	,
240  = 466.16	,
226  = 493.88	,

214  = 523.25	,
202  = 554.37	,
190  = 587.33	,
180  = 622.25	,
170  = 659.25	,
160  = 698.46	,
151  = 739.99	,
143  = 783.99	,
135  = 830.61	,
127  = 880.00	,
120  = 932.33	,
113  = 987.77	,

107  = 1046.50	,
101  = 1108.73	,
95  =  1174.66	,
90  =  1244.51	,
85  =  1318.51	,
80  =  1396.91	,
76  =  1479.98	,
71  =  1567.98	,
67  =  1661.22	,
64  =  1760.00	,
60  =  1864.66	,
57  =  1975.53	,
}
