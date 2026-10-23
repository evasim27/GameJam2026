extends Node2D
## The kid on the tape. Doesn't move on its own; the game places it from the RoomRun.
## The node sits on the floor; the sprite is lifted so its feet touch it.

const SHEET := preload("res://assets/rewind/kid.png")
const LOOK_FRAME := 2

var sprite: Sprite2D
var _walk := 0.0


func _init() -> void:
	sprite = Sprite2D.new()
	sprite.texture = SHEET
	sprite.hframes = 3
	sprite.offset = Vector2(0, -12)
	add_child(sprite)


## Lantern glow, drawn as a soft warm circle in front of the kid.
func _draw() -> void:
	if not sprite.visible or sprite.modulate.a < 0.9:
		return
	for i in 3:
		draw_circle(Vector2(7, -6), 10.0 - i * 3.0, Color(1.0, 0.75, 0.35, 0.06 + i * 0.03))


func place(x: float, y: float) -> void:
	var dx := x - position.x
	position = Vector2(x, y)
	if dx > 0.0:
		_walk += dx
		sprite.frame = int(_walk / 4.0) % 2
		sprite.offset.y = -12.0 - (1.0 if sprite.frame == 1 else 0.0)
	queue_redraw()


func stand() -> void:
	sprite.frame = 0
	sprite.offset.y = -12.0
	sprite.modulate = Color.WHITE
	sprite.visible = true
	queue_redraw()


func look_at_camera() -> void:
	sprite.frame = LOOK_FRAME
	queue_redraw()


## Freeze frame, then turn into a see-through echo.
func fail() -> void:
	sprite.modulate = Color(0.75, 1.0, 1.0, 0.5)
	queue_redraw()


func leave() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
