extends SceneTree
## Run: godot --headless --path game --script res://tools/check_ending.gd

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var ending_script = load("res://rewind/ending.gd")
	for candy_count in range(4):
		for fails in [0, 2]:
			var ending = ending_script.new()
			var candies: Array[String] = []
			for i in candy_count:
				candies.append(["Maja 1989", "Luka 1994", "Tina 2003"][i])
			ending.setup(candies, fails, 3 + fails, 47.5)
			root.add_child(ending)
			ending.set_process(false)
			assert(ending._images.size() == 7)
			for texture in ending._images:
				assert(texture != null)
			for shot in range(6):
				assert(ending._shot == shot)
				ending._process(ending.SHOTS[shot].duration)
			assert(ending.results_visible())
			ending._process(120.0)
			assert(ending.results_visible())
			ending._shot = 0
			var key := InputEventKey.new()
			key.pressed = true
			key.keycode = KEY_SPACE
			ending._unhandled_input(key)
			assert(ending._shot == 1)
			key.keycode = KEY_ESCAPE
			ending._unhandled_input(key)
			assert(ending.results_visible())
			ending.free()
	# Check the actual game handoff and the supplied run statistics.
	var main = load("res://rewind/main.tscn").instantiate()
	root.add_child(main)
	main._intro.queue_free()
	main._enter_room(0, false)
	main.candies.assign(["Maja 1989", "Luka 1994", "Tina 2003"])
	main.total_fails = 2
	main.tape_used = 47.5
	main._end()
	assert(main._ending._candies.size() == 3)
	assert(main._ending._fails == 2)
	assert(main._ending._tape == 47.5)
	assert(main.world.scale == Vector2(2, 2))
	assert(not main.hud.visible)
	main.free()
	print("ENDING CHECK PASSED: 0–3 candies, optional echoes, seven shots, next/skip, persistent results, game handoff")
	quit()
