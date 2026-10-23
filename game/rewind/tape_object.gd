class_name TapeObject
extends Node2D
## Anything on the tape. Its state must depend only on tape time `t`,
## so scrubbing back and forth always shows the same picture.

const DUNGEON := preload("res://assets/kenney_tiny_dungeon/tilemap_packed.png")


## The kid can't walk through `position.x` while this is true.
func blocks(_t: float) -> bool:
	return false


## Width of the zone starting at `position.x` where `is_deadly` applies.
func zone_width() -> float:
	return 0.0


func is_deadly(_t: float) -> bool:
	return false


## Called every frame with the current tape time to update visuals.
func show_time(_t: float) -> void:
	pass


## How much this object distorts the screen at time t: {tracking, noise}.
func screen_effect(_t: float) -> Dictionary:
	return {}


## Coloured windows to draw on the HUD timeline: [{from, to, color}].
func timeline_marks(_tape_length: float) -> Array:
	return []


static func in_windows(t: float, windows: Array[Vector2]) -> bool:
	for w in windows:
		if t >= w.x and t < w.y:
			return true
	return false


static func make_tile_sprite(col: int, row: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = DUNGEON
	s.region_enabled = true
	s.region_rect = Rect2(col * 16, row * 16, 16, 16)
	return s
