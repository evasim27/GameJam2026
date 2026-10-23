class_name FalseWall
extends TapeObject
## A wrong frame of wall pasted over the way out. Blocks the kid until its glitch steps it aside.

const WALL := preload("res://assets/rewind/wall.png")

@export var glitch_id := "wall"
@export var size := Vector2(28, 48)
@export var tint := Color(0.3, 0.24, 0.44)

var _open := false


func blocks(run: RoomRun) -> bool:
	return not run.glitched.has(glitch_id)


func show_time(run: RoomRun) -> void:
	var open := run.glitched.has(glitch_id)
	if open != _open:
		_open = open
		queue_redraw()


func _draw() -> void:
	var r := Rect2(-4, -size.y, size.x, size.y)
	if _open:
		r.position.y -= size.y - 6.0  # rolled up out of the frame like a bad splice
	draw_set_transform(r.position, 0.0, Vector2(0.5, 0.5))
	draw_texture_rect(WALL, Rect2(Vector2.ZERO, r.size * 2.0), true, tint)
	draw_set_transform(Vector2.ZERO)
	draw_rect(r, Color(0.05, 0.04, 0.08), false, 1.0)
