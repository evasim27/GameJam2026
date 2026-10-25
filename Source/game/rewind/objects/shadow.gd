class_name Shadow
extends TapeObject
## A shadow off the stairs that slides across the kid's path on a rhythm of room time.
## With `always` it never leaves: the over-long shadow waiting at the top of the stairs.

const ART := preload("res://assets/rewind/cinematic/shadow-monster.png")
const IDLE_FRAME := Rect2(42, 16, 43, 96)
const REACH_FRAME := Rect2(133, 16, 118, 96)

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
	var alpha := clampf(_cover, 0.0, 1.0)
	var centre := width / 2.0 + sin(_t * 2.0) * 1.2
	var reaching := _cover > 0.8 and fposmod(_t + position.x * 0.01, 2.4) < 0.36
	var frame := REACH_FRAME if reaching else IDLE_FRAME
	var sprite_height := height + 24.0
	var sprite_width := sprite_height * frame.size.x / frame.size.y
	var bob := sin(_t * 2.3) * 1.2
	var dest := Rect2(centre - sprite_width / 2.0, -sprite_height + bob, sprite_width, sprite_height)
	# A dim cool halo keeps the figure readable under the staircase.
	draw_circle(Vector2(centre, -sprite_height * 0.72 + bob), 11.0, Color(0.26, 0.44, 0.8, 0.08 * alpha))
	# Mirror both poses around the sprite centre so the monster faces the approaching kid.
	draw_set_transform(Vector2(centre * 2.0, 0.0), 0.0, Vector2(-1.0, 1.0))
	draw_texture_rect_region(ART, dest, frame, Color(1.0, 1.0, 1.0, alpha))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(-4, -2, width + 8, 3), Color(0.03, 0.0, 0.06, 0.3 * alpha))


func timeline_marks(length: float) -> Array:
	if always:
		return []
	return periodic_marks(length, period, from, to, Color(0.6, 0.4, 1.0, 0.7), 1)
