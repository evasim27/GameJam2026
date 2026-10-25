extends Room
## Optional scene behind the foyer clock door. The main tape run is kept intact.

signal cue(text: String, sound: String)
signal tape_reached

const CRT := preload("res://assets/rewind/cinematic/crt-cabinet.png")
const HALLWAY := preload("res://assets/forbidden/hallway_v3.png")
const FONT := preload("res://assets/fonts/VT323-Regular.ttf")

const TAPE_X := 420.0
const WALK_SPEED := 27.0

var walk_x := 18.0
var playing := false
var at_tape := false
var _elapsed := 0.0
var _next_cue := 0
var _pause_whispered := false
var _door_flash := 0.0
var _shadow_flash := 0.0
var _tracking_flash := 0.0
var _tape_sprite: Sprite2D


func build() -> void:
	title = "THE FORBIDDEN ROOM"
	width = 480.0
	start_x = walk_x
	# Each full illustration fits a 320x180 room panel. The floor in the art
	# meets the kid's feet at y=136; the repeated panels make the hall uncanny.
	var background := add_drawing(_draw_hall, Vector2.ZERO, -1)
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_drawing(_draw_crt, Vector2(446, FLOOR))
	add_text("PLAY ME", Vector2(432, 74), Color(0.65, 0.96, 0.83), 12)
	add_drawing(_overlay, Vector2.ZERO, 2)
	_tape_sprite = Sprite2D.new()
	_tape_sprite.texture = Candy.SPRITE
	_tape_sprite.region_enabled = true
	_tape_sprite.region_rect = Candy.sprite_region("")
	_tape_sprite.scale = Candy.ICON_SIZE / _tape_sprite.region_rect.size
	_tape_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tape_sprite.position = Vector2(TAPE_X, FLOOR - 9)
	_tape_sprite.modulate = Color(1.3, 1.25, 1.1)
	_tape_sprite.z_index = 3
	add_child(_tape_sprite)


func _ready() -> void:
	kid.place(walk_x, FLOOR)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	_tape_sprite.position.y = FLOOR - 9 + sin(_elapsed * 6.0)
	_shadow_flash = maxf(0.0, _shadow_flash - delta)
	_tracking_flash = maxf(0.0, _tracking_flash - delta)
	_door_flash = maxf(0.0, _door_flash - delta)
	if playing and not at_tape:
		walk_x = minf(walk_x + WALK_SPEED * delta, TAPE_X)
		kid.place(walk_x, FLOOR)
		var cue_x := [128.0, 282.0, 370.0]
		if _next_cue < cue_x.size() and walk_x >= cue_x[_next_cue]:
			match _next_cue:
				0: cue.emit("You missed a frame.", "whisper_frame")
				1:
					_door_flash = 0.65
					_tracking_flash = 0.45
					cue.emit("The steel door moved on its own.", "shadow_warning")
				2:
					_shadow_flash = 0.75
					cue.emit("Something followed you through the static.", "echo")
			_next_cue += 1
		if walk_x >= TAPE_X:
			playing = false
			at_tape = true
			kid.look_at_camera()
			tape_reached.emit()
	queue_redraw()


func stopped() -> void:
	if not _pause_whispered and walk_x > 120.0 and walk_x < 400.0:
		_pause_whispered = true
		if walk_x > 270.0:
			_shadow_flash = 0.65
		cue.emit("I can still see you.", "whisper_see")


func tracking_flash() -> float:
	return _tracking_flash


func _draw_hall(d: Node2D) -> void:
	# Draw the complete 16:9 illustration once per 320-room-pixel segment.
	# Source pixels are never used as room coordinates; this fixes the giant
	# pipe and floating-child framing from the earlier backdrop.
	for i in 2:
		d.draw_texture_rect(HALLWAY, Rect2(i * WIDTH, 0, WIDTH, 180), false)
	# Cover the repeated join with a slim dark support, like the pipework.
	for seam_x in [WIDTH]:
		d.draw_rect(Rect2(seam_x - 1, 0, 2, FLOOR), Color(0.07, 0.14, 0.14, 0.65))
	# Mark the doors as a deliberate, impossible sequence.
	for i in 2:
		var door_x: float = 31.0 + i * WIDTH
		d.draw_rect(Rect2(door_x - 2, 63, 14, 9), Color(0.02, 0.07, 0.07, 0.75))
		d.draw_string(FONT, Vector2(door_x, 70), "0%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("d7d9bc"))

func _overlay(d: Node2D) -> void:
	# A faulty fluorescent flickers over each copy of the hallway.
	for i in 2:
		var x: float = [132.0, 452.0][i]
		var flicker := 0.5 + 0.5 * sin(_elapsed * 17.0 + i * 1.4)
		d.draw_rect(Rect2(x, 40, 52, 91), Color(0.53, 0.95, 0.68, 0.025 + flicker * 0.025))
	if _door_flash > 0.0:
		# A face appears behind the mesh of the second numbered door for one beat.
		d.draw_rect(Rect2(348, 72, 13, 7), Color(0.36, 0.02, 0.03, _door_flash * 0.65))
		d.draw_circle(Vector2(351, 75), 1.0, Color(1.0, 0.3, 0.28, _door_flash))
		d.draw_circle(Vector2(357, 75), 1.0, Color(1.0, 0.3, 0.28, _door_flash))
	if _shadow_flash > 0.0:
		var x := walk_x - 30.0
		_draw_ellipse_shadow(d, Vector2(x, 110), _shadow_flash)
	if _tracking_flash > 0.0:
		for i in 4:
			var y := 34.0 + i * 24.0 + sin(_elapsed * 43.0 + i) * 5.0
			d.draw_rect(Rect2(walk_x - 70.0, y, 130, 1), Color(0.27, 0.94, 0.98, _tracking_flash * 0.55))
	if at_tape:
		d.draw_string(FONT, Vector2(TAPE_X - 23, FLOOR - 17), "UNLISTED TAPE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.76, 0.95, 0.96))


func _draw_ellipse_shadow(d: Node2D, pos: Vector2, alpha: float) -> void:
	d.draw_circle(pos, 9, Color(0.02, 0.01, 0.05, alpha))
	d.draw_rect(Rect2(pos.x - 7, pos.y, 14, 24), Color(0.02, 0.01, 0.05, alpha))
	d.draw_circle(pos + Vector2(-3, -1), 1, Color(0.55, 0.91, 0.98, alpha))
	d.draw_circle(pos + Vector2(3, -1), 1, Color(0.55, 0.91, 0.98, alpha))


func _draw_crt(d: Node2D) -> void:
	d.draw_texture_rect_region(CRT, Rect2(-24, -51, 48, 51), Rect2(64, 84, 1056, 1168))
	var pulse := 0.5 + 0.5 * sin(d.t * 13.0)
	d.draw_rect(Rect2(-10, -41, 21, 14), Color(0.36, 0.84, 0.91, 0.18 + pulse * 0.11))
