extends SceneTree

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var bat_script = load("res://rewind/objects/bat.gd")
	for i in range(4):
		var bat = bat_script.new()
		root.add_child(bat)
		bat.position = Vector2(90 + i * 100, 180)
		bat.scale = Vector2(3, 3)
		bat._since = 0.0
		bat._t = (i + 0.5) / 4.0 * TAU / 18.0
		bat._bats.append(Vector2(0, -44))
		bat.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var output = ProjectSettings.globalize_path("res://../tmp/bat-flight-render.png")
	root.get_texture().get_image().save_png(output)
	print("Bat drawing: all four wing poses rendered")
	quit()
