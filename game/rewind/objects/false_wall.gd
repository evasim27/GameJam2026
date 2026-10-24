class_name FalseWall
extends TapeObject
## A wrong frame of wall pasted over the way out. Blocks the kid until its glitch steps it aside.
## A narrow, rough stone wall from floor to ceiling, so it reads as a barrier and not as decor.

## Local rect of the wall, the kid stops with its centre at x = 0.
const AREA := Rect2(2, -136, 12, 136)

@export var glitch_id := "wall"

var _open := false


func blocks(run: RoomRun) -> bool:
	return not run.glitched.has(glitch_id)


func show_time(run: RoomRun) -> void:
	var open := run.glitched.has(glitch_id)
	if open != _open:
		_open = open
		queue_redraw()


func _draw() -> void:
	if _open:
		return  # rolled up out of the frame like a bad splice
	var r := AREA
	# Contact shadow on the floor and a dark mortar bed behind the stones.
	draw_rect(Rect2(r.position.x - 3, -2, r.size.x + 6, 3), Color(0, 0, 0, 0.35))
	draw_rect(r, Color(0.09, 0.08, 0.08))
	# Courses of uneven stones; seeded, so the wall never shimmers while the tape scrubs.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4711
	var y := r.end.y
	while y > r.position.y:
		var h := float(rng.randi_range(5, 9))
		var top := maxf(y - h, r.position.y)
		var x := r.position.x - float(rng.randi_range(0, 3))
		while x < r.end.x:
			var w := float(rng.randi_range(5, 9))
			var stone := Rect2(maxf(x, r.position.x), top + 1, minf(x + w, r.end.x) - maxf(x, r.position.x) - 1, y - top - 1)
			if stone.size.x >= 1.0 and stone.size.y >= 1.0:
				_stone(stone, rng)
			x += w
		y = top
	# The side facing the kid catches the candlelight, the far side falls into shadow.
	draw_rect(Rect2(r.position.x, r.position.y, 1, r.size.y), Color(1.0, 0.8, 0.55, 0.18))
	draw_rect(Rect2(r.end.x - 2, r.position.y, 2, r.size.y), Color(0, 0, 0, 0.35))
	draw_rect(r, Color(0.04, 0.035, 0.05), false, 1.0)


func _stone(s: Rect2, rng: RandomNumberGenerator) -> void:
	var v := rng.randf_range(-0.05, 0.05)
	var base := Color(0.36 + v, 0.31 + v, 0.27 + v * 0.7)  # candlelit field stone
	draw_rect(s, base)
	draw_rect(Rect2(s.position, Vector2(s.size.x, 1)), base.lightened(0.18))
	draw_rect(Rect2(s.position.x, s.end.y - 1, s.size.x, 1), base.darkened(0.4))
	draw_rect(Rect2(s.end.x - 1, s.position.y, 1, s.size.y), base.darkened(0.25))
	# Knocked-off corners keep the stones rough instead of brick-square.
	var mortar := Color(0.09, 0.08, 0.08)
	if s.size.x >= 3 and s.size.y >= 3:
		for corner in [s.position, Vector2(s.end.x - 1, s.position.y), Vector2(s.position.x, s.end.y - 1), s.end - Vector2.ONE]:
			if rng.randf() < 0.6:
				draw_rect(Rect2(corner, Vector2.ONE), mortar)
	if s.size.x >= 4 and rng.randf() < 0.5:  # pits and moss
		var p := Vector2(s.position.x + rng.randi_range(1, int(s.size.x) - 2), s.position.y + rng.randi_range(1, maxi(int(s.size.y) - 2, 1)))
		var speck := base.darkened(0.3) if rng.randf() < 0.6 else Color(0.3, 0.38, 0.24)
		draw_rect(Rect2(p, Vector2.ONE), speck)
