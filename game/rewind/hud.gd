extends Control
## VCR on-screen display: mode, timecode and date stamp, tape budget, the room-time timeline,
## ghost subtitles, hints and big messages.

const OSD := Color(0.93, 0.95, 1.0)
const DIM := Color(0.6, 0.6, 0.72)
const CYAN := Color(0.5, 1.0, 1.0)
const AMBER := Color(1.0, 0.75, 0.3)
const RED := Color(0.75, 0.12, 0.12)

var mode := "STOP"
var room_time := 0.0
var kid_time := 0.0
var seen_time := 0.0
var timeline_length := 30.0
var tape := 1.0
var tape_budget := 1.0
var eater := 0.0
var date := "31/10/1989"
var candies := 0
var controls := ""
var marks: Array = []
var message := ""
var sub_message := ""
## 0..1: the tape-eater wrapping the whole picture after it reached the playhead.
var wrap := 0.0

var _subtitle := ""
var _subtitle_t := 0.0
var _hint := ""
var _hint_t := 0.0
var _blink := 0.0


func say(text: String) -> void:
	_subtitle = text
	_subtitle_t = 4.0


func hint(text: String) -> void:
	_hint = text
	_hint_t = 5.0


func clear_texts() -> void:
	_subtitle_t = 0.0
	_hint_t = 0.0
	message = ""
	sub_message = ""


func _process(delta: float) -> void:
	_blink += delta
	_subtitle_t -= delta
	_hint_t -= delta
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	var w := size.x

	if mode != "PAUSE" or fmod(_blink, 1.0) < 0.6:
		draw_string(font, Vector2(16, 30), _mode_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, OSD)
	draw_string(font, Vector2(16, 52), "SLADKARIJE %d/3" % candies, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, DIM)
	draw_string(font, Vector2(w - 240, 30), "SP " + _timecode(room_time), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, OSD)
	draw_string(font, Vector2(w - 240, 52), date, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, OSD)

	# Tape left in this room. Pause is free; everything else spends it.
	var frac := clampf(tape / tape_budget, 0.0, 1.0)
	var bar := Rect2(w - 240, 60, 160, 8)
	draw_rect(bar, DIM, false, 1.0)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), Color(0.65, 1.0, 0.56) if frac > 0.3 else AMBER)
	draw_string(font, Vector2(w - 72, 69), "%.1fs" % maxf(tape, 0.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, DIM)

	_draw_timeline(font)

	if _hint_t > 0.0:
		draw_string(font, Vector2(0, 250), _hint, HORIZONTAL_ALIGNMENT_CENTER, w, 22, CYAN)
	if _subtitle_t > 0.0:
		_draw_subtitle(font)
	if wrap > 0.0:
		_draw_wrap()
	if message != "":
		draw_string(font, Vector2(0, 160), message, HORIZONTAL_ALIGNMENT_CENTER, w, 48, OSD)
		draw_string(font, Vector2(0, 192), sub_message, HORIZONTAL_ALIGNMENT_CENTER, w, 20, DIM)


func _draw_timeline(font: Font) -> void:
	var x0 := 16.0
	var x1 := size.x - 16.0
	var y := size.y - 30.0
	var span := x1 - x0
	draw_rect(Rect2(x0, y, span, 8), Color(0.1, 0.08, 0.16))
	# Footage already seen; scrubbing works inside it.
	draw_rect(Rect2(x0, y, span * clampf(seen_time / timeline_length, 0.0, 1.0), 8), Color(0.2, 0.18, 0.3))
	for m in marks:
		var a: float = x0 + span * clampf(m.from / timeline_length, 0.0, 1.0)
		var b: float = x0 + span * clampf(m.to / timeline_length, 0.0, 1.0)
		var row: int = m.get("row", 0)
		var r := Rect2(a, y, maxf(b - a, 2.0), 8)
		if row == 1:
			r = Rect2(a, y + 10, maxf(b - a, 2.0), 3)
		elif row == 2:
			r = Rect2(a, y + 15, maxf(b - a, 2.0), 3)
		draw_rect(r, m.color)
	var head := x0 + span * clampf(room_time / timeline_length, 0.0, 1.0)
	# The tape-eater's red trail creeping up on the playhead.
	if eater > 0.0:
		var tail := head - (1.0 - eater) * 160.0
		draw_rect(Rect2(tail - 40.0 * eater, y - 3, 40.0 * eater, 14), Color(RED, 0.5))
		draw_rect(Rect2(tail - 2, y - 5, 3, 18), RED)
	draw_rect(Rect2(head - 1, y - 5, 2, 20), Color.WHITE)
	# Where the kid is in its own time: the gap is how far the house was rewound.
	var kid := x0 + span * clampf(kid_time / timeline_length, 0.0, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(kid - 3, y + 20), Vector2(kid + 3, y + 20), Vector2(kid, y + 16)]), AMBER)
	draw_string(font, Vector2(x0, y - 8), controls, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, DIM)


func _draw_subtitle(font: Font) -> void:
	var w := size.x
	var text_w := font.get_string_size(_subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	var r := Rect2((w - text_w) / 2.0 - 8, 270, text_w + 16, 24)
	draw_rect(r, Color(0, 0, 0, 0.75))
	var jitter := 1.0 if fmod(_blink, 0.9) < 0.05 else 0.0
	draw_string(font, Vector2(r.position.x + 8 + jitter, 288), _subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.9, 1.0, 1.0))


func _draw_wrap() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.7 * wrap))
	for i in 24:
		var pts := PackedVector2Array()
		for k in 21:
			var x := w * k / 20.0
			pts.append(Vector2(x, h * (i + 0.5) / 24.0 + sin(_blink * 3.0 + k * 0.7 + i) * 18.0 * wrap))
		draw_polyline(pts, Color(RED if i % 3 == 0 else Color(0.3, 0.15, 0.1), wrap), 3.0)


func _mode_label() -> String:
	match mode:
		"PLAY": return "PLAY ▶"
		"REW": return "REW ◀◀"
		"SCRUB+": return "SCRUB ▶▶"
		"SCRUB-": return "SCRUB ◀◀"
		"PAUSE": return "PAUSE ❚❚"
	return "STOP ■"


static func _timecode(t: float) -> String:
	return "%d:%02d:%02d" % [int(t) / 60, int(t) % 60, int(fmod(t, 1.0) * 30.0)]
