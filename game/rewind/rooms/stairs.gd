extends Room
## Static below the stairs. A shadow slides across the foot of the stairs on a rhythm, then a
## short safe stretch by a small TV full of static. Glitching while the kid is at the TV and the
## frame tears shifts the wardrobe and shows a hidden door under the stairs. Ignore it and the kid
## goes up the stairs into the long shadow. Luka 1994 waits behind the door if it opened early.

const WALL := preload("res://assets/rewind/wall.png")
const WAINSCOT := preload("res://assets/rewind/wainscot.png")
const FLOOR_TEX := preload("res://assets/rewind/floor.png")
const WARDROBE := preload("res://assets/noble_interior/wardrobe_small.png")

const STAIRS_FROM := 236.0
const TV_X := 150.0
const DOOR_X := 200.0

var _tv_noise := 0.0


func build() -> void:
	title = "STATIC BELOW THE STAIRS"
	tape_budget = 16.0
	timeline_length = 20.0

	add_tiled(WALL, Rect2(0, 0, WIDTH, 104), Color(0.24, 0.22, 0.36))
	add_tiled(WAINSCOT, Rect2(0, 104, WIDTH, 32), Color(0.42, 0.34, 0.4))
	add_tiled(FLOOR_TEX, Rect2(0, FLOOR, WIDTH, 44), Color(0.72, 0.6, 0.7))
	add_drawing(_photos, Vector2(14, 40))
	add_drawing(_back_stairs)
	add_drawing(_crates, Vector2(236, FLOOR))
	add_drawing(_cobwebs)
	add_drawing(_warm_spill)

	var foot := Shadow.new()
	foot.width = 24.0
	foot.period = 3.2
	foot.from = 2.0
	foot.to = 3.0
	add_object(foot, 72)

	var tear := GlitchSpot.new()
	tear.glitch_id = "door"
	tear.area = Rect2(-6, -38, 32, 38)
	tear.period = 3.0
	tear.from = 1.6
	tear.to = 2.4
	tear.kid_min = 120.0
	tear.kid_max = 196.0
	add_object(tear, DOOR_X)

	var luka := Candy.new()
	luka.candy_name = "Luka 1994"
	luka.needs_glitch = "door"
	luka.glitch_before_x = 160.0
	luka.lift = 8.0
	add_object(luka, DOOR_X - 2.0)

	var door := Door.new()
	door.needs_glitch = "door"
	door.cover = WARDROBE
	door.cover_slide = Vector2(26, 0)
	door.light = Color(0.4, 1.0, 1.0)
	add_object(door, DOOR_X)

	add_drawing(_front_stairs)
	var top := Shadow.new()
	top.always = true
	top.width = 30.0
	top.height = 60.0
	top.hint_x = TV_X
	add_object(top, 290, floor_y(290))
	add_drawing(_tv, Vector2(TV_X, FLOOR))


func floor_y(x: float) -> float:
	return FLOOR - maxf(x - STAIRS_FROM, 0.0) * 0.45


func trigger_hints() -> Array:
	return [{"x": 120.0, "text": "Slika je poškodovana — poskusi tukaj.", "button": "track", "keys": ["E"], "hold": false, "done": "glitch"}]


func retry_hint() -> String:
	return "Vrata so tam, kjer slika preskakuje." if fails >= 2 else ""


func idle_hint_target(run: RoomRun) -> float:
	return DOOR_X if run.glitched.has("door") else TV_X


func show_run(run: RoomRun) -> void:
	super(run)
	_tv_noise = run.room_time


## The big staircase along the back wall; the dark space under it holds the junk and the TV.
func _back_stairs(d: Node2D) -> void:
	var under := PackedVector2Array([Vector2(60, FLOOR), Vector2(320, 30), Vector2(320, FLOOR)])
	d.draw_colored_polygon(under, Color(0.05, 0.03, 0.08, 0.75))
	var wood := Color(0.3, 0.18, 0.13)
	var x := 60.0
	while x < 320.0:
		var y := FLOOR - (x - 60.0) * 0.41
		d.draw_rect(Rect2(x, y - 4, 9, 4), wood)
		d.draw_rect(Rect2(x, y - 4, 9, 1), Color(0.45, 0.28, 0.2))
		x += 9.0
	d.draw_line(Vector2(60, FLOOR), Vector2(320, 30), Color(0.18, 0.1, 0.08), 2.0)
	# A shadow that is far too long for the banister.
	d.draw_colored_polygon(PackedVector2Array([
		Vector2(200, 52), Vector2(320, 0), Vector2(320, 20), Vector2(230, 64)]), Color(0, 0, 0, 0.5))


## The flight the kid climbs if nothing opens the door.
func _front_stairs(d: Node2D) -> void:
	var x := STAIRS_FROM
	var wood := Color(0.42, 0.26, 0.18)
	while x < WIDTH:
		var y := floor_y(x + 6.0)
		d.draw_rect(Rect2(x, y, 6, FLOOR + 44 - y), Color(0.22, 0.13, 0.1))
		d.draw_rect(Rect2(x, y, 6, 2), wood)
		x += 6.0


func _crates(d: Node2D) -> void:
	for c in [Rect2(0, -14, 16, 14), Rect2(14, -10, 12, 10), Rect2(4, -24, 12, 10)]:
		d.draw_rect(c, Color(0.32, 0.2, 0.12))
		d.draw_rect(c, Color(0.16, 0.09, 0.06), false, 1.0)
		d.draw_line(c.position, c.end, Color(0.16, 0.09, 0.06), 1.0)


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


## Photos of different kids, all in the same spot and the same pose. Clearer after 3 failures.
func _photos(d: Node2D) -> void:
	var a := 0.35 if total_fails < 3 else 0.9
	var kids := [Color(0.35, 0.2, 0.5), Color(0.85, 0.85, 0.82), Color(0.85, 0.45, 0.15)]
	for i in kids.size():
		var p := Vector2(i * 14, (i % 2) * 4)
		d.draw_rect(Rect2(p, Vector2(11, 14)), Color(0.35, 0.25, 0.12, a))
		d.draw_rect(Rect2(p + Vector2(1, 1), Vector2(9, 12)), Color(0.75, 0.7, 0.6, a))
		var k: Color = kids[i]
		k.a = a
		d.draw_rect(Rect2(p + Vector2(4, 3), Vector2(3, 3)), k)
		d.draw_rect(Rect2(p + Vector2(3, 6), Vector2(5, 6)), k)


## A small CRT without a cable, hissing cyan static. After a failure it flashes the door outline.
func _tv(d: Node2D) -> void:
	d.draw_rect(Rect2(-10, -12, 20, 12), Color(0.3, 0.2, 0.14))
	d.draw_rect(Rect2(-9, -28, 18, 16), Color(0.15, 0.14, 0.16))
	var screen := Rect2(-7, -26, 14, 11)
	var noise_seed := int(d.t * 24.0)
	for y in int(screen.size.y):
		for x in int(screen.size.x):
			var n := float((noise_seed * 73 + x * 31 + y * 17 + x * y * 7) % 11) / 10.0
			d.draw_rect(Rect2(screen.position + Vector2(x, y), Vector2.ONE), Color(0.3 + n * 0.5, 0.8 + n * 0.2, 1.0, 1.0))
	if fails > 0 and fmod(d.t, 2.0) < 0.15:
		d.draw_rect(Rect2(screen.position + Vector2(4, 2), Vector2(6, 9)), Color(0.05, 0.1, 0.15), false, 1.0)
	for i in 4:
		d.draw_circle(Vector2(0, -20), 16.0 - i * 3.0, Color(0.4, 1.0, 1.0, 0.03))
