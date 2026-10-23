class_name Door
extends TapeObject
## The way out of a room. The kid leaves when it reaches `position.x`.
## A hidden door only exists once its glitch has happened; `cover` is what hid it.

@export var needs_glitch := ""
@export var cover: Texture2D
@export var cover_slide := Vector2(24, 0)
@export var light := Color(1.0, 0.75, 0.4)

var _open := true
var _cover: Sprite2D


func _ready() -> void:
	_open = needs_glitch == ""
	if cover:
		_cover = Sprite2D.new()
		_cover.texture = cover
		_cover.scale = Vector2(0.5, 0.5)
		_cover.offset = Vector2(0, -32)
		_cover.position = Vector2(8, 0)
		_cover.z_index = 1
		add_child(_cover)


func is_exit(run: RoomRun) -> bool:
	return needs_glitch == "" or run.glitched.has(needs_glitch)


func show_time(run: RoomRun) -> void:
	var was := _open
	_open = is_exit(run)
	if _cover:
		_cover.position = Vector2(8, 0) + (cover_slide if _open else Vector2.ZERO)
	if was != _open:
		queue_redraw()


func _draw() -> void:
	if not _open:
		return
	var r := Rect2(-2, -34, 20, 34)
	draw_rect(r, Color(0.16, 0.09, 0.08))
	draw_rect(r.grow(-2), Color(0.36, 0.2, 0.14))
	draw_rect(Rect2(1, -30, 14, 11), Color(0.3, 0.16, 0.12))
	draw_rect(Rect2(1, -16, 14, 13), Color(0.3, 0.16, 0.12))
	draw_rect(Rect2(12, -18, 2, 2), Color(1.0, 0.7, 0.3))
	# Light leaking under and around the door.
	var l := light
	l.a = 0.5
	draw_rect(Rect2(-2, -1, 20, 1), l)
	l.a = 0.2
	draw_rect(Rect2(-3, -35, 1, 34), l)
	draw_rect(Rect2(18, -35, 1, 34), l)
