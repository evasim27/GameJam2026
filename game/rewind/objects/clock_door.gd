class_name ClockDoor
extends TapeObject
## A door the grandfather clock opens once, between `open_from` and `open_to` of room time.
## By the time the kid gets there it is shut, so the house has to be wound back a long way.

const FONT := preload("res://assets/fonts/VT323-Regular.ttf")

@export var open_from := 5.0
@export var open_to := 7.5

var _open := false


func blocks(run: RoomRun) -> bool:
	return not (run.room_time >= open_from and run.room_time < open_to)


func show_time(run: RoomRun) -> void:
	var open := not blocks(run)
	if open != _open:
		_open = open
		queue_redraw()


func _draw() -> void:
	var frame := Rect2(-2, -36, 20, 36)
	draw_rect(frame, Color(0.14, 0.08, 0.07))
	if _open:
		draw_rect(frame.grow(-2), Color(1.0, 0.7, 0.35, 0.35))
		draw_rect(Rect2(-1, -34, 4, 34), Color(0.36, 0.2, 0.14))
	else:
		draw_rect(frame.grow(-2), Color(0.36, 0.2, 0.14))
		draw_rect(Rect2(12, -18, 2, 2), Color(1.0, 0.7, 0.3))
	# The times it opens, in gold above the door.
	draw_set_transform(Vector2(-6, -40), 0.0, Vector2(0.5, 0.5))
	draw_string(FONT, Vector2.ZERO, "%s-%s" % [_clock(open_from), _clock(open_to)], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.85, 0.45))
	draw_set_transform(Vector2.ZERO)


func timeline_marks(_length: float) -> Array:
	return [{"from": open_from, "to": open_to, "color": Color(1.0, 0.85, 0.45, 0.9), "row": 2}]


static func _clock(t: float) -> String:
	return "0:%02d" % int(t)
