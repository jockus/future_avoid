// Courtesy of Jeroen
 
package main

import "w4"

Input :: struct #packed {
    gamepads:  [4]w4.Buttons,
    mouse: struct #packed {
        pos:     [2]i16,
        buttons: w4.MouseButtons,
    },
}
#assert(size_of(Input) == 4 + 2 + 2 + 1)

input := [2]Input{}
frames_between_new_input: u32

/*
    Borrowed from `core:math/rand`
*/
Rand :: struct {
    state: u64,
    inc:   u64,
}
global_rand: Rand

update_input_and_randomness_pool :: proc "contextless" (start := true) {
    if start {
        /*
            Grab new input and mix into randomness state.
        */
        input[0] = (^Input)(uintptr(0x16))^

        if input[0] == input[1] {
            // No new input
            frames_between_new_input += 1
        } else {
            /*
                Mix input into randomness. Use FNV-64 to hash input.
            */
            input_bytes := transmute([size_of(Input)]u8)input[0]
            input_hash  := fnv64(input_bytes[:])

            /*
                Grab 64 bits of randomness from current stream, add frames between input.
            */
            salt := u64(rand_u32()) << 32 | u64(rand_u32())
            salt += u64(frames_between_new_input)

            seed := salt * input_hash

            rand_init(seed)

            frames_between_new_input = 1
        }
    } else {

        input[1] = input[0]
    }
}

/*
    Borrowed from `core:math/rand` + `core:hash`.
*/
rand_init :: proc "contextless" (seed: u64) {
    global_rand.state = 0
    global_rand.inc = (seed << 1) | 1
    rand_u32()
    global_rand.state += seed
    rand_u32()
}

rand_u32 :: proc "contextless" () -> u32 {
    old_state := global_rand.state
    global_rand.state = old_state * 6364136223846793005 + (global_rand.inc|1)
    xor_shifted := u32(((old_state>>18) ~ old_state) >> 27)
    rot := u32(old_state >> 59)
    return (xor_shifted >> rot) | (xor_shifted << ((-rot) & 31))
}

rand_frac :: proc "contextless" () -> f32 {
	return f32(rand_u32()) / f32(max(u32))
}

fnv64 :: proc "contextless" (data: []byte, seed := u64(0xcbf29ce484222325)) -> u64 {
    h: u64 = seed
    for b in data {
        h = (h * 0x100000001b3) ~ u64(b)
    }
    return h
}

mouse_pressed :: proc "contextless" (button : w4.MouseButton) -> bool {
	return button in input[0].mouse.buttons && button not_in input[1].mouse.buttons
}
