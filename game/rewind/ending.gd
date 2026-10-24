extends Node2D
## Seven ending shots. Results stay on screen until the player rewinds to the start.
## Art stays independent of run data: candy, echoes and the final label are drawn at runtime.

const FONT := preload("res://assets/fonts/VT323-Regular.ttf")
const FADE_IN := 0.4
const CHARS_PER_SECOND := 28.0
const LINE_PAUSE := 0.7
const SHOTS := [
	{"duration": 6.5, "image": "res://assets/ending/01_waking_home.png",
		"lines": ["November 1st. Morning in the kid's own home.", "The kid wakes in bed. Halloween is over."]},
	{"duration": 5.5, "image": "res://assets/ending/02_candy_bag_home.png",
		"lines": ["The kid checks last night's candy bag.", "Something else has come home, too."]},
	{"duration": 5.5, "image": "res://assets/ending/03_blank_tape_home.png",
		"lines": ["A blank videotape. No warning. No name."]},
	{"duration": 6.5, "image": "res://assets/ending/04_camera_gaze_home_v2.png",
		"lines": ["For a moment, the kid looks straight at you."]},
	{"duration": 5.5, "image": "res://assets/ending/05_empty_armchair.png",
		"lines": ["Elsewhere, the viewer's chair is empty."]},
	{"duration": 5.0, "image": "res://assets/ending/06_ejected_tape.png",
		"lines": ["The VCR ejects the tape.", "The recording has ended."]},
	{"duration": 0.0, "image": "res://assets/ending/07_results.png",
		"lines": []},
]

var _candies: Array[String] = []
var _fails := 0
var _attempts := 0
var _tape := 0.0
var _shot := 0
var _t := 0.0
var _images: Array[Texture2D] = []
var _echo_texture: Texture2D
var _echo_region := Rect2()


func setup(candies: Array[String], fails: int, attempts: int, tape_used: float) -> void:
	_candies.assign(candies)
	_fails = maxi(fails, 0)
	_attempts = maxi(attempts, 0)
	_tape = maxf(tape_used, 0.0)


func _ready() -> void:
	_echo_texture = load("res://assets/ending/pajama_echo.png") as Texture2D
	_echo_region = Rect2(_echo_texture.get_image().get_used_rect())
	for shot in SHOTS:
		_images.append(load(shot.image) as Texture2D)


func results_visible() -> bool:
	return _shot == SHOTS.size() - 1


func _unhandled_input(event: InputEvent) -> void:
	if results_visible() or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ESCAPE:
		_shot = SHOTS.size() - 1
		_t = 0.0
	else:
		_next_shot()
	get_viewport().set_input_as_handled()
	queue_redraw()


func _next_shot() -> void:
	_shot = mini(_shot + 1, SHOTS.size() - 1)
	_t = 0.0


func _process(delta: float) -> void:
	_t += delta
	if not results_visible() and _t >= SHOTS[_shot].duration:
		_next_shot()
	queue_redraw()


func _draw() -> void:
	if _images.is_empty():
		return
	draw_texture_rect(_images[_shot], Rect2(0, 0, 320, 180), false)
	if _shot == 1:
		_draw_candy_count()
	if _shot == 3 and _fails > 0:
		_draw_echoes()
	if results_visible():
		_draw_results()
	else:
		var lines: Array = SHOTS[_shot].lines.duplicate()
		if _shot == 1:
			lines[1] = "Three memories made it out." if _candies.size() == 3 else "Some names are still trapped on the tape."
		if _shot == 5:
			lines[1] = "The voices are free." if _candies.size() == 3 else "The missing voices remain inside."
		if _shot == 3 and _fails > 0:
			lines.append("Behind the kid, earlier attempts linger.")
		_draw_story(lines)
		_text("any key: next   ESC: results", Vector2(4, 176), 12, Color(0.7, 0.7, 0.8))
		_text("%d / 7" % (_shot + 1), Vector2(290, 176), 12, Color(0.7, 0.7, 0.8))
	if _t < FADE_IN:
		draw_rect(Rect2(0, 0, 320, 180), Color(0, 0, 0, 1.0 - _t / FADE_IN))


func _draw_candy_count() -> void:
	# Never paint uncollected candy into a fixed illustration.
	draw_rect(Rect2(8, 139, 115, 24), Color(0.02, 0.02, 0.04, 0.85))
	_text("MEMORIES  %d/3" % mini(_candies.size(), 3), Vector2(14, 154), 14, Color(1, 0.9, 0.7))
	for i in mini(_candies.size(), 3):
		draw_texture_rect_region(Candy.SPRITE, Rect2(Vector2(86 + i * 11, 146), Candy.ICON_SIZE), Candy.sprite_region(_candies[i]))


func _draw_echoes() -> void:
	var appear := clampf((_t - 0.8) / 1.2, 0.0, 1.0)
	for i in mini(_fails, 6):
		var x := 18.0 + i * 14.0
		var alpha := appear * (0.22 + sin(_t * 2.0 + i) * 0.06)
		var height := 48.0
		var width := height * _echo_region.size.x / maxf(_echo_region.size.y, 1.0)
		draw_texture_rect_region(_echo_texture, Rect2(x, 80 + i % 2 * 5, width, height),
			_echo_region, Color(0.65, 0.95, 1.0, alpha))


func _draw_results() -> void:
	draw_rect(Rect2(162, 12, 150, 119), Color(0.02, 0.02, 0.04, 0.9))
	_text("END OF TAPE", Vector2(172, 32), 23, Color(0.93, 0.95, 1.0))
	_text("MEMORIES   %d/3" % mini(_candies.size(), 3), Vector2(172, 49), 15, Color(0.9, 0.9, 1.0))
	_text("ATTEMPTS   %d" % _attempts, Vector2(172, 64), 15, Color(0.9, 0.9, 1.0))
	_text("TAPE USED  %.1f s" % _tape, Vector2(172, 79), 15, Color(0.9, 0.9, 1.0))
	for i in 3:
		var name: String = ["Maja 1989", "Luka 1994", "Tina 2003"][i]
		var freed := _candies.has(name)
		_text("%s  %s" % [name.to_upper(), "FREE" if freed else "LOST"], Vector2(172, 96 + i * 11), 13, Color(0.52, 1.0, 0.95) if freed else Color(0.74, 0.7, 0.8))
	# The cassette label reveals the fate of the voices, including partial rescues.
	var label := "ALL FREE" if _candies.size() == 3 else "STILL LOST"
	var width := FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x / 2.0
	_text(label, Vector2(160 - width / 2.0, 141), 14, Color(0.1, 0.06, 0.05))
	draw_rect(Rect2(0, 163, 320, 17), Color(0.02, 0.02, 0.04, 0.85))
	_text("R — rewind to start", Vector2(108, 175), 12, Color(0.75, 0.75, 0.85))


func _draw_story(lines: Array) -> void:
	draw_rect(Rect2(0, 4, 320, 10 + lines.size() * 11), Color(0, 0, 0, 0.65))
	var start := 0.4
	for i in lines.size():
		var line: String = lines[i]
		var shown := clampi(int((_t - start) * CHARS_PER_SECOND), 0, line.length())
		if shown > 0:
			var width := FONT.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x / 2.0
			_text(line.left(shown), Vector2((320.0 - width) / 2.0, 16 + i * 11), 12, Color(0.93, 0.95, 1.0))
		start += line.length() / CHARS_PER_SECOND + LINE_PAUSE


func _text(text: String, pos: Vector2, size: int, color: Color) -> void:
	draw_set_transform(pos, 0.0, Vector2(0.5, 0.5))
	draw_string(FONT, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size * 2, color)
	draw_set_transform(Vector2.ZERO)
