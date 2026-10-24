class_name Door
extends TapeObject
## The way out of a room. The kid leaves when it reaches `position.x`.
## A hidden door only exists once its glitch has happened; `cover` is what hid it.

const ART := preload("res://rewind/door_art.gd")

@export var needs_glitch := ""
@export var cover: Texture2D
@export var cover_slide := Vector2(24, 0)
@export var light := Color(1.0, 0.75, 0.4)
@export var visual_size := Vector2(36, 64)

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
	ART.draw_door(self, Rect2(Vector2(-visual_size.x / 2.0, -visual_size.y), visual_size), true, light)
