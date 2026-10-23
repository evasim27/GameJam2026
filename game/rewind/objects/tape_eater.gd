class_name TapeEater
extends TapeObject
## A knot of unwound tape that got hungry. It doesn't chase the kid, it chases the playhead:
## still on Pause, creeping on Play, lunging on Rewind. `run.eater` is how close it is (0..1).
## Glitching the reel by the VCR duplicates an empty frame and it jumps into the TV instead.

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
		for i in 4:
			var pts := PackedVector2Array()
			for k in 8:
				pts.append(tv + Vector2(-8 + k * 2.2, sin(_t * 4.0 + k + i) * 3.0 + i * 2.0 - 3.0))
			draw_polyline(pts, RED if i % 2 == 0 else BROWN, 1.0)
		return
	# Strands crawl out of the VCR towards the right; the further along, the longer and thicker.
	var length := 20.0 + _p * 220.0
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
	# Two empty reels where a face should be. They spin faster the closer it gets.
	var head := Vector2(length, -20)
	for side in [-7.0, 7.0]:
		var centre := head + Vector2(side, 0)
		draw_circle(centre, 6.0, Color(0.05, 0.03, 0.04))
		draw_arc(centre, 6.0, 0, TAU, 16, RED, 1.0)
		var a := _t * (2.0 + 14.0 * _p)
		for s in 3:
			var ang := a + s * TAU / 3.0
			draw_line(centre, centre + Vector2(cos(ang), sin(ang)) * 5.0, Color(0.7, 0.6, 0.55), 1.0)
	# Its shadow over the walls grows with it.
	draw_rect(Rect2(-40, -140, length + 60, 140), Color(0.0, 0.0, 0.0, 0.35 * _p))


func screen_effect(run: RoomRun) -> Dictionary:
	return {"noise": 0.25 * run.eater} if active(run) else {}
