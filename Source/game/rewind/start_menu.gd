extends Control
## Wait for PLAY before creating the intro or starting any audio.

signal play_requested

const BACKDROP := preload("res://assets/exterior/exterior_background.png")
const TITLE_FONT := preload("res://assets/fonts/Nosifer-Regular.ttf")
const INK := Color(0.93, 0.95, 1.0)
const VIOLET := Color(0.78, 0.61, 1.0)
const DIM := Color(0.6, 0.6, 0.72)

var _play_button: Button
var _mute_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := TextureRect.new()
	backdrop.texture = BACKDROP
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.02, 0.045, 0.8)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	center.add_child(column)
	column.add_child(_label("VHS / SP     ·     31 / 10 / 1989", 14, DIM))
	var title := _label("LOST IN TAPE", 32, INK)
	title.add_theme_font_override("font", TITLE_FONT)
	column.add_child(title)
	column.add_child(_label("You control the tape. Not Lea.", 19, VIOLET))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 8
	column.add_child(spacer)

	_play_button = _button("PLAY")
	_play_button.pressed.connect(_play)
	column.add_child(_play_button)
	_mute_button = _button("MUTE")
	_mute_button.toggle_mode = true
	_mute_button.button_pressed = AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))
	_mute_button.toggled.connect(_set_muted)
	column.add_child(_mute_button)
	_update_mute_label()
	column.add_child(_label("UP / DOWN: select    ENTER / SPACE: confirm", 14, DIM))
	_play_button.grab_focus()


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(240, 38)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 23)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", VIOLET)
	button.add_theme_color_override("font_focus_color", VIOLET)
	for state_name in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.045, 0.09, 0.92)
		style.border_color = VIOLET if state_name != "normal" else Color(0.34, 0.29, 0.42)
		style.set_border_width_all(2 if state_name == "focus" else 1)
		style.set_corner_radius_all(3)
		button.add_theme_stylebox_override(state_name, style)
	return button


func _set_muted(muted: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), muted)
	_update_mute_label()


func _update_mute_label() -> void:
	_mute_button.text = "UNMUTE" if _mute_button.button_pressed else "MUTE"
	_mute_button.tooltip_text = "Turn all music and sound effects back on" if _mute_button.button_pressed else "Mute all music and sound effects"


func _play() -> void:
	_play_button.disabled = true
	_mute_button.disabled = true
	play_requested.emit()
