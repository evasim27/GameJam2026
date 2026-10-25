extends SceneTree
## Run: godot --headless --path game --script res://tools/check_ending.gd

const NAMES := ["Maja 1989", "Luka 1994", "Tina 2003"]
const VARIANTS := ["none", "maja", "luka", "maja_luka", "tina", "maja_tina", "luka_tina"]


func _initialize() -> void:
	call_deferred("_check")


func _candies_for(mask: int) -> Array[String]:
	var candies: Array[String] = []
	for i in NAMES.size():
		if mask & (1 << i):
			candies.append(NAMES[i])
	return candies


func _check() -> void:
	var ending_script = load("res://rewind/ending.gd")
	assert(ending_script != null and ending_script.can_instantiate())
	for mask in range(8):
		for fails in [0, 2]:
			var ending = ending_script.new()
			var candies := _candies_for(mask)
			ending.setup(candies, fails, 3 + fails, 47.5, fails > 0)
			root.add_child(ending)
			ending.set_process(false)
			assert(ending._rescue_mask == mask)
			assert(ending._ending_name == ("EXCHANGE" if mask == 7 else "REWIND"))
			var story_count := 4 if mask == 0 else 5
			assert(ending._images.size() == story_count + 1)
			if mask == 7:
				assert(ending._shots.back().image == ending._shots[story_count - 1].image)
			else:
				assert(ending._shots.back().image == "res://assets/ending/07_results.png")
			for texture in ending._images:
				assert(texture != null and texture.get_width() > 0)
			if mask > 0 and mask < 7:
				assert(ending._shots[1].image.ends_with("/%s/02_children_returned.png" % VARIANTS[mask]))
				assert(ending._shots[2].image.ends_with("/%s/03_wrong_morning.png" % VARIANTS[mask]))
				var reunion: String = ending._shots[3].image
				if mask & 1:
					assert(reunion.ends_with("/04_mother_recognizes.png"))
				elif mask & 2:
					assert(reunion.ends_with("/04_mother_recognizes_luka.png"))
				else:
					assert(reunion.ends_with("/04_mother_recognizes_tina.png"))
			if mask == 0:
				assert(ending._shots[0].image.ends_with("/01_no_hands.png"))
				assert(ending._shots[2].image.ends_with("/none/03_wrong_morning.png"))
			if mask == 7:
				assert(ending._shots[2].image.ends_with("/ending_exchange/03_inside_the_screen.png"))
				assert(ending._shots[3].image.ends_with("/ending_exchange/04_hand_on_glass.png"))
				assert(ending._shots[4].image.ends_with("/ending_exchange/05_do_not_play.png"))
			for shot in range(story_count):
				var data: Dictionary = ending._shots[shot]
				var reveal_time: float = ending.FADE_IN
				for line in data.lines:
					var width: float = ending.FONT.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x / 2.0
					assert(width <= ending.TEXT_WIDTH)
					reveal_time += line.length() / ending.CHARS_PER_SECOND + ending.LINE_PAUSE
				assert(data.duration >= reveal_time + 1.0)
				assert(ending._shot == shot)
				ending._process(data.duration - 0.01)
				assert(ending._shot == shot)
				ending._process(0.02)
			assert(ending.results_visible())
			ending._process(120.0)
			assert(ending.results_visible())
			# Space advances, release/repeat are ignored, Escape skips, results remain.
			ending._shot = 0
			var key := InputEventKey.new()
			key.keycode = KEY_SPACE
			ending._unhandled_input(key)
			assert(ending._shot == 0)
			key.pressed = true
			key.echo = true
			ending._unhandled_input(key)
			assert(ending._shot == 0)
			key.echo = false
			ending._unhandled_input(key)
			assert(ending._shot == 1)
			key.keycode = KEY_ESCAPE
			ending._unhandled_input(key)
			assert(ending.results_visible())
			key.keycode = KEY_SPACE
			ending._unhandled_input(key)
			assert(ending.results_visible())
			ending.free()
	# Repeated/unknown identifiers must not accidentally count as three rescued children.
	var sanitized = ending_script.new()
	var repeated: Array[String] = ["Tina 2003", "Tina 2003", "unknown"]
	sanitized.setup(repeated, -1, -1, -1.0, true)
	assert(sanitized._rescue_mask == 4 and sanitized._candies.size() == 1)
	assert(sanitized._fails == 0 and sanitized._attempts == 0 and sanitized._tape == 0.0)
	assert(sanitized._unlisted_tape)
	sanitized.free()
	# Exercise the real game handoff for every rescued set, not only the ending in isolation.
	var main = load("res://rewind/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	main._intro.free()
	main.intro_music.stop()
	for mask in range(8):
		main._debug_jump(0)
		main.candies.assign(_candies_for(mask))
		main.total_fails = 2
		main.tape_used = 47.5
		main._secret_found = true
		main._end()
		assert(main.state == main.State.ENDING)
		assert(main._ending._rescue_mask == mask)
		assert(main._ending._candies == _candies_for(mask))
		assert(main._ending._fails == 2)
		assert(main._ending._attempts == 4)
		assert(main._ending._tape == 47.5)
		assert(main._ending._unlisted_tape)
		assert(main.world.scale == Vector2(2, 2))
		assert(not main.hud.visible)
		await process_frame
	main._ending._shot = main._ending._shots.size() - 1
	var restart := InputEventKey.new()
	restart.pressed = true
	restart.keycode = KEY_R
	restart.physical_keycode = KEY_R
	assert(restart.is_action_pressed("restart"))
	main._unhandled_input(restart)
	await process_frame
	await process_frame
	assert(current_scene != main)
	assert(current_scene.state == current_scene.State.INTRO)
	current_scene.free()
	current_scene = null
	# Let the audio server release the restarted intro's playback streams before exit.
	await create_timer(0.1).timeout
	print("ENDING CHECK PASSED: all 8 rescue sets, exact cast/reunions, all textures, readable timed captions, next/skip, persistent results, real game handoff and R restart")
	call_deferred("quit")
