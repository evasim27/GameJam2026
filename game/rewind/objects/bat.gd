class_name Bat
extends TapeObject
## Bats let loose by a glitch. The glitch leaves a torn frame on the film; from the moment it
## happened a bat flies in from the right edge of the room every `period` seconds of room time
## and heads for the kid, bobbing up and down. A bat only hurts if it reaches the kid while it is
## down low, so the player times the tape until each one passes over the kid's head.
## Every bat's flight depends only on room time, so rewinding flies them back out of the room.

@export var needs_glitch := "wall"
## A new bat flies in every `period` seconds after the glitch.
@export var period := 4.5
@export var speed := 22.0
## Seconds for one dive down and back up.
@export var bob := 2.2
## Room x where the bats come in, just past the right edge of the room.
@export var enter_x := 652.0
## Bats give up this far left of where they came in.
@export var reach := 280.0
## Where the torn frame sits, relative to position.
@export var damage := Rect2(-6, -112, 26, 54)

const HIGH := -44.0
const LOW := -12.0
## A bat lower than this is at the kid's height.
const HEAD := -32.0
const HIT_WIDTH := 5.0

var _t := 0.0
var _since := INF  # room time of the glitch; INF = not happened yet
var _bats: Array[Vector2] = []


func _ready() -> void:
	# In front of doors, their covers and the kid, so a bat is never lost behind the scenery.
	z_index = 2


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
			out.append(Vector2(enter_x - position.x - speed * age, lerpf(HIGH, LOW, dive)))
		k += 1
	return out


func _since_glitch(run: RoomRun) -> float:
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
	if not run.glitched.has(needs_glitch):
		return {}
	# The damaged frame hisses, louder for every bat at the kid's height.
	var low := 0
	for b in _bats:
		if b.y > HEAD:
			low += 1
	return {"noise": 0.04 + 0.06 * low}


func _draw() -> void:
	if _since == INF:
		return
	_draw_damage()
	for i in _bats.size():
		var b := _bats[i]
		var drop := clampf((b.y - HIGH) / (LOW - HIGH), 0.0, 1.0)
		# Their shadows on the floor grow as they come down, so a dive reads at a glance.
		draw_rect(Rect2(b.x - 2.0 - 4.0 * drop, -1, 4.0 + 8.0 * drop, 2), Color(0, 0, 0, 0.1 + 0.3 * drop))
		_draw_bat(b.round(), drop, i)


## Film damage left by the glitch: scratches and colour-split slices.
func _draw_damage() -> void:
	var r := damage
	var flick := int(_t * 12.0)
	var y := r.position.y
	var i := 0
	while y < r.end.y:
		var h := 2.0 + float((flick + i * 5) % 3)
		var shift := float(((flick * 7 + i * 13) % 7) - 3)
		var c := Color(0.4, 1.0, 1.0, 0.22) if (flick + i) % 2 == 0 else Color(1.0, 0.35, 1.0, 0.22)
		draw_rect(Rect2(r.position.x + shift, y, r.size.x, minf(h, r.end.y - y)), c)
		y += h + 2.0
		i += 1
	for k in 3:
		var x := r.position.x + fposmod(float(k * 9 + flick * (k + 1)), r.size.x)
		draw_line(Vector2(x, r.position.y - 20), Vector2(x, 0), Color(0.95, 0.95, 0.85, 0.12), 1.0)


## Facing left, towards the kid.
func _draw_bat(c: Vector2, drop: float, i: int) -> void:
	var flap := sin(_t * (18.0 + 10.0 * drop) + i * 1.3)
	# A pale rim first, one pixel out on every side, so the dark bat reads on dark doorways too.
	var rim := Color(0.85, 0.75, 1.0, 0.7)
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		_bat_shape(c + o, flap, rim, rim)
	_bat_shape(c, flap, Color(0.07, 0.05, 0.09), Color(0.14, 0.09, 0.16))
	var eye := Color(1.0, 0.25, 0.2, 0.7 + 0.3 * drop)
	draw_rect(Rect2(c + Vector2(-2, -1), Vector2.ONE), eye)
	draw_rect(Rect2(c + Vector2(0, -1), Vector2.ONE), eye)


func _bat_shape(c: Vector2, flap: float, body: Color, wing: Color) -> void:
	for side in [-1.0, 1.0]:
		var tip := c + Vector2(side * 10.0, -3.0 - 5.0 * flap)
		var elbow := c + Vector2(side * 6.0, -4.0 - 3.0 * flap)
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(side * 1.5, -1), elbow, tip,
			c + Vector2(side * 8.0, 1.0 - flap), c + Vector2(side * 5.0, 0.5),
			c + Vector2(side * 3.0, 2.0)]), wing)
		draw_line(c + Vector2(side * 1.5, -1), elbow, body, 1.0)
		draw_line(elbow, tip, body, 1.0)
	draw_rect(Rect2(c + Vector2(-2, -2), Vector2(4, 5)), body)
	draw_rect(Rect2(c + Vector2(-2, -4), Vector2(1, 2)), body)  # ears
	draw_rect(Rect2(c + Vector2(1, -4), Vector2(1, 2)), body)
