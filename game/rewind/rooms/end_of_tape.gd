extends Room
## End of Tape. Shelves of cassettes, a VCR and a big CRT. The exit on the right is covered by a
## wrong frame of wall: glitch it at its cyan tear. Once the kid gets close, the tape-eater crawls
## out of the VCR after the playhead; glitch the wound reel next to the VCR to trap it in the TV.
## Both glitches are needed. Tina 2003 lies behind the wall for a quick, precise pass.

const WALL := preload("res://assets/rewind/wall.png")
const FLOOR_TEX := preload("res://assets/rewind/floor.png")
const ARMCHAIR := preload("res://assets/noble_interior/armchair_tall.png")
const KID := preload("res://assets/rewind/kid.png")
const FONT := preload("res://assets/fonts/VT323-Regular.ttf")

const VCR_X := 112.0
const CRT_X := 176.0
const WALL_X := 272.0
const EXIT_X := 300.0
const NAMES := ["Maja", "Luka", "Tina", "Ana", "Jaka", "Eva"]


func build() -> void:
	title = "END OF TAPE"
	tape_budget = 22.0
	timeline_length = 24.0

	add_tiled(WALL, Rect2(0, 0, width, FLOOR), Color(0.1, 0.09, 0.14))
	add_tiled(FLOOR_TEX, Rect2(0, FLOOR, width, 44), Color(0.3, 0.27, 0.34))
	add_drawing(_shelves, Vector2(14, FLOOR))
	add_drawing(_label, Vector2(206, 76))
	add_drawing(_daylight, Vector2(EXIT_X, FLOOR))
	add_drawing(_crt, Vector2(CRT_X, FLOOR))
	add_drawing(_vcr, Vector2(VCR_X, FLOOR))

	var exit := Door.new()
	exit.light = Color(0.95, 0.95, 1.0)
	add_object(exit, EXIT_X)
	var tina := Candy.new()
	tina.candy_name = "Tina 2003"
	tina.period = 5.0
	tina.from = 0.0
	tina.to = 0.4
	add_object(tina, 286)
	add_object(FalseWall.new(), WALL_X)

	var wall_tear := GlitchSpot.new()
	wall_tear.glitch_id = "wall"
	wall_tear.area = Rect2(-4, -48, 28, 48)
	wall_tear.period = 5.0
	wall_tear.from = 3.6
	wall_tear.to = 4.6
	add_object(wall_tear, WALL_X)

	var eater := TapeEater.new()
	eater.trigger_x = 150.0
	eater.tv = Vector2(CRT_X - VCR_X, -40)
	eater.hint_x = VCR_X
	add_object(eater, VCR_X, FLOOR - 6)

	var reel := GlitchSpot.new()
	reel.glitch_id = "reel"
	reel.area = Rect2(-6, -14, 12, 10)
	reel.period = 4.0
	reel.from = 2.5
	reel.to = 3.1
	reel.kid_min = 150.0
	add_object(reel, VCR_X - 14.0)


func idle_hint_target(run: RoomRun) -> float:
	return WALL_X + 10.0 if not run.glitched.has("wall") else EXIT_X


## Shelves of tapes.
func _shelves(d: Node2D) -> void:
	var wood := Color(0.2, 0.12, 0.09)
	for row in 4:
		var y := -18.0 - row * 22.0
		d.draw_rect(Rect2(0, y, 70, 2), wood)
		for i in 11:
			var c := Color(0.12, 0.12, 0.14) if (i + row) % 3 else Color(0.85, 0.82, 0.75)
			d.draw_rect(Rect2(2 + i * 6, y - 12, 4, 12), c)
	d.draw_rect(Rect2(0, -96, 2, 96), wood)
	d.draw_rect(Rect2(68, -96, 2, 96), wood)


## A tape label pinned to the wall with children's names. More are crossed out after 5 failures.
func _label(d: Node2D) -> void:
	var label := Rect2(0, 0, 58, 26)
	d.draw_rect(label.grow(1), Color(0.05, 0.04, 0.04))
	d.draw_rect(label, Color(0.75, 0.72, 0.62))
	var crossed := 3 if total_fails < 5 else NAMES.size()
	d.draw_set_transform(Vector2(3, 8), 0.0, Vector2(0.5, 0.5))
	for i in NAMES.size():
		var p := Vector2((i % 2) * 54, int(i / 2.0) * 15)
		d.draw_string(FONT, p, NAMES[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.15, 0.1, 0.1))
		if i < crossed:
			d.draw_line(p + Vector2(-1, -5), p + Vector2(40, -5), Color(0.1, 0.05, 0.05), 2.0)
	d.draw_set_transform(Vector2.ZERO)


func _vcr(d: Node2D) -> void:
	d.draw_rect(Rect2(-24, -6, 40, 6), Color(0.08, 0.08, 0.1))
	d.draw_rect(Rect2(-20, -5, 22, 1), Color(0.02, 0.02, 0.02))
	var blink := 1.0 if fmod(d.t, 1.0) < 0.5 else 0.3
	d.draw_rect(Rect2(8, -4, 2, 1), Color(0.4, 1.0, 0.5, blink))
	# The wound reel by the VCR.
	d.draw_circle(Vector2(-14, -10), 4.0, Color(0.06, 0.04, 0.04))
	d.draw_arc(Vector2(-14, -10), 4.0, 0, TAU, 12, Color(0.35, 0.2, 0.15), 1.0)


## The big CRT. Mostly the kid from the foyer; after 6 failures, an empty armchair in a dark room.
func _crt(d: Node2D) -> void:
	d.draw_rect(Rect2(-24, -14, 48, 14), Color(0.12, 0.08, 0.06))
	d.draw_rect(Rect2(-22, -54, 44, 40), Color(0.1, 0.1, 0.11))
	var screen := Rect2(-18, -50, 36, 30)
	var flicker := 0.85 + 0.15 * sin(d.t * 30.0)
	d.draw_rect(screen, Color(0.1, 0.18, 0.2) * flicker)
	if total_fails >= 6 and fmod(d.t, 5.0) < 1.0:
		d.draw_rect(screen, Color(0.02, 0.02, 0.03))
		d.draw_texture_rect(ARMCHAIR, Rect2(screen.position + Vector2(8, 4), Vector2(20, 20)), false, Color(0.4, 0.4, 0.5))
	elif fmod(d.t, 3.0) < 1.2:
		d.draw_texture_rect_region(KID, Rect2(screen.position + Vector2(13, 8), Vector2(10, 15)), Rect2(0, 0, 16, 24), Color(0.6, 1.0, 1.0, 0.8))
	for y in range(int(screen.position.y), int(screen.end.y), 2):
		d.draw_line(Vector2(screen.position.x, y), Vector2(screen.end.x, y), Color(0, 0, 0, 0.25), 1.0)


## Pale outdoor light leaking through the cracks around the exit.
func _daylight(d: Node2D) -> void:
	for i in 5:
		d.draw_rect(Rect2(-8 - i * 3, -40 - i * 2, 28 + i * 6, 40 + i * 2), Color(0.9, 0.92, 1.0, 0.03))
