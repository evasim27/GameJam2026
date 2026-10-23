extends Node2D
## The echo of a failed attempt: a pale copy of the kid hovering where it failed.
## The newest one points at what matters, turns to the camera when the kid comes close and says
## one line; older ones just hover. A `bridge` echo stands still in a hole, its head at floor level.

const SHEET := preload("res://assets/exterior/player_walk_6f.png")
const KidNode := preload("res://rewind/kid.gd")
## The kid's sprite, tinted pale cyan.
const TINT := Color(0.6, 1.0, 1.0)

var target_x := 0.0
var line := ""
var sprite: Sprite2D
var _t := 0.0
var _facing_camera := false
var bridge := false
var quiet := false


func _init() -> void:
	sprite = Sprite2D.new()
	sprite.texture = SHEET
	sprite.hframes = KidNode.FRAMES
	sprite.scale = Vector2(KidNode.SCALE, KidNode.SCALE)
	sprite.offset = Vector2(0, KidNode.FEET_OFFSET)
	sprite.modulate = TINT
	add_child(sprite)


func setup(x: float, y: float, point_at: float, subtitle: String, in_hole := false, silent := false) -> void:
	position = Vector2(x, y)
	target_x = point_at
	line = subtitle
	bridge = in_hole
	quiet = silent or in_hole
	visible = true
	sprite.flip_h = target_x < x


func notice(kid_x: float) -> void:
	_facing_camera = absf(kid_x - position.x) < 28.0
	# No front-facing frame: it turns around to face the kid instead.
	sprite.flip_h = (kid_x < position.x) if _facing_camera else (target_x < position.x)


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	# Hover, and tear at the edges like a bad signal.
	sprite.position = Vector2.ZERO if bridge else Vector2(0, -3.0 + sin(_t * 2.0) * 1.5)
	sprite.offset.x = 1.0 if fmod(_t, 1.7) < 0.08 else 0.0
	sprite.modulate.a = (0.75 + 0.2 * sin(_t * 7.0)) * (0.6 if quiet and not bridge else 1.0)
	queue_redraw()


func _draw() -> void:
	if _facing_camera or quiet:
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
