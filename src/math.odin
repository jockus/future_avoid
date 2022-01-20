package main

import "core:math"

PI :: 3.1459
vec2 :: [2]f32

floor :: proc "contextless" (x : f32) -> f32 {
	return f32(int(x))
}

modd :: proc "contextless" (x, y : f32) -> f32 {
	return (x - floor(x / y) * y)
}

sin :: proc "contextless" (rad : f32) -> f32 {
	rad := rad
	if rad < 0 do rad *= -1
	rad = modd(rad, 2*PI)
	i := (rad / (2*PI)) * sine_steps
	a := sine_table[int(i) % sine_steps]
	b := sine_table[int(i+1) % sine_steps]
	return lerp(a, b, i-floor(i))
}

cos :: proc "contextless" (rad : f32) -> f32 {
	return sin((3.1459 * 0.5) - rad)
}

sqrt :: proc "contextless" (v : f32) -> f32 {
	return math.sqrt(v)
}

pow :: proc "contextless" (x, y : int) -> int {
	if y == 0 do return 1
	else if y % 2 == 0 do return pow(x, y/2) * pow(x, y/2)
	else do return x * pow(x, y/2) * pow(x, y/2)
}

lerp :: proc "contextless" (a, b, t : f32) -> f32 {
	return a * (1 - t) + b * t
}

map_range :: proc "contextless" (input_start, input_end, output_start, output_end, input : f32) -> f32 {
	slope := (output_end - output_start) / (input_end - input_start)
	return output_start + slope * (input - input_start)
}

dot :: proc "contextless" (a, b : vec2) -> f32 {
	return a.x*b.x + a.y*b.y
}

vec_min :: proc "contextless" (a, b : vec2) -> vec2 {
	return vec2{
		min(a.x, b.x),
		min(a.y, b.y),
	}
}

vec_length :: proc "contextless" (v : vec2) -> f32 {
	return sqrt(v.x*v.x + v.y*v.y)
}

vec_norm :: proc "contextless" (v : vec2) -> vec2 {
	return v / vec_length(v)
}

// https://www.shadertoy.com/view/XsXSz4
triangle_dist :: proc "contextless" (p : vec2, v : [3]vec2) -> f32 {
	e0 := v[1] - v[0]
	e1 := v[2] - v[1]
	e2 := v[0] - v[2]

	v0 := p - v[0]
	v1 := p - v[1]
	v2 := p - v[2]

	pq0 := v0 - e0 * clamp(dot(v0, e0) / dot(e0, e0), 0.0, 1.0)
	pq1 := v1 - e1 * clamp(dot(v1, e1) / dot(e1, e1), 0.0, 1.0)
	pq2 := v2 - e2 * clamp(dot(v2, e2) / dot(e2, e2), 0.0, 1.0)
    
    s := e0.x * e2.y - e0.y * e2.x
    d := vec_min(vec_min(vec2{dot(pq0, pq0), s * (v0.x * e0.y - v0.y * e0.x)},
                      vec2{dot(pq1, pq1), s * (v1.x * e1.y - v1.y * e1.x)}),
                      vec2{dot(pq2, pq2), s * (v2.x * e2.y - v2.y * e2.x)})

	r := -sqrt(d.x)
	return d.y > 0 ? r : -r
}


