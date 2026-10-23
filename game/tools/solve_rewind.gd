# Checks that the Be Kind, Rewind level is solvable and finds the solution using the least rewinding.
# Run: godot --headless --path . --script res://tools/solve_rewind.gd [-- res://rewind/main.tscn]
extends SceneTree

const TICK := 0.05
const TAPE_LENGTH := 60.0
const REWIND_TICKS := 2


func _init() -> void:
	var path := "res://rewind/main.tscn"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		path = args[0]
	var root: Node = load(path).instantiate()
	var objects: Array = []
	for o in root.get_node("Level/Objects").get_children():
		if o is TapeObject:
			objects.append(o)
	var start_x: float = root.get_node("Level/Kid").position.x
	var goal_x: float = root.get_node("Level/Goal").position.x

	_report_play_only(objects, start_x, goal_x)
	_solve(objects, start_x, goal_x)
	root.free()
	quit()


func _report_play_only(objects: Array, start_x: float, goal_x: float) -> void:
	var x := start_x
	var max_tick := int(TAPE_LENGTH / TICK)
	for tick in range(1, max_tick + 1):
		var t := tick * TICK
		x = TapeSim.move_kid(objects, x, TICK, t, start_x)
		var killer := TapeSim.hazard_at(objects, x, t)
		if killer:
			print("Play only: kid dies to %s at t=%.2f x=%.1f" % [killer.name, t, x])
			return
		if x >= goal_x:
			print("Play only: WINS at t=%.2f (level too easy!)" % t)
			return
	print("Play only: tape ends with kid at x=%.1f" % x)


func _solve(objects: Array, start_x: float, goal_x: float) -> void:
	var max_tick := int(TAPE_LENGTH / TICK)
	var start := [0, start_x]
	var dist := {_key(0, start_x): 0}
	var parent := {}
	var deque: Array = [[0, start_x, 0]]  # tick, x, cost (in rewind ticks)
	var visited := 0
	var best_x := start_x
	var best_t := 0.0
	while deque.size() > 0:
		var s: Array = deque.pop_front()
		var tick: int = s[0]
		var x: float = s[1]
		var cost: int = s[2]
		var k := _key(tick, x)
		if dist.get(k, 1 << 30) < cost:
			continue
		visited += 1
		if x > best_x:
			best_x = x
			best_t = tick * TICK
		if x >= goal_x:
			print("Solvable. States explored: %d. Rewound %.1f tape seconds in total." % [visited, cost * TICK])
			_print_path(parent, k, start_x)
			return
		for action in [1, -REWIND_TICKS]:
			var nt: int = tick + action
			if nt < 0 or nt > max_tick:
				continue
			var t := nt * TICK
			var nx := TapeSim.move_kid(objects, x, (nt - tick) * TICK, t, start_x)
			if TapeSim.hazard_at(objects, nx, t):
				continue
			var nc := cost + (0 if action > 0 else REWIND_TICKS)
			var nk := _key(nt, nx)
			if nc < dist.get(nk, 1 << 30):
				dist[nk] = nc
				parent[nk] = [k, tick, x, action]
				if action > 0:
					deque.push_front([nt, nx, nc])
				else:
					deque.push_back([nt, nx, nc])
	print("NOT solvable. States explored: %d. Furthest kid got: x=%.1f at t=%.2f" % [visited, best_x, best_t])


func _print_path(parent: Dictionary, k: String, start_x: float) -> void:
	var steps: Array = []
	while parent.has(k):
		var p: Array = parent[k]
		steps.push_front(p)
		k = p[0]
	var segs: Array = []
	for st in steps:
		var dir := "PLAY" if st[3] > 0 else "REW"
		if segs.is_empty() or segs[-1].dir != dir:
			segs.append({"dir": dir, "from": st[1] * TICK, "x": st[2]})
	for i in segs.size():
		var s: Dictionary = segs[i]
		print("  %-4s from t=%5.2f (kid x=%.1f)" % [s.dir, s.from, s.x])


func _key(tick: int, x: float) -> String:
	return "%d:%d" % [tick, roundi(x * 100.0)]
