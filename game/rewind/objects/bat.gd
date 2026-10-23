@tool
class_name Bat
extends TapeObject
## A bat that swoops low across its zone on a fixed rhythm.

@export var width := 24.0
@export var period := 5.0
@export var swoop_from := 0.0
@export var swoop_to := 2.5

var _sprite: Sprite2D


func _ready() -> void:
	_sprite = make_tile_sprite(0, 10)
	add_child(_sprite)
	show_time(0.0)


func zone_width() -> float:
	return width


func is_deadly(t: float) -> bool:
	var phase := fposmod(t, period)
	return phase >= swoop_from and phase < swoop_to


func show_time(t: float) -> void:
	if not _sprite:
		return
	var phase := fposmod(t, period)
	if is_deadly(t):
		var k := (phase - swoop_from) / (swoop_to - swoop_from)
		_sprite.position = Vector2(lerpf(-4.0, width + 4.0, k), -8 - 4.0 * sin(k * TAU * 2.0))
	else:
		_sprite.position = Vector2(width / 2.0 + sin(t * 3.0) * 6.0, -56 + sin(t * 9.0) * 2.0)


func timeline_marks(tape_length: float) -> Array:
	var marks := []
	var start := 0.0
	while start < tape_length:
		marks.append({"from": start + swoop_from, "to": minf(start + swoop_to, tape_length), "color": Color(0.85, 0.3, 0.4, 0.55), "row": 1})
		start += period
	return marks
