extends SceneTree
## Prepare the generated stair art on the furniture's half-room-pixel grid.
## Run: Godot --headless --path Source/game --script res://tools/export_front_stairs.gd

func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path("res://../assets/front_stairs/front-stairs-source.png"))
	assert(source != null and not source.is_empty())
	var image := source.get_region(source.get_used_rect())
	# Five 12 px treads correspond to five 6-unit steps in the room.
	image.resize(60, 28, Image.INTERPOLATE_NEAREST)
	var path := "res://assets/rewind/cinematic/front-stairs.png"
	assert(image.save_png(ProjectSettings.globalize_path(path)) == OK)
	print("Exported foreground staircase: ", path, " (60x28, original alpha retained)")
	quit()
