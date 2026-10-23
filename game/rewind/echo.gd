extends Node2D
## The echo of the last failed attempt: a pale copy of the kid hovering where it failed.
## It points at what matters, turns to the camera when the kid comes close and says one line.

const SHEET := preload("res://assets/rewind/echo.png")

var target_x := 0.0
var line := ""
var sprite: Sprite2D
var _t := 0.0
var _facing_camera := false


func _init() -> void:
	sprite = Sprite2D.new()
	sprite.texture = SHEET
	sprite.hframes = 2
	sprite.offset = Vector2(0, -12)
	add_child(sprite)


func setup(x: float, y: float, point_at: float, subtitle: String) -> void:
	position = Vector2(x, y)
	target_x = point_at
	line = subtitle
	visible = true
	sprite.flip_h = target_x < x


func notice(kid_x: float) -> void:
	_facing_camera = absf(kid_x - position.x) < 28.0
	sprite.frame = 1 if _facing_camera else 0


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	# Hover, and tear at the edges like a bad signal.
	sprite.position = Vector2(0, -3.0 + sin(_t * 2.0) * 1.5)
	sprite.offset.x = 1.0 if fmod(_t, 1.7) < 0.08 else 0.0
	sprite.modulate.a = 0.75 + 0.2 * sin(_t * 7.0)
	queue_redraw()


func _draw() -> void:
	if _facing_camera:
		return
	# A pale arm pointing the way, and a pulsing marker over the spot.
	var dir := signf(target_x - position.x)
	if dir == 0.0:
		dir = 1.0
	var c := Color(0.85, 1.0, 1.0, 0.45 + 0.25 * sin(_t * 4.0))
	draw_line(Vector2(dir * 5, -14), Vector2(dir * 11, -17), c, 1.0)
	var mx := target_x - position.x
	var bob := sin(_t * 4.0) * 2.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(mx - 3, -46 + bob), Vector2(mx + 3, -46 + bob), Vector2(mx, -42 + bob)]), c)
