extends SceneTree
## Exercise soundtrack transitions and actual loop boundaries without changing gameplay.

func _initialize() -> void:
	call_deferred("_check")


func _check() -> void:
	var game = load("res://rewind/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	assert(not game._ambient_music.playing and not game._ambient_hiss.playing)
	game._debug_jump(0)
	game.hud.clear_texts()
	game.hud.mode = "PLAY"
	game._update_ambience(2.0)
	assert(game._ambient_music.playing and game._ambient_hiss.playing)
	assert(game._ambient_music.volume_db <= -27 and game._ambient_hiss.volume_db <= -38)
	assert(not game.SFX["static"].loop)
	assert(game.GAMEPLAY_MUSIC.loop_mode == AudioStreamWAV.LOOP_DISABLED)
	# Both ambient layers must keep playing after crossing their real audio boundaries.
	game._ambient_music.seek(game._ambient_music.stream.get_length() - 0.2)
	game._ambient_hiss.seek(game._ambient_hiss.stream.get_length() - 0.2)
	await create_timer(0.8).timeout
	assert(game._ambient_music.playing and game._ambient_hiss.playing)
	assert(game._ambient_music.get_playback_position() < 2.0)
	assert(game._ambient_hiss.get_playback_position() < 2.0)
	var previous_position: float = game._ambient_music.get_playback_position()
	game._debug_jump(1)
	await create_timer(0.15).timeout
	assert(game._ambient_music.get_playback_position() >= previous_position)
	game.hud.clear_texts()
	game.hud.mode = "PAUSE"
	game._update_ambience(2.0)
	assert(is_equal_approx(game._ambient_music.volume_db, -31.0))
	game._sound("ping")
	game._update_ambience(0.2)
	assert(game._ambient_music.volume_db < -31.0 and game._ambient_hiss.volume_db < -42.0)
	game._debug_jump(0)
	game._enter_forbidden()
	assert(game._ambient_music.stream == game._secret_music_loop)
	assert(game._ambient_music.stream != game._gameplay_music_loop)
	game._start_forbidden_video()
	assert(not game._ambient_music.playing and not game._ambient_hiss.playing)
	assert(game._forbidden_video._music.playing)
	assert(game._forbidden_video.MUSIC == game.SECRET_MUSIC)
	game._forbidden_video._process(1.0)
	assert(game._forbidden_video._voice.playing)
	assert(is_equal_approx(game._forbidden_video._music.volume_db, -20.0))
	game._forbidden_video.skip()
	assert(not game._forbidden_video._voice.playing and not game._forbidden_video._music.playing)
	game._return_from_forbidden()
	game._update_ambience(0.1)
	assert(game._ambient_music.stream == game._gameplay_music_loop)
	# Every rescue set must use the right chosen music-box theme, with no gameplay overlap.
	for mask in 8:
		game._debug_jump(0)
		game.candies.clear()
		for i in 3:
			if mask & (1 << i):
				game.candies.append(game.MEMORY_IDS[i])
		game._end()
		var ending = game._ending
		var expected: AudioStream = ending.EXCHANGE_MUSIC if mask == 7 else ending.REWIND_MUSIC
		assert(ending._music.playing and ending._music.stream.loop)
		assert(is_equal_approx(ending._music.stream.get_length(), expected.get_length()))
		assert(not game._ambient_music.playing and not game._ambient_hiss.playing)
		assert(not game.intro_music.playing)
		ending._process(2.0)
		assert(is_equal_approx(ending._music.volume_db, -18.0))
		ending._shot = ending._shots.size() - 1
		ending._process(0.5)
		assert(is_equal_approx(ending._music.volume_db, -27.0))
		await process_frame
	game._ending._music.seek(game._ending._music.stream.get_length() - 0.2)
	await create_timer(0.8).timeout
	assert(game._ending._music.playing)
	assert(game._ending._music.get_playback_position() < 2.0)
	game.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.1).timeout
	print("AUDIO OK: loop wraps, room continuity, pause/ducking, distinct secret/Jigsaw music, quiet under voice, clean skip/return, all 8 ending selections")
	quit()
