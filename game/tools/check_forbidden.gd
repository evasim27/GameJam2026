extends SceneTree
## Quick integration check for the optional room and the return to the foyer.

const MAIN := preload("res://rewind/main.tscn")


func _initialize() -> void:
	call_deferred("_check")


func _check() -> void:
	var game := MAIN.instantiate()
	root.add_child(game)
	await process_frame
	game._debug_jump(0)
	await process_frame
	assert(game.room_index == 0)
	assert(not game._can_enter_forbidden())
	game.run.kid_x = 313.0
	game.run.room_time = 6.5
	game.run.seen_time = 9.0
	game._show()
	assert(game._can_enter_forbidden())
	var original_run: RoomRun = game.run
	game._enter_forbidden()
	assert(game.run == original_run)
	assert(not game.room.visible)
	assert(game._forbidden != null)
	assert(game.world.scale == Vector2(2, 2))
	assert(game.hud.cinematic_mode)
	game._process(0.1)
	assert(is_zero_approx(game.world.position.y))
	game._forbidden.walk_x = game._forbidden.TAPE_X - 0.1
	game._forbidden.playing = true
	game._forbidden._process(0.1)
	assert(game._forbidden.at_tape)
	game._start_forbidden_video()
	assert(game._forbidden_video != null)
	game._forbidden_video._process(1.0)
	assert(game._forbidden_video._voice.playing)
	game._forbidden_signal_lost()
	assert(game.state == game.State.FORBIDDEN_LOST)
	assert(game.hud.message == "YOU WEREN'T MEANT TO SEE THAT")
	assert(not game.hud.cinematic_mode)
	game._secret_lost_t = 0.01
	game._process(0.05)
	assert(game.run == original_run)
	assert(game.room.visible)
	assert(is_equal_approx(game.run.room_time, 6.5))
	assert(is_equal_approx(game.run.kid_x, 313.0))
	assert(game._secret_found and game._secret_visited)
	assert(not game._can_enter_forbidden())
	print("FORBIDDEN ROOM: entry, tape and return OK")
	game.queue_free()
	await process_frame
	quit()
