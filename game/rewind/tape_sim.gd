class_name TapeSim
## Shared rules for how the kid moves along the tape. Used by the game and the level solver.

const KID_SPEED := 12.0  # px per tape second
const EPS := 0.01


## Moves the kid by the tape delta `dt` (negative while rewinding), stopping at closed blockers.
static func move_kid(objects: Array, x: float, dt: float, t: float, min_x: float) -> float:
	var target := x + KID_SPEED * dt
	for o: TapeObject in objects:
		if not o.blocks(t):
			continue
		var bx := o.position.x
		if dt > 0.0 and x < bx and target >= bx:
			target = minf(target, bx - EPS)
		elif dt < 0.0 and x > bx and target <= bx:
			target = maxf(target, bx + EPS)
	return maxf(target, min_x)


## Returns the object killing the kid at (x, t), or null.
static func hazard_at(objects: Array, x: float, t: float) -> TapeObject:
	for o: TapeObject in objects:
		var w := o.zone_width()
		if w > 0.0 and x >= o.position.x and x <= o.position.x + w and o.is_deadly(t):
			return o
	return null
