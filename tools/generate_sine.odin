package main

import "core:fmt"
import "core:math"

main :: proc() {
	fmt.printf("sine :: [?]f32{{\n")
	steps :: 128
	for i in 0..<steps {
		fmt.printf("	%v,\n", math.sin(f32(i) * ((f32(math.PI)*2) / f32(steps))))
	}
	fmt.printf("}\n")
}
