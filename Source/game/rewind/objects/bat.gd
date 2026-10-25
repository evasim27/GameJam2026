class_name Bat
extends TapeObject
## Bats let loose by a glitch. The glitch leaves a torn frame on the film; from the moment it
## happened a bat flies in from the right edge of the room every `period` seconds of room time
## and heads for the kid, bobbing up and down. A bat only hurts if it reaches the kid while it is
## down low, so the player times the tape until each one passes over the kid's head.
## Every bat's flight depends only on room time, so rewinding flies them back out of the room.
## With starts_at, a recorded tear repeats automatically instead of waiting for a glitch.

@export var needs_glitch := "wall"
## Finite for recurring damaged tape that releases bats without pressing Glitch.
@export var starts_at := INF
## How long the vertical camera filter flashes at each release.
@export var damage_duration := 0.75
## A new bat flies in every `period` seconds after the glitch.
@export var period := 4.5
@export var speed := 22.0
## Seconds for one dive down and back up.
@export var bob := 2.2
## Earliest entrance x; each release also stays beyond the current camera's right edge.
@export var enter_x := 652.0
## Automatic hallway tears only release while the kid is in their section.
@export var release_from_x := -INF
@export var release_to_x := INF
## Bats give up this far left of where they came in.
@export var reach := 280.0

const HIGH := -44.0
const LOW := -12.0
## A bat lower than this is at the kid's height.
const HEAD := -32.0
const HIT_WIDTH := 5.0
const BAT_SHEET := preload("res://assets/rewind/cinematic/bat-flight-4f.png")
const BAT_FRAME_SIZE := Vector2(128, 128)
const BAT_DRAW_SIZE := Vector2(32, 32)

var _t := 0.0
var _since := INF  # room time of the glitch; INF = not happened yet
var _bats: Array[Vector2] = []
## World-space entrance captured for each wave, so flying bats stay fixed when the camera moves.
var _spawn_x := {}


func advance(run: RoomRun, mode: String, _dt: float) -> void:
	var since := _since_glitch(run)
	if mode == "rewind":
		# Once a birth is wound off the tape, replay it outside the new camera position.
		for wave in _spawn_x.keys():
			if since + wave * period > run.room_time:
				_spawn_x.erase(wave)
	else:
		_record_spawns(run)


func on_glitch(run: RoomRun, id: String) -> void:
	if id == needs_glitch:
		_record_spawns(run)


func _record_spawns(run: RoomRun) -> void:
	var since := _since_glitch(run)
	if run.room_time < since:
		return
	var first := maxi(int(ceil((run.room_time - reach / speed - since) / period)), 0)
	var last := int(floor((run.room_time - since) / period))
	for wave in range(first, last + 1):
		if not _spawn_x.has(wave):
			# The full wing (11 px including its rim) must start outside the picture.
			_spawn_x[wave] = maxf(enter_x, run.right_of_view() + 16.0) if run.kid_x >= release_from_x and run.kid_x <= release_to_x else NAN


func _ready() -> void:
	# In front of doors, their covers and the kid, so a bat is never lost behind the scenery.
	z_index = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Positions of the bats in flight at room time `t`, relative to position.
func bats_at(t: float, since: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if t < since:
		return out
	var life := reach / speed
	var k := maxi(int(ceil((t - life - since) / period)), 0)
	while since + k * period <= t:
		var age := t - (since + k * period)
		if age < life:
			var dive := 0.5 - 0.5 * cos(TAU * age / bob)
			var entrance: float = _spawn_x.get(k, NAN)
			if is_finite(entrance):
				out.append(Vector2(entrance - position.x - speed * age, lerpf(HIGH, LOW, dive)))
		k += 1
	return out


func _since_glitch(run: RoomRun) -> float:
	if is_finite(starts_at):
		return starts_at
	return run.glitch_times.get(needs_glitch, INF) if run.glitched.has(needs_glitch) else INF


func kills(run: RoomRun) -> bool:
	var kid := run.kid_x - position.x
	for b in bats_at(run.room_time, _since_glitch(run)):
		if absf(b.x - kid) < HIT_WIDTH and b.y > HEAD:
			return true
	return false


func hint_target(run: RoomRun) -> float:
	return run.kid_x


func show_time(run: RoomRun) -> void:
	_t = run.room_time
	_since = _since_glitch(run)
	_bats = bats_at(_t, _since)
	queue_redraw()


func screen_effect(run: RoomRun) -> Dictionary:
	var since := _since_glitch(run)
	if run.room_time < since:
		return {}
	var wave := int(floor((run.room_time - since) / period))
	var visible_release := is_finite(float(_spawn_x.get(wave, NAN)))
	# The damaged frame hisses, louder for every bat at the kid's height.
	var low := 0
	for b in bats_at(run.room_time, since):
		if b.y > HEAD:
			low += 1
	var tearing := visible_release and fposmod(run.room_time - since, period) < damage_duration
	return {"noise": 0.04 + 0.06 * low, "bat_tracking": 0.65 if tearing else 0.0}


func _draw() -> void:
	if _t < _since:
		return
	for i in _bats.size():
		var b := _bats[i]
		var drop := clampf((b.y - HIGH) / (LOW - HIGH), 0.0, 1.0)
		# Their shadows on the floor grow as they come down, so a dive reads at a glance.
		draw_rect(Rect2(b.x - 2.0 - 4.0 * drop, -1, 4.0 + 8.0 * drop, 2), Color(0, 0, 0, 0.1 + 0.3 * drop))
		_draw_bat(b.round(), drop, i)


## Facing left, towards the kid.
func _draw_bat(c: Vector2, drop: float, i: int) -> void:
	# Use room time so pausing and rewinding also freeze and reverse the wingbeat.
	var phase := fposmod((_t * (18.0 + 10.0 * drop) + i * 1.3) / TAU, 1.0)
	var frame := mini(int(phase * 4.0), 3)
	draw_texture_rect_region(BAT_SHEET,
		Rect2(c - BAT_DRAW_SIZE / 2.0, BAT_DRAW_SIZE),
		Rect2(Vector2(frame * BAT_FRAME_SIZE.x, 0), BAT_FRAME_SIZE))
