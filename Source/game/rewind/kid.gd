extends Node2D
## The kid on the tape. Doesn't move on its own; the game places it from the RoomRun.
## The node sits on the floor; the sprite is lifted so its feet touch it.
## Same character as the intro: the 6-frame walk sheet (40x56 frames), drawn at half size.

const SHEET := preload("res://assets/exterior/player_walk_6f.png")
const FRAMES := 6
const SCALE := 0.5
## Feet are on the bottom row of each frame.
const FEET_OFFSET := -27.0
## Room pixels walked per animation frame.
const STRIDE := 3.0

var sprite: Sprite2D
var _walk := 0.0


func _init() -> void:
	sprite = Sprite2D.new()
	sprite.texture = SHEET
	sprite.hframes = FRAMES
	sprite.scale = Vector2(SCALE, SCALE)
	sprite.offset = Vector2(0, FEET_OFFSET)
	add_child(sprite)


## Glow of the pumpkin bucket, drawn as a soft warm circle in front of the kid.
func _draw() -> void:
	if not sprite.visible or sprite.modulate.a < 0.9:
		return
	for i in 3:
		draw_circle(Vector2(7 if not sprite.flip_h else -7, -5), 10.0 - i * 3.0, Color(1.0, 0.75, 0.35, 0.06 + i * 0.03))


func place(x: float, y: float) -> void:
	var dx := x - position.x
	position = Vector2(x, y)
	if dx > 0.0:
		_walk += dx
		sprite.frame = int(_walk / STRIDE) % FRAMES
	queue_redraw()


func stand() -> void:
	sprite.frame = 0
	sprite.modulate = Color.WHITE
	sprite.visible = true
	queue_redraw()


## The sheet has no front-facing frame, so the kid stops and turns back toward the viewer's side.
func look_at_camera() -> void:
	sprite.frame = 0
	sprite.flip_h = true
	queue_redraw()


## Freeze frame, then turn into a see-through echo.
func fail() -> void:
	sprite.modulate = Color(0.75, 1.0, 1.0, 0.5)
	queue_redraw()


func leave() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
