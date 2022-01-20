package main

import "w4"

/* TODO:
	Palette work
	Clean up code and push

	Add font X
	Add scoring X
	Figure out graphics for wall X
	Add title screen X
	Add music X
	Death particles X
	Better music X
*/

time : f32

player := struct{
	pos : vec2,
	vel : vec2,
}{}
player_size :: f32(5.3)
player_drag :: 0.98

first_boot := true
holding : bool
has_held : bool

wall_frac : f32

game_over := false
game_over_timer : f32

particles : [20]struct{
	pos : vec2,
	vel : vec2,
	rot : f32,
}

Obstacle :: struct {
	position : vec2,
	size : f32,
	rotation : f32,
}
MAX_OBSTACLES :: 4
MAX_OBSTACLE_SIZE :: f32(12)
num_obstacles := 0
obstacles : [MAX_OBSTACLES]Obstacle
future : [MAX_OBSTACLES]Obstacle

level := 0
score := 0
high_score : int

mod_player : Mod_Player

levels := [?]struct {
	bg_height : u32,
	bg_data : [^]u8,
	obstacles : int,
	all_ghost : bool,
} {
	{
		grab_swing_height,
		&grab_swing[0],
		0,
		true,
	},
	{
		future_avoid_height,
		&future_avoid[0],
		2,
		true,
	},
	{
		0,
		nil,
		2,
		false,
	},
	{
		quickly_height,
		&quickly[0],
		4,
		false,
	},
}

@export
start :: proc "c" () {
    rand_init(42)
    frames_between_new_input = 1 // Used in randomness salt multiplication.

	w4.diskr(&high_score, size_of(high_score))
	reset()

	rgb :: proc "contextless" (r, g, b : int) -> u32 {
		return u32(0) << 24 | u32(r) << 16 | u32(g) << 8 | u32(b);
	}
	// https://colorhunt.co/palette/feece9ccd1e4fe7e6d2f3a8f
	w4.PALETTE[0] = rgb(254, 236, 233) 
	w4.PALETTE[1] = rgb(254, 126, 109)
	w4.PALETTE[2] = rgb(47, 58, 143)
	w4.PALETTE[3] = rgb(204, 209, 228)

	mod_player.mod = &title_mod

}

@export
update :: proc "c" () {
	if !game_over {
		mod_play(&mod_player)
	}

    update_input_and_randomness_pool()
    defer update_input_and_randomness_pool(false)

	if first_boot {
		title_screen()
	}
	else {
		game()
		if game_over {
			game_over_screen()
		}
	}
}

reset :: proc "contextless" () {
	player.pos = {80, 80}
	player.vel = {}

	level = 0
	score = 0
	holding = false
	has_held = false
	wall_frac = 0

	num_obstacles = 0
	future = {}
	obstacles = {}
}

advance :: proc "contextless" () {
	score += int((1-wall_frac) * 100)
	wall_frac = 0
	level += 1
	num_obstacles = MAX_OBSTACLES
	if level < len(levels) {
		num_obstacles = levels[level].obstacles
	}
	obstacles = future
	for i in 0..<num_obstacles {
		future := &future[i]
		future.position = vec2{rand_frac() * 160, rand_frac() * 160} 
		future.size = 4 + rand_frac() * (MAX_OBSTACLE_SIZE - 4)
		future.rotation = rand_frac() * PI * 2
	}
	if score > high_score {
		high_score = score
		w4.diskw(&high_score, size_of(high_score))
	}
}

game :: proc "contextless" () {
	dt :: f32(1/60.0)
	gravity :: 250

	if !game_over do time += dt
	if game_over {
		game_over_timer += dt
	}

	// Level bg
	if !game_over {
		w4.DRAW_COLORS^ = 4
		if level < len(levels) && levels[level].bg_data != nil {
			w4.blit(levels[level].bg_data, 0, 0, 160, levels[level].bg_height)
		}
	}


	screen_size :: 160
	
	mouse_pos := vec2{f32(w4.MOUSE_X^), f32(w4.MOUSE_Y^)}
	to_m := (player.pos - mouse_pos)
	dist := to_m.x*to_m.x + to_m.y*to_m.y
	close_enough_to_grab := vec_length(to_m) < player_size * 4

	if !game_over {
		if .Left in input[0].mouse.buttons {
			if .Left not_in input[1].mouse.buttons && close_enough_to_grab {
				holding = true
				has_held = true
			}
		}
		else {
			holding = false
		}
		
	}

	
	if !game_over {
		f : vec2
		if holding {
			scale : f32 = -1000
			f = (player.pos - mouse_pos) * scale
		}
		
		a : vec2
		// Stop gravity until ball has been grabbed for the first time
		if has_held {
			a.y = gravity
		}
		a += f * dt
		player.vel += a * dt
		player.pos += player.vel * dt
		player.vel *= player_drag

		if player.pos.x < 0 {
			die()
		}
		if player.pos.x >= 160 {
			player.pos.x -= 160
			holding = false
			advance()
		}
		// Bit of leeway
		if player.pos.y < -40 do die()
		if player.pos.y > 200 do die()
	}


	if level >= len(levels)-1
	{
		if !game_over {
			wall_frac += 0.1 * dt
		}
		wall := [4]vec2{
			{0, 0},
			{160 * wall_frac, 0},
			{0, 160},
			{160 * wall_frac, 160},
		}
		draw_quad(wall, true, false)

		if !game_over && wall_frac > 0.1 && wall_frac * 160 > (player.pos.x-player_size) {
			 die()
		}
	}

	make_triangle :: proc "contextless" (pos : vec2, radius : f32, rotation : f32) -> [3]vec2 {
		return [3]vec2{
			{pos.x + cos(rotation + PI*2*(1/3.0)) * radius, pos.y + sin(rotation + PI*2*(1/3.0)) * radius},
			{pos.x + cos(rotation + PI*2*(2/3.0)) * radius, pos.y + sin(rotation + PI*2*(2/3.0)) * radius},
			{pos.x + cos(rotation + PI*2*(3/3.0)) * radius, pos.y + sin(rotation + PI*2*(3/3.0)) * radius},
		}
	}


	// Rope
	if !game_over && holding {
		w4.DRAW_COLORS^ = 3
		w4.line(i32(player.pos.x), i32(player.pos.y), i32(mouse_pos.x), i32(mouse_pos.y))
	}

	// Player
	if !game_over {
		draw_circle(player.pos, player_size, 2)
	}
	else {
		for p in &particles {
			p.vel.y += gravity * dt
			p.pos += p.vel * dt
			p.rot += dt * 10
			p.vel *= player_drag
			tris := make_triangle(p.pos, 2, p.rot)
			draw_triangle(tris, 2, true, false)
		}
	}


	// Futures
	for i in 0..<num_obstacles {
		f := &future[i]
		f.rotation += dt
		tris := make_triangle(f.position, f.size, f.rotation)
		w4.DRAW_COLORS^ = 3
		draw_triangle(tris, 1, false)
	}

	// Obstacles
	for i in 0..<num_obstacles {
		obstacle := &obstacles[i]
		obstacle.rotation += dt

		tris := make_triangle(obstacle.position, obstacle.size, obstacle.rotation)
		w4.DRAW_COLORS^ = 3
		draw_triangle(tris, 1, true)

		dis := triangle_dist(player.pos, tris)
		// Collision check and highlight
		highlight_max := 2


		if !game_over {
			// Player reflection
			reflection_distance :: player_size * 6
			if dis < reflection_distance {
				to_c := vec_norm(obstacle.position - player.pos)
				to_c *= (0.5 * player_size) + (player_size * (dis / reflection_distance)) * 0.3
				size_frac := obstacle.size / MAX_OBSTACLE_SIZE
				size := map_range(player_size, reflection_distance, 2 * size_frac, 0, dis)
				draw_circle(player.pos + to_c, size, 1)
			}

			if dis < player_size {
				die()
			}
		}
	}

	// Scores
	if !game_over {
		w4.DRAW_COLORS^ = 4
		if level > 0 {
			text({100,152}, "Score: ")
			number({130, 152}, score)
		}
		else {
			text({34,140}, "High Score: ")
			number({100, 140}, high_score)
		}
	}

	// Mouse cursor
	if !holding {
		w4.DRAW_COLORS^ = 3
		w4.blit(transmute([^]u8) &cursor[0], i32(mouse_pos.x - 9 * 0.5), i32(mouse_pos.y - 9 * 0.5), 9, 9)
	}
}

title_screen :: proc "contextless" () {
	w4.DRAW_COLORS^ = 0x2431;
	w4.blit(&title[0], 0, 0, title_width, title_height, title_flags)
	if mouse_pressed(.Left) {
		first_boot = false
	}
}

game_over_screen :: proc "contextless" () {
	// Grace timer to show death and avoid accidental clicks
	if game_over_timer < 0.75 do return

	w4.blit(&future_avoid[0], 0, 20, future_avoid_width, future_avoid_height, future_avoid_flags)

	panel := [4]vec2{
		{30, 80},
		{130, 80},
		{30, 110},
		{130, 110},
	}
	w4.DRAW_COLORS^ = 3
	draw_quad(panel, true, false)

	w4.DRAW_COLORS^ = 4
	text({40,84}, "Score: ")
	number({100, 84}, score)

	text({35,96}, "High Score: ")
	number({100, 96}, high_score)

	if mouse_pressed(.Left) {
		reset()
		game_over = false
	}
}

die :: proc "contextless" () {
	mod_stop(&mod_player)

	w4.tone_complex(600, 1, w4.Tone_Duration{release = 70}, 50, .Noise)

	game_over = true
	game_over_timer = 0 
	for p in &particles {
		p.pos = player.pos + {(rand_frac() - 0.5) * 10, (rand_frac() - 0.5) * 10}
		p.vel = player.vel * 0.5 + {(rand_frac() - 0.5) * 30, (rand_frac() - 0.5) * 30}
		p.rot = rand_frac() * 2 * PI
	}
}
