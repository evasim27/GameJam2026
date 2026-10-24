class_name TapeEater
extends TapeObject
## The End of Tape boss. Blinking reels watch from darkness until the kid wakes a tape creature
## and its devouring void; spilled tape holds the kid at `hold_x` until the fight is over.
## `run.eater` is its progress towards the playhead (0..1), reaching 1 is SIGNAL LOST.
##
## Phase 1, The Reel: it crawls out of the VCR, creeping on Play and lunging on Rewind.
## The wound reel flashes blue now and then; glitching it then jams the tape and knocks it back.
## Phase 2, The Screen: it hides in the CRT, which alternates between the monster and an empty
## frame on play time (kid_time), while a strong static wave rolls by on room time. Only
## rewinding shifts one against the other. Rewinding feeds it, except while the TV shows the
## empty frame. Glitching when the empty frame meets the wave lets the picture swallow it.

const MONSTER := preload("res://assets/rewind/cinematic/tape-monster.png")
const EYES := preload("res://rewind/objects/tape_monster_eyes.tscn")
const VOID_SHADER := preload("res://rewind/tape_void.gdshader")
# Alpha bounds of the generated sprite, excluding the transparent outer margin.
const MONSTER_REGION := Rect2(51, 23, 2094, 701)

const RED := Color(0.6, 0.1, 0.1)
const BROWN := Color(0.25, 0.12, 0.08)
const TAPE := Color(0.18, 0.1, 0.07)
const BLUE := Color(0.3, 0.55, 1.0)
## Reels on top of the VCR, relative to position. The first one is the wound reel.
const REELS := [Vector2(-14, -4), Vector2(-3, -4)]
const COLLAPSE := 0.8

enum Phase { DORMANT, REEL, SCREEN, DEFEATED }

@export var trigger_x := 150.0
## The spilled tape stops the kid here until the boss is beaten.
@export var hold_x := 166.0
## Room-space point inside the second shelf, configured by the room.
@export var hiding_spot := Vector2(49, 79)
@export var play_rate := 0.2
@export var rewind_rate := 0.5
@export var jam_glitch := "reel"
@export var screen_glitch := "screen"
## The CRT picture, relative to position.
@export var screen := Rect2(46, -46, 33, 22)
## Phase 2 cycle: the monster fills the TV for `monster_time`, then the empty frame shows.
@export var screen_period := 3.0
@export var monster_time := 1.6
## When the static wave rolls through, in room time since the jam (same period).
@export var wave_from := 0.3
@export var wave_to := 0.9

var reel_spot: GlitchSpot

var _t := 0.0
var _p := 0.0
var _phase := Phase.DORMANT
var _empty := false
var _wave := 0.0  # 0..1 through the static wave, -1 outside it
var _since_defeat := 0.0
var _reel_open := false
var _kid := Vector2.ZERO
var _eyes: AnimatedSprite2D
var _void: ColorRect
var _void_material: ShaderMaterial
var _ribbon_mesh := ArrayMesh.new()


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


func phase(run: RoomRun) -> Phase:
	if run.glitched.has(screen_glitch):
		return Phase.DEFEATED
	if run.glitched.has(jam_glitch):
		return Phase.SCREEN
	return Phase.REEL if run.kid_x >= trigger_x else Phase.DORMANT


func active(run: RoomRun) -> bool:
	var p := phase(run)
	return p == Phase.REEL or p == Phase.SCREEN


## Phase 2: the TV shows the empty frame. Runs on play time, so Pause and Rewind freeze it.
func empty_frame(run: RoomRun) -> bool:
	return phase(run) == Phase.SCREEN and fposmod(_screen_clock(run), screen_period) >= monster_time


## Phase 2: the static wave rolls through the picture. Runs on room time.
func static_wave(run: RoomRun) -> bool:
	return phase(run) == Phase.SCREEN and periodic(_wave_clock(run), screen_period, wave_from, wave_to)


func _screen_clock(run: RoomRun) -> float:
	return run.kid_time - run.glitch_kid_times.get(jam_glitch, 0.0)


func _wave_clock(run: RoomRun) -> float:
	return run.room_time - run.glitch_times.get(jam_glitch, 0.0)


func blocks(run: RoomRun) -> bool:
	return phase(run) != Phase.DEFEATED


func block_x() -> float:
	return hold_x


func advance(run: RoomRun, mode: String, dt: float) -> void:
	if not active(run):
		return
	var rate := play_rate
	if mode != "play":
		# Rewind feeds it. The empty frame doesn't.
		rate = 0.0 if empty_frame(run) else rewind_rate
	run.eater = minf(run.eater + dt * rate, 1.0)


## The jam knocks it back into the machine; it has to cross the whole picture again.
func on_glitch(run: RoomRun, id: String) -> void:
	if id == jam_glitch:
		run.eater = 0.0


func kills(run: RoomRun) -> bool:
	return active(run) and run.eater >= 1.0


func hint_target(run: RoomRun) -> float:
	if phase(run) == Phase.SCREEN:
		return position.x + screen.get_center().x
	return super.hint_target(run)


func show_time(run: RoomRun) -> void:
	_t = run.room_time
	_p = run.eater
	_phase = phase(run)
	_empty = empty_frame(run)
	_wave = -1.0
	if static_wave(run):
		_wave = inverse_lerp(wave_from, wave_to, fposmod(_wave_clock(run), screen_period))
	_since_defeat = run.room_time - run.glitch_times.get(screen_glitch, 0.0)
	_reel_open = reel_spot != null and reel_spot.can_glitch(run)
	_kid = Vector2(run.kid_x, run.kid_y()) - position
	if is_instance_valid(_eyes):
		_eyes.visible = _phase == Phase.DORMANT or (_phase == Phase.REEL and _p <= 0.0)
		# Tape time drives the blink too: Pause freezes it and Rewind reverses it.
		var phase_t := fposmod(_t, 1.24)
		var frame := 0 if phase_t < 1.0 else (1 if phase_t < 1.07 else (2 if phase_t < 1.17 else 3))
		_eyes.set_frame_and_progress(frame, 0.0)
	queue_redraw()


func _draw() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_update_void()
	_draw_reels()
	match _phase:
		Phase.REEL:
			_draw_held_kid()
			if _p > 0.0:
				_draw_devouring_wave()
				_draw_glitch_particles()
		Phase.SCREEN:
			_draw_held_kid()
			_draw_screen()
			if _p > 0.0:
				_draw_glitch_particles()
		Phase.DEFEATED:
			_draw_swallowed()


## Two reels on the deck. They turn with room time, jam spills tape, and defeat stops both.
func _draw_reels() -> void:
	var spin := _t * 4.0
	if _phase == Phase.DEFEATED:
		spin = 0.6
	if _reel_open:
		# The damaged reel flashes blue: this is the frame to catch.
		for i in 4:
			draw_circle(REELS[0], 5.0 + i * 2.0, Color(BLUE, 0.16 - i * 0.03))
	for i in REELS.size():
		var c: Vector2 = REELS[i]
		draw_circle(c, 4.0, Color(0.06, 0.04, 0.04))
		var rim := BLUE if i == 0 and _reel_open else Color(0.35, 0.2, 0.15)
		draw_arc(c, 4.0, 0, TAU, 12, rim, 1.0)
		draw_circle(c, 2.4 if i == 0 else 1.6, TAPE)  # wound tape
		for k in 3:
			var a := spin * (1.0 if i == 0 else 1.4) + k * TAU / 3.0
			draw_line(c, c + Vector2.from_angle(a) * 3.5, Color(0.55, 0.5, 0.45), 1.0)
	if _phase == Phase.SCREEN or _phase == Phase.DEFEATED:
		# The jam: a loop of tape spilled out of the wound reel and down the side of the deck.
		var sway := sin(_t * 3.0) if _phase == Phase.SCREEN else 0.0
		var pts := PackedVector2Array()
		for k in 9:
			var f := k / 8.0
			pts.append(REELS[0] + Vector2(-4.0 - 6.0 * sin(f * PI) + sway, f * 9.0))
		draw_polyline(pts, TAPE, 1.0)


## Spilled tape runs from the VCR along the floor and wraps the kid's ankles.
func _draw_held_kid() -> void:
	if _kid.x < hold_x - position.x - 1.0:
		return
	var feet := _kid + Vector2(0, -1)
	for s in 2:
		var pts := PackedVector2Array()
		var from := Vector2(4.0 + s * 3.0, 0.0)
		for k in 13:
			var f := k / 12.0
			var p := from.lerp(feet + Vector2(-2 + s * 3, -s * 2), f)
			p.y += sin(f * PI) * 2.0 + sin(_t * 6.0 + f * 9.0 + s) * 0.6
			pts.append(p)
		draw_polyline(pts, TAPE, 1.0)
	for k in 3:
		draw_arc(feet + Vector2(0, -1 - k * 2), 3.0, 0, TAU, 8, Color(TAPE, 0.9), 1.0)


## Phase 2: the CRT alternates between the monster and the empty frame; the wave rolls over both.
func _draw_screen() -> void:
	var r := screen
	if _empty:
		# The empty frame: an empty dark room with a faint timestamp.
		draw_rect(r, Color(0.06, 0.07, 0.09))
		draw_rect(Rect2(r.position + Vector2(2, r.size.y - 6), Vector2(r.size.x - 4, 4)), Color(0.1, 0.1, 0.12))
		draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(5, 1)), Color(0.7, 0.75, 0.8, 0.5))
	else:
		draw_rect(r, Color(0.12, 0.03, 0.03))
		var bob := sin(_t * 9.0) * 0.8
		# Pressed up against the glass, filling the picture's width.
		var size := Vector2(r.size.x - 2, (r.size.x - 2) * MONSTER_REGION.size.y / MONSTER_REGION.size.x) * 1.0
		var origin := Vector2(r.position.x + 1, r.get_center().y - size.y / 2.0 + bob)
		_draw_animated_monster(Rect2(origin, size), Color(1.0, 0.75, 0.75))
	if _wave >= 0.0:
		# The strong static wave: a bright band of snow rolling down the picture.
		var noise_seed := int(_t * 30.0)
		var band_y := r.position.y + _wave * r.size.y
		for k in 70:
			var x := r.position.x + float((noise_seed * 17 + k * 37) % int(r.size.x))
			var y := r.position.y + float((noise_seed * 29 + k * 53) % int(r.size.y))
			var near := 1.0 - minf(absf(y - band_y) / 6.0, 1.0)
			draw_rect(Rect2(x, y, 1, 1), Color(0.9, 0.95, 1.0, 0.25 + 0.7 * near))
		draw_rect(Rect2(r.position.x, band_y - 1, r.size.x, 3), Color(0.85, 0.92, 1.0, 0.7))
	for y in range(int(r.position.y), int(r.end.y), 2):
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color(0, 0, 0, 0.25), 1.0)


## The picture swallows the monster: it squeezes into a line, then into a dot, like a CRT off.
func _draw_swallowed() -> void:
	var r := screen
	var f := 1.0 if _since_defeat < 0.0 else clampf(_since_defeat / COLLAPSE, 0.0, 1.0)
	draw_rect(r, Color(0.02, 0.02, 0.03))
	if f < 1.0:
		var squash := Rect2(r.position.x, r.get_center().y - r.size.y * 0.5 * (1.0 - f), r.size.x, maxf(r.size.y * (1.0 - f), 1.0))
		if f > 0.6:
			var w := r.size.x * (1.0 - (f - 0.6) / 0.4)
			squash = Rect2(r.get_center().x - w / 2.0, r.get_center().y, maxf(w, 1.0), 1.0)
		draw_texture_rect_region(MONSTER, squash, MONSTER_REGION, Color(1.6, 1.6, 1.8))
	else:
		draw_rect(Rect2(r.get_center() - Vector2(0.5, 0.5), Vector2.ONE), Color(0.8, 0.9, 1.0, 0.5))


## Keep the consuming void in the camera bounds as the character moves.
func _update_void() -> void:
	if not is_instance_valid(_void):
		return
	_void.visible = (_phase == Phase.REEL or _phase == Phase.SCREEN) and _p > 0.0
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
	_draw_animated_monster(Rect2(origin, size))


## Bend the existing ribbons gently, keeping the reel eyes and mouth anchored.
## Room time makes Pause freeze the pose and Rewind run the same motion backwards.
func _draw_animated_monster(rect: Rect2, tint := Color.WHITE) -> void:
	const COLUMNS := 48
	const ROWS := 8
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var texture_size := Vector2(MONSTER.get_size())
	# Twelve poses per second preserve the stepped feel of the pixel-art sprites.
	var animation_time := floorf(_t * 12.0) / 12.0
	for row in range(ROWS + 1):
		for column in range(COLUMNS + 1):
			var uv := Vector2(float(column) / COLUMNS, float(row) / ROWS)
			var loose := 1.0 - smoothstep(0.60, 0.78, uv.x)
			var wave := animation_time * TAU * 0.75 + uv.x * TAU * 1.5
			# Different phases across the ribbon mass keep this from moving as one slab.
			var offset := Vector2(
				sin(wave * 0.5 + uv.y * TAU) * 0.45,
				sin(wave + uv.y * PI) * 1.35
			) * loose * (rect.size.x / 108.0)
			var point := rect.position + uv * rect.size + offset
			vertices.append(Vector3(point.x, point.y, 0.0))
			uvs.append((MONSTER_REGION.position + uv * MONSTER_REGION.size) / texture_size)
	for row in ROWS:
		for column in COLUMNS:
			var top := row * (COLUMNS + 1) + column
			var bottom := top + COLUMNS + 1
			indices.append_array(PackedInt32Array([top, top + 1, bottom, top + 1, bottom + 1, bottom]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	_ribbon_mesh.clear_surfaces()
	_ribbon_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	draw_mesh(_ribbon_mesh, MONSTER, Transform2D.IDENTITY, tint)


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
	if not active(run):
		return {}
	if static_wave(run):
		return {"noise": 0.06 * run.eater + 0.3, "tracking": 0.4}
	return {"noise": 0.06 * run.eater}
