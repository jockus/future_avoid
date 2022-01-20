package main

import "w4"

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

Note :: struct {
	freq : u16,
	instrument : u8,
}

Pattern :: struct {
	notes : [64][4]Note,
}

Mod :: struct {
	instruments : []Instrument,
	patterns : []Pattern,
}

Mod_Player :: struct {
	frame_counter : int,
	pattern_counter : u8,
	note_counter : u8,
	play : bool,
	mod : ^Mod,
}

mod_play :: proc "contextless" (player : ^Mod_Player) {
	player.frame_counter += 1

	// Roughly match original mod file speeds
	if player.frame_counter % 3 != 0 do return

	for channel in 0..<4 {
		note := player.mod.patterns[player.pattern_counter].notes[player.note_counter][channel]
		if note.freq != 0 {
			using instrument := &player.mod.instruments[note.instrument-1]

			duration := w4.Tone_Duration{a, d, r, s,}
			if note_pitch {
				freq := note.freq

				// Adjust bass down an octave
				if channel == 2 do freq /= 2

				// Chorus channel 2 by adding a bit of offset
				if channel == 1 do freq += 2

				w4.tone_complex(freq, freq, duration, u32(volume), w4.Tone_Channel(channel), .Quarter)
			}
			else {
				w4.tone_complex(pitch1, pitch2, duration, u32(volume), w4.Tone_Channel(channel))
			}
		}
	}
	player.note_counter += 1
	if player.note_counter == 64 {
		player.note_counter = 0
		player.pattern_counter += 1
		if int(player.pattern_counter) >= len(player.mod.patterns) {
			player.pattern_counter = 0
		}
	}
}

mod_stop :: proc "contextless" (player : ^Mod_Player) {
	mod_player.note_counter = 0
	mod_player.pattern_counter = 0
	w4.tone(0, 0, 0, w4.Tone_Channel(1))
	w4.tone(0, 0, 0, w4.Tone_Channel(2))
	w4.tone(0, 0, 0, w4.Tone_Channel(3))
	w4.tone(0, 0, 0, w4.Tone_Channel(4))
}
