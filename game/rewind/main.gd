extends Node2D
## Lost in Tape: you don't control the kid, you control the tape.
## Intro -> The Last House (foyer tutorial) -> Static below the stairs -> End of Tape -> ending.

const Intro := preload("res://rewind/intro.gd")
const Ending := preload("res://rewind/ending.gd")
const ROOMS := [
	preload("res://rewind/rooms/foyer.gd"),
	preload("res://rewind/rooms/stairs.gd"),
	preload("res://rewind/rooms/end_of_tape.gd"),
]
## Echo subtitles, in order of total failures. Each is said at most once per game.
const LINES := [
	"Spet si me previl nazaj.",
	"Tukaj sem že bil. Večkrat.",
	"Hiša ne pozabi. Samo snema.",
	"Kjer se slika trga, ne vidi.",
	"Kdo drži daljinca?",
	"Zdaj vidi tudi tebe.",
]
const LINE_TAPE := "Zmanjkalo me je."
const LINE_EATER := "Trak je lačen."
## The date stamp keeps 31/10 but the year moves on with every failure: this has happened before.
const YEARS := [1989, 1994, 2003, 2009, 2016, 2026]
const REWIND_SPEED := 1.0
const SCRUB_SPEED := 4.0

enum State { INTRO, ROOM, FAILING, LEAVING, ENDING }

var state := State.INTRO
var room_index := 0
var room: Room
var run: RoomRun

var room_fails := [0, 0, 0]
var total_fails := 0
var candies: Array[String] = []
var tape_used := 0.0
var _used_lines := {}
var _echoes := {}  # room index -> {x, y, target, line}
var _seen_hints := {}
var _rewind_unlocked := false
var _free_rewind_used := false
var _echo_spoke := false
var _last_mode := ""
var _fx_burst := 0.0
var _intro: Node2D

@onready var world: Node2D = $World
@onready var hud: Control = $HUD/OSD
@onready var vhs: ShaderMaterial = $VHS/Screen.material


func _ready() -> void:
	hud.visible = false
	_intro = Intro.new()
	_intro.finished.connect(_on_intro_finished)
	world.add_child(_intro)


func _on_intro_finished() -> void:
	_intro.queue_free()
	hud.visible = true
	_enter_room(0, true)


func _enter_room(i: int, first_time: bool) -> void:
	room_index = i
	if room:
		room.queue_free()
	room = ROOMS[i].new()
	room.setup(room_fails[i], total_fails)
	world.add_child(room)
	run = RoomRun.new(room)
	run.free_rewind = room.free_first_rewind and not _free_rewind_used
	_echo_spoke = false
	if _echoes.has(i):
		var e: Dictionary = _echoes[i]
		room.echo.setup(e.x, e.y, e.target, e.line)

	hud.clear_texts()
	hud.wrap = 0.0
	hud.timeline_length = room.timeline_length
	hud.tape_budget = room.tape_budget
	hud.marks = []
	for o in room.objects:
		hud.marks.append_array(o.timeline_marks(room.timeline_length))
	# Short windows last, so they stay visible on top of long ones.
	hud.marks.sort_custom(func(a, b): return a.to - a.from > b.to - b.from)
	if first_time:
		hud.message = room.title
		hud.sub_message = "drži D za PLAY, spusti za PAUSE" if i == 0 else ""
	var retry := room.retry_hint()
	if retry != "":
		hud.hint(retry)
	_update_controls()
	state = State.ROOM
	_show()


func _update_controls() -> void:
	var c := "D/→ PLAY"
	if _rewind_unlocked:
		c += "   A/← PREVIJ   SHIFT HITRO"
	if room_index >= 1:
		c += "   E GLITCH"
	c += "   R ZNOVA"
	hud.controls = c


func _unhandled_input(event: InputEvent) -> void:
	if state == State.ENDING and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
		return
	if state != State.ROOM:
		return
	if event.is_action_pressed("tape_glitch") and room_index >= 1:
		_glitch()
	elif event.is_action_pressed("restart"):
		_enter_room(room_index, false)


func _process(delta: float) -> void:
	hud.date = "31/10/%d" % YEARS[mini(total_fails, YEARS.size() - 1)]
	hud.candies = candies.size()
	if state == State.ROOM:
		_tick(delta)
	_fx_burst = maxf(_fx_burst - delta, 0.0)
	if state == State.ROOM or state == State.LEAVING:
		_update_screen_fx()


func _tick(delta: float) -> void:
	var fast := Input.is_action_pressed("tape_fast") and _rewind_unlocked
	var mode := "PAUSE"
	var ev := ""
	var had := run.taken.size()
	if Input.is_action_pressed("tape_rewind") and _rewind_unlocked:
		mode = "SCRUB-" if fast else "REW"
		ev = run.rewind(delta * (SCRUB_SPEED if fast else REWIND_SPEED))
		if run.free_rewind:
			_free_rewind_used = true
	elif Input.is_action_pressed("tape_play"):
		if fast and run.room_time < run.seen_time:
			mode = "SCRUB+"
			ev = run.scrub(delta * SCRUB_SPEED)
		else:
			mode = "PLAY"
			ev = run.play(delta)
	hud.mode = mode
	if mode != "PAUSE" and hud.message != "" and state == State.ROOM:
		hud.message = ""
		hud.sub_message = ""
	if mode == "PAUSE" and _last_mode != "PAUSE":
		_on_pause()
	_last_mode = mode

	if run.taken.size() > had:
		hud.say("+%ds  %s" % [int(RoomRun.CANDY_BONUS), run.taken.keys()[-1].to_upper()])
	_show()
	_check_hints()
	if ev == "fail":
		_fail()
	elif ev == "win":
		_leave_room()


## Tutorial: the first pause after the planned failure teaches Rewind.
func _on_pause() -> void:
	if room_index == 0 and room_fails[0] >= 1 and not _rewind_unlocked:
		_unlock_rewind()


func _unlock_rewind() -> void:
	_rewind_unlocked = true
	hud.hint("Previj hišo. Otrok ostane tukaj.   [A / ←]")
	_update_controls()


func _check_hints() -> void:
	for h in room.trigger_hints():
		if run.kid_x >= h.x and not _seen_hints.has(h.text):
			_seen_hints[h.text] = true
			hud.hint(h.text + "   [E]")
	if room.echo.visible:
		room.echo.notice(run.kid_x)
		if not _echo_spoke and absf(run.kid_x - room.echo.position.x) < 28.0:
			_echo_spoke = true
			if room.echo.line != "":
				hud.say(room.echo.line)


func _glitch() -> void:
	var id := run.glitch()
	if id == "":
		return
	_fx_burst = 0.35
	_show()
	if run.tape <= RoomRun.EPS:
		run.out_of_tape = true
		_fail()


func _show() -> void:
	room.show_run(run)
	room.kid.place(run.kid_x, run.kid_y())
	hud.room_time = run.room_time
	hud.kid_time = run.kid_time
	hud.seen_time = run.seen_time
	hud.tape = run.tape
	hud.eater = run.eater


func _update_screen_fx() -> void:
	var tracking := 0.0
	var noise := 0.04
	if hud.mode == "REW" or hud.mode.begins_with("SCRUB"):
		tracking = 0.5
		noise = 0.12
	for o in room.objects:
		var fx := o.screen_effect(run)
		tracking += fx.get("tracking", 0.0)
		noise += fx.get("noise", 0.0)
	if _fx_burst > 0.0:
		tracking = 1.5
		noise = 0.5
	vhs.set_shader_parameter("tracking", tracking)
	vhs.set_shader_parameter("noise_amount", noise)


func _fail() -> void:
	state = State.FAILING
	hud.mode = "STOP"
	room.kid.fail()
	total_fails += 1
	room_fails[room_index] += 1
	tape_used += run.tape_used
	if not _rewind_unlocked and total_fails >= 2:
		_unlock_rewind()

	var line := ""
	var target := room.idle_hint_target(run)
	if run.out_of_tape:
		hud.message = "KONEC TRAKU"
		hud.sub_message = "trak za to sobo je porabljen"
		line = LINE_TAPE
	elif run.cause is TapeEater:
		hud.message = "TRAK JE POJEDEN"
		hud.sub_message = "požiralec je dosegel glavo predvajanja"
		line = LINE_EATER
		target = run.cause.hint_target(run)
		create_tween().tween_property(hud, "wrap", 1.0, 0.8)
	else:
		hud.message = "IZGUBLJEN SIGNAL"
		hud.sub_message = "posnetek se vrača na začetek sobe"
		target = run.cause.hint_target(run)
	if line == "" or _used_lines.has(line):
		line = LINES[mini(total_fails - 1, LINES.size() - 1)]
	if _used_lines.has(line):
		line = ""
	_used_lines[line] = true
	# A newer echo replaces the old one in the same room.
	_echoes[room_index] = {"x": run.kid_x, "y": run.kid_y(), "target": target, "line": line}

	vhs.set_shader_parameter("noise_amount", 0.85)
	vhs.set_shader_parameter("tracking", 1.0)
	await get_tree().create_timer(1.6).timeout
	_enter_room(room_index, false)


func _leave_room() -> void:
	state = State.LEAVING
	hud.mode = "STOP"
	tape_used += run.tape_used
	for candy_name in run.taken:
		candies.append(candy_name)
	room.kid.leave()
	await get_tree().create_timer(1.2).timeout
	if room_index + 1 < ROOMS.size():
		_enter_room(room_index + 1, true)
	else:
		_end()


func _end() -> void:
	state = State.ENDING
	room.queue_free()
	room = null
	hud.visible = false
	vhs.set_shader_parameter("tracking", 0.0)
	vhs.set_shader_parameter("noise_amount", 0.05)
	# Attempts: one per room plus every failure except the planned tutorial one.
	var attempts := ROOMS.size() + maxi(total_fails - 1, 0)
	var ending := Ending.new()
	ending.setup(candies, total_fails, attempts, tape_used)
	world.add_child(ending)
