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
# Boss phase 2: play time after the jam until the TV shows its empty frame.
const EMPTY := 1.7
const TINA_REWIND := 4.2
# End of Tape gallery: past the first knight, then the second knight without meeting a bat.
const HALL_PASS := ["steps", [["to_x", 90.0], ["rewind", 1.0], ["to_x", 150.0], ["rewind", 1.0]]]

# [room, description, actions, expected result, expected candy ("" = none), echoes already in the room]
# Actions: ["play", s] ["rewind", s] ["scrub", s] ["to_x", x] ["glitch_when_possible"]
#          ["rewind_to_glitch"] rewinds until a glitch is possible, then glitches
const PLANS := [
	[FOYER, "first play is the planned lesson", [["play", 30.0]], "fail:Pumpkin", ""],
	[FOYER, "no adjustment at the second pumpkin", [["to_x", 80.0], ["rewind", 1.75], ["play", 30.0]], "fail:Pumpkin", ""],
	[FOYER, "past the pumpkins, never glitching the wall", [["to_x", 80.0], ["rewind", 1.75], ["to_x", 180.0], ["rewind", 0.5], ["play", 60.0]], "fail:tape", "Maja 1994"],
	[FOYER, "straight past the shut clock door, skipping the secret room", [["to_x", 80.0], ["rewind", 1.75], ["to_x", 180.0], ["rewind", 0.5], ["to_x", 460.0], ["glitch_when_possible"], ["to_x", 440.0], ["rewind", 3.0], ["play", 60.0]], "win", "Maja 1994"],
	[FOYER, "wind back to the clock, glitch the wall", [["to_x", 80.0], ["rewind", 1.75], ["to_x", 180.0], ["rewind", 0.5], ["to_x", 320.0], ["rewind", 4.0], ["glitch_when_possible"], ["to_x", 440.0], ["rewind", 1.5], ["play", 60.0]], "win", "Maja 1994"],
	[FOYER, "full tutorial with Maja", [["to_x", 80.0], ["rewind", 1.75], ["to_x", 180.0], ["rewind", 0.8], ["to_x", 320.0], ["rewind", 4.0], ["glitch_when_possible"], ["to_x", 440.0], ["rewind", 1.5], ["play", 60.0]], "win", "Maja 1994"],
	[FOYER, "scrub forward past the window again", [["to_x", 80.0], ["rewind", 1.75], ["to_x", 180.0], ["rewind", 0.5], ["to_x", 320.0], ["rewind", 7.0], ["scrub", 1.5], ["glitch_when_possible"], ["to_x", 440.0], ["rewind", 1.0], ["play", 60.0]], "win", "Maja 1994"],
	[FOYER, "waiting at the wall, bad timing for the bats", [["to_x", 80.0], ["rewind", 1.75], ["to_x", 180.0], ["rewind", 0.5], ["to_x", 320.0], ["rewind", 4.0], ["to_x", 460.0], ["glitch_when_possible"], ["rewind", 1.5], ["play", 60.0]], "fail:Bat", "Maja 1994"],
	[FOYER, "waiting at the wall, bats fly over", [["to_x", 80.0], ["rewind", 1.75], ["to_x", 180.0], ["rewind", 0.5], ["to_x", 320.0], ["rewind", 4.0], ["to_x", 460.0], ["glitch_when_possible"], ["to_x", 440.0], ["rewind", 3.0], ["play", 60.0]], "win", "Maja 1994"],
	[STAIRS, "first fall into the hole", [["play", 30.0]], "fail:Hole", ""],
	[STAIRS, "bridge crossed; skeleton catches the kid", [["play", 30.0]], "fail:Skeleton", "", BRIDGE],
	[STAIRS, "second skeleton catches the kid", [["to_x", 180.0], ["rewind", 1.0], ["play", 30.0]], "fail:Skeleton", "", BRIDGE],
	[STAIRS, "rewinding preserves the echo bridge", [["to_x", 100.0], ["rewind", 3.0], ["play", 30.0]], "fail:Shadow", "", BRIDGE],
	[STAIRS, "ignore the tear, go up the stairs", [["to_x", 100.0], ["rewind", 3.0], ["to_x", 540.0], ["play", 30.0]], "fail:Shadow", "", BRIDGE],
	[STAIRS, "both guards, glitch late, no candy", [["to_x", 100.0], ["rewind", 3.0], ["to_x", 642.0], ["rewind", 1.5], ["glitch_when_possible"], ["play", 30.0]], "win", "", BRIDGE],
	[STAIRS, "glitch early, bat catches the kid", [["to_x", 100.0], ["rewind", 3.0], ["to_x", 610.0], ["rewind", 1.5], ["glitch_when_possible"], ["play", 30.0]], "fail:Bat", "", BRIDGE],
	[STAIRS, "rewind the bat dive, collect Luka", [["to_x", 100.0], ["rewind", 3.0], ["to_x", 610.0], ["rewind", 1.5], ["glitch_when_possible"], ["to_x", 660.0], ["rewind", 2.0], ["play", 30.0]], "win", "Luka 1989", BRIDGE],
	[END, "first knight catches the kid", [["play", 30.0]], "fail:Knight", ""],
	[END, "past the first knight, second one swings", [["to_x", 90.0], ["rewind", 1.0], ["play", 30.0]], "fail:Knight", ""],
	[END, "rewinding into the bats", [["to_x", 90.0], ["rewind", 1.0], ["to_x", 210.0], ["rewind", 1.5], ["play", 30.0]], "fail:Bat", ""],
	[END, "gallery cleared, no glitch: eaten", [HALL_PASS, ["play", 30.0]], "fail:TapeEater", ""],
	[END, "rewinding with the eater out is deadly", [HALL_PASS, ["to_x", 480.0], ["rewind", 3.0], ["play", 30.0]], "fail:TapeEater", ""],
	[END, "reel jammed, then just playing: eaten", [HALL_PASS, ["glitch_when_possible"], ["play", 30.0]], "fail:TapeEater", ""],
	[END, "reel jammed, rewinding the monster feeds it", [HALL_PASS, ["glitch_when_possible"], ["rewind", 2.5], ["play", 30.0]], "fail:TapeEater", ""],
	[END, "boss beaten, wall still shut", [HALL_PASS, ["glitch_when_possible"], ["play", EMPTY], ["rewind_to_glitch"], ["play", 60.0]], "fail:tape", ""],
	[END, "empty frame meets the static wave", [HALL_PASS, ["glitch_when_possible"], ["play", EMPTY], ["rewind_to_glitch"], ["glitch_when_possible"], ["play", 30.0]], "win", "Tina 2003"],
	[END, "full boss fight and Tina", [HALL_PASS, ["glitch_when_possible"], ["play", EMPTY], ["rewind_to_glitch"], ["glitch_when_possible"], ["to_x", 590.0], ["rewind", TINA_REWIND], ["play", 30.0]], "win", "Tina 2003"],
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
	failed += _check_repeated_bats()
	quit(1 if failed else 0)


func _check_repeated_bats() -> int:
	var room: Room = load(STAIRS).new()
	room.setup(1, 1, BRIDGE)
	var run := RoomRun.new(room)
	var checked := 0
	var failed := 0
	for object in room.objects:
		if not object is Bat or not is_finite(object.starts_at):
			continue
		var bat: Bat = object
		var ok := bat.bats_at(bat.starts_at - 0.1, bat.starts_at).is_empty()
		for cycle in [0, 1, 2]:
			var release: float = bat.starts_at + cycle * bat.period
			run.kid_x = bat.position.x - 60.0
			run.camera_right = bat.enter_x + 40.0 * cycle
			run.room_time = release
			bat.advance(run, "play", 0.0)
			var born := bat.bats_at(release, bat.starts_at)
			if born.is_empty():
				ok = false
				continue
			var birth_x: float = bat.position.x + born[-1].x
			# Even the wing tips start offscreen; moving the camera cannot drag a flying bat.
			ok = ok and birth_x - 11.0 > run.right_of_view()
			run.camera_right += 80.0
			run.room_time = release + 0.1
			bat.advance(run, "play", 0.1)
			var flown := bat.bats_at(run.room_time, bat.starts_at)
			ok = ok and is_equal_approx(bat.position.x + flown[-1].x, birth_x - bat.speed * 0.1)
			ok = ok and bat.screen_effect(run).get("bat_tracking", 0.0) > 0.0
			run.room_time = release + bat.damage_duration + 0.1
			ok = ok and bat.screen_effect(run).get("bat_tracking", 0.0) == 0.0
			# Each wave can hit at its low point, including after replaying earlier footage.
			run.room_time = release + bat.bob / 2.0
			run.kid_x = birth_x - bat.speed * bat.bob / 2.0
			ok = ok and bat.kills(run)
		run.room_time = bat.starts_at - 0.1
		bat.advance(run, "rewind", bat.period * 3.0)
		ok = ok and not bat.kills(run) and bat.screen_effect(run).is_empty()
		checked += 1
		if not ok:
			failed += 1
		print("%s recurring hallway bats at x=%.0f: offscreen releases, camera movement, vertical filter, hits and rewind" % ["OK  " if ok else "FAIL", bat.position.x])
	if checked != 2:
		failed += 1
		print("FAIL expected two recurring hallway bat sources")
	room.free()
	return failed


func _replay(run: RoomRun, actions: Array) -> String:
	for a in actions:
		var ev := ""
		match a[0]:
			"steps":
				ev = _replay(run, a[1])
				if ev != "none":
					return ev
				ev = ""
			"play":
				ev = _repeat(func(): return run.play(DT), a[1])
			"rewind":
				ev = _repeat(func(): return run.rewind(DT), a[1])
			"scrub":
				ev = _repeat(func(): return run.scrub(DT), a[1])
			"to_x":
				while run.kid_x < a[1] and ev == "":
					ev = run.play(DT)
			"rewind_to_glitch":
				while not run.can_glitch() and ev == "" and run.room_time > 0.0:
					ev = run.rewind(DT)
				if ev == "" and run.can_glitch():
					run.glitch()
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
	if run.cause is SwordGuard:
		return "fail:Knight" if run.cause.kind == SwordGuard.Kind.KNIGHT else "fail:Skeleton"
	return "fail:" + run.cause.get_script().get_global_name()
