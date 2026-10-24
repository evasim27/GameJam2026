class_name TapeEater
extends TapeObject
## A knot of unwound tape that got hungry. It doesn't chase the kid, it chases the playhead:
## still on Pause, creeping on Play, lunging on Rewind. `run.eater` is how close it is (0..1).
## Glitching the reel by the VCR duplicates an empty frame and it jumps into the TV instead.

const ART := preload("res://assets/monsters/tape_monster.png")
const IDLE_FRAME := Rect2(41, 210, 886, 479)
const LUNGE_FRAME := Rect2(943, 50, 1143, 636)

const RED := Color(0.6, 0.1, 0.1)
const BROWN := Color(0.25, 0.12, 0.08)

@export var trigger_x := 150.0
@export var play_rate := 0.2
@export var rewind_rate := 0.4
@export var banish_glitch := "reel"
## Where it ends up after the glitch, relative to position.
@export var tv := Vector2(0, -60)

var _t := 0.0
var _p := 0.0
var _banished := false


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
	queue_redraw()


func _draw() -> void:
	if _banished:
		# Trapped in the wrong picture on the TV.
		draw_texture_rect_region(ART, Rect2(tv + Vector2(-10, -7), Vector2(20, 11)), IDLE_FRAME, Color(0.45, 0.9, 1.0, 0.65))
		for i in 4:
			var pts := PackedVector2Array()
			for k in 8:
				pts.append(tv + Vector2(-8 + k * 2.2, sin(_t * 4.0 + k + i) * 3.0 + i * 2.0 - 3.0))
			draw_polyline(pts, RED if i % 2 == 0 else BROWN, 1.0)
		return
	# The film-creature throws a mechanical shadow and drags strips of tape out of the VCR.
	var length := 20.0 + _p * 220.0
	draw_rect(Rect2(-40, -140, length + 60, 140), Color(0.0, 0.0, 0.0, 0.35 * _p))
	for i in 7:
		var pts := PackedVector2Array()
		var steps := 16
		for k in steps + 1:
			var f := float(k) / steps
			var x := f * length
			var y := -6.0 - i * 4.0 + sin(_t * 2.5 + f * 9.0 + i * 1.3) * (3.0 + 8.0 * f)
			pts.append(Vector2(x, y))
		var c := RED if i % 3 == 0 else BROWN
		c.a = 0.6 + 0.4 * _p
		draw_polyline(pts, c, 1.0 + (1.0 if _p > 0.5 and i % 2 == 0 else 0.0))
	# The moving cassette from the concept art replaces the old drawn head.
	var head := Vector2(length, -20)
	var lunging := _p > 0.65 or (_p > 0.25 and fposmod(_t, 1.8) < 0.22)
	var frame := LUNGE_FRAME if lunging else IDLE_FRAME
	var size := Vector2(70, 39) if lunging else Vector2(60, 33)
	var bob := sin(_t * (3.0 + 3.0 * _p)) * 1.0
	var dest := Rect2(head - Vector2(size.x * 0.52, size.y * 0.37) + Vector2(0, bob), size)
	draw_texture_rect_region(ART, dest, frame)
	for i in 5:
		var x := fposmod(_t * (13.0 + i * 3.0) + i * 31.0, length)
		draw_rect(Rect2(x, -18.0 - i * 5.0, 3, 1), Color(0.9, 0.2, 0.18, 0.7))


func screen_effect(run: RoomRun) -> Dictionary:
	return {"noise": 0.25 * run.eater} if active(run) else {}
