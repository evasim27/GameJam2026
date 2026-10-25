# Verify actual scene frames, pause/rewind determinism, and the blade's danger window.
# godot --headless --path game --script res://tools/check_sword_guards.gd
extends SceneTree


func _init() -> void:
	call_deferred("_check_guards")


func _check_guards() -> void:
	var room: Room = load("res://rewind/rooms/stairs.gd").new()
	room.setup(0, 0)
	root.add_child(room)
	await process_frame
	var count := 0
	for object in room.objects:
		if not object is SwordGuard:
			continue
		var guard := object as SwordGuard
		assert(guard.kind == SwordGuard.Kind.SKELETON, "Level two uses two skeletons")
		var run := RoomRun.new(room)
		var recorded: Array[int] = []
		# Record forward, then revisit every moment backwards on the same live sprite.
		for tick in 2521:
			run.room_time = tick / 60.0
			guard.show_time(run)
			var frame := guard._sprite.frame
			recorded.append(frame)
			assert(guard.is_deadly(run.room_time) == (frame == 3 or frame == 4))
		for tick in range(2520, -1, -1):
			run.room_time = tick / 60.0
			guard.show_time(run)
			assert(guard._sprite.frame == recorded[tick], "Rewind must restore the same pose")
		assert(not guard._sprite.is_playing(), "The recording clock must own the animation")
		run.room_time = guard.swing_from + 0.2
		guard.show_time(run)
		var paused_frame := guard._sprite.frame
		await process_frame
		await process_frame
		assert(guard._sprite.frame == paused_frame, "Pause must freeze the wind-up")
		# Rewinding while standing in reach can bring the blade back into the kid.
		run.kid_x = guard.position.x + guard.width / 2.0
		run.room_time = guard.swing_from + SwordGuard.STRIKE_TO + 0.1
		assert(not guard.kills(run))
		assert(run.rewind(0.2) == "fail" and run.cause == guard)
		count += 1
	assert(count == 2, "The extended room needs two skeletons")
	assert(room.width == 800.0)
	print("OK: both guards match lethal frames, pause, rewind, and the extended level layout")
	room.free()
	quit()
