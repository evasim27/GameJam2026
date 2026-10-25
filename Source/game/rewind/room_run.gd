class_name RoomRun
extends RefCounted
## One attempt at one room. Pure rules, no visuals, so tools/check_levels.gd can replay it headless.
##
## Two clocks: `kid_time` only runs during Play and decides where the kid is.
## `room_time` runs during Play and goes back during Rewind, so rewinding moves the house
## and its hazards, never the kid. The outcome depends only on the two clocks and the glitches.

const KID_SPEED := 24.0  # px per second of kid_time
const GLITCH_COST := 3.0
const CANDY_BONUS := 2.0
const EPS := 0.01

var room: Room
var kid_time := 0.0
var room_time := 0.0
var seen_time := 0.0  # furthest room_time already played; scrubbing can't go past it
var kid_x := 0.0
var tape := 0.0
var tape_used := 0.0
var free_rewind := false
var glitched := {}  # glitch id -> kid_x when it happened
var glitch_times := {}  # glitch id -> room_time when it happened
var glitch_kid_times := {}  # glitch id -> kid_time when it happened
var taken := {}  # candy name -> true
var eater := 0.0  # tape-eater progress towards the playhead, 0..1
var cause: TapeObject = null  # what ended the attempt
var out_of_tape := false
## The renderer supplies the actual camera edge; headless replays use its target framing.
var camera_right := NAN
var view_width := 640.0 / 3.0

var _rewound_free := false


func right_of_view() -> float:
	var target_right := clampf(kid_x - view_width * 0.4, 0.0, maxf(room.width - view_width, 0.0)) + view_width
	return maxf(camera_right, target_right) if is_finite(camera_right) else target_right


func _init(r: Room) -> void:
	room = r
	kid_x = r.start_x
	tape = r.tape_budget
	free_rewind = r.free_first_rewind


func play(dt: float) -> String:
	if _rewound_free:
		free_rewind = false  # the free tutorial rewind ends when the tape plays again
	dt = minf(dt, tape)
	_spend(dt)
	var from_x := kid_x
	var to_x := kid_x + KID_SPEED * dt
	for o in room.objects:
		if o.blocks(self) and from_x < o.block_x() and to_x >= o.block_x():
			to_x = minf(to_x, o.block_x() - EPS)
	kid_time += dt
	room_time += dt
	seen_time = maxf(seen_time, room_time)
	for o in room.objects:
		if o is Candy and not taken.has(o.candy_name) and from_x < o.position.x and to_x >= o.position.x and o.available(self):
			taken[o.candy_name] = true
			tape += CANDY_BONUS
	kid_x = to_x
	for o in room.objects:
		o.advance(self, "play", dt)
	return _check()


func rewind(dt: float) -> String:
	var d := minf(dt, room_time)
	if d <= 0.0:
		return ""
	if free_rewind:
		_rewound_free = true
	else:
		d = minf(d, tape)
		_spend(d)
	room_time -= d
	for o in room.objects:
		o.advance(self, "rewind", d)
	return _check()


## Moves the room forward through already-seen footage without the kid. Costs like a rewind.
func scrub(dt: float) -> String:
	var d := minf(minf(dt, seen_time - room_time), tape)
	if d <= 0.0:
		return ""
	_spend(d)
	room_time += d
	for o in room.objects:
		o.advance(self, "scrub", d)
	return _check()


## Tries a deliberate glitch. Returns the glitch id, or "" if nothing here is glitchable right now.
func glitch() -> String:
	for o in room.objects:
		if o is GlitchSpot and o.can_glitch(self):
			glitched[o.glitch_id] = kid_x
			glitch_times[o.glitch_id] = room_time
			glitch_kid_times[o.glitch_id] = kid_time
			_spend(minf(GLITCH_COST, tape))
			for other in room.objects:
				other.on_glitch(self, o.glitch_id)
			return o.glitch_id
	return ""


func can_glitch() -> bool:
	for o in room.objects:
		if o is GlitchSpot and o.can_glitch(self):
			return true
	return false


func kid_y() -> float:
	return room.floor_y(kid_x)


func _spend(d: float) -> void:
	tape -= d
	tape_used += d


func _check() -> String:
	for o in room.objects:
		if o.kills(self):
			cause = o
			return "fail"
	for o in room.objects:
		if o.is_exit(self) and kid_x >= o.position.x - 1.0:
			return "win"
	if tape <= EPS:
		out_of_tape = true
		return "fail"
	return ""
