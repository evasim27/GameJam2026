@tool
extends TapeObject
## Decoration. Bobs with tape time, so it also moves backwards when you rewind.

@export var phase := 0.0

var _sprite: Sprite2D


func _ready() -> void:
	_sprite = make_tile_sprite(1, 10)
	_sprite.modulate = Color(0.8, 0.9, 1.0, 0.55)
	add_child(_sprite)
	show_time(0.0)


func show_time(t: float) -> void:
	if _sprite:
		_sprite.position = Vector2(sin(t * 0.7 + phase) * 10.0, sin(t * 2.0 + phase) * 4.0)
