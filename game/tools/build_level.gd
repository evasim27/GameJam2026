# Generates res://assets/tileset.tres and res://scenes/main.tscn from the ASCII map below.
# Run: godot --headless --path . --script res://tools/build_level.gd
# After that the level can be edited normally in the Godot editor.
extends SceneTree

const TILE := 18
const TILES_TEX := "res://assets/kenney_pixel_platformer/tilemap_packed.png"
const BG_TEX := "res://assets/kenney_pixel_platformer/tilemap-backgrounds_packed.png"

# '#' ground  'P' player  '^' spikes  'D' exit door (bottom half)
# 'm' mushroom  's' sprout  'g' signpost
const MAP := [
	"................................................",
	"................................................",
	"................................................",
	"................................................",
	"................................................",
	"................................................",
	"................................................",
	"................................................",
	"................................................",
	".............................................D..",
	"#........................................#######",
	"#..............................................#",
	"#.................................####.........#",
	"#..............................................#",
	"#...........................###................#",
	"#.................##...........................#",
	"#..P.g..s.........##..^^^^....m.........s......#",
	"############....################################",
	"############....################################",
	"############....################################",
]

const DECOR := {"m": Vector2i(8, 6), "s": Vector2i(4, 6), "g": Vector2i(6, 4)}


func _init() -> void:
	var tileset := _build_tileset()
	ResourceSaver.save(tileset, "res://assets/tileset.tres")
	tileset = load("res://assets/tileset.tres")

	var root := Node2D.new()
	root.name = "Main"
	root.set_script(load("res://scripts/main.gd"))

	_add_background(root)

	var terrain := TileMapLayer.new()
	terrain.name = "Terrain"
	terrain.tile_set = tileset
	terrain.modulate = Color(0.78, 0.72, 0.92)
	_add(root, terrain)

	var decor := TileMapLayer.new()
	decor.name = "Decor"
	decor.tile_set = tileset
	decor.modulate = Color(0.78, 0.72, 0.92)
	_add(root, decor)

	var spikes_scene: PackedScene = load("res://scenes/spikes.tscn")
	var spikes_root := Node2D.new()
	spikes_root.name = "Spikes"
	_add(root, spikes_root)

	for y in MAP.size():
		var row: String = MAP[y]
		for x in row.length():
			var c := row[x]
			var center := Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)
			match c:
				"#":
					terrain.set_cell(Vector2i(x, y), 0, _ground_tile(x, y))
				"^":
					var s := spikes_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
					s.name = "Spike%d" % (spikes_root.get_child_count() + 1)
					s.position = center
					_add(spikes_root, s, false)
				"P":
					var p: Node2D = load("res://scenes/player.tscn").instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
					p.position = center
					_add(root, p, false)
				"D":
					var d: Node2D = load("res://scenes/exit_door.tscn").instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
					d.name = "ExitDoor"
					d.position = center - Vector2(0, TILE / 2.0)
					_add(root, d, false)
				_:
					if DECOR.has(c):
						decor.set_cell(Vector2i(x, y), 0, DECOR[c])

	# Keep the player drawn above everything else in the level.
	root.move_child(root.get_node("Player"), -1)
	_add_hud(root)

	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/main.tscn")
	root.free()
	print("Level built.")
	quit()


func _add(parent: Node, child: Node, own_children := true) -> void:
	parent.add_child(child)
	child.owner = parent.owner if parent.owner else parent
	if own_children:
		for c in child.get_children():
			c.owner = child.owner


func _solid(x: int, y: int) -> bool:
	if y >= MAP.size():
		return true
	if y < 0 or x < 0 or x >= MAP[y].length():
		return false
	return MAP[y][x] == "#"


# Picks the Kenney ground tile with the right borders for this cell.
func _ground_tile(x: int, y: int) -> Vector2i:
	var up := _solid(x, y - 1)
	var down := _solid(x, y + 1)
	var left := _solid(x - 1, y)
	var right := _solid(x + 1, y)
	var col := 0
	if left and right:
		col = 2
	elif right:
		col = 1
	elif left:
		col = 3
	var row := 2
	if not up and down:
		row = 3
	elif up and down:
		row = 6
	elif up and not down:
		row = 7
	return Vector2i(col, row)


func _build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()

	var src := TileSetAtlasSource.new()
	src.texture = load(TILES_TEX)
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)

	var h := TILE / 2.0
	var square := PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])
	for row in [2, 3, 6, 7]:
		for col in 4:
			var coords := Vector2i(col, row)
			src.create_tile(coords)
			var data := src.get_tile_data(coords, 0)
			data.add_collision_polygon(0)
			data.set_collision_polygon_points(0, 0, square)
	for coords in DECOR.values():
		src.create_tile(coords)
	return ts


func _add_background(root: Node2D) -> void:
	var sky := ColorRect.new()
	sky.name = "Sky"
	sky.color = Color(0.043, 0.035, 0.07)
	var bg_layer := CanvasLayer.new()
	bg_layer.name = "SkyLayer"
	bg_layer.layer = -10
	_add(root, bg_layer)
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	_add(bg_layer, sky)

	var parallax := Parallax2D.new()
	parallax.name = "Hills"
	parallax.scroll_scale = Vector2(0.3, 1.0)
	parallax.repeat_size = Vector2(96 * 5, 0)
	parallax.repeat_times = 3
	_add(root, parallax)

	var hills := Sprite2D.new()
	hills.name = "Sprite2D"
	hills.texture = load(BG_TEX)
	hills.centered = false
	hills.region_enabled = true
	hills.region_rect = Rect2(0, 0, 96, 72)
	hills.scale = Vector2(5, 5)
	hills.modulate = Color(0.17, 0.13, 0.27)
	_add(parallax, hills)


func _add_hud(root: Node2D) -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	_add(root, hud)

	var title := Label.new()
	title.name = "Title"
	title.text = "CRYPT 1-1 · THE STACK"
	title.position = Vector2(10, 6)
	title.add_theme_color_override("font_color", Color(0.92, 0.89, 0.81))
	_add(hud, title)

	var heap := Label.new()
	heap.name = "Heap"
	heap.text = "HEAP 0/4"
	heap.position = Vector2(560, 6)
	heap.add_theme_color_override("font_color", Color(0.65, 1.0, 0.56))
	_add(hud, heap)

	var status := Label.new()
	status.name = "Status"
	status.text = "A/D move · SPACE jump · R restart"
	status.position = Vector2(10, 22)
	status.add_theme_color_override("font_color", Color(0.6, 0.56, 0.68))
	_add(hud, status)
