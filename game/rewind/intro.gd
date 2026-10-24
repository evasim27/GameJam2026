extends Node2D
## Opening: the story typed out on top of each shot. Any key goes to the next shot, Esc skips.
## (1) the kid walks up the street to the last lit house, (2) knocks, the door opens, it goes in,
## (3-7) the house_entry cutscene stills: the hall, the TV glow, the "DO NOT PLAY" tape, the VCR,
## pulled into the TV, PLAY.
## Shots 1 and 2 are one continuous exterior scene (from game_v1), drawn at 480x270 and scaled down.
## The stills are 1280x720 copies of assets/cutscenes/house_entry, drawn over the full 320x180 view.

signal finished

const FONT := preload("res://assets/fonts/VT323-Regular.ttf")
const EXTERIOR := preload("res://assets/exterior/exterior_background.png")
const EXTERIOR_OPEN := preload("res://assets/exterior/exterior_background_open.png")
const WALK_SHEET := preload("res://assets/exterior/player_walk_6f.png")
const WALK_FRAME := Vector2(40, 56)
const WALK_FPS := 9.0
## Exterior art is 480x270; the intro is 320x180.
const EXTERIOR_SCALE := 320.0 / 480.0
## Exterior timeline, in seconds since shot 1 started (shot 1 is the walk, shot 2 starts at the door).
const AT_DOOR := 6.5
const KNOCK_AT := AT_DOOR + 1.5
const DOOR_OPENS := KNOCK_AT + 1.12
const ENTER_AT := DOOR_OPENS + 0.45
const INSIDE_AT := ENTER_AT + 0.7
const CHARS_PER_SECOND := 28.0
const LINE_PAUSE := 0.7
## Each still fades in from black.
const FADE_IN := 0.4
const SHOTS := [
	{
		"duration": AT_DOOR,
		"image": "",
		"lines": ["October 31st, late at night. Every house is dark", "except the last one. A kid in a homemade costume", "wants just one more candy."],
	},
	{
		"duration": 5.0,
		"image": "",
		"lines": ["The kid knocks and the door swings open.", "There is no one on the threshold."],
	},
	{
		"duration": 6.0,
		"image": "res://assets/intro/house_01_entering_house.png",
		"lines": ["Pumpkins glow in the hall. The calendar: 31/10.", "The house is quiet, as if it has been waiting."],
	},
	{
		"duration": 5.0,
		"image": "res://assets/intro/house_02_screen_lit_room.png",
		"lines": ["A blue TV glow spills from the living room.", "Three names whisper: Maja, Luka, Tina."],
	},
	{
		"duration": 6.5,
		"image": "res://assets/intro/house_03_discovering_vhs.png",
		"lines": ["A videotape lies on the coffee table.", "The handwritten label says: DO NOT PLAY."],
	},
	{
		"duration": 5.5,
		"image": "res://assets/intro/house_04_inserting_vhs.png",
		"lines": ["The kid puts it in the VCR anyway."],
	},
	{
		"duration": 8.5,
		"image": "res://assets/intro/house_05_pulled_into_tv.png",
		"lines": ["The screen pulls the kid in. Caught on tape.", "You can't control the kid. Control the tape.", "Find three candy memories. Free the voices."],
	},
]

var _images := {}

var _t := 0.0
var _done := false


func _ready() -> void:
	for i in SHOTS.size():
		var path: String = SHOTS[i].image
		if path != "" and ResourceLoader.exists(path):
			_images[i] = load(path)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ESCAPE:
		_finish()
	else:
		_t = _shot_start(_shot() + 1)
		if _t >= _shot_start(SHOTS.size()):
			_finish()


func _process(delta: float) -> void:
	_t += delta
	if _t >= _shot_start(SHOTS.size()):
		_finish()
	queue_redraw()


func _finish() -> void:
	if not _done:
		_done = true
		finished.emit()


func _shot() -> int:
	for i in SHOTS.size():
		if _t < _shot_start(i + 1):
			return i
	return SHOTS.size() - 1


func _shot_start(i: int) -> float:
	var s := 0.0
	for k in i:
		s += SHOTS[k].duration
	return s


func _draw() -> void:
	var shot := _shot()
	var s := _t - _shot_start(shot)
	if _images.has(shot):
		draw_texture_rect(_images[shot], Rect2(0, 0, 320, 180), false)
		if s < FADE_IN:
			draw_rect(Rect2(0, 0, 320, 180), Color(0, 0, 0, 1.0 - s / FADE_IN))
	else:
		match shot:
			0: _draw_exterior(s)
			1: _draw_exterior(s + AT_DOOR)
	if shot == SHOTS.size() - 1 and s > 6.0:
		_text("PLAY ▶", Vector2(8, 166), 24, Color(0.93, 0.95, 1.0))
	_draw_story(SHOTS[shot].lines, s)
	_text("any key: next   ESC: skip", Vector2(4, 176), 12, Color(0.5, 0.5, 0.6, 0.6))


## The narration, typed out line by line in a band at the top.
func _draw_story(lines: Array, s: float) -> void:
	draw_rect(Rect2(0, 4, 320, 10 + lines.size() * 11), Color(0, 0, 0, 0.6))
	var start := 0.4
	for i in lines.size():
		var line: String = lines[i]
		var shown := clampi(int((s - start) * CHARS_PER_SECOND), 0, line.length())
		if shown > 0:
			var w := FONT.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x / 2.0
			_text(line.left(shown), Vector2((320.0 - w) / 2.0, 16 + i * 11), 12, Color(0.93, 0.95, 1.0))
		start += line.length() / CHARS_PER_SECOND + LINE_PAUSE


## The kid walks up to the last lit house, says the line, knocks, the door opens and it goes in.
## `e` is the time since shot 1 started; positions are in the 480x270 exterior art.
func _draw_exterior(e: float) -> void:
	var pos := Vector2(380, 176)
	var walking := false
	if e < 5.1:
		pos = Vector2(75, 196).lerp(Vector2(350, 196), e / 5.1)
		walking = true
	elif e < AT_DOOR:
		pos = Vector2(350, 196).lerp(Vector2(380, 176), (e - 5.1) / 1.4)
		walking = true
	elif e >= ENTER_AT:
		pos = Vector2(380, 176).lerp(Vector2(395, 176), minf((e - ENTER_AT) / 0.7, 1.0))
		walking = true
	else:
		# Two knocks: a small lean into the door each time.
		for k in [KNOCK_AT, KNOCK_AT + 0.41]:
			var d: float = e - k
			if d >= 0.0 and d < 0.09:
				pos.x += 2.0 * d / 0.09
			elif d >= 0.09 and d < 0.21:
				pos.x += 2.0 * (1.0 - (d - 0.09) / 0.12)
	var frame := int(e * WALK_FPS) % 6 if walking else 0

	draw_set_transform(Vector2.ZERO, 0.0, Vector2(EXTERIOR_SCALE, EXTERIOR_SCALE))
	draw_texture(EXTERIOR_OPEN if e >= DOOR_OPENS else EXTERIOR, Vector2.ZERO)
	if e < INSIDE_AT:
		draw_texture_rect_region(WALK_SHEET, Rect2(pos - WALK_FRAME / 2.0, WALK_FRAME), Rect2(Vector2(frame * WALK_FRAME.x, 0), WALK_FRAME))
	draw_set_transform(Vector2.ZERO)

	var line := ""
	if e >= AT_DOOR and e < KNOCK_AT:
		line = "Trick or treat!"
	elif e >= KNOCK_AT and e < DOOR_OPENS:
		line = "*knock knock*"
	if line != "":
		_text(line, Vector2(325, 127) * EXTERIOR_SCALE, 10, Color(1.0, 0.92, 0.72))


## Crisp text: draw at 2x size, then scale the canvas by half.
func _text(text: String, pos: Vector2, size: int, color: Color) -> void:
	draw_set_transform(pos, 0.0, Vector2(0.5, 0.5))
	draw_string(FONT, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size * 2, color)
	draw_set_transform(Vector2.ZERO)
