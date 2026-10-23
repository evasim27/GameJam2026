class_name Shadow
extends TapeObject
## A shadow off the stairs that slides across the kid's path on a rhythm of room time.
## With `always` it never leaves: the over-long shadow waiting at the top of the stairs.

@export var width := 24.0
@export var period := 3.2
@export var from := 2.0
@export var to := 3.0
@export var always := false
@export var height := 40.0

var _cover := 0.0  # 0 = gone, 1 = fully over the path
var _t := 0.0


func zone_width() -> float:
	return width


func is_deadly(t: float) -> bool:
	return always or periodic(t, period, from, to)


func show_time(run: RoomRun) -> void:
	_t = run.room_time
	if always:
		_cover = 1.0
	else:
		var phase := fposmod(_t, period)
		const SLIDE := 0.4
		if phase >= from and phase < to:
			_cover = 1.0
		elif phase >= from - SLIDE and phase < from:
			_cover = (phase - (from - SLIDE)) / SLIDE
		elif phase >= to and phase < to + SLIDE:
			_cover = 1.0 - (phase - to) / SLIDE
		else:
			_cover = 0.0
	queue_redraw()


func _draw() -> void:
	if _cover <= 0.0:
		return
	# Thin, uneven fingers reaching down from above, fading towards the tips.
	var reach := height * _cover
	var fingers := 4
	for i in fingers:
		var x := width * (i + 0.5) / fingers
		var sway := sin(_t * 3.0 + i * 1.7) * 2.0
		var tip := -height - 20.0 + (reach + 20.0) * (0.6 + 0.4 * absf(sin(i * 2.3 + 0.5)))
		var top := -height - 30.0
		var segs := 6
		for k in segs:
			var f0 := float(k) / segs
			var f1 := float(k + 1) / segs
			var y0 := lerpf(top, tip, f0)
			var y1 := lerpf(top, tip, f1)
			var w0 := lerpf(3.0, 0.5, f0)
			var w1 := lerpf(3.0, 0.5, f1)
			var c0 := Color(0.03, 0.0, 0.06, (0.85 - 0.5 * f0) * (0.4 + 0.6 * _cover))
			draw_colored_polygon(PackedVector2Array([
				Vector2(x - w0 + sway * f0, y0), Vector2(x + w0 + sway * f0, y0),
				Vector2(x + w1 + sway * f1, y1), Vector2(x - w1 + sway * f1, y1)]), c0)
	var c := Color(0.03, 0.0, 0.06, 0.5 * _cover)
	var floor_c := c
	floor_c.a *= 0.6
	draw_rect(Rect2(-4, -2, width + 8, 3), floor_c)


func timeline_marks(length: float) -> Array:
	if always:
		return []
	return periodic_marks(length, period, from, to, Color(0.6, 0.4, 1.0, 0.7), 1)
