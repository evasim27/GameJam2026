class_name Hole
extends TapeObject
## A hole in the floor, `slots` kid-widths wide. Nothing on the tape gets the kid across:
## every fall leaves an echo standing in the next free slot, heads level with the floor,
## and once every slot holds one the kid walks over them.

const SLOT := 20.0  # one kid width
const DEPTH := 44.0

@export var slots := 2


func zone_width() -> float:
	return SLOT * slots


## How many slots already hold an echo from an earlier fall in this room.
func filled() -> int:
	var n := 0
	for g in room.ghosts:
		if g.get("bridge", false) and g.x >= position.x and g.x <= position.x + zone_width():
			n += 1
	return mini(n, slots)


## Where the echo of a fall into slot `i` stands, in room pixels.
func slot_center(i: int) -> float:
	return position.x + SLOT * (i + 0.5)


## The kid falls once its centre is over the first free slot.
func kills(run: RoomRun) -> bool:
	var n := filled()
	return n < slots and run.kid_x >= slot_center(n) and run.kid_x <= position.x + zone_width()


func hint_target(_run: RoomRun) -> float:
	return slot_center(filled())


func _draw() -> void:
	var w := zone_width()
	# The pit, darker towards the bottom, with a faint cyan glow where the tape shows through.
	draw_rect(Rect2(0, 0, w, DEPTH), Color(0.02, 0.01, 0.03))
	for i in 4:
		draw_rect(Rect2(0, i * 3.0, w, 3), Color(0.12, 0.07, 0.06, 0.6 - i * 0.15))
	draw_rect(Rect2(4, DEPTH - 6, w - 8, 6), Color(0.4, 1.0, 1.0, 0.06))
	# Broken floorboard ends on both sides.
	var wood := Color(0.33, 0.2, 0.13)
	for b in [Rect2(-2, 0, 4, 3), Rect2(-1, 3, 3, 2), Rect2(w - 2, 0, 4, 3), Rect2(w - 2, 3, 2, 3)]:
		draw_rect(b, wood)
	draw_line(Vector2(0, 0), Vector2(w, 0), Color(0, 0, 0, 0.6), 1.0)
