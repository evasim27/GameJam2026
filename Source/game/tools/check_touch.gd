extends SceneTree
## Run with --headless --path Source/game --script res://tools/check_touch.gd.


func _initialize() -> void:
	call_deferred("_check")


func _touch(point: Vector2, pressed: bool, index := 0) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	root.push_input(event, true)
	await process_frame
	await process_frame


func _tap(point: Vector2) -> void:
	await _touch(point, true)
	await _touch(point, false)


func _click(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
		await process_frame


func _check() -> void:
	create_timer(20.0).timeout.connect(func(): quit(1))
	var game = load("res://rewind/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var hud: Control = game.hud
	var middle := Vector2(320, 120)

	await _click(game._start_menu._play_button.get_global_rect().get_center())
	assert(game.state == game.State.INTRO)
	var shot: int = game._intro._shot()
	await _tap(middle)
	assert(game.state != game.State.INTRO or game._intro._shot() == shot + 1)
	game._intro._finish()
	await process_frame
	assert(game.state == game.State.ROOM and not game._playing)

	var play: Vector2 = hud._button_rect("play").get_center()
	var pause: Vector2 = hud._button_rect("pause").get_center()
	await _tap(pause)
	assert(not game._playing)
	await _tap(play)
	assert(game._playing and hud.mode == "PLAY")
	await _tap(play)
	assert(game._playing)
	await _click(pause)
	assert(not game._playing and hud.mode == "PAUSE")
	# Taps on the picture do nothing during gameplay.
	await _tap(middle)
	assert(not game._playing)

	game._rewind_unlocked = true
	game._update_controls()
	await _click(play)
	for i in 20:
		await process_frame
	var rew: Vector2 = hud._button_rect("rew").get_center()
	await _touch(rew, true, 1)
	assert(Input.is_action_pressed("tape_rewind") and hud.mode == "REW")
	await create_timer(1.0).timeout
	assert(Input.is_action_pressed("tape_fast") and hud.mode == "SCRUB-")
	await _touch(rew, false, 1)
	assert(not Input.is_action_pressed("tape_rewind") and not Input.is_action_pressed("tape_fast"))
	assert(hud.mode == "PAUSE")

	game.queue_free()
	await create_timer(0.1).timeout
	print("TOUCH OK: start menu click, tap advances intro, PLAY/PAUSE taps, hold REW for fast rewind")
	quit()
