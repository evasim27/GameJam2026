extends Node2D
## Incomplete rescues play Rewind with the exact rescued cast; all three play Exchange.
## Space advances the story; Escape exits only from the final results screen.

signal exit_requested

const FONT := preload("res://assets/fonts/VT323-Regular.ttf")
const DialogueBox := preload("res://rewind/dialogue_box.gd")
const SEQUENCES := preload("res://rewind/ending_sequences.gd")
const REWIND_MUSIC := preload("res://assets/audio/musicbox3_sad_tune.ogg")
const EXCHANGE_MUSIC := preload("res://assets/audio/musicbox1_spooky_waltz.ogg")
const FADE_IN := 0.4
const CHARS_PER_SECOND := 28.0
const LINE_PAUSE := 0.7
const TEXT_WIDTH := 282.0

var _candies: Array[String] = []
var _fails := 0
var _attempts := 0
var _tape := 0.0
var _unlisted_tape := false
var _rescue_mask := 0
var _ending_name := "REWIND"
var _shots: Array[Dictionary] = []
var _shot := 0
var _t := 0.0
var _images: Array[Texture2D] = []
var _music: AudioStreamPlayer


func setup(candies: Array[String], fails: int, attempts: int, tape_used: float, unlisted_tape := false) -> void:
	_candies.clear()
	_rescue_mask = 0
	for i in SEQUENCES.NAMES.size():
		var name: String = SEQUENCES.NAMES[i]
		if candies.has(name):
			_candies.append(name)
			_rescue_mask |= 1 << i
	_fails = maxi(fails, 0)
	_attempts = maxi(attempts, 0)
	_tape = maxf(tape_used, 0.0)
	_unlisted_tape = unlisted_tape
	_build_shots()


func _build_shots() -> void:
	_shots.clear()
	_shot = 0
	_t = 0.0
	_ending_name = "EXCHANGE" if _rescue_mask == 7 else "REWIND"
	var frames: Array = SEQUENCES.EXCHANGE if _rescue_mask == 7 else SEQUENCES.REWIND[_rescue_mask]
	for frame in frames:
		var lines := _wrap_caption(frame.caption)
		var duration := FADE_IN + 1.4
		for line in lines:
			duration += line.length() / CHARS_PER_SECOND + LINE_PAUSE
		_shots.append({"image": frame.image, "lines": lines, "duration": maxf(5.0, duration)})
	# Rewind ends on the warm morning results layout; Exchange keeps its ejected tape.
	var results_image: String = frames.back().image if _rescue_mask == 7 else "res://assets/ending/07_results.png"
	_shots.append({"image": results_image, "lines": [], "duration": 0.0})


func _wrap_caption(caption: String) -> Array[String]:
	var lines: Array[String] = []
	var line := ""
	for word in caption.split(" ", false):
		var candidate := word if line.is_empty() else line + " " + word
		if not line.is_empty() and FONT.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x / 2.0 > TEXT_WIDTH:
			lines.append(line)
			line = word
		else:
			line = candidate
	if not line.is_empty():
		lines.append(line)
	return lines


func _ready() -> void:
	if _shots.is_empty():
		_build_shots()
	for shot in _shots:
		_images.append(load(shot.image) as Texture2D)
	_music = AudioStreamPlayer.new()
	var loop := (EXCHANGE_MUSIC if _rescue_mask == 7 else REWIND_MUSIC).duplicate() as AudioStreamOggVorbis
	loop.loop = true
	_music.stream = loop
	_music.volume_db = -60.0
	add_child(_music)
	_music.play()


func results_visible() -> bool:
	return not _shots.is_empty() and _shot == _shots.size() - 1


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if results_visible():
		if event.keycode != KEY_ESCAPE:
			return
		exit_requested.emit()
	elif event.keycode == KEY_SPACE:
		_next_shot()
	else:
		return
	get_viewport().set_input_as_handled()
	queue_redraw()


func _next_shot() -> void:
	_shot = mini(_shot + 1, _shots.size() - 1)
	_t = 0.0


func _process(delta: float) -> void:
	_t += delta
	if not results_visible() and _t >= _shots[_shot].duration:
		_next_shot()
	_music.volume_db = move_toward(_music.volume_db, -27.0 if results_visible() else -18.0, delta * 30.0)
	queue_redraw()


func _draw() -> void:
	if _images.is_empty():
		return
	draw_texture_rect(_images[_shot], Rect2(0, 0, 320, 180), false)
	if results_visible():
		_draw_results()
	else:
		_draw_story(_shots[_shot].lines)
		draw_rect(Rect2(0, 164, 320, 16), Color(0.02, 0.02, 0.04, 0.8))
		_text("SPACE / TAP: next", Vector2(4, 176), 12, Color(0.7, 0.7, 0.8))
		_text("%d / %d" % [_shot + 1, _shots.size() - 1], Vector2(290, 176), 12, Color(0.7, 0.7, 0.8))
	if _t < FADE_IN:
		draw_rect(Rect2(0, 0, 320, 180), Color(0, 0, 0, 1.0 - _t / FADE_IN))


func _draw_results() -> void:
	var rewind := _rescue_mask != 7
	# Keep Rewind's panel above the foreground cassette and its illuminated label.
	var panel := Rect2(162, 12, 150, 119) if rewind else Rect2(154, 10, 158, 148)
	var x := 172.0 if rewind else 164.0
	var stats_y := 49.0 if rewind else 60.0
	var names_y := 96.0 if rewind else 107.0
	draw_rect(panel, Color(0.02, 0.02, 0.04, 0.92))
	_text("END OF TAPE", Vector2(x, 32 if rewind else 29), 23, Color(0.93, 0.95, 1.0))
	if not rewind:
		_text(_ending_name, Vector2(x, 44), 14, Color(0.52, 1.0, 0.95))
	_text("MEMORIES   %d/3" % _candies.size(), Vector2(x, stats_y), 15, Color(0.9, 0.9, 1.0))
	_text("ATTEMPTS   %d" % _attempts, Vector2(x, stats_y + 15), 15, Color(0.9, 0.9, 1.0))
	_text("TAPE USED  %.1f s" % _tape, Vector2(x, stats_y + 30), 15, Color(0.9, 0.9, 1.0))
	# Oldest first; NAMES keeps its order because the rescue masks depend on it.
	var by_year: Array = SEQUENCES.NAMES.duplicate()
	by_year.sort_custom(func(a: String, b: String): return a.get_slice(" ", 1).to_int() < b.get_slice(" ", 1).to_int())
	for i in by_year.size():
		var name: String = by_year[i]
		var freed := _candies.has(name)
		_text("%s  %s" % [name.to_upper(), "FREE" if freed else "LOST"], Vector2(x, names_y + i * 11), 13, Color(0.52, 1.0, 0.95) if freed else Color(0.74, 0.7, 0.8))
	if _unlisted_tape:
		_text("UNLISTED TAPE FOUND", Vector2(x, 127 if rewind else 147), 12, Color(0.83, 0.68, 1.0))
	if rewind:
		var width := FONT.get_string_size(_ending_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x / 2.0
		_text(_ending_name, Vector2(160 - width / 2.0, 141), 14, Color(0.1, 0.06, 0.05))
	draw_rect(Rect2(0, 163, 320, 17), Color(0.02, 0.02, 0.04, 0.85))
	_text("ESC: exit game", Vector2(124, 175), 12, Color(0.75, 0.75, 0.85))


func _draw_story(lines: Array) -> void:
	var shown_lines: Array[String] = []
	var start := FADE_IN
	for i in lines.size():
		var line: String = lines[i]
		var shown := clampi(int((_t - start) * CHARS_PER_SECOND), 0, line.length())
		shown_lines.append(line.left(shown))
		start += line.length() / CHARS_PER_SECOND + LINE_PAUSE
	var box_width := DialogueBox.width(FONT, lines, 12, 300.0)
	DialogueBox.draw_lines(self, FONT, lines, _ending_name, Rect2((320 - box_width) / 2.0, 6, box_width, DialogueBox.height(lines.size(), 12)), Color(0.77, 0.64, 1.0), 12, shown_lines)


func _text(text: String, pos: Vector2, size: int, color: Color) -> void:
	draw_set_transform(pos, 0.0, Vector2(0.5, 0.5))
	draw_string(FONT, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size * 2, color)
	draw_set_transform(Vector2.ZERO)
