@tool
class_name ClockDoor
extends TapeObject
## A door that the grandfather clock opens at `open_at` and shuts again at `close_at`.

@export var open_at := 6.0
@export var close_at := 999.0

var _closed: Sprite2D
var _open: Sprite2D
var _label: Label


func _ready() -> void:
	_closed = make_tile_sprite(9, 3)
	_open = make_tile_sprite(9, 1)
	for s in [_closed, _open]:
		s.position = Vector2(0, -8)
		add_child(s)
	_label = Label.new()
	_label.text = "%d:%02d" % [int(open_at) / 60, int(open_at) % 60]
	_label.position = Vector2(-10, -30)
	_label.scale = Vector2(0.5, 0.5)
	_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	add_child(_label)
	show_time(0.0)


func blocks(t: float) -> bool:
	return t < open_at or t >= close_at


func show_time(t: float) -> void:
	if not _closed:
		return
	var shut := blocks(t)
	_closed.visible = shut
	_open.visible = not shut


func timeline_marks(tape_length: float) -> Array:
	return [{"from": open_at, "to": minf(open_at + 0.4, tape_length), "color": Color(1.0, 0.85, 0.45)}]
