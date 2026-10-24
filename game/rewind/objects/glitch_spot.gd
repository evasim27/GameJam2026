class_name GlitchSpot
extends TapeObject
## A damaged frame. Pressing Glitch while it tears (and while the kid is in the right place)
## changes the picture until the room restarts, e.g. reveals a door.

@export var glitch_id := ""
## The torn area, relative to position.
@export var area := Rect2(-8, -40, 16, 40)
@export var period := 3.0
@export var from := 1.6
@export var to := 2.4
@export var kid_min := -INF
@export var kid_max := INF
## Another glitch that has to happen first; until then this frame doesn't tear at all.
@export var requires := ""
@export var tint := Color(0.4, 1.0, 1.0)
## Chime as soon as the window opens (boss fight), so the moment is heard as well as seen.
@export var cue := false

## Raised by the room after repeated failures, so the tear gets more obvious.
var strength := 0.0
var _t := 0.0
var _done := false
var _active := false


func active(t: float) -> bool:
	return periodic(t, period, from, to)


## Whether the frame tears right now. Subclasses can time it on more than room time.
func window_open(run: RoomRun) -> bool:
	return active(run.room_time)


func unlocked(run: RoomRun) -> bool:
	return not run.glitched.has(glitch_id) and (requires == "" or run.glitched.has(requires))


func can_glitch(run: RoomRun) -> bool:
	return unlocked(run) and window_open(run) and run.kid_x >= kid_min and run.kid_x <= kid_max


func show_time(run: RoomRun) -> void:
	_t = run.room_time
	_done = not unlocked(run)
	_active = window_open(run)
	queue_redraw()


func _draw() -> void:
	if _done:
		return
	var cyan := tint
	if _active:
		# Tracking tear: horizontal slices shifted sideways. Seeded by room time, so it scrubs.
		var noise_seed := int(_t * 20.0)
		var y := area.position.y
		var i := 0
		while y < area.end.y:
			var h := 2.0 + float((noise_seed + i * 7) % 3)
			var shift := float(((noise_seed * 13 + i * 31) % 9) - 4)
			var c := cyan if (noise_seed + i) % 2 == 0 else Color(1.0, 0.35, 1.0)
			c.a = 0.55
			draw_rect(Rect2(area.position.x + shift, y, area.size.x, minf(h, area.end.y - y)), c)
			y += h + 1.0
			i += 1
	else:
		var pulse := 0.5 + 0.5 * sin(_t * 5.0)
		var c := cyan
		c.a = 0.12 + 0.1 * pulse + 0.15 * strength
		draw_rect(area, c, false, 1.0)
		draw_line(area.position + Vector2(area.size.x, 0), area.end, c, 1.0 + strength)


func screen_effect(run: RoomRun) -> Dictionary:
	return {"tracking": 0.35} if unlocked(run) and window_open(run) else {}


func timeline_marks(length: float) -> Array:
	return periodic_marks(length, period, from, to, Color(tint, 0.9))
