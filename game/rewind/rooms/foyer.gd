extends Room
## The Last House: the foyer, and the whole tutorial. Two screens long, one lesson each:
## Play/Pause; the first pumpkin always catches the kid on the first play (a planned lesson) and
## teaches Rewind (the first one is free); the second pumpkin has no marked window and holds the
## Maja 1989 candy; the clock door only opened early in the recording, so the house has to be
## wound back a long way (SHIFT is faster); the damaged wall teaches Glitch, and can't kill,
## but the glitch damages the film and lets out bats that fly at the kid and have to pass over it.

const WALL := preload("res://assets/rewind/cinematic/wall.png")
const WAINSCOT := preload("res://assets/rewind/cinematic/wainscot.png")
const FLOOR_TEX := preload("res://assets/rewind/cinematic/floor.png")
const DOOR_ART := preload("res://rewind/door_art.gd")
const COAT_RACK := preload("res://assets/rewind/cinematic/coat-rack-states.png")
const CANDLE := preload("res://assets/rewind/cinematic/candle.png")
const CANDLE_SHORT := preload("res://assets/rewind/cinematic/candle-short.png")
const CANDLE_DOUBLE := preload("res://assets/rewind/cinematic/candle-double.png")
const CLOCK := preload("res://assets/noble_interior/clock_tall.png")
const TABLE := preload("res://assets/noble_interior/table_side.png")
const CABINET := preload("res://assets/noble_interior/cabinet_tall.png")
const ARMCHAIR := preload("res://assets/noble_interior/armchair_tall.png")
const WARDROBE := preload("res://assets/noble_interior/wardrobe_small.png")

const WARM := Color(0.8, 0.72, 0.88)
const CLOCK_DOOR_X := 330.0
const WALL_X := 470.0
const BAT_X := 524.0
const EXIT_X := 600.0


func build() -> void:
	title = "THE LAST HOUSE"
	width = 640.0
	tape_budget = 42.0
	timeline_length = 30.0
	free_first_rewind = true
	glitch_from_x = 390.0

	add_tiled(WALL, Rect2(0, 0, width, 104), Color(0.72, 0.64, 0.58))  # faded floral wallpaper
	add_tiled(WAINSCOT, Rect2(0, 104, width, 32), Color(0.88, 0.78, 0.7), 32.0)
	add_tiled(FLOOR_TEX, Rect2(0, FLOOR, width, 44), Color(0.9, 0.8, 0.72))
	for x in [86, 230, 412, 560]:
		var picture := add_wall_decor(WallDecor.Kind.PORTRAIT, Vector2(x, 88), int(x / 70))
		picture.rotation = -0.06 if x == 412 else 0.025
	for x in [136, 362, 510]:
		add_wall_decor(WallDecor.Kind.SCONCE, Vector2(x, 96))
	add_wall_decor(WallDecor.Kind.WEB, Vector2(2, 73), 1)
	add_wall_decor(WallDecor.Kind.WEB, Vector2(638, 73), 1, true)
	add_wall_decor(WallDecor.Kind.WEB, Vector2(282, 73))
	add_wall_decor(WallDecor.Kind.SCRATCHES, Vector2(436, 94))
	add_drawing(_entrance_door, Vector2(0, FLOOR))
	add_drawing(_coat_rack, Vector2(54, FLOOR + 3.0))
	add_furniture(TABLE, 168, WARM)
	add_furniture(CABINET, 262, WARM)
	add_furniture(CLOCK, 306, WARM)
	add_furniture(ARMCHAIR, 392, WARM)
	add_furniture(WARDROBE, 540, WARM)
	# Unevenly burned singles and close pairs share the furniture's surface baseline.
	add_drawing(_candle.bind(2), Vector2(162, FLOOR - 18.5))
	add_drawing(_candle.bind(1), Vector2(176, FLOOR - 18.5))
	add_drawing(_candle, Vector2(258, FLOOR - 30))
	add_drawing(_candle.bind(1), Vector2(268, FLOOR - 30))
	add_drawing(_candle.bind(3), Vector2(538, FLOOR - 28))
	add_drawing(_date_graffiti, Vector2(150, 87))

	# Play, Pause, Rewind.
	add_object(_pumpkin(4.0, 2.8, 4.0, true, 1.0, Color.WHITE), 100)
	# Reading a hazard without timeline marks, and a candy.
	add_object(_pumpkin(2.2, 0.0, 1.0, false, 1.5, Color(1.0, 0.82, 0.62)), 210)
	var maja := Candy.new()
	maja.candy_name = "Maja 1989"
	maja.period = 2.2
	maja.from = 1.35
	maja.to = 1.6
	maja.lift = 9.0
	add_object(maja, 218)
	# Winding the house back a long way, and scrubbing.
	var clock_door := ClockDoor.new()
	clock_door.open_from = 5.0
	clock_door.open_to = 8.0
	add_object(clock_door, CLOCK_DOOR_X)
	# Glitch. If the kid gets there first it just waits at the wall.
	add_object(FalseWall.new(), WALL_X)
	var tear := GlitchSpot.new()
	tear.glitch_id = "wall"
	tear.area = FalseWall.AREA.grow(2)
	tear.period = 4.0
	tear.from = 2.0
	tear.to = 3.0
	tear.kid_min = glitch_from_x
	add_object(tear, WALL_X)
	# The glitch tears the film and lets bats out; each one has to fly over the kid, not into it.
	add_object(Bat.new(), BAT_X)
	add_object(Door.new(), EXIT_X)


## Hand-sprayed date: uneven strokes, soft overspray and a few runs of wet paint.
func _date_graffiti(d: Node2D) -> void:
	var strokes := [
		PackedVector2Array([Vector2(0, 2), Vector2(3, 0), Vector2(6, 1), Vector2(5, 5), Vector2(2, 6), Vector2(5, 6), Vector2(6, 9), Vector2(4, 12), Vector2(0, 11)]),
		PackedVector2Array([Vector2(9, 3), Vector2(12, 0), Vector2(11, 12)]),
		PackedVector2Array([Vector2(15, 13), Vector2(21, -1)]),
		PackedVector2Array([Vector2(23, 3), Vector2(26, 1), Vector2(25, 12)]),
		PackedVector2Array([Vector2(32, 0), Vector2(29, 2), Vector2(28, 9), Vector2(30, 12), Vector2(33, 11), Vector2(35, 4), Vector2(34, 1), Vector2(32, 0)]),
	]
	# Repeatable speckles stay attached to the wallpaper even when the tape moves.
	var spray := RandomNumberGenerator.new()
	spray.seed = 3110
	for stroke in strokes:
		d.draw_polyline(stroke, Color(0.83, 0.81, 0.72, 0.055), 4.0, true)
		d.draw_polyline(stroke, Color(0.87, 0.85, 0.76, 0.16), 2.6, true)
		d.draw_polyline(stroke, Color(0.91, 0.89, 0.8, 0.78), 1.25, true)
		for segment in range(stroke.size() - 1):
			for dot in 9:
				var p: Vector2 = stroke[segment].lerp(stroke[segment + 1], spray.randf())
				p += Vector2(spray.randfn(0, 1.2), spray.randfn(0, 1.2))
				d.draw_circle(p, spray.randf_range(0.12, 0.35), Color(0.89, 0.86, 0.77, spray.randf_range(0.12, 0.38)), true, -1, true)
	for drip in [Vector3(4, 11, 5), Vector3(11, 10, 3), Vector3(30, 11, 4)]:
		var start := Vector2(drip.x, drip.y)
		var end := start + Vector2(-0.3, drip.z)
		d.draw_line(start, end, Color(0.88, 0.85, 0.76, 0.5), 0.6, true)
		d.draw_circle(end, 0.45, Color(0.9, 0.87, 0.78, 0.65), true, -1, true)


func trigger_hints() -> Array:
	return [
		{"x": 40.0, "text": "D again = PAUSE. PAUSE doesn't use tape.", "button": "pause", "keys": ["D"], "hold": false, "done": "pause"},
		{"x": 140.0, "text": "This pumpkin isn't on the timeline. Watch for when it starts shaking."},
		{"x": 196.0, "text": "Pink window = candy. Gives back 2 s of tape."},
		{"x": 280.0, "text": "The door is only open 0:05-0:08. SHIFT + A rewinds faster.", "button": "rew", "keys": ["SHIFT", "A"], "done": "fast_rewind"},
		{"x": 345.0, "text": "FF moves the house forward, but only through footage you've seen.", "button": "ff", "keys": ["F"], "done": "scrub"},
		{"x": 390.0, "text": "When the picture tears (cyan), press E. A glitch costs 3 s.", "button": "track", "keys": ["E"], "hold": false, "done": "glitch"},
		{"x": 486.0, "text": "The glitch damaged the film. Bats fly out at you: let each one pass while it is up high."},
	]


func _pumpkin(period: float, from: float, to: float, marks: bool, size: float, tint: Color) -> Pumpkin:
	var p := Pumpkin.new()
	p.period = period
	p.bite_from = from
	p.bite_to = to
	p.show_marks = marks
	p.size = size
	p.tint = tint
	return p


func _entrance_door(d: Node2D) -> void:
	DOOR_ART.draw_door(d, Rect2(-2, -64, 36, 64), false, Color(1.0, 0.65, 0.25, 0.6))


## The fourth hook fills with a child's costume after the second failed attempt.
func _coat_rack(d: Node2D) -> void:
	var height := 48.0
	var frame := 1 if total_fails >= 2 else 0
	# Both atlas cells share the same crop, so switching preserves the rack's baseline.
	var source := Rect2(frame * 768 + 48, 24, 672, 960)
	# An even pixel width keeps both edges aligned with the room's pixel grid.
	var rack_width := roundf(height * source.size.x / source.size.y / 2.0) * 2.0
	d.draw_texture_rect_region(COAT_RACK, Rect2(-rack_width / 2.0, -height, rack_width, height), source)


func _candle(d: Node2D, variant := 0) -> void:
	if variant == 3:
		d.draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	var texture: Texture2D = CANDLE
	var source := Rect2(204, 306, 480, 1294)
	var destination := Rect2(-3, -16, 6, 16)
	var flames := [Vector2(0, -14)]
	if variant == 1:
		texture = CANDLE_SHORT
		source = Rect2(204, 430, 752, 788)
		destination = Rect2(-3.5, -7.5, 7, 7.5)
		flames = [Vector2(0, -6)]
	elif variant >= 2:
		texture = CANDLE_DOUBLE
		source = Rect2(76, 158, 944, 1140)
		destination = Rect2(-6, -14, 12, 14)
		flames = [Vector2(-1.5, -12), Vector2(2.25, -8)]
	# Each wick has its own soft light and flicker, including both flames in a pair.
	for flame in flames:
		var phase: float = d.position.x * 0.37 + flame.x * 1.7 + variant
		var flicker := 0.88 + 0.12 * sin(d.t * 9.0 + phase) * sin(d.t * 6.3 + phase)
		var strength := 0.7 if variant == 1 else 1.0
		for i in 8:
			d.draw_circle(flame, (15.0 - i * 1.6) * flicker * strength, Color(1.0, 0.57, 0.16, (0.008 + i * 0.003) * flicker * strength))
	# Cropped transparent margins keep every brass base seated on the furniture.
	d.draw_texture_rect_region(texture, destination, source)
	d.draw_set_transform(Vector2.ZERO)
