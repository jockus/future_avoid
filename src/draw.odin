package main

import "w4"

draw :: proc "contextless" (x, y : int, color : u8) {
	if x < 0 || x >= 160 do return
	if y < 0 || y >= 160 do return
	offset := (y * 160 + x) / 4
	bitshift := u8((y * 160 + x) % 4)
	byte := &w4.FRAMEBUFFER[offset]
	byte^ = byte^ & ~(u8(3) << (bitshift * 2)) | (u8(color) << (bitshift * 2))
}

draw_circle :: proc "contextless" (pos : vec2, size : f32, col : u8) {
	hs := f32(int(size+1))
	for y in pos.y-hs..<pos.y+hs {
		for x in pos.x-hs..<pos.x+hs {
			to_p := vec2{x, y} - pos
			if vec_length(to_p) < size {
				draw(int(x),int(y),col)
			}
		}
	}
}

draw_triangle :: proc "contextless" (v : [3]vec2, c : u8, fill := true, lines := true) {
	if fill {
		v := v
		// sort vertices
		if v[0].y > v[1].y do v[0], v[1] = v[1], v[0]
		if v[0].y > v[2].y do v[0], v[2] = v[2], v[0]
		if v[1].y > v[2].y do v[1], v[2] = v[2], v[1]

		total_height := v[2].y - v[0].y
		for y in v[0].y..<v[1].y {
			segment_height := v[1].y-v[0].y+1
			alpha := (y-v[0].y)/total_height
			beta  := (y-v[0].y)/segment_height

			min_p := v[0] + (v[2] - v[0]) * alpha
			max_p := v[0] + (v[1] - v[0]) * beta
			if min_p.x > max_p.x do min_p, max_p = max_p, min_p

			for x in min_p.x..<max_p.x {
				draw(int(x), int(y), c)
			}
		}
		for y in v[1].y..<v[2].y {
			segment_height := v[2].y-v[1].y+1
			alpha := (y-v[0].y)/total_height
			beta  := (y-v[1].y)/segment_height

			min_p := v[0] + (v[2] - v[0]) * alpha
			max_p := v[1] + (v[2] - v[1]) * beta
			if min_p.x > max_p.x do min_p, max_p = max_p, min_p

			for x in min_p.x..<max_p.x {
				draw(int(x), int(y), c)
			}
		}
	}
	if lines {
		w4.line(i32(v[0].x), i32(v[0].y),
				i32(v[1].x), i32(v[1].y))
		w4.line(i32(v[1].x), i32(v[1].y),
				i32(v[2].x), i32(v[2].y))
		w4.line(i32(v[2].x), i32(v[2].y),
				i32(v[0].x), i32(v[0].y))
	}
}

draw_quad :: proc "contextless" (v : [4]vec2, fill := true, lines := true) {
	draw_triangle([3]vec2{v.x, v.y, v.z}, 1, fill, lines)
	draw_triangle([3]vec2{v.z, v.y, v.w}, 1, fill, lines)
}

char :: proc "contextless" (pos : vec2, char : int) {
	for j in 0..<8 {
		row := (int(char) / int(32)) * 32 * 8
		w4.blit(&font[row + j * 32 + (int(char) % 32)], i32(pos.x), i32(int(pos.y) + j), 8, 1)
	}
}

text :: proc "contextless" (pos : vec2, str : string) {
	char_width :: 5
	for c, i in str {
		char({pos.x + f32(i * char_width), pos.y}, int(c))
	}
}

number :: proc "contextless" (pos : vec2, number : int) {
	number_width :: 7
	digits := 0
	{
		number := number
		for number > 0 {
			digits += 1
			number /= 10
		}
	}
	for digit := digits-1; digit >= 0; digit-=1 {
		v := number
		if digit > 0 {
			v /= pow(int(10), digit)
		}
		v %= 10
		char({pos.x + f32(digits-1 - digit) * number_width, pos.y}, int('0' + v))
	}
}
