extends Room
## Static below the stairs. One fall leaves an echo in the hole; the next take can cross it.
## Two skeletons guard the extended hallway with differently timed sword swings.
## Then the stairs: a shadow slides across the foot of the stairs on a rhythm, then a
## short safe stretch by a small TV full of static. Glitching while the kid is at the TV and the
## frame tears shifts the wardrobe and shows a hidden door under the stairs. Ignore it and the kid
## goes up the stairs into the long shadow. Opening the door releases diving bats, just like
## the foyer wall. Luka 1994 waits behind the door if it opened early.

const WALL := preload("res://assets/rewind/cinematic/wall.png")
const WAINSCOT := preload("res://assets/rewind/cinematic/wainscot.png")
const FLOOR_TEX := preload("res://assets/rewind/cinematic/floor.png")
const STAIRS_ART := preload("res://assets/rewind/cinematic/stairs.png")
const TV_ART := preload("res://assets/rewind/cinematic/crt-unplugged.png")
const COSTUME_GHOST := preload("res://assets/rewind/costumes_level2/ghost.png")
const COSTUME_WIZARD := preload("res://assets/rewind/costumes_level2/wizard.png")
const COSTUME_BAT := preload("res://assets/rewind/costumes_level2/bat.png")
const WARDROBE := preload("res://assets/noble_interior/wardrobe_small.png")
const DOOR_ART := preload("res://rewind/door_art.gd")
const FALL_INSCRIPTION := preload("res://assets/rewind/cinematic/fall-wood-inscription.png")
const CRATE_STACK := preload("res://assets/rewind/cinematic/crate-stack.png")

## The hallway with the hole; everything under the stairs starts after it.
const HALL := 480.0
const HOLE_X := 120.0
const SKELETON_X := 200.0
const SECOND_SKELETON_X := 360.0
const STAIRS_FROM := HALL + 276.0
const TV_X := HALL + 150.0
const DOOR_X := HALL + 230.0

var _tv_noise := 0.0


func build() -> void:
	title = "STATIC BELOW THE STAIRS"
	width = HALL + WIDTH
	tape_budget = 42.0
	timeline_length = 42.0

	add_tiled(WALL, Rect2(0, 0, width, 104), Color(0.42, 0.44, 0.56))
	add_tiled(WAINSCOT, Rect2(0, 104, width, 32), Color(0.58, 0.6, 0.72), 32.0)
	add_tiled(FLOOR_TEX, Rect2(0, FLOOR, width, 44), Color(0.68, 0.7, 0.8))
	add_drawing(_photos, Vector2(14, 84))
	add_drawing(_back_stairs, Vector2(HALL, 0))
	# The hallway: a couple of sconces and a crooked portrait looking down at the hole.
	add_wall_decor(WallDecor.Kind.SCONCE, Vector2(64, 96))
	add_wall_decor(WallDecor.Kind.SCONCE, Vector2(208, 96))
	add_wall_decor(WallDecor.Kind.SCONCE, Vector2(324, 92))
	add_wall_decor(WallDecor.Kind.SCONCE, Vector2(452, 96))
	add_wall_decor(WallDecor.Kind.PORTRAIT, Vector2(280, 86), 2)
	add_wall_decor(WallDecor.Kind.PORTRAIT, Vector2(414, 86), 1)
	add_wall_decor(WallDecor.Kind.WEB, Vector2(384, 73))
	var watcher := add_wall_decor(WallDecor.Kind.PORTRAIT, Vector2(244, 86), 1)
	watcher.rotation = 0.05
	add_wall_decor(WallDecor.Kind.SCRATCHES, Vector2(188, 100))
	var portrait := add_wall_decor(WallDecor.Kind.PORTRAIT, Vector2(HALL + 112, 88), 2)
	portrait.rotation = -0.09
	add_wall_decor(WallDecor.Kind.SCONCE, Vector2(HALL + 70, 96))
	add_wall_decor(WallDecor.Kind.WEB, Vector2(2, 73), 1)
	add_wall_decor(WallDecor.Kind.WEB, Vector2(width - 2, 48), 0, true)
	add_wall_decor(WallDecor.Kind.SCRATCHES, Vector2(HALL + 178, 98))
	add_drawing(_crates, Vector2(HALL + 96, FLOOR))
	add_drawing(_cobwebs, Vector2(HALL, 0))
	add_drawing(_warm_spill)
	# Knife-cut grooves sit directly in the wooden panels below the wallpaper.
	var inscription := Sprite2D.new()
	inscription.texture = FALL_INSCRIPTION
	inscription.region_enabled = true
	inscription.region_rect = Rect2(FALL_INSCRIPTION.get_image().get_used_rect())
	inscription.centered = false
	# The zoomed gameplay camera crops the wall above y=60 while on the floor.
	inscription.position = Vector2(94, 113)
	var inscription_size := inscription.region_rect.size
	inscription.scale = Vector2.ONE * minf(44.0 / inscription_size.x, 15.0 / inscription_size.y)
	inscription.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_deco.add_child(inscription)

	var hole := Hole.new()
	hole.slots = 1
	add_object(hole, HOLE_X)

	var skeleton := SwordGuard.new()
	add_object(skeleton, SKELETON_X)
	var second_skeleton := SwordGuard.new()
	second_skeleton.period = 3.8
	second_skeleton.swing_from = 1.8
	add_object(second_skeleton, SECOND_SKELETON_X)
	# Repeated damaged frames release bats in both stretches of the hallway.
	for source in [Vector2(300.0, 6.2), Vector2(480.0, 12.0)]:
		var hallway_bats := Bat.new()
		hallway_bats.starts_at = source.y
		hallway_bats.period = 7.0
		hallway_bats.bob = 3.2
		hallway_bats.enter_x = source.x + 60.0
		hallway_bats.release_from_x = source.x - 180.0
		hallway_bats.release_to_x = source.x + 60.0
		hallway_bats.reach = 180.0
		hallway_bats.damage_duration = 0.75
		add_object(hallway_bats, source.x)

	var foot := Shadow.new()
	foot.width = 24.0
	foot.period = 3.2
	foot.from = 2.0
	foot.to = 3.0
	add_object(foot, HALL + 72)

	var tear := GlitchSpot.new()
	tear.glitch_id = "door"
	tear.area = Rect2(-6, -38, 32, 38)
	tear.period = 3.0
	tear.from = 1.6
	tear.to = 2.4
	tear.kid_min = HALL + 120.0
	tear.kid_max = HALL + 196.0
	add_object(tear, DOOR_X)
	# Keep their entrance close enough to meet the kid before the hidden exit.
	var bats := Bat.new()
	bats.needs_glitch = "door"
	bats.period = 1.5
	bats.damage_duration = 0.75
	bats.enter_x = DOOR_X + 56.0
	add_object(bats, DOOR_X)

	var luka := Candy.new()
	luka.candy_name = "Luka 1994"
	luka.needs_glitch = "door"
	luka.glitch_before_x = HALL + 160.0
	luka.lift = 8.0
	add_object(luka, DOOR_X - 2.0)

	var door := Door.new()
	door.visual_size = Vector2(30, 54)
	door.needs_glitch = "door"
	door.cover = WARDROBE
	# Clear of the door frame, still on the flat floor before the front stairs.
	door.cover_slide = Vector2(26, 0)
	door.light = Color(0.4, 1.0, 1.0)
	add_object(door, DOOR_X)

	add_drawing(_front_stairs)
	var top := Shadow.new()
	top.always = true
	top.width = 30.0
	top.height = 60.0
	top.hint_x = TV_X
	add_object(top, HALL + 290, floor_y(HALL + 290))
	add_drawing(_tv, Vector2(TV_X, FLOOR))


func floor_y(x: float) -> float:
	return FLOOR - maxf(x - STAIRS_FROM, 0.0) * 0.45


func trigger_hints() -> Array:
	return [
		{"x": HOLE_X - 50.0, "text": "The floor is gone. Your next take may need the last one."},
		{"x": SKELETON_X - 44.0, "text": "Watch the raised sword. Rewind the swing, then pass after the blade falls."},
		{"x": 248.0, "text": "The damaged tape keeps releasing bats. Watch their dives and rewind to pass beneath them."},
		{"x": SECOND_SKELETON_X - 44.0, "text": "Another skeleton. Its sword follows a different rhythm."},
		{"x": HALL + 120.0, "text": "The picture is damaged here. Try it.", "button": "track", "keys": ["E"], "hold": false, "done": "glitch"},
		{"x": TV_X + 12.0, "text": "Opening the hidden door releases bats. Rewind their dive so they pass above your head."},
	]


func retry_hint() -> String:
	var bridged := 0
	for g in ghosts:
		if g.get("bridge", false):
			bridged += 1
	if bridged >= 1:
		if not ghosts.is_empty():
			var last_x: float = ghosts[-1].x
			if last_x >= SKELETON_X and last_x <= SKELETON_X + 26.0:
				return "The skeleton raises its sword before it strikes. Change its timing from a safe distance."
			if last_x >= SECOND_SKELETON_X and last_x <= SECOND_SKELETON_X + 26.0:
				return "The second skeleton has its own rhythm. Rewind before you enter its sword's reach."
		if fails > bridged:
			return "At the TV, glitch the torn picture to find the door."
		return "Your last take is still here. Walk over its echo."
	return ""


func idle_hint_target(run: RoomRun) -> float:
	return DOOR_X if run.glitched.has("door") else TV_X


func show_run(run: RoomRun) -> void:
	super(run)
	_tv_noise = run.room_time


## The big staircase along the back wall; the dark space under it holds the junk and the TV.
func _back_stairs(d: Node2D) -> void:
	var under := PackedVector2Array([Vector2(60, FLOOR), Vector2(320, 30), Vector2(320, FLOOR)])
	d.draw_colored_polygon(under, Color(0.05, 0.03, 0.08, 0.75))
	var art_size := Vector2(260.0, 260.0 * STAIRS_ART.get_height() / STAIRS_ART.get_width())
	d.draw_texture_rect(STAIRS_ART, Rect2(Vector2(60, FLOOR - art_size.y), art_size), false)
	# A shadow that is far too long for the banister.
	d.draw_colored_polygon(PackedVector2Array([
		Vector2(200, 52), Vector2(320, 0), Vector2(320, 20), Vector2(230, 64)]), Color(0, 0, 0, 0.5))


## The flight the kid climbs if nothing opens the door.
func _front_stairs(d: Node2D) -> void:
	var x := STAIRS_FROM
	var wood := Color(0.42, 0.26, 0.18)
	while x < width:
		var y := floor_y(x + 6.0)
		d.draw_rect(Rect2(x, y, 6, FLOOR + 44 - y), Color(0.22, 0.13, 0.1))
		d.draw_rect(Rect2(x, y, 6, 2), wood)
		x += 6.0


func _crates(d: Node2D) -> void:
	var size := Vector2(28.0, 28.0 * CRATE_STACK.get_height() / CRATE_STACK.get_width())
	d.draw_texture_rect(CRATE_STACK, Rect2(Vector2(0, -size.y), size), false, Color(0.82, 0.8, 0.88))


func _cobwebs(d: Node2D) -> void:
	var c := Color(0.8, 0.8, 0.9, 0.25)
	for p in [Vector2(250, 60), Vector2(186, 84)]:
		for i in 5:
			var a := PI * 0.5 + i * PI / 8.0
			d.draw_line(p, p + Vector2(cos(a), sin(a)) * 14.0, c, 1.0)
		d.draw_arc(p, 6.0, PI * 0.5, PI * 1.0, 6, c, 1.0)
		d.draw_arc(p, 11.0, PI * 0.5, PI * 1.0, 8, c, 1.0)


## The warm light from the foyer ends here.
func _warm_spill(d: Node2D) -> void:
	for i in 6:
		d.draw_rect(Rect2(0, 0, 10 + i * 8, 180), Color(1.0, 0.6, 0.25, 0.03))


## Small costume pictures hang low on the wall, crooked around their top hooks.
func _photos(d: Node2D) -> void:
	var costumes := [COSTUME_GHOST, COSTUME_WIZARD, COSTUME_BAT]
	var angles := [-0.16, 0.0, 0.2]
	for i in costumes.size():
		var hook := Vector2(6 + i * 16, 3 if i == 1 else 0)
		d.draw_set_transform(hook, angles[i])
		var frame := Rect2(-6, 0, 12, 17)
		# Layered walnut and aged brass frame around a dark portrait background.
		d.draw_rect(Rect2(frame.position + Vector2(1, 1), frame.size), Color(0, 0, 0, 0.35))
		d.draw_rect(frame, Color(0.12, 0.08, 0.07))
		d.draw_rect(frame.grow(-1), Color(0.48, 0.35, 0.18))
		d.draw_rect(frame.grow(-2), Color(0.07, 0.08, 0.12))
		var texture: Texture2D = costumes[i]
		var scale_factor := minf(8.0 / texture.get_width(), 13.0 / texture.get_height())
		var size := Vector2(texture.get_width(), texture.get_height()) * scale_factor
		d.draw_texture_rect(texture, Rect2(frame.get_center() - size / 2.0, size), false, Color(0.8, 0.84, 0.94))
	d.draw_set_transform(Vector2.ZERO)


## The loose two-pin plug is visible on the floor, yet the CRT still hisses with static.
## After a failure it flashes the door outline.
func _tv(d: Node2D) -> void:
	# Full image includes the cable and plug; cabinet feet meet the floor baseline.
	d.draw_texture_rect(TV_ART, Rect2(-18, -37, 60, 40), false)
	var screen := Rect2(-10, -30, 16, 12)
	var noise_seed := int(d.t * 24.0)
	for y in int(screen.size.y):
		for x in int(screen.size.x):
			var n := float((noise_seed * 73 + x * 31 + y * 17 + x * y * 7) % 11) / 10.0
			d.draw_rect(Rect2(screen.position + Vector2(x, y), Vector2.ONE), Color(0.3 + n * 0.5, 0.8 + n * 0.2, 1.0, 0.72))
	if fails > 0 and fmod(d.t, 2.0) < 0.15:
		DOOR_ART.draw_door(d, Rect2(screen.position + Vector2(4, 1), Vector2(6, 10)), true, Color.TRANSPARENT, Color(0.4, 0.65, 0.75))
	for i in 4:
		d.draw_circle(screen.get_center(), 16.0 - i * 3.0, Color(0.4, 1.0, 1.0, 0.03))
