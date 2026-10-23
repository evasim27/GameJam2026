extends Control
## VCR on-screen display: mode, timecode, tape health, timeline and big messages.

const OSD := Color(0.93, 0.95, 1.0)
const DIM := Color(0.6, 0.6, 0.72)

var mode := "STOP"
var tape_time := 0.0
var tape_length := 60.0
var health := 1.0
var message := ""
var sub_message := ""
var marks: Array = []
var _blink := 0.0


func _process(delta: float) -> void:
	_blink += delta
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	var w := size.x

	if mode != "PAUSE" or fmod(_blink, 1.0) < 0.6:
		draw_string(font, Vector2(16, 30), _mode_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, OSD)
	draw_string(font, Vector2(w - 220, 30), "SP " + _timecode(tape_time), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, OSD)

	# Tape health: the tape-eater chews a bit every time you rewind.
	draw_string(font, Vector2(w - 220, 52), "TAPE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, DIM)
	for i in 10:
		var r := Rect2(w - 176 + i * 15, 40, 11, 12)
		if i < ceili(health * 10.0):
			draw_rect(r, Color(0.65, 1.0, 0.56) if health > 0.3 else Color(1.0, 0.3, 0.35))
		else:
			draw_rect(r, DIM, false)

	_draw_timeline(font)

	if message != "":
		draw_string(font, Vector2(0, 160), message, HORIZONTAL_ALIGNMENT_CENTER, w, 48, OSD)
		draw_string(font, Vector2(0, 192), sub_message, HORIZONTAL_ALIGNMENT_CENTER, w, 20, DIM)


func _draw_timeline(font: Font) -> void:
	var x0 := 16.0
	var x1 := size.x - 16.0
	var y := size.y - 26.0
	var span := x1 - x0
	draw_rect(Rect2(x0, y, span, 8), Color(0.1, 0.08, 0.16))
	for m in marks:
		var a: float = x0 + span * clampf(m.from / tape_length, 0.0, 1.0)
		var b: float = x0 + span * clampf(m.to / tape_length, 0.0, 1.0)
		var row_y := y if m.get("row", 0) == 0 else y + 10.0
		draw_rect(Rect2(a, row_y, maxf(b - a, 2.0), 8 if m.get("row", 0) == 0 else 3), m.color)
	var head := x0 + span * tape_time / tape_length
	draw_rect(Rect2(head - 1, y - 5, 2, 20), Color.WHITE)
	draw_string(font, Vector2(x0, y - 8), "D/→ PLAY   A/← REWIND   SHIFT FAST   R EJECT", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, DIM)


func _mode_label() -> String:
	match mode:
		"PLAY": return "PLAY ▶"
		"FF": return "FF ▶▶"
		"REW": return "REW ◀◀"
		"PAUSE": return "PAUSE ❚❚"
	return "STOP ■"


static func _timecode(t: float) -> String:
	return "%d:%02d:%02d" % [int(t) / 60, int(t) % 60, int(fmod(t, 1.0) * 30.0)]
