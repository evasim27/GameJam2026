class_name ClockDoor
extends TapeObject
## A door the grandfather clock opens once, between `open_from` and `open_to` of room time.
## It leads to the optional secret room, so it never stands in the kid's way down the hall.

const FONT := preload("res://assets/fonts/VT323-Regular.ttf")
const ART := preload("res://rewind/door_art.gd")

@export var open_from := 5.0
@export var open_to := 7.5

var _open := false


func is_open(run: RoomRun) -> bool:
	return run.room_time >= open_from and run.room_time < open_to


func show_time(run: RoomRun) -> void:
	var open := is_open(run)
	if open != _open:
		_open = open
		queue_redraw()


func _draw() -> void:
	ART.draw_door(self, Rect2(-18, -64, 36, 64), _open, Color(1.0, 0.7, 0.35, 1.0 if _open else 0.3))
	# The times it opens, in gold above the door.
	draw_set_transform(Vector2(-18, -69), 0.0, Vector2(0.5, 0.5))
	draw_string(FONT, Vector2.ZERO, "%s-%s" % [_clock(open_from), _clock(open_to)], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.85, 0.45))
	draw_set_transform(Vector2.ZERO)


## Above the timeline, so the candy's pink windows on row 2 can't cover it.
func timeline_marks(_length: float) -> Array:
	return [{"from": open_from, "to": open_to, "color": Color(1.0, 0.85, 0.45, 0.9), "row": 3}]


static func _clock(t: float) -> String:
	return "0:%02d" % int(t)
