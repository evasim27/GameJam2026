# Replays scripted tape inputs against each room's rules and checks the outcome, so the
# timings can be tuned without playing. Run:
#   godot --headless --path . --script res://tools/check_levels.gd
extends SceneTree

const DT := 1.0 / 60.0
const FOYER := "res://rewind/rooms/foyer.gd"
const STAIRS := "res://rewind/rooms/stairs.gd"
const END := "res://rewind/rooms/end_of_tape.gd"
# One echo standing in the stairs hallway's hole (slot at x 130).
const SLOT_1 := {"x": 130.0, "y": 160.0, "target": 0.0, "line": "", "bridge": true}
const BRIDGE := [SLOT_1]

# [room, description, actions, expected result, expected candy ("" = none), echoes already in the room]
# Actions: ["play", s] ["rewind", s] ["scrub", s] ["to_x", x] ["glitch_when_possible"]
const PLANS := [
	[FOYER, "first play is the planned lesson", [["play", 30.0]], "fail:Pumpkin", ""],
	[FOYER, "no adjustment at the second pumpkin", [["to_x", 80.0], ["rewind", 1.75], ["play", 30.0]], "fail:Pumpkin", ""],
	[FOYER, "past the pumpkins, clock door stays shut", [["to_x", 80.0], ["rewind", 1.75], ["to_x", 180.0], ["rewind", 0.5], ["play", 60.0]], "fail:tape", ""],
	[FOYER, "wind back to the clock, glitch the wall", [["to_x", 80.0], ["rewind", 1.75], ["to_x", 180.0], ["rewind", 0.5], ["to_x", 320.0], ["rewind", 4.0], ["glitch_when_possible"], ["to_x", 440.0], ["rewind", 1.5], ["play", 60.0]], "win", ""],
	[FOYER, "full tutorial with Maja", [["to_x", 80.0], ["rewind", 1.75], ["to_x", 180.0], ["rewind", 0.8], ["to_x", 320.0], ["rewind", 4.0], ["glitch_when_possible"], ["to_x", 440.0], ["rewind", 1.5], ["play", 60.0]], "win", "Maja 1989"],
	[FOYER, "scrub forward past the window again", [["to_x", 80.0], ["rewind", 1.75], ["to_x", 180.0], ["rewind", 0.5], ["to_x", 320.0], ["rewind", 7.0], ["scrub", 1.5], ["glitch_when_possible"], ["to_x", 440.0], ["rewind", 1.0], ["play", 60.0]], "win", ""],
	[FOYER, "waiting at the wall, bad timing for the bats", [["to_x", 80.0], ["rewind", 1.75], ["to_x", 180.0], ["rewind", 0.5], ["to_x", 320.0], ["rewind", 4.0], ["to_x", 460.0], ["glitch_when_possible"], ["rewind", 1.5], ["play", 60.0]], "fail:Bat", ""],
	[FOYER, "waiting at the wall, bats fly over", [["to_x", 80.0], ["rewind", 1.75], ["to_x", 180.0], ["rewind", 0.5], ["to_x", 320.0], ["rewind", 4.0], ["to_x", 460.0], ["glitch_when_possible"], ["to_x", 440.0], ["rewind", 3.0], ["play", 60.0]], "win", ""],
	[STAIRS, "first fall into the hole", [["play", 30.0]], "fail:Hole", ""],
	[STAIRS, "one echo forms the bridge; shadow ahead", [["play", 30.0]], "fail:Shadow", "", BRIDGE],
	[STAIRS, "rewinding preserves the echo bridge", [["to_x", 100.0], ["rewind", 3.0], ["play", 30.0]], "fail:Shadow", "", BRIDGE],
	[STAIRS, "ignore the tear, go up the stairs", [["to_x", 300.0], ["rewind", 2.3], ["play", 30.0]], "fail:Shadow", "", BRIDGE],
	[STAIRS, "glitch late, no candy", [["to_x", 300.0], ["rewind", 2.3], ["to_x", 402.0], ["glitch_when_possible"], ["play", 30.0]], "win", "", BRIDGE],
	[STAIRS, "glitch early, Luka", [["to_x", 300.0], ["rewind", 2.3], ["to_x", 370.0], ["rewind", 1.5], ["glitch_when_possible"], ["play", 30.0]], "win", "Luka 1994", BRIDGE],
	[END, "only the wall glitch: eaten", [["glitch_when_possible"], ["play", 30.0]], "fail:TapeEater", ""],
	[END, "both glitches", [["glitch_when_possible"], ["glitch_when_possible"], ["play", 30.0]], "win", ""],
	[END, "both glitches and Tina", [["glitch_when_possible"], ["glitch_when_possible"], ["rewind", 1.0], ["play", 30.0]], "win", "Tina 2003"],
	[END, "rewinding with the eater out is deadly", [["glitch_when_possible"], ["to_x", 160.0], ["rewind", 3.0], ["play", 30.0]], "fail:TapeEater", ""],
]


func _init() -> void:
	var failed := 0
	for plan in PLANS:
		var room: Room = load(plan[0]).new()
		var ghosts: Array = plan[5] if plan.size() > 5 else []
		room.setup(ghosts.size(), ghosts.size(), ghosts)
		var run := RoomRun.new(room)
		var result := _replay(run, plan[2])
		var candy := ", ".join(run.taken.keys())
		var ok: bool = result == plan[3] and candy == plan[4]
		if not ok:
			failed += 1
		print("%s %-16s %-40s -> %-16s candy=%-10s kid_x=%.0f kid_t=%.2f room_t=%.2f tape=%.1f eater=%.2f" % [
			"OK  " if ok else "FAIL", room.title.left(16), plan[1], result, candy, run.kid_x, run.kid_time, run.room_time, run.tape, run.eater])
		room.free()
	print("%d/%d plans behave as expected" % [PLANS.size() - failed, PLANS.size()])
	quit(1 if failed else 0)


func _replay(run: RoomRun, actions: Array) -> String:
	for a in actions:
		var ev := ""
		match a[0]:
			"play":
				ev = _repeat(func(): return run.play(DT), a[1])
			"rewind":
				ev = _repeat(func(): return run.rewind(DT), a[1])
			"scrub":
				ev = _repeat(func(): return run.scrub(DT), a[1])
			"to_x":
				while run.kid_x < a[1] and ev == "":
					ev = run.play(DT)
			"glitch_when_possible":
				while not run.can_glitch() and ev == "":
					ev = run.play(DT)
				if ev == "":
					run.glitch()
		if ev != "":
			return _describe(run, ev)
	return "none"


func _repeat(step: Callable, seconds: float) -> String:
	var steps := roundi(seconds / DT)
	for i in steps:
		var ev: String = step.call()
		if ev != "":
			return ev
	return ""


func _describe(run: RoomRun, ev: String) -> String:
	if ev != "fail":
		return ev
	if run.out_of_tape:
		return "fail:tape"
	return "fail:" + run.cause.get_script().get_global_name()
