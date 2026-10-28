extends SceneTree
## Run with --headless --path Source/game --script res://tools/check_start_menu.gd.


func _initialize() -> void:
	call_deferred("_check")


func _key(keycode: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = keycode
		event.physical_keycode = keycode
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame


func _click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame


func _check() -> void:
	create_timer(15.0).timeout.connect(func(): quit(1))
	var master := AudioServer.get_bus_index("Master")
	var original_mute := AudioServer.is_bus_mute(master)
	AudioServer.set_bus_mute(master, false)
	var game = load("res://rewind/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	assert(game.state == game.State.MENU)
	assert(game._intro == null and game.room == null and game.run == null)
	assert(not game.intro_music.playing and not game.hud.visible)
	game._process(120.0)
	for key in [KEY_D, KEY_R, KEY_ESCAPE]:
		await _key(key)
	assert(game.state == game.State.MENU and game._intro == null)
	assert(not game._ambient_music.playing and not game._ambient_hiss.playing)

	var menu: Control = game._start_menu
	assert(root.gui_get_focus_owner() == menu._play_button)
	await _key(KEY_DOWN)
	assert(root.gui_get_focus_owner() == menu._mute_button)
	await _key(KEY_ENTER)
	assert(AudioServer.is_bus_mute(master) and menu._mute_button.text == "UNMUTE")
	assert(game.state == game.State.MENU and not game.intro_music.playing)
	await _click(menu._mute_button)
	assert(not AudioServer.is_bus_mute(master) and menu._mute_button.text == "MUTE")
	await _click(menu._mute_button)
	assert(AudioServer.is_bus_mute(master))
	await _key(KEY_UP)
	assert(root.gui_get_focus_owner() == menu._play_button)
	await _key(KEY_SPACE)
	assert(game.state == game.State.INTRO and game._start_menu == null)
	assert(game.intro_music.playing and game._intro._t < 1.0)
	assert(AudioServer.is_bus_mute(master))
	await _key(KEY_ESCAPE)
	assert(game.state == game.State.ROOM and game.room_index == 0)
	assert(game.hud.visible and not game._playing)
	assert(AudioServer.is_bus_mute(master))
	game.queue_free()
	await process_frame

	# A pre-existing master mute must be reflected when the menu is opened again.
	game = load("res://rewind/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	assert(game._start_menu._mute_button.button_pressed)
	assert(game._start_menu._mute_button.text == "UNMUTE")
	await _click(game._start_menu._play_button)
	assert(game.state == game.State.INTRO and game._start_menu == null)
	game.queue_free()
	await process_frame
	AudioServer.set_bus_mute(master, original_mute)
	await create_timer(0.1).timeout
	print("START MENU OK: startup waits silently, keyboard/mouse controls, mute/unmute, PLAY starts intro, skip reaches paused gameplay")
	quit()
