class_name TapeObject
extends Node2D
## Anything recorded on the tape. Its state must depend only on the RoomRun (both clocks
## and the glitches), so scrubbing back and forth always shows the same picture.

## Shown by the echo after a failure caused by this object.
@export var hint_x := NAN
var room: Room


## The kid can't walk through `position.x` while this is true.
func blocks(_run: RoomRun) -> bool:
	return false


## Where the kid stops while `blocks` is true.
func block_x() -> float:
	return position.x


## Width of the zone starting at `position.x` where `is_deadly` applies.
func zone_width() -> float:
	return 0.0


func is_deadly(_t: float) -> bool:
	return false


func kills(run: RoomRun) -> bool:
	var w := zone_width()
	return w > 0.0 and run.kid_x >= position.x and run.kid_x <= position.x + w and is_deadly(run.room_time)


func is_exit(_run: RoomRun) -> bool:
	return false


## Called for every bit of tape movement. `mode` is "play", "rewind" or "scrub".
func advance(_run: RoomRun, _mode: String, _dt: float) -> void:
	pass


## Called right after a glitch happened anywhere in the room.
func on_glitch(_run: RoomRun, _id: String) -> void:
	pass


## Called every frame to update visuals.
func show_time(_run: RoomRun) -> void:
	pass


## How much this object distorts the screen right now: {tracking, bat_tracking, noise}.
func screen_effect(_run: RoomRun) -> Dictionary:
	return {}


## Coloured windows on the HUD timeline, in room time: [{from, to, color, row}].
func timeline_marks(_length: float) -> Array:
	return []


## Where the echo points after this object ended an attempt.
func hint_target(_run: RoomRun) -> float:
	return position.x + zone_width() / 2.0 if is_nan(hint_x) else hint_x


static func periodic(t: float, period: float, from: float, to: float) -> bool:
	var phase := fposmod(t, period)
	return phase >= from and phase < to


static func periodic_marks(length: float, period: float, from: float, to: float, color: Color, row := 0) -> Array:
	var marks := []
	var start := 0.0
	while start < length:
		marks.append({"from": start + from, "to": minf(start + to, length), "color": color, "row": row})
		start += period
	return marks
