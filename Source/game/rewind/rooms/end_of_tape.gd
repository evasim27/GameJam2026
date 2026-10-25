extends Room
## End of Tape. First a long gallery: two knights in armour swing on their own rhythms while a
## damaged stretch of tape keeps releasing diving bats. Then shelves of cassettes, a VCR and a big CRT. The exit on the right is covered by a
## wrong frame of wall: glitch it at its cyan tear once the boss is beaten. Once the kid gets close, the tape monster
## crawls out of the VCR and its spilled tape holds the kid: a two-phase boss fight (TapeEater).
## The Reel: glitch the wound reel while it flashes blue to jam it. The Screen: rewind until the
## TV's empty frame meets the static wave, then glitch so the picture swallows it.
## Tina 2003 lies behind the wall for a quick, precise pass.

const WALL := preload("res://assets/rewind/cinematic/wall.png")
const FLOOR_TEX := preload("res://assets/rewind/cinematic/floor.png")
const BOOKCASE := preload("res://assets/rewind/cinematic/bookcase-hidden-monster.png")
const CRT := preload("res://assets/rewind/cinematic/crt-cabinet.png")
const PROJECTOR := preload("res://assets/rewind/cinematic/projector-body.png")
const ARMCHAIR := preload("res://assets/noble_interior/armchair_tall.png")
const KID := preload("res://assets/exterior/player_walk_6f.png")
const FONT := preload("res://assets/fonts/VT323-Regular.ttf")

## The gallery with the knights and bats; the tape room starts after it.
const HALL := 320.0
const KNIGHT_X := 110.0
const SECOND_KNIGHT_X := 236.0
const BATS_X := 180.0
const VCR_X := HALL + 112.0
const CRT_X := HALL + 176.0
const WALL_X := HALL + 272.0
const EXIT_X := HALL + 300.0
const TRIGGER_X := HALL + 150.0
const BATS_START := 4.0
## Where the spilled tape holds the kid during the boss fight: VCR and CRT both in view.
const HOLD_X := HALL + 166.0
const NAMES := ["Maja", "Luka", "Tina", "Ana", "Jaka", "Eva"]


func build() -> void:
	title = "END OF TAPE"
	width = HALL + WIDTH
	tape_budget = 50.0
	timeline_length = 50.0

	add_tiled(WALL, Rect2(0, 0, width, FLOOR), Color(0.1, 0.09, 0.14))
	add_tiled(FLOOR_TEX, Rect2(0, FLOOR, width, 44), Color(0.3, 0.27, 0.34))
	# The gallery: sconces between the knights, portraits watching them.
	add_wall_decor(WallDecor.Kind.WEB, Vector2(2, 73))
	add_wall_decor(WallDecor.Kind.SCONCE, Vector2(60, 98))
	add_wall_decor(WallDecor.Kind.PORTRAIT, Vector2(KNIGHT_X + 13, 86), 1)
	add_wall_decor(WallDecor.Kind.SCONCE, Vector2(172, 98))
	add_wall_decor(WallDecor.Kind.SCRATCHES, Vector2(196, 110))
	add_wall_decor(WallDecor.Kind.PORTRAIT, Vector2(SECOND_KNIGHT_X + 13, 86), 2)
	# The tape room.
	var portrait := add_wall_decor(WallDecor.Kind.PORTRAIT, Vector2(HALL + 123, 88), 2)
	portrait.rotation = 0.12
	add_wall_decor(WallDecor.Kind.PORTRAIT, Vector2(HALL + 270, 88), 1)
	add_wall_decor(WallDecor.Kind.SCONCE, Vector2(HALL + 237, 99))
	add_wall_decor(WallDecor.Kind.WEB, Vector2(width - 2, 73), 1, true)
	add_wall_decor(WallDecor.Kind.WEB, Vector2(HALL + 86, 75), 1)
	add_wall_decor(WallDecor.Kind.SCRATCHES, Vector2(HALL + 251, 112))
	add_drawing(_shelves, Vector2(HALL + 14, FLOOR))
	add_drawing(_label, Vector2(HALL + 206, 76))
	add_drawing(_daylight, Vector2(EXIT_X, FLOOR))
	add_drawing(_crt, Vector2(CRT_X, FLOOR))
	add_drawing(_vcr, Vector2(VCR_X, FLOOR))

	var knight := SwordGuard.new()
	knight.kind = SwordGuard.Kind.KNIGHT
	knight.swing_from = 4.0
	add_object(knight, KNIGHT_X)
	var second_knight := SwordGuard.new()
	second_knight.kind = SwordGuard.Kind.KNIGHT
	second_knight.period = 3.6
	second_knight.swing_from = 1.2
	add_object(second_knight, SECOND_KNIGHT_X)
	# A damaged stretch of tape between the knights keeps releasing diving bats.
	var bats := Bat.new()
	bats.starts_at = BATS_START
	bats.period = 6.0
	bats.bob = 3.2
	bats.enter_x = BATS_X + 60.0
	bats.release_from_x = BATS_X - 140.0
	bats.release_to_x = BATS_X + 50.0
	bats.reach = 160.0
	bats.damage_duration = 0.75
	add_object(bats, BATS_X)

	var exit := Door.new()
	exit.light = Color(0.95, 0.95, 1.0)
	add_object(exit, EXIT_X)
	var tina := Candy.new()
	tina.candy_name = "Tina 2003"
	add_object(tina, HALL + 286)
	add_object(FalseWall.new(), WALL_X)

	var wall_tear := GlitchSpot.new()
	wall_tear.glitch_id = "wall"
	wall_tear.area = FalseWall.AREA.grow(2)
	wall_tear.period = 5.0
	wall_tear.from = 3.6
	wall_tear.to = 4.6
	# Only after the boss, so its tear can never steal the E meant for the reel or the TV.
	wall_tear.requires = "screen"
	add_object(wall_tear, WALL_X)

	var eater := TapeEater.new()
	eater.trigger_x = TRIGGER_X
	eater.hold_x = HOLD_X
	eater.hiding_spot = Vector2(HALL + 50, 80)
	eater.screen = Rect2(CRT_X - VCR_X - 18, -46, 33, 22)
	eater.hint_x = VCR_X
	add_object(eater, VCR_X, FLOOR - 6)

	var reel := GlitchSpot.new()
	reel.glitch_id = "reel"
	# Match the wound reel on top of the generated projector.
	reel.area = Rect2(-6, -22, 12, 12)
	reel.period = 4.0
	reel.from = 2.5
	reel.to = 3.1
	reel.kid_min = TRIGGER_X
	reel.tint = TapeEater.BLUE
	reel.cue = true
	add_object(reel, VCR_X - 14.0)
	eater.reel_spot = reel

	var tv := ScreenSpot.new()
	tv.glitch_id = "screen"
	tv.requires = "reel"
	tv.area = Rect2(-18, -52, 33, 22)
	tv.cue = true
	tv.eater = eater
	tv.z_index = 21
	add_object(tv, CRT_X)


func idle_hint_target(run: RoomRun) -> float:
	if run.kid_x < HALL:
		return super.idle_hint_target(run)
	if not run.glitched.has("reel") and run.kid_x >= TRIGGER_X:
		return VCR_X
	if not run.glitched.has("screen") and run.glitched.has("reel"):
		return CRT_X
	return WALL_X + 10.0 if not run.glitched.has("wall") else EXIT_X


func trigger_hints() -> Array:
	return [
		{"x": KNIGHT_X - 44.0, "text": "A knight. Wait for the blade to fall, or rewind the swing."},
		{"x": BATS_X - 60.0, "text": "Damaged tape: bats keep coming. Let them pass above your head."},
		{"x": SECOND_KNIGHT_X - 44.0, "text": "This one swings faster."},
		{"x": TRIGGER_X, "text": "It crawls out of the VCR. When the reel flashes blue, press E."},
	]


## Parted tapes on the second shelf hide the blinking reel eyes.
func _shelves(d: Node2D) -> void:
	d.draw_texture_rect_region(BOOKCASE, Rect2(0, -96, 70, 96), Rect2(176, 102, 792, 1168))


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
	d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Alpha bounds; preserve the source proportions and put the feet on the floor.
	d.draw_texture_rect_region(PROJECTOR, Rect2(-26, -19.246, 44, 19.246), Rect2(141, 134, 1518, 664))
	# Its reels are drawn by TapeEater, so Pause/Rewind affect their motion.


## The big CRT. Mostly the kid from the foyer; after 6 failures, an empty armchair in a dark room.
func _crt(d: Node2D) -> void:
	var screen := Rect2(-18, -52, 33, 22)
	var flicker := 0.85 + 0.15 * sin(d.t * 30.0)
	for i in 5:
		d.draw_rect(screen.grow(3 + i * 3), Color(0.12, 0.48, 0.8, 0.008 * flicker))
	d.draw_texture_rect_region(CRT, Rect2(-26, -58, 52, 58), Rect2(64, 84, 1056, 1168))
	d.draw_rect(screen, Color(0.1, 0.18, 0.2) * flicker)
	if total_fails >= 6 and fmod(d.t, 5.0) < 1.0:
		d.draw_rect(screen, Color(0.02, 0.02, 0.03))
		d.draw_texture_rect(ARMCHAIR, Rect2(screen.get_center() - Vector2(8, 8), Vector2(16, 16)), false, Color(0.4, 0.4, 0.5))
	elif fmod(d.t, 3.0) < 1.2:
		d.draw_texture_rect_region(KID, Rect2(screen.get_center() - Vector2(5, 7), Vector2(10, 14)), Rect2(0, 0, 40, 56), Color(0.6, 1.0, 1.0, 0.8))
	for y in range(int(screen.position.y), int(screen.end.y), 2):
		d.draw_line(Vector2(screen.position.x, y), Vector2(screen.end.x, y), Color(0, 0, 0, 0.25), 1.0)


## Pale outdoor light leaking through the cracks around the exit.
func _daylight(d: Node2D) -> void:
	for i in 5:
		d.draw_rect(Rect2(-8 - i * 3, -40 - i * 2, 28 + i * 6, 40 + i * 2), Color(0.9, 0.92, 1.0, 0.03))
