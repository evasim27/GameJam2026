extends Node2D
## Opening: four shots with the story typed out on top. Any key goes to the next shot, Esc skips.
## (1) a tape clicks into a VCR in the dark, (2) the viewer's room with the "NE PREDVAJAJ" cover,
## (3) an autumn street with the last lit house, (4) the kid takes a candy, the door shuts, PLAY.
##
## To replace a shot's picture, drop a 320x180 (or any 16:9) PNG at `image`; until then the
## placeholder drawing below is used.

signal finished

const FONT := preload("res://assets/fonts/VT323-Regular.ttf")
const ARMCHAIR := preload("res://assets/noble_interior/armchair_tall.png")
const KidNode := preload("res://rewind/kid.gd")
const CHARS_PER_SECOND := 28.0
const LINE_PAUSE := 0.7
const SHOTS := [
	{
		"duration": 6.5,
		"image": "res://assets/intro/shot_1.png",
		"lines": ["31. oktober, pozno zvečer.", "Nekdo v temni sobi vstavi kaseto v videorekorder."],
	},
	{
		"duration": 7.5,
		"image": "res://assets/intro/shot_2.png",
		"lines": ["Na ovitku je z roko napisano: NE PREDVAJAJ.", "Posnetek se vseeno začne."],
	},
	{
		"duration": 9.0,
		"image": "res://assets/intro/shot_3.png",
		"lines": ["Jesenska ulica. Vse hiše so že temne,", "razen zadnje. Otrok v doma narejenem kostumu", "hoče samo še eno sladkarijo."],
	},
	{
		"duration": 9.5,
		"image": "res://assets/intro/shot_4.png",
		"lines": ["Otrok vzame sladkarijo in stopi noter.", "Vrata se za njim zaprejo. Hiša ga je ujela na trak.", "Otroka ne moreš voditi. Lahko pa upravljaš trak."],
	},
]

var _images := {}

var _t := 0.0
var _kid: Node2D
var _done := false


func _ready() -> void:
	for i in SHOTS.size():
		var path: String = SHOTS[i].image
		if ResourceLoader.exists(path):
			_images[i] = load(path)
	_kid = KidNode.new()
	_kid.visible = false
	add_child(_kid)


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
	var shot := _shot()
	_kid.visible = shot == 3 and not _images.has(3)
	if shot == 3:
		var s := _t - _shot_start(3)
		# Walks up, takes the candy, walks in.
		var x := minf(120.0 + minf(s, 2.0) * 24.0 + maxf(s - 3.5, 0.0) * 24.0, 220.0)
		_kid.place(x, 150.0)
		_kid.visible = _kid.visible and s < 5.2  # inside before the door shuts
		if s >= 2.0 and s < 3.5:
			_kid.stand()
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
	else:
		match shot:
			0: _draw_click(s)
			1: _draw_viewer_room(s)
			2: _draw_street(s)
			3: _draw_porch(s)
	_draw_story(SHOTS[shot].lines, s)
	_text("tipka: naprej   ESC: preskoči", Vector2(4, 176), 12, Color(0.5, 0.5, 0.6, 0.6))


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


func _draw_click(s: float) -> void:
	draw_rect(Rect2(0, 0, 320, 180), Color.BLACK)
	if s > 0.8:
		_text("*klik*", Vector2(146, 92), 16, Color(0.7, 0.7, 0.75, clampf((s - 0.8) * 2.0, 0.0, 1.0)))
	if s > 1.8:
		draw_rect(Rect2(150, 120, 20, 2), Color(0.4, 1.0, 0.5, 0.6))


func _draw_viewer_room(s: float) -> void:
	draw_rect(Rect2(0, 0, 320, 180), Color(0.03, 0.03, 0.06))
	# The TV is the only light.
	var glow := 0.8 + 0.2 * sin(s * 20.0)
	for i in 5:
		draw_circle(Vector2(210, 90), 90.0 - i * 15.0, Color(0.35, 0.8, 0.9, 0.03 * glow))
	draw_rect(Rect2(180, 66, 60, 46), Color(0.12, 0.12, 0.13))
	_static(Rect2(185, 70, 50, 36), s)
	draw_rect(Rect2(176, 112, 68, 30), Color(0.1, 0.07, 0.05))
	draw_rect(Rect2(186, 118, 40, 6), Color(0.06, 0.06, 0.07))
	# The armchair, seen from behind: the viewer is never shown.
	draw_set_transform(Vector2(40, 72), 0.0, Vector2(1.4, 1.4))
	draw_texture(ARMCHAIR, Vector2.ZERO, Color(0.12, 0.1, 0.16))
	draw_set_transform(Vector2.ZERO)
	# The tape's cover on the floor.
	draw_rect(Rect2(128, 150, 46, 20), Color(0.1, 0.1, 0.1))
	draw_rect(Rect2(130, 152, 42, 16), Color(0.85, 0.82, 0.72))
	_text("NE", Vector2(135, 160), 12, Color(0.1, 0.05, 0.05))
	_text("PREDVAJAJ", Vector2(134, 167), 10, Color(0.1, 0.05, 0.05))


func _draw_street(s: float) -> void:
	for i in 18:
		var c := Color(0.05, 0.05, 0.16).lerp(Color(0.25, 0.12, 0.3), i / 17.0)
		draw_rect(Rect2(0, i * 7, 320, 7), c)
	draw_circle(Vector2(262, 64), 10.0, Color(0.95, 0.9, 0.8))
	draw_rect(Rect2(0, 126, 320, 54), Color(0.08, 0.06, 0.1))
	var pan := s * 6.0
	for i in 6:
		var x := i * 58.0 - pan
		var h := 40.0 + float((i * 37) % 20)
		var last := i == 4
		var body := Color(0.12, 0.1, 0.16) if not last else Color(0.2, 0.13, 0.15)
		draw_rect(Rect2(x, 126 - h, 46, h), body)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 4, 126 - h), Vector2(x + 23, 126 - h - 20), Vector2(x + 50, 126 - h)]), body)
		if last:
			# The last lit house in the street.
			for wx in [x + 8, x + 28]:
				draw_rect(Rect2(wx, 126 - h + 10, 10, 10), Color(1.0, 0.65, 0.25))
				draw_circle(Vector2(wx + 5, 126 - h + 15), 14.0, Color(1.0, 0.6, 0.2, 0.08))
			draw_rect(Rect2(x + 18, 104, 10, 22), Color(1.0, 0.7, 0.3))
	# Falling leaves.
	for i in 8:
		var lx := fmod(i * 47.0 + s * 20.0, 320.0)
		var ly := fmod(i * 23.0 + s * 30.0, 140.0)
		draw_rect(Rect2(lx, ly, 2, 1), Color(0.85, 0.45, 0.15))


func _draw_porch(s: float) -> void:
	draw_rect(Rect2(0, 0, 320, 180), Color(0.06, 0.05, 0.12))
	draw_rect(Rect2(0, 150, 320, 30), Color(0.18, 0.11, 0.08))
	draw_rect(Rect2(150, 40, 150, 110), Color(0.2, 0.13, 0.15))
	# The doorway: warm light, a hand with a candy, then it shuts behind the kid.
	var shut := clampf((s - 5.0) / 0.5, 0.0, 1.0)
	draw_rect(Rect2(210, 100, 26, 50), Color(1.0, 0.7, 0.35))
	draw_rect(Rect2(210, 100, 26 * shut, 50), Color(0.3, 0.17, 0.12))
	if s > 1.5 and s < 3.2:
		draw_rect(Rect2(204, 124, 10, 4), Color(0.85, 0.75, 0.65))
		draw_rect(Rect2(196, 124, 7, 4), Color(1.0, 0.5, 0.75))
	if s > 5.6:
		_text("PLAY ▶", Vector2(8, 166), 24, Color(0.93, 0.95, 1.0))


func _static(r: Rect2, s: float) -> void:
	var n := int(s * 24.0)
	for y in range(0, int(r.size.y), 2):
		for x in range(0, int(r.size.x), 2):
			var v := float((n * 71 + x * 13 + y * 29 + x * y) % 13) / 12.0
			draw_rect(Rect2(r.position + Vector2(x, y), Vector2(2, 2)), Color(0.3 + v * 0.6, 0.7 + v * 0.3, 0.9, 1.0))


## Crisp text: draw at 2x size, then scale the canvas by half.
func _text(text: String, pos: Vector2, size: int, color: Color) -> void:
	draw_set_transform(pos, 0.0, Vector2(0.5, 0.5))
	draw_string(FONT, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size * 2, color)
	draw_set_transform(Vector2.ZERO)
