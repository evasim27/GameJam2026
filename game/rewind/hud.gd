extends Control
## VCR on-screen display (mode, timecode and date stamp, tape left, the room-time timeline,
## ghost subtitles, hints, big messages) and the VCR's front panel along the bottom, whose
## buttons sink when their keys are pressed. Tutorial prompts press those buttons for you.

const OSD := Color(0.93, 0.95, 1.0)
const DIM := Color(0.6, 0.6, 0.72)
const CYAN := Color(0.5, 1.0, 1.0)
const VIOLET := Color(0.78, 0.61, 1.0)
const AMBER := Color(1.0, 0.75, 0.3)
const RED := Color(0.75, 0.12, 0.12)
const LED := Color(0.45, 1.0, 0.45)
const BLOOD_FONT := preload("res://assets/fonts/Nosifer-Regular.ttf")

const PANEL_H := 54.0
const BUTTON := Vector2(70, 18)
const BUTTON_GAP := 8.0
## id, label on the button, keyboard key, input action held down (if any).
const BUTTONS := [
	["rew", "◀◀ REW", "A", "tape_rewind"],
	["play", "▶ PLAY", "D", ""],
	["pause", "❚❚ PAUSE", "D", ""],
	["ff", "FF ▶▶", "F", "tape_ff"],
	["track", "TRACKING", "E", "tape_glitch"],
	["eject", "EJECT", "R", "restart"],
]

var mode := "STOP"
var room_time := 0.0
var kid_time := 0.0
var kid_x := 0.0
var seen_time := 0.0
var timeline_length := 30.0
var tape := 1.0
var tape_budget := 1.0
var eater := 0.0
var date := "31/10/1989"
var candies := 0
var memory_name := ""
var memory_found := false
## Buttons the player hasn't learned yet are dark and unlabelled.
var unlocked := {"rew": false, "ff": false, "track": false}
## Timeline marks: {from, to, color, row, from_x, until_x}. Shown while the kid is between the two.
var marks: Array = []
var message := ""
var sub_message := ""
## 0..1: the tape-eater wrapping the whole picture after it reached the playhead.
var wrap := 0.0
var prompt_done := ""

var _subtitle := ""
var _subtitle_t := 0.0
var _hint := ""
var _hint_t := 0.0
var _blink := 0.0
var _flash := {}
var _prompt_button := ""
var _prompt_keys: Array = []
var _prompt_hold := true
var _prompt_t := 0.0


func say(text: String) -> void:
	_subtitle = text
	_subtitle_t = 4.0


func hint(text: String) -> void:
	_hint = text
	_hint_t = 5.0


## Briefly sinks a panel button, e.g. when PLAY/PAUSE is toggled.
func flash(button: String) -> void:
	_flash[button] = 0.18


## Tutorial: an arrow keeps pressing `button` on the panel, with the keyboard `keys` above it.
## `hold` buttons stay down, others are tapped. `done` names the action that dismisses it
## (the game checks it); it also disappears on its own after a while.
func prompt(button: String, keys: Array, hold: bool, done: String) -> void:
	_prompt_button = button
	_prompt_keys = keys
	_prompt_hold = hold
	_prompt_t = 0.0
	prompt_done = done


func clear_prompt() -> void:
	_prompt_button = ""
	prompt_done = ""


func clear_texts() -> void:
	clear_prompt()
	_subtitle_t = 0.0
	_hint_t = 0.0
	message = ""
	sub_message = ""


func _process(delta: float) -> void:
	_blink += delta
	_subtitle_t -= delta
	_hint_t -= delta
	for k in _flash.keys():
		_flash[k] -= delta
	if _prompt_button != "":
		_prompt_t += delta
		if _prompt_t > 12.0:
			clear_prompt()
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	var w := size.x

	if mode != "PAUSE" or fmod(_blink, 1.0) < 0.6:
		draw_string(font, Vector2(16, 30), _mode_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, VIOLET if mode == "REW" or mode == "SCRUB-" else OSD)
	draw_string(font, Vector2(16, 52), "MEMORIES %d/3" % candies, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, DIM)
	draw_string(font, Vector2(16, 72), "%s  %s" % [memory_name, "SAVED" if memory_found else "MISSING"], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, CYAN if memory_found else AMBER)
	draw_string(font, Vector2(w - 240, 30), "SP " + _timecode(room_time), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, OSD)
	draw_string(font, Vector2(w - 240, 52), date, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, OSD)

	# Tape left in this room. Pause doesn't use any; everything else does.
	var frac := clampf(tape / tape_budget, 0.0, 1.0)
	var bar := Rect2(w - 240, 60, 160, 8)
	draw_rect(bar, DIM, false, 1.0)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), Color(0.65, 1.0, 0.56) if frac > 0.3 else AMBER)
	draw_string(font, Vector2(w - 72, 69), "%.1fs" % maxf(tape, 0.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, DIM)

	_draw_timeline()
	if mode == "REW" or mode == "SCRUB-":
		_draw_rewind_cue(font)
	_draw_panel(font)
	if _prompt_button != "":
		_draw_prompt(font)
	if _hint_t > 0.0:
		draw_string(font, Vector2(0, 92), _hint, HORIZONTAL_ALIGNMENT_CENTER, w, 20, CYAN)
	if _subtitle_t > 0.0:
		_draw_subtitle(font)
	if wrap > 0.0:
		_draw_wrap()
	if message != "":
		if message == "SIGNAL LOST":
			var shake := Vector2(sin(_blink * 29.0) * 1.5, cos(_blink * 23.0) * 0.5)
			draw_string(BLOOD_FONT, Vector2(2, 153) + shake, message, HORIZONTAL_ALIGNMENT_CENTER, w, 42, Color(0.12, 0.01, 0.02))
			draw_string(BLOOD_FONT, Vector2(0, 150) + shake, message, HORIZONTAL_ALIGNMENT_CENTER, w, 42, Color(0.78, 0.06, 0.09))
		else:
			draw_string(font, Vector2(0, 148), message, HORIZONTAL_ALIGNMENT_CENTER, w, 48, OSD)
		draw_string(font, Vector2(0, 182), sub_message, HORIZONTAL_ALIGNMENT_CENTER, w, 20, DIM)


func _draw_rewind_cue(font: Font) -> void:
	var w := size.x
	draw_rect(Rect2(6, 6, w - 12, size.y - PANEL_H - 12), VIOLET, false, 2.0)
	var band := Rect2(w / 2.0 - 154, 190, 308, 27)
	draw_rect(band, Color(0.08, 0.04, 0.17, 0.83))
	draw_rect(band, VIOLET, false, 1.0)
	draw_string(font, Vector2(0, 209), "HOUSE REWINDS  ◀◀   KID STAYS", HORIZONTAL_ALIGNMENT_CENTER, w, 20, OSD)


func _draw_timeline() -> void:
	var x0 := 16.0
	var x1 := size.x - 16.0
	var y := size.y - PANEL_H - 26.0
	var span := x1 - x0
	draw_rect(Rect2(x0, y, span, 8), Color(0.1, 0.08, 0.16))
	# Footage already seen; FF works inside it.
	draw_rect(Rect2(x0, y, span * clampf(seen_time / timeline_length, 0.0, 1.0), 8), Color(0.2, 0.18, 0.3))
	for m in marks:
		if kid_x > m.get("until_x", INF) or kid_x < m.get("from_x", -INF):
			continue
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


## The VCR's front panel: brand, cassette slot, and a row of buttons with status lights.
func _draw_panel(font: Font) -> void:
	var w := size.x
	var top := size.y - PANEL_H
	draw_rect(Rect2(0, top, w, PANEL_H), Color(0.12, 0.12, 0.14))
	draw_rect(Rect2(0, top, w, 2), Color(0.32, 0.32, 0.36))
	draw_rect(Rect2(0, top + PANEL_H - 3, w, 3), Color(0.05, 0.05, 0.06))
	draw_string(font, Vector2(14, top + 18), "LOST·IN·TAPE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.75, 0.75, 0.8))
	draw_string(font, Vector2(14, top + 30), "VHS  HQ  4-HEAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, DIM)
	draw_rect(Rect2(14, top + 36, 112, 10), Color(0.02, 0.02, 0.03))
	draw_rect(Rect2(16, top + 38, 108, 2), Color(0.2, 0.2, 0.22))
	for b in BUTTONS:
		_draw_button(font, b, false)


func _button_rect(id: String) -> Rect2:
	var top := size.y - PANEL_H
	var x := size.x - 14.0 - BUTTONS.size() * (BUTTON.x + BUTTON_GAP) + BUTTON_GAP
	for b in BUTTONS:
		if b[0] == id:
			return Rect2(Vector2(x, top + 16), BUTTON)
		x += BUTTON.x + BUTTON_GAP
	return Rect2()


func _draw_button(font: Font, b: Array, simulated_down: bool) -> void:
	var id: String = b[0]
	var r := _button_rect(id)
	var locked: bool = unlocked.has(id) and not unlocked[id]
	var down: bool = simulated_down or _flash.get(id, 0.0) > 0.0
	if b[3] != "" and not locked and Input.is_action_pressed(b[3]):
		down = true
	# Status light above the button.
	var lit: bool = (id == "play" and mode == "PLAY") or (id == "pause" and mode == "PAUSE") \
		or (id == "rew" and (mode == "REW" or mode == "SCRUB-")) or (id == "ff" and mode == "SCRUB+") \
		or (id == "track" and down)
	var led_c := (CYAN if id == "track" else LED) if lit else Color(0.2, 0.22, 0.2)
	draw_rect(Rect2(r.get_center().x - 4, r.position.y - 8, 8, 3), led_c)
	# The button sinks into the panel when pressed.
	draw_rect(Rect2(r.position + Vector2(0, 3), r.size), Color(0.04, 0.04, 0.05))
	var face := Rect2(r.position + Vector2(0, 2.0 if down else 0.0), r.size)
	var col := Color(0.62, 0.62, 0.66) if not down else Color(0.42, 0.42, 0.46)
	if locked:
		col = Color(0.24, 0.24, 0.27)
	draw_rect(face, col)
	draw_rect(Rect2(face.position, Vector2(face.size.x, 1)), Color(0.85, 0.85, 0.9) if not locked else col)
	var label: String = b[1]
	var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(font, Vector2(face.get_center().x - tw / 2.0, face.position.y + 14), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.1, 0.1, 0.12) if not locked else Color(0.15, 0.15, 0.17))
	if not locked:
		var key: String = b[2]
		var kw := font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string(font, Vector2(r.get_center().x - kw / 2.0, r.end.y + 14), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, DIM)


## An arrow keeps pressing the panel button, with the keyboard keys to use shown above it.
func _draw_prompt(font: Font) -> void:
	var cycle := fmod(_prompt_t, 1.4)
	# The panel button goes down with the last key of a combo.
	var down := _pressed_at(cycle - (_prompt_keys.size() - 1) * 0.18)
	for b in BUTTONS:
		if b[0] == _prompt_button:
			_draw_button(font, b, down)
	var r := _button_rect(_prompt_button)
	var push := 3.0 if down else -3.0 + sin(_prompt_t * 6.0) * 1.5
	var tip := Vector2(r.get_center().x, r.position.y - 10.0 + push)
	draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-7, -9), tip + Vector2(7, -9)]), CYAN)
	draw_rect(Rect2(tip.x - 2, tip.y - 30, 4, 21), CYAN)

	# Keycaps above the arrow, pressed in step with the button (combos one after the other).
	const H := 22.0
	const GAP := 18.0
	var widths: Array[float] = []
	var total := 0.0
	for k: String in _prompt_keys:
		var kw := 30.0 if k.length() == 1 else 14.0 + k.length() * 10.0
		widths.append(kw)
		total += kw
	total += GAP * (_prompt_keys.size() - 1)
	var caption := "HOLD" if _prompt_hold else "PRESS"
	var cap_w := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var top := tip.y - 30.0 - H - 12.0
	var x := clampf(tip.x - total / 2.0, 12.0, size.x - total - cap_w - 30.0)
	draw_rect(Rect2(x - 8, top - 6, total + cap_w + 28, H + 16), Color(0, 0, 0, 0.6))
	for i in _prompt_keys.size():
		_draw_key(font, Rect2(x, top, widths[i], H - 6), _prompt_keys[i], _pressed_at(cycle - i * 0.18))
		if i < _prompt_keys.size() - 1:
			draw_string(font, Vector2(x + widths[i] + 4, top + 16), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, OSD)
		x += widths[i] + GAP
	draw_string(font, Vector2(x - GAP + 10, top + 14), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, OSD)


## Whether a simulated key is down at time `c` of the 1.4 s cycle: held, or tapped twice.
func _pressed_at(c: float) -> bool:
	if _prompt_hold:
		return c >= 0.25 and c < 1.1
	return (c >= 0.25 and c < 0.4) or (c >= 0.6 and c < 0.75)


## A keycap: the face sinks into its base when pressed.
func _draw_key(font: Font, r: Rect2, label: String, down: bool) -> void:
	const DEPTH := 5.0
	var sink := DEPTH - 2.0 if down else 0.0
	draw_rect(Rect2(r.position + Vector2(0, DEPTH), r.size), Color(0.25, 0.25, 0.32))
	var face := Rect2(r.position + Vector2(0, sink), r.size)
	draw_rect(face, Color(0.55, 0.95, 1.0) if down else Color(0.9, 0.9, 0.95))
	draw_rect(face, Color(0.1, 0.1, 0.14), false, 1.0)
	var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_string(font, Vector2(face.get_center().x - tw / 2.0, face.position.y + 13), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.08, 0.08, 0.12))


func _draw_subtitle(font: Font) -> void:
	var w := size.x
	var text_w := font.get_string_size(_subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	var r := Rect2((w - text_w) / 2.0 - 8, 100, text_w + 16, 24)
	draw_rect(r, Color(0, 0, 0, 0.75))
	var jitter := 1.0 if fmod(_blink, 0.9) < 0.05 else 0.0
	draw_string(font, Vector2(r.position.x + 8 + jitter, 118), _subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.9, 1.0, 1.0))


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
		"SCRUB+": return "FF ▶▶"
		"SCRUB-": return "REW ◀◀◀"
		"PAUSE": return "PAUSE ❚❚"
	return "STOP ■"


static func _timecode(t: float) -> String:
	return "%d:%02d:%02d" % [int(t) / 60, int(t) % 60, int(fmod(t, 1.0) * 30.0)]
