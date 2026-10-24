class_name TapeEater
extends TapeObject
## Blinking reels watch from darkness until the kid wakes a tape creature and its devouring void.
## Still on Pause, creeping on Play, lunging on Rewind; `run.eater` is its progress (0..1).
## Glitching the reel by the VCR duplicates an empty frame and it jumps into the TV instead.

const MONSTER := preload("res://assets/rewind/cinematic/tape-monster.png")
const EYES := preload("res://rewind/objects/tape_monster_eyes.tscn")
const VOID_SHADER := preload("res://rewind/tape_void.gdshader")
# Alpha bounds of the generated sprite, excluding the transparent outer margin.
const MONSTER_REGION := Rect2(76, 128, 1850, 552)

const RED := Color(0.6, 0.1, 0.1)
const BROWN := Color(0.25, 0.12, 0.08)

@export var trigger_x := 150.0
## Room-space point inside the second shelf, configured by the room.
@export var hiding_spot := Vector2(49, 79)
@export var play_rate := 0.2
@export var rewind_rate := 0.4
@export var banish_glitch := "reel"
## Where it ends up after the glitch, relative to position.
@export var tv := Vector2(0, -60)

var _t := 0.0
var _p := 0.0
var _banished := false
var _kid := Vector2.ZERO
var _eyes: AnimatedSprite2D
var _void: ColorRect
var _void_material: ShaderMaterial


func _ready() -> void:
	z_index = 20
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_void_material = ShaderMaterial.new()
	_void_material.shader = VOID_SHADER
	_void = ColorRect.new()
	_void.material = _void_material
	_void.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_void.z_index = -20
	add_child(_void)
	_eyes = EYES.instantiate() as AnimatedSprite2D
	_eyes.position = hiding_spot - position
	_eyes.scale = Vector2(0.015, 0.015)
	# Tiny eyes are part of the shelf scenery, behind the kid and attack effects.
	_eyes.z_index = -20
	_eyes.modulate = Color(0.45, 0.37, 0.30, 0.9)
	add_child(_eyes)
	_eyes.stop()


func active(run: RoomRun) -> bool:
	return run.kid_x >= trigger_x and not run.glitched.has(banish_glitch)


func advance(run: RoomRun, mode: String, dt: float) -> void:
	if active(run):
		run.eater = minf(run.eater + dt * (play_rate if mode == "play" else rewind_rate), 1.0)


func kills(run: RoomRun) -> bool:
	return active(run) and run.eater >= 1.0


func show_time(run: RoomRun) -> void:
	_t = run.room_time
	_p = run.eater
	_banished = run.glitched.has(banish_glitch)
	_kid = Vector2(run.kid_x, run.kid_y()) - position
	if is_instance_valid(_eyes):
		_eyes.visible = not _banished and _p <= 0.0
		# Tape time drives the blink too: Pause freezes it and Rewind reverses it.
		var phase := fposmod(_t, 1.24)
		var frame := 0 if phase < 1.0 else (1 if phase < 1.07 else (2 if phase < 1.17 else 3))
		_eyes.set_frame_and_progress(frame, 0.0)
	queue_redraw()


func _draw() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_update_void()
	if _banished:
		# The same creature is now trapped inside the CRT picture.
		var flicker := 0.75 + 0.25 * sin(_t * 19.0)
		draw_texture_rect_region(MONSTER, Rect2(tv + Vector2(-12, -4), Vector2(24, 8)), MONSTER_REGION, Color(0.65, 0.85, 0.85, flicker))
		return
	if _p <= 0.0:
		return
	_draw_devouring_wave()
	_draw_glitch_particles()


## Keep the consuming void in the camera bounds as the character moves.
func _update_void() -> void:
	if not is_instance_valid(_void):
		return
	_void.visible = not _banished and _p > 0.0
	if not _void.visible:
		return
	var view: Rect2 = get_global_transform_with_canvas().affine_inverse() * get_viewport_rect()
	_void.position = view.position
	_void.size = view.size
	_void_material.set_shader_parameter("tape_time", _t)
	_void.z_index = -1
	var center := Vector2(_devouring_front(view) - 12.0, _kid.y - 20.0)
	_void_material.set_shader_parameter("center", (center - view.position) / view.size)
	_void_material.set_shader_parameter("front", (_devouring_front(view) - view.position.x) / view.size.x)


func _devouring_front(view: Rect2) -> float:
	var front := lerpf(view.position.x - 12.0, _kid.x - 10.0, minf(_p / 0.9, 1.0))
	if _p > 0.9:
		front = lerpf(_kid.x - 10.0, view.end.x + 108.0, smoothstep(0.9, 1.0, _p))
	return front


func _draw_devouring_wave() -> void:
	var view: Rect2 = get_global_transform_with_canvas().affine_inverse() * get_viewport_rect()
	var front := _devouring_front(view)
	# A compact tape creature leads the destruction instead of filling the whole screen itself.
	var size := Vector2(108.0, 108.0 * MONSTER_REGION.size.y / MONSTER_REGION.size.x)
	var bob := sin(_t * 5.0) * 1.25
	var origin := Vector2(front - size.x, _kid.y - size.y + 2.0 + bob)
	draw_texture_rect_region(MONSTER, Rect2(origin, size), MONSTER_REGION)


## Tape-time particles pull broken pixels off the surviving picture into the void.
## No wall-clock emitter: Pause freezes the fragments and Rewind reverses their motion.
func _draw_glitch_particles() -> void:
	var strength := minf(_p * 8.0, 1.0) * (1.0 - smoothstep(0.94, 1.0, _p))
	if strength <= 0.0:
		return
	var view: Rect2 = get_global_transform_with_canvas().affine_inverse() * get_viewport_rect()
	var front := _devouring_front(view)
	var sink_y := _kid.y - 20.0
	var colors := [Color(0.32, 0.62, 0.64), Color(0.54, 0.26, 0.45), Color(0.7, 0.64, 0.52), Color(0.18, 0.23, 0.26)]
	for i in 96:
		var seed := fposmod(float(i) * 0.6180339, 1.0)
		var age := fposmod(_t * (0.65 + seed * 0.6) + seed * 9.0, 1.0)
		var source_y := view.position.y + fposmod(float(i) * 0.7548776, 1.0) * view.size.y
		var edge := front - 0.16 * pow(absf((source_y - sink_y) / view.size.y), 0.65) * view.size.x
		var x := edge + 24.0 * (1.0 - age) - 18.0 * age * age
		var y := lerpf(source_y, sink_y, age * age * 0.75) + sin(age * 8.0 + i) * 2.0
		var pos := Vector2(x, y).round()
		var size := Vector2(1.0 + float(i % 5), 1.0 + float(i % 2))
		var color: Color = colors[i % colors.size()]
		color.a = sin(age * PI) * strength * (0.45 + seed * 0.5)
		draw_rect(Rect2(pos, size), color)
		if i % 4 == 0:
			# Separated RGB echoes and short horizontal scanline tears.
			var ghost := Color(0.28, 0.58, 0.65, color.a * 0.35)
			draw_rect(Rect2(pos + Vector2(3, -1), size), ghost)
			draw_line(pos + Vector2(size.x + 1, 0), pos + Vector2(size.x + 5, 0), Color(color, color.a * 0.3), 1.0)


func screen_effect(run: RoomRun) -> Dictionary:
	return {"noise": 0.06 * run.eater} if active(run) else {}
