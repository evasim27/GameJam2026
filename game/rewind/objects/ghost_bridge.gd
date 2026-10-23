@tool
class_name GhostBridge
extends TapeObject
## A pit with a bridge that only exists while the tape is full of static.

const PLANK := Rect2(16, 48, 16, 16)

@export var width := 32.0
@export var static_windows: Array[Vector2] = [Vector2(19.0, 23.0)]

var _planks: Array[Sprite2D] = []


func _ready() -> void:
	var count := int(width / 16.0)
	for i in count:
		var s := make_tile_sprite(1, 3)
		s.position = Vector2(8 + i * 16, 8)
		add_child(s)
		_planks.append(s)
	show_time(0.0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, width, 60), Color(0.02, 0.01, 0.04))


func zone_width() -> float:
	return width


func is_deadly(t: float) -> bool:
	return not in_windows(t, static_windows)


func show_time(t: float) -> void:
	var solid := not is_deadly(t)
	for i in _planks.size():
		var flicker := 0.12 + 0.08 * sin(t * 40.0 + i)
		_planks[i].modulate = Color(0.6, 1.0, 1.0, 0.85) if solid else Color(0.6, 1.0, 1.0, flicker)


func screen_effect(t: float) -> Dictionary:
	return {"noise": 0.3} if not is_deadly(t) else {}


func timeline_marks(_tape_length: float) -> Array:
	var marks := []
	for w in static_windows:
		marks.append({"from": w.x, "to": w.y, "color": Color(0.5, 1.0, 1.0, 0.8)})
	return marks
