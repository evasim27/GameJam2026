extends Node2D
## Opening: the story typed out on top of each shot. Space advances; Esc skips.
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
const WIND_SHADER := preload("res://rewind/exterior_wind.gdshader")
const WIND_SOUND := preload("res://assets/audio/wind_loop.ogg")
const DOOR_SOUND := preload("res://assets/audio/door_creak.wav")
const TV_SOUND := preload("res://assets/audio/static.mp3")
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
var _backdrop: Sprite2D
var _wind_audio: AudioStreamPlayer
var _door_audio: AudioStreamPlayer
var _tv_audio: AudioStreamPlayer
var _door_heard := false


func _ready() -> void:
	_backdrop = Sprite2D.new()
	_backdrop.centered = false
	_backdrop.texture = EXTERIOR
	_backdrop.scale = Vector2.ONE * EXTERIOR_SCALE
	_backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_backdrop.show_behind_parent = true
	var wind_material := ShaderMaterial.new()
	wind_material.shader = WIND_SHADER
	_backdrop.material = wind_material
	add_child(_backdrop)
	_wind_audio = _make_sound(WIND_SOUND, -27.0, true)
	_door_audio = _make_sound(DOOR_SOUND, -9.0)
	_tv_audio = _make_sound(TV_SOUND, -22.0, true)
	for i in SHOTS.size():
		var path: String = SHOTS[i].image
		if path != "" and ResourceLoader.exists(path):
			_images[i] = load(path)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ESCAPE:
		_finish()
	elif event.keycode == KEY_SPACE:
		_t = _shot_start(_shot() + 1)
		if _t >= _shot_start(SHOTS.size()):
			_finish()


func _process(delta: float) -> void:
	_t += delta
	var exterior := _t < _shot_start(2)
	_backdrop.visible = exterior
	if exterior:
		_backdrop.texture = EXTERIOR_OPEN if _t >= DOOR_OPENS else EXTERIOR
		if _t >= DOOR_OPENS and not _door_heard:
			_door_heard = true
			_door_audio.play()
	elif _wind_audio.playing:
		_wind_audio.stop()
	if not exterior and _door_audio.playing:
		_door_audio.stop()
	var at_tv := _t >= _shot_start(3) and _t < _shot_start(6)
	if at_tv and not _tv_audio.playing:
		_tv_audio.play()
	elif not at_tv and _tv_audio.playing:
		_tv_audio.stop()
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
	_text("SPACE: next   ESC: skip", Vector2(4, 176), 12, Color(0.5, 0.5, 0.6, 0.6))


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
	if e < INSIDE_AT:
		draw_texture_rect_region(WALK_SHEET, Rect2(pos - WALK_FRAME / 2.0, WALK_FRAME), Rect2(Vector2(frame * WALK_FRAME.x, 0), WALK_FRAME))
	_draw_leaves(e)
	draw_set_transform(Vector2.ZERO)

	var line := ""
	if e >= AT_DOOR and e < KNOCK_AT:
		line = "Trick or treat!"
	elif e >= KNOCK_AT and e < DOOR_OPENS:
		line = "*knock knock*"
	if line != "":
		_text(line, Vector2(325, 127) * EXTERIOR_SCALE, 10, Color(1.0, 0.92, 0.72))


func _draw_leaves(t: float) -> void:
	var anchors := [Vector2(23, 77), Vector2(53, 55), Vector2(82, 92), Vector2(106, 111), Vector2(455, 84), Vector2(469, 124), Vector2(36, 143)]
	for i in anchors.size():
		var phase := fposmod(t * (10.0 + i * 1.8) + i * 13.0, 72.0)
		var p: Vector2 = anchors[i] + Vector2(phase - 25.0 + sin(t * 1.2 + i) * 3.0, phase * 0.55 + sin(t * 2.0 + i) * 2.0)
		if p.y > 215.0 or p.x < 0.0 or p.x > 480.0:
			continue
		var color := Color(0.35, 0.19, 0.12, 0.8) if i % 2 == 0 else Color(0.48, 0.24, 0.11, 0.85)
		draw_colored_polygon(PackedVector2Array([p, p + Vector2(3, 1), p + Vector2(1, 3)]), color)


func _make_sound(stream: AudioStream, volume: float, looping := false) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream.duplicate() if looping else stream
	if looping:
		if player.stream is AudioStreamOggVorbis:
			(player.stream as AudioStreamOggVorbis).loop = true
		elif player.stream is AudioStreamMP3:
			(player.stream as AudioStreamMP3).loop = true
	player.volume_db = volume
	player.autoplay = stream == WIND_SOUND
	add_child(player)
	return player


## Crisp text: draw at 2x size, then scale the canvas by half.
func _text(text: String, pos: Vector2, size: int, color: Color) -> void:
	draw_set_transform(pos, 0.0, Vector2(0.5, 0.5))
	draw_string(FONT, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size * 2, color)
	draw_set_transform(Vector2.ZERO)
