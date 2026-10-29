extends Control
## VCR on-screen display (mode, timecode and date stamp, tape left, the room-time timeline,
## ghost subtitles, hints, big messages) and the VCR's front panel along the bottom, whose
## buttons sink when their keys are pressed. Tutorial prompts press those buttons for you.
## Clicking or touching a panel button presses its key, so the deck also plays on phones.

const OSD := Color(0.93, 0.95, 1.0)
const DIM := Color(0.6, 0.6, 0.72)
const CYAN := Color(0.5, 1.0, 1.0)
const VIOLET := Color(0.78, 0.61, 1.0)
const AMBER := Color(1.0, 0.75, 0.3)
const RED := Color(0.75, 0.12, 0.12)
const LED := Color(0.45, 1.0, 0.45)
const BLOOD_FONT := preload("res://assets/fonts/Nosifer-Regular.ttf")
const DialogueBox := preload("res://rewind/dialogue_box.gd")

const PANEL_H := 54.0
## A recovered memory's card stays on the right this long, then its cassette flies to the counter.
const PICKUP_HOLD := 2.6
const PICKUP_FLY := 0.7
const PICKUP_LAND := 0.5
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
## Pointer index used for the (real, not touch-emulated) mouse.
const MOUSE_POINTER := -100
## Holding REW by touch this long also holds SHIFT, since phones have no SHIFT key.
const FAST_REWIND_HOLD := 0.8

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
var saved_memories: Array[String] = []
## Buttons the player hasn't learned yet are dark and unlabelled.
var unlocked := {"rew": false, "ff": false, "track": false}
## Timeline marks: {from, to, color, row, from_x, until_x}. Shown while the kid is between the two.
var marks: Array = []
var message := ""
var sub_message := ""
## The secret hallway keeps only small captions so its full height remains visible.
var cinematic_mode := false
## 0..1: the tape-eater wrapping the whole picture after it reached the playhead.
var wrap := 0.0
var prompt_done := ""

var _subtitle := ""
var _speaker := "ECHO"
var _speech_source: WeakRef
var _speech_offset := Vector2(0, -31)
var _subtitle_t := 0.0
var _hint := ""
var _hint_t := 0.0
var _pickup_id := ""
var _pickup_t := 0.0
var _pickup_bonus := 0
var _landed_t := 0.0
var _blink := 0.0
var _flash := {}
var _prompt_button := ""
var _prompt_keys: Array = []
var _prompt_hold := true
var _prompt_t := 0.0
## Pointer index (finger or mouse) -> id of the panel button it holds down.
var _pointers := {}
var _rew_held_t := 0.0
var _fast_by_touch := false


func say(text: String, speaker := "ECHO", source: Node2D = null, offset := Vector2(0, -31)) -> void:
	_subtitle = text
	_speaker = speaker
	_subtitle_t = 4.0
	_speech_source = weakref(source) if source != null else null
	_speech_offset = offset
	queue_redraw()


func hint(text: String) -> void:
	_hint = text
	_hint_t = 5.0
	queue_redraw()


func recover_memory(id: String, bonus_seconds: int) -> void:
	_pickup_id = id
	_pickup_t = PICKUP_HOLD + PICKUP_FLY
	_pickup_bonus = bonus_seconds
	queue_redraw()


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
	_subtitle = ""
	_speech_source = null
	_subtitle_t = 0.0
	_hint = ""
	_hint_t = 0.0
	_pickup_t = 0.0
	_pickup_id = ""
	_landed_t = 0.0
	message = ""
	sub_message = ""
	queue_redraw()


func _process(delta: float) -> void:
	_blink += delta
	_subtitle_t -= delta
	_hint_t -= delta
	if _pickup_t > 0.0 and _pickup_t <= delta:
		_landed_t = PICKUP_LAND
	_pickup_t = maxf(0.0, _pickup_t - delta)
	_landed_t = maxf(0.0, _landed_t - delta)
	for k in _flash.keys():
		_flash[k] -= delta
	if _prompt_button != "":
		_prompt_t += delta
		if _prompt_t > 12.0:
			clear_prompt()
	_rew_held_t = _rew_held_t + delta if _pointers.values().has("rew") else 0.0
	if _rew_held_t >= FAST_REWIND_HOLD and not _fast_by_touch:
		_fast_by_touch = true
		_send_key(KEY_SHIFT, true)
	elif _rew_held_t == 0.0 and _fast_by_touch:
		_fast_by_touch = false
		_send_key(KEY_SHIFT, false)
	queue_redraw()


func _input(event: InputEvent) -> void:
	var pointer: int
	if event is InputEventScreenTouch:
		pointer = event.index
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.device != InputEvent.DEVICE_ID_EMULATION:
		pointer = MOUSE_POINTER
	else:
		return
	if not event.pressed:
		if _pointers.has(pointer):
			var id: String = _pointers[pointer]
			_pointers.erase(pointer)
			if not _pointers.values().has(id):
				_send_key(_button_key(id), false)
			get_viewport().set_input_as_handled()
		return
	if not is_visible_in_tree() or cinematic_mode:
		return
	var id := _button_at(make_input_local(event).position)
	if id == "":
		return
	get_viewport().set_input_as_handled()
	# PLAY and PAUSE share one key that toggles, so only press the one that changes something.
	if (id == "play" and mode == "PLAY") or (id == "pause" and mode != "PLAY"):
		return
	if not _pointers.values().has(id):
		_send_key(_button_key(id), true)
	_pointers[pointer] = id


## The panel button under `pos`, counting its light and key label and the gaps around it.
func _button_at(pos: Vector2) -> String:
	for b in BUTTONS:
		var r := _button_rect(b[0])
		var area := Rect2(r.position.x - BUTTON_GAP / 2.0, size.y - PANEL_H, r.size.x + BUTTON_GAP, PANEL_H)
		if area.has_point(pos):
			return b[0]
	return ""


func _button_key(id: String) -> Key:
	for b in BUTTONS:
		if b[0] == id:
			return OS.find_keycode_from_string(b[2])
	return KEY_NONE


func _send_key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)


func _draw() -> void:
	var font := get_theme_default_font()
	var w := size.x
	if cinematic_mode:
		if _subtitle_t > 0.0:
			_draw_subtitle(font)
		if _hint_t > 0.0:
			_draw_cinematic_caption(font, _hint, size.y - 42.0, OSD)
		return

	_draw_status(font)
	if message == "":
		_draw_memory_pickup(font)

	_draw_timeline()
	if mode == "REW" or mode == "SCRUB-":
		_draw_rewind_cue(font)
	_draw_panel(font)
	if _prompt_button != "":
		_draw_prompt(font)
	if _hint_t > 0.0:
		_draw_hint(font)
	if _subtitle_t > 0.0:
		_draw_subtitle(font)
	if wrap > 0.0:
		_draw_wrap()
	if message != "":
		if message == "YOU WEREN'T MEANT TO SEE THAT":
			var shake := Vector2(sin(_blink * 29.0) * 1.5, cos(_blink * 23.0) * 0.5)
			for i in 2:
				var line := "YOU WEREN'T MEANT" if i == 0 else "TO SEE THAT"
				var y := 137.0 + i * 39.0
				draw_string(BLOOD_FONT, Vector2(2, y + 3) + shake, line, HORIZONTAL_ALIGNMENT_CENTER, w, 34, Color(0.12, 0.01, 0.02))
				draw_string(BLOOD_FONT, Vector2(0, y) + shake, line, HORIZONTAL_ALIGNMENT_CENTER, w, 34, Color(0.78, 0.06, 0.09))
		else:
			# A dark band behind the message keeps it readable over any room.
			draw_rect(Rect2(0, 104, w, 90), Color(0, 0, 0, 0.6))
			draw_string_outline(font, Vector2(0, 148), message, HORIZONTAL_ALIGNMENT_CENTER, w, 48, 6, Color.BLACK)
			draw_string(font, Vector2(0, 148), message, HORIZONTAL_ALIGNMENT_CENTER, w, 48, Color(0.62, 0.62, 0.66) if message == "SIGNAL LOST" else OSD)
		var sub_color := Color(1.0, 0.3, 0.3) if message == "SIGNAL LOST" else DIM
		draw_string_outline(font, Vector2(0, 182), sub_message, HORIZONTAL_ALIGNMENT_CENTER, w, 20, 5, Color.BLACK)
		draw_string(font, Vector2(0, 182), sub_message, HORIZONTAL_ALIGNMENT_CENTER, w, 20, sub_color)


func _draw_card(rect: Rect2, accent: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.03, 0.055, 0.66)
	style.border_color = Color(accent, 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	draw_style_box(style, rect)


func _label(font: Font, value: String, pos: Vector2, font_size: int, color := OSD) -> void:
	DialogueBox.text(self, font, value, pos, font_size, color)


func _draw_status(font: Font) -> void:
	var ink := Color(0.91, 0.92, 0.88, 0.76)
	var faint := Color(0.78, 0.8, 0.78, 0.55)
	var accent := Color(VIOLET, 0.76) if mode == "REW" or mode == "SCRUB-" else ink
	if mode == "PLAY":
		accent = Color(0.58, 0.77, 0.62, 0.84)
	elif mode == "PAUSE":
		accent = Color(0.82, 0.46, 0.43, 0.84)
	_draw_osd_field(Rect2(12, 12, 180, 62))
	_label(font, "VHS / SP", Vector2(23, 25), 9, faint)
	_label(font, "MEMORIES", Vector2(137, 25), 9, faint)
	_label(font, _mode_label(), Vector2(23, 46), 19, accent)
	# A memory still flying in only counts once its cassette lands, then the counter flashes.
	var shown := candies - (1 if _pickup_t > 0.0 and saved_memories.has(_pickup_id) else 0)
	var land := _landed_t / PICKUP_LAND
	_label(font, "%d/3" % shown, Vector2(158, 46), 16, ink.lerp(CYAN, land))
	_label(font, "%s %s" % [memory_name, "SAVED" if memory_found else "MISSING"], Vector2(23, 65), 11, faint)
	for i in 3:
		var lit := ink.lerp(CYAN, land) if i == shown - 1 else ink
		draw_rect(Rect2(143 + i * 12, 60, 8, 2), lit if i < shown else Color(0.7, 0.7, 0.72, 0.18))

	var x := size.x - 202.0
	_draw_osd_field(Rect2(x, 12, 190, 62))
	_label(font, "COUNTER / SP", Vector2(x + 12, 25), 9, faint)
	_label(font, date, Vector2(x + 117, 25), 11, faint)
	_label(font, _timecode(room_time), Vector2(x + 12, 46), 19, ink)
	var remaining := "%.1fs" % maxf(tape, 0.0)
	var tw := font.get_string_size(remaining, HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x / 2.0
	_label(font, remaining, Vector2(x + 178 - tw, 46), 16, Color(AMBER, 0.75) if tape < tape_budget * 0.3 else ink)
	var frac := clampf(tape / maxf(tape_budget, 0.01), 0.0, 1.0)
	var bar := Rect2(x + 12, 54, 166, 2)
	draw_rect(bar, Color(0.8, 0.8, 0.8, 0.12))
	var tape_color := Color(0.48, 0.60, 0.50, 0.68)
	if frac < 0.15:
		tape_color = Color(0.65, 0.36, 0.34, 0.68)
	elif frac < 0.3:
		tape_color = Color(0.66, 0.53, 0.39, 0.68)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), tape_color)
	_label(font, "TAPE REMAINING", Vector2(x + 12, 67), 9, faint)
	_label(font, "%d%%" % int(frac * 100), Vector2(x + 157, 67), 9, faint)


func _draw_osd_field(rect: Rect2) -> void:
	DialogueBox.draw_osd_panel(self, rect)


## The memory just recovered: a card on the right for a moment, then its cassette flies into
## the MEMORIES counter in the top-left corner.
func _draw_memory_pickup(font: Font) -> void:
	if _pickup_t <= 0.0 or _pickup_id == "":
		return
	var rect := Rect2(size.x - 190, 88, 178, 38)
	var cassette := Rect2(rect.position + Vector2(141, 13), Candy.ICON_SIZE * 2.6)
	var region := Candy.sprite_region(_pickup_id)
	if _pickup_t > PICKUP_FLY:
		# Slides in from the right edge.
		var shown := PICKUP_HOLD + PICKUP_FLY - _pickup_t
		var slide := (1.0 - ease(clampf(shown / 0.25, 0.0, 1.0), 0.4)) * 200.0
		rect.position.x += slide
		cassette.position.x += slide
		_draw_card(rect, CYAN)
		var accent := StyleBoxFlat.new()
		accent.draw_center = false
		accent.border_color = CYAN
		accent.border_width_left = 2
		accent.set_corner_radius_all(4)
		draw_style_box(accent, rect)
		_label(font, "MEMORY SAVED  +%ds" % _pickup_bonus, rect.position + Vector2(10, 11), 10, CYAN)
		_label(font, _pickup_id.to_upper().replace(" ", " / "), rect.position + Vector2(10, 29), 20)
		draw_texture_rect_region(Candy.SPRITE, cassette, region)
		return
	var k := ease(1.0 - _pickup_t / PICKUP_FLY, -2.2)
	var target := Rect2(Vector2(150, 34), Candy.ICON_SIZE * 1.4)
	var from := cassette.get_center()
	var to := target.get_center()
	# An arc rather than a straight line, with a short cyan trail behind the cassette.
	var arc := Vector2(0, -sin(k * PI) * 28.0)
	for i in range(4, 0, -1):
		var kt := maxf(k - i * 0.05, 0.0)
		var p := from.lerp(to, kt) + Vector2(0, -sin(kt * PI) * 28.0)
		draw_circle(p, 4.0 - i * 0.6, Color(CYAN, 0.35 - i * 0.07))
	var r := Rect2(Vector2.ZERO, cassette.size.lerp(target.size, k))
	r.position = from.lerp(to, k) + arc - r.size / 2.0
	draw_texture_rect_region(Candy.SPRITE, r, region)


func _draw_hint(font: Font) -> void:
	var lines := DialogueBox.wrap(font, _hint, minf(376, size.x - 44), 16)
	var width := DialogueBox.width(font, lines, 16, minf(400, size.x - 24))
	var rect := Rect2(12, 88, width, DialogueBox.height(lines.size(), 16, false))
	if _subtitle_t > 0.0 and _speech_source != null:
		var speech := _speech_layout(font)
		if not speech.is_empty() and rect.intersects(speech.rect.grow(8)):
			var left_space: float = speech.rect.position.x - 24
			var right_edge := size.x - 202 if _pickup_t > PICKUP_FLY else size.x - 12
			var right_space: float = right_edge - speech.rect.end.x - 12
			if left_space >= 140 or right_space >= 140:
				var available := left_space if left_space >= 140 else right_space
				lines = DialogueBox.wrap(font, _hint, minf(376, available - 20), 16)
				rect.size = Vector2(DialogueBox.width(font, lines, 16, available), DialogueBox.height(lines.size(), 16, false))
				if left_space < 140:
					rect.position.x = speech.rect.end.x + 12
			else:
				rect.position.y = size.y - PANEL_H - 32 - rect.size.y
	DialogueBox.draw_instruction(self, font, lines, rect, 16)


func _draw_cinematic_caption(font: Font, text: String, y: float, color: Color) -> void:
	var lines := DialogueBox.wrap(font, text, size.x - 64, 16)
	var width := DialogueBox.width(font, lines, 16, size.x - 40)
	var h := DialogueBox.height(lines.size(), 16, false)
	DialogueBox.draw_instruction(self, font, lines, Rect2((size.x - width) / 2.0, y - h, width, h), 16)


func _draw_rewind_cue(font: Font) -> void:
	var w := size.x
	draw_rect(Rect2(6, 6, w - 12, size.y - PANEL_H - 12), VIOLET, false, 2.0)
	var band := Rect2(w / 2.0 - 106, 212, 212, 25)
	draw_rect(band, Color(0.08, 0.04, 0.17, 0.83))
	draw_rect(band, VIOLET, false, 1.0)
	draw_string(font, Vector2(0, 230), "HOUSE REWINDS  ◀◀", HORIZONTAL_ALIGNMENT_CENTER, w, 20, OSD)


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
		elif row == 3:
			r = Rect2(a, y - 5, maxf(b - a, 2.0), 3)
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
	draw_rect(Rect2(0, top, w, PANEL_H), Color(0.045, 0.04, 0.065, 0.97))
	draw_rect(Rect2(0, top, w, 1), Color(0.28, 0.27, 0.35))
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
	var col := Color(0.14, 0.13, 0.19) if not down else Color(0.18, 0.32, 0.35)
	if locked:
		col = Color(0.075, 0.065, 0.10)
	draw_rect(face, col)
	draw_rect(face, Color(0.33, 0.32, 0.41) if not locked else Color(0.15, 0.14, 0.19), false, 1.0)
	var label: String = b[1]
	var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(font, Vector2(face.get_center().x - tw / 2.0, face.position.y + 14), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, OSD if not locked else Color(0.28, 0.26, 0.34))
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
	var cue_ink := Color(0.66, 0.76, 0.66, 0.85)
	draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-7, -9), tip + Vector2(7, -9)]), cue_ink)
	draw_rect(Rect2(tip.x - 2, tip.y - 30, 4, 21), cue_ink)

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
	DialogueBox.draw_osd_panel(self, Rect2(x - 8, top - 6, total + cap_w + 28, H + 16))
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
	draw_rect(Rect2(r.position + Vector2(0, DEPTH), r.size), Color(0.07, 0.075, 0.075, 0.85))
	var face := Rect2(r.position + Vector2(0, sink), r.size)
	draw_rect(face, Color(0.34, 0.41, 0.34, 0.9) if down else Color(0.16, 0.17, 0.16, 0.8))
	draw_rect(face, Color(0.65, 0.68, 0.61, 0.65), false, 1.0)
	var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_string(font, Vector2(face.get_center().x - tw / 2.0, face.position.y + 13), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.93, 0.95, 0.89))


func _draw_subtitle(font: Font) -> void:
	var layout := _speech_layout(font)
	if layout.is_empty():
		return
	DialogueBox.draw_speech(self, font, layout.lines, _speaker, layout.rect, CYAN, 16, layout.tip)


func _speech_layout(font: Font) -> Dictionary:
	var max_width := minf(270.0, size.x - 24.0)
	var lines := DialogueBox.wrap(font, _subtitle, max_width - 20, 16)
	var box_width := DialogueBox.width(font, lines, 16, max_width)
	var h := DialogueBox.height(lines.size(), 16)
	if _speech_source != null:
		var source := _speech_source.get_ref() as Node2D
		if not is_instance_valid(source) or not source.is_inside_tree() or not source.is_visible_in_tree():
			return {}
		var anchor := get_global_transform_with_canvas().affine_inverse() * source.get_global_transform_with_canvas() * _speech_offset
		if anchor.x < 0 or anchor.x > size.x or anchor.y < 12 or anchor.y > size.y - PANEL_H:
			return {}
		var x := clampf(anchor.x - box_width / 2, 8, size.x - box_width - 8)
		var y := maxf(6, anchor.y - h - 10)
		return {"lines": lines, "rect": Rect2(x, y, box_width, h), "tip": anchor}
	# Unseen voices stay a caption; only an actual on-screen speaker gets a pointer.
	return {"lines": lines, "rect": Rect2((size.x - box_width) / 2, size.y - 88 - h, box_width, h), "tip": Vector2.INF}


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
