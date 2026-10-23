@tool
class_name GlitchWall
extends TapeObject
## A solid wall that only lets the kid through during tracking glitches on the tape.
## It's not a bug, it's a door.

@export var glitch_windows: Array[Vector2] = [Vector2(14.0, 14.8)]

var _tiles: Array[Sprite2D] = []


func _ready() -> void:
	for i in 3:
		var s := make_tile_sprite(4, 3)
		s.position = Vector2(0, -8 - i * 16)
		add_child(s)
		_tiles.append(s)
	show_time(0.0)


func blocks(t: float) -> bool:
	return not in_windows(t, glitch_windows)


func show_time(t: float) -> void:
	var glitching := not blocks(t)
	for i in _tiles.size():
		var s := _tiles[i]
		if glitching:
			s.offset = Vector2(sin(t * 97.0 + i * 3.0) * 3.0, 0)
			s.modulate = Color(1.0, 0.3, 1.0, 0.45) if i % 2 == 0 else Color(0.3, 1.0, 1.0, 0.45)
		else:
			s.offset = Vector2.ZERO
			s.modulate = Color.WHITE


func screen_effect(t: float) -> Dictionary:
	return {"tracking": 1.0} if not blocks(t) else {}


func timeline_marks(_tape_length: float) -> Array:
	var marks := []
	for w in glitch_windows:
		marks.append({"from": w.x, "to": w.y, "color": Color(1.0, 0.3, 1.0, 0.9)})
	return marks
