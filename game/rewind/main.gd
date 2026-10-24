extends Node2D
## Lost in Tape: you don't control the kid, you control the tape.
## Intro -> The Last House (foyer tutorial) -> Static below the stairs -> End of Tape -> ending.

const Intro := preload("res://rewind/intro.gd")
const Ending := preload("res://rewind/ending.gd")
const KidNode := preload("res://rewind/kid.gd")
const ROOMS := [
	preload("res://rewind/rooms/foyer.gd"),
	preload("res://rewind/rooms/stairs.gd"),
	preload("res://rewind/rooms/end_of_tape.gd"),
]
## Echo subtitles, in order of total failures. Each is said at most once per game.
const LINES := [
	"You rewound me again.",
	"I've been here before. Many times.",
	"The house doesn't forget. It just records.",
	"Where the picture tears, it can't see.",
	"Who's holding the remote?",
	"Now it sees you too.",
]
const LINE_TAPE := "I ran out."
const LINE_EATER := "The tape is hungry."
const MEMORY_NAMES := ["MAJA", "LUKA", "TINA"]
const MEMORY_IDS := ["Maja 1989", "Luka 1994", "Tina 2003"]
const SFX := {
	"click": preload("res://assets/audio/vhs_button_click.mp3"),
	"tape": preload("res://assets/audio/vhs_play.mp3"),
	"rewind": preload("res://assets/audio/rewind.ogg"),
	"glitch": preload("res://assets/audio/glitch.ogg"),
	"candy": preload("res://assets/audio/candy.wav"),
	"echo": preload("res://assets/audio/echo.wav"),
	"static": preload("res://assets/audio/static.mp3"),
	"pumpkin_warning": preload("res://assets/audio/pumpkin_rattle.wav"),
	"bat_warning": preload("res://assets/audio/bat_warning.ogg"),
	"shadow_warning": preload("res://assets/audio/shadow_warning.ogg"),
	"eater_warning": preload("res://assets/audio/eater_warning.ogg"),
}
## The date stamp keeps 31/10 but the year moves on with every failure: this has happened before.
const YEARS := [1989, 1994, 2003, 2009, 2016, 2026]
## Rooms are seen up close and the camera follows the kid; the intro and ending use the full view.
const ROOM_ZOOM := 3.0
const FULL_ZOOM := 2.0
## How far from the left edge of the view the kid stays, so there is room to see what's coming.
const LOOK_AHEAD := 0.4
const CAMERA_SPEED := 6.0
const MARK_AHEAD := 200.0
## Failing this many times in one room after the foyer sends the tape back to the foyer.
const MAX_ROOM_FAILS := 6
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
var _echoes := {}  # room index -> [{x, y, target, line, bridge}], oldest first
var _seen_hints := {}
var _playing := false  # PLAY/PAUSE is one toggle; rewinding or FF drops back to pause
var _rewind_unlocked := false
var _glitch_unlocked := false
var _free_rewind_used := false
var _echo_spoke := false
var _last_mode := ""
var _fx_burst := 0.0
var _intro: Node2D
var _ending: Node2D
var _cam := Vector2.ZERO
var _sound_players := {}
var _warning_state := {}
var _jumps := 0  # bumped by the debug level picker so pending fail/leave timers don't fire
var _debug_list: VBoxContainer

@onready var world: Node2D = $World
@onready var hud: Control = $HUD/OSD
@onready var vhs: ShaderMaterial = $VHS/Screen.material
@onready var intro_music: AudioStreamPlayer = $IntroMusic


func _ready() -> void:
	for id in SFX:
		var player := AudioStreamPlayer.new()
		var looping: bool = id == "rewind" or id == "tape"
		player.stream = SFX[id].duplicate() if looping else SFX[id]
		if looping:
			player.stream.set("loop", true)
		player.volume_db = -20.0 if id == "rewind" or id == "static" else -12.0
		add_child(player)
		_sound_players[id] = player
	hud.visible = false
	_intro = Intro.new()
	_intro.finished.connect(_on_intro_finished)
	world.add_child(_intro)
	if OS.is_debug_build():
		_build_debug_menu()


## Debug builds only: a corner button that opens a list of levels to jump straight into.
func _build_debug_menu() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var box := VBoxContainer.new()
	box.position = Vector2(8, 8)
	layer.add_child(box)
	var toggle := _debug_button("DEBUG")
	toggle.pressed.connect(func(): _debug_list.visible = not _debug_list.visible)
	box.add_child(toggle)
	_debug_list = VBoxContainer.new()
	_debug_list.visible = false
	box.add_child(_debug_list)
	var levels := ["Intro", "1 · The Last House", "2 · Static Below the Stairs", "3 · End of Tape", "Ending"]
	for i in levels.size():
		var b := _debug_button(levels[i])
		b.pressed.connect(_debug_jump.bind(i - 1))
		_debug_list.add_child(b)


func _debug_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	# Never take focus, or the deck keys would press it.
	b.focus_mode = Control.FOCUS_NONE
	return b


## -1 restarts from the intro, 0.. enters that room, ROOMS.size() plays the ending.
func _debug_jump(target: int) -> void:
	_debug_list.visible = false
	if target < 0:
		get_tree().reload_current_scene()
		return
	_jumps += 1
	if is_instance_valid(_intro):
		_intro.queue_free()
		intro_music.stop()
	if is_instance_valid(_ending):
		_ending.queue_free()
		_ending = null
	# Later rooms assume the foyer already taught rewind.
	if target > 0 and not _rewind_unlocked:
		_rewind_unlocked = true
		hud.clear_prompt()
	vhs.set_shader_parameter("rewind_amount", 0.0)
	if target >= ROOMS.size():
		if not room:
			room = ROOMS[0].new()
			world.add_child(room)
		_end()
		return
	hud.visible = true
	_enter_room(target, true)


func _on_intro_finished() -> void:
	var fade := create_tween()
	fade.tween_property(intro_music, "volume_db", -60.0, 0.8)
	fade.tween_callback(intro_music.stop)
	_intro.queue_free()
	hud.visible = true
	_enter_room(0, true)


func _enter_room(i: int, first_time: bool) -> void:
	_stop_sound("rewind")
	_stop_sound("static")
	_warning_state.clear()
	room_index = i
	if room:
		room.queue_free()
	room = ROOMS[i].new()
	room.setup(room_fails[i], total_fails, _echoes.get(i, []))
	world.add_child(room)
	run = RoomRun.new(room)
	world.scale = Vector2(ROOM_ZOOM, ROOM_ZOOM)
	_cam = _camera_target()
	run.free_rewind = room.free_first_rewind and not _free_rewind_used
	_echo_spoke = false

	hud.clear_texts()
	hud.wrap = 0.0
	hud.timeline_length = room.timeline_length
	hud.tape_budget = room.tape_budget
	hud.memory_name = MEMORY_NAMES[i]
	hud.memory_found = false
	hud.marks = []
	for o in room.objects:
		# A mark shows up on the timeline once the kid is about a screen away from its object,
		# and disappears once the kid is past it.
		for m in o.timeline_marks(room.timeline_length):
			m["from_x"] = o.position.x - MARK_AHEAD
			m["until_x"] = o.position.x + o.zone_width()
			hud.marks.append(m)
	# Short windows last, so they stay visible on top of long ones.
	hud.marks.sort_custom(func(a, b): return a.to - a.from > b.to - b.from)
	if first_time:
		hud.message = room.title
		hud.sub_message = "D = PLAY / PAUSE   ·   FIND MAJA'S MEMORY" if i == 0 else "FIND %s'S MEMORY" % MEMORY_NAMES[i]
		if i == 0:
			hud.prompt("play", ["D"], false, "play")
	_glitch_unlocked = _glitch_unlocked or room.glitch_from_x <= 0.0
	var retry := room.retry_hint()
	if retry == "" and i > 0 and room_fails[i] >= MAX_ROOM_FAILS / 2:
		retry = "%d more failures here and the tape goes back to the start." % (MAX_ROOM_FAILS - room_fails[i])
	if retry != "":
		hud.hint(retry)
	_update_controls()
	_playing = false
	state = State.ROOM
	_show()


## Lights up the VCR panel buttons the player has learned so far.
func _update_controls() -> void:
	hud.unlocked = {"rew": _rewind_unlocked, "ff": _rewind_unlocked, "track": _glitch_unlocked}


func _unhandled_input(event: InputEvent) -> void:
	if state == State.ENDING and _ending.results_visible() and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
		return
	if state != State.ROOM:
		return
	# Every deck button clicks, even when it does nothing yet.
	for action in ["tape_play", "tape_rewind", "tape_ff", "tape_glitch"]:
		if event.is_action_pressed(action) and not event.is_echo():
			_sound("click")
	if event.is_action_pressed("tape_play") and not event.is_echo():
		_playing = not _playing
		hud.flash("play" if _playing else "pause")
	elif event.is_action_pressed("tape_glitch") and _glitch_unlocked:
		_glitch()
	elif event.is_action_pressed("restart"):
		_enter_room(room_index, false)


func _process(delta: float) -> void:
	hud.date = "31/10/%d" % YEARS[mini(total_fails, YEARS.size() - 1)]
	hud.candies = candies.size() + (run.taken.size() if state == State.ROOM else 0)
	if state == State.ROOM:
		_tick(delta)
	if room:
		_cam = _cam.lerp(_camera_target(), minf(CAMERA_SPEED * delta, 1.0))
		world.position = (-_cam * ROOM_ZOOM).round()
	_fx_burst = maxf(_fx_burst - delta, 0.0)
	# The deck only whirrs while the tape is actually playing.
	var tape_player: AudioStreamPlayer = _sound_players["tape"]
	var tape_running := state == State.ROOM and _last_mode == "PLAY"
	if tape_running != tape_player.playing:
		if tape_running:
			tape_player.play()
		else:
			tape_player.stop()
	if state == State.ROOM or state == State.LEAVING:
		_update_screen_fx()


func _tick(delta: float) -> void:
	var fast := Input.is_action_pressed("tape_fast") and _rewind_unlocked
	var mode := "PAUSE"
	var ev := ""
	var had := run.taken.size()
	if Input.is_action_pressed("tape_rewind") and _rewind_unlocked:
		_playing = false
		mode = "SCRUB-" if fast else "REW"
		ev = run.rewind(delta * (SCRUB_SPEED if fast else REWIND_SPEED))
		if run.free_rewind:
			_free_rewind_used = true
	elif Input.is_action_pressed("tape_ff") and _rewind_unlocked and run.room_time < run.seen_time:
		_playing = false
		mode = "SCRUB+"
		ev = run.scrub(delta * SCRUB_SPEED)
	elif _playing:
		mode = "PLAY"
		ev = run.play(delta)
	hud.mode = mode
	if _prompt_done(mode):
		hud.clear_prompt()
	if mode != "PAUSE" and hud.message != "" and state == State.ROOM:
		hud.message = ""
		hud.sub_message = ""
	if mode == "PAUSE" and _last_mode != "PAUSE":
		_on_pause()
	var rewinding := mode == "REW" or mode == "SCRUB-"
	var rewind_player: AudioStreamPlayer = _sound_players["rewind"]
	if rewinding and not rewind_player.playing:
		rewind_player.play()
	elif not rewinding and rewind_player.playing:
		rewind_player.stop()
	_last_mode = mode

	if run.taken.size() > had:
		hud.say("%s'S MEMORY SAVED  +%ds" % [run.taken.keys()[-1].split(" ")[0].to_upper(), int(RoomRun.CANDY_BONUS)])
		_sound("candy")
	_show()
	_update_warning_sounds(mode)
	if not _glitch_unlocked and run.kid_x >= room.glitch_from_x:
		_glitch_unlocked = true
		_update_controls()
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
	hud.hint("Rewind the house. The kid stays put.")
	hud.prompt("rew", ["A"], true, "rewind")
	_update_controls()


func _check_hints() -> void:
	for h in room.trigger_hints():
		if run.kid_x >= h.x and not _seen_hints.has(h.text):
			_seen_hints[h.text] = true
			hud.hint(h.text)
			if h.has("keys"):
				hud.prompt(h.button, h.keys, h.get("hold", true), h.done)
	for e in room.echoes:
		e.notice(run.kid_x)
	if room.echo.visible:
		if not _echo_spoke and absf(run.kid_x - room.echo.position.x) < 28.0:
			_echo_spoke = true
			if room.echo.line != "":
				hud.say(room.echo.line)


## Whether the player just did what the key prompt on screen asks for.
func _prompt_done(mode: String) -> bool:
	match hud.prompt_done:
		"play": return mode == "PLAY"
		"pause": return mode == "PAUSE" and _last_mode == "PLAY"
		"rewind": return mode == "REW" or mode == "SCRUB-"
		"fast_rewind": return mode == "SCRUB-"
		"scrub": return mode == "SCRUB+"
	return false


func _glitch() -> void:
	var id := run.glitch()
	if id == "":
		return
	if hud.prompt_done == "glitch":
		hud.clear_prompt()
	_fx_burst = 0.35
	_sound("glitch")
	_show()
	if run.tape <= RoomRun.EPS:
		run.out_of_tape = true
		_fail()


func _show() -> void:
	room.show_run(run)
	room.kid.place(run.kid_x, run.kid_y())
	hud.room_time = run.room_time
	hud.kid_time = run.kid_time
	hud.kid_x = run.kid_x
	hud.seen_time = run.seen_time
	hud.tape = run.tape
	hud.eater = run.eater
	hud.memory_found = run.taken.has(MEMORY_IDS[room_index])


## Play an audible cue only as a hazard enters its warning state.
func _update_warning_sounds(mode: String) -> void:
	if mode != "PLAY":
		return
	for o in room.objects:
		var cue := ""
		var warn := false
		var distance := o.position.x - run.kid_x
		if o is Pumpkin:
			var pumpkin := o as Pumpkin
			var until_bite := fposmod(pumpkin.bite_from - run.room_time, pumpkin.period)
			warn = not pumpkin.is_deadly(run.room_time) and until_bite < Pumpkin.WARN_TIME and distance > -8.0 and distance < 80.0
			cue = "pumpkin_warning"
		elif o is Bat:
			var bat := o as Bat
			for b in bat.bats_at(run.room_time, bat._since_glitch(run)):
				var ahead := o.position.x + b.x - run.kid_x
				if ahead > 2.0 and ahead < 55.0 and b.y > -52.0:
					warn = true
					break
			cue = "bat_warning"
		elif o is Shadow:
			var shadow := o as Shadow
			var phase := fposmod(run.room_time, shadow.period)
			warn = (shadow.always or (phase >= shadow.from - 0.4 and phase < shadow.from)) and distance > -12.0 and distance < 80.0
			cue = "shadow_warning"
		elif o is TapeEater:
			warn = (o as TapeEater).active(run) and run.eater > 0.58
			cue = "eater_warning"
		if cue == "":
			continue
		var key := str(o.get_instance_id())
		if warn and not _warning_state.get(key, false):
			_sound(cue)
		_warning_state[key] = warn


## Top-left corner of the view, in room pixels, keeping the kid in sight and the view inside the room.
func _camera_target() -> Vector2:
	var view := get_viewport_rect().size / ROOM_ZOOM
	var x := clampf(run.kid_x - view.x * LOOK_AHEAD, 0.0, maxf(room.width - view.x, 0.0))
	var y := clampf(run.kid_y() - view.y * 0.62, 0.0, maxf(180.0 - view.y, 0.0))
	return Vector2(x, y)


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
	vhs.set_shader_parameter("rewind_amount", 1.0 if hud.mode == "REW" or hud.mode == "SCRUB-" else 0.0)


func _fail() -> void:
	state = State.FAILING
	_stop_sound("rewind")
	_sound("echo")
	_sound("static")
	hud.mode = "STOP"
	room.kid.fail()
	total_fails += 1
	room_fails[room_index] += 1
	tape_used += run.tape_used
	if not _rewind_unlocked and total_fails >= 2:
		_unlock_rewind()

	var reset: bool = room_index > 0 and room_fails[room_index] >= MAX_ROOM_FAILS
	var line := ""
	var target := room.idle_hint_target(run)
	var echo_pos := Vector2(run.kid_x, run.kid_y())
	var in_hole := run.cause is Hole
	if run.out_of_tape:
		hud.message = "END OF TAPE"
		hud.sub_message = "the tape for this room is used up"
		line = LINE_TAPE
	elif run.cause is TapeEater:
		hud.message = "TAPE EATEN"
		hud.sub_message = "the eater reached the playhead"
		line = LINE_EATER
		target = run.cause.hint_target(run)
		create_tween().tween_property(hud, "wrap", 1.0, 0.8)
	else:
		hud.message = "SIGNAL LOST"
		hud.sub_message = "the recording returns to the start of the room"
		target = run.cause.hint_target(run)
	if in_hole:
		# The kid drops into the free slot; its echo stays there, head level with the floor.
		var hole: Hole = run.cause
		echo_pos = Vector2(hole.slot_center(hole.filled()), room.floor_y(run.kid_x) - KidNode.FEET_OFFSET - 3.0)
		target = room.width - 24.0
		create_tween().tween_property(room.kid, "position", echo_pos, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if reset:
		hud.message = "REWIND TO START"
		hud.sub_message = "%d failures in one room: the tape goes back to the house" % MAX_ROOM_FAILS
	if line == "" or _used_lines.has(line):
		line = LINES[mini(total_fails - 1, LINES.size() - 1)]
	if _used_lines.has(line):
		line = ""
	_used_lines[line] = true
	# Echoes pile up: every failure in a room leaves one that stays until the room is cleared.
	if not _echoes.has(room_index):
		_echoes[room_index] = []
	_echoes[room_index].append({"x": echo_pos.x, "y": echo_pos.y, "target": target, "line": line, "bridge": in_hole})

	vhs.set_shader_parameter("noise_amount", 0.85)
	vhs.set_shader_parameter("tracking", 1.0)
	var jumps := _jumps
	await get_tree().create_timer(1.6).timeout
	if jumps != _jumps:
		return
	if reset:
		_rewind_to_start()
	else:
		_enter_room(room_index, false)


## Too many failures in one room: everything after the intro is recorded over, from the foyer.
func _rewind_to_start() -> void:
	room_fails = [0, 0, 0]
	_echoes = {}
	candies.clear()
	_enter_room(0, true)


func _leave_room() -> void:
	state = State.LEAVING
	_stop_sound("rewind")
	hud.mode = "STOP"
	tape_used += run.tape_used
	for candy_name in run.taken:
		candies.append(candy_name)
	_echoes.erase(room_index)
	room.kid.leave()
	var jumps := _jumps
	await get_tree().create_timer(1.2).timeout
	if jumps != _jumps:
		return
	if room_index + 1 < ROOMS.size():
		_enter_room(room_index + 1, true)
	else:
		_end()


func _end() -> void:
	state = State.ENDING
	room.queue_free()
	room = null
	world.position = Vector2.ZERO
	world.scale = Vector2(FULL_ZOOM, FULL_ZOOM)
	hud.visible = false
	vhs.set_shader_parameter("tracking", 0.0)
	vhs.set_shader_parameter("noise_amount", 0.05)
	vhs.set_shader_parameter("rewind_amount", 0.0)
	# Attempts: one per room plus every failure except the planned tutorial one.
	var attempts := ROOMS.size() + maxi(total_fails - 1, 0)
	_ending = Ending.new()
	_ending.setup(candies, total_fails, attempts, tape_used)
	world.add_child(_ending)


func _sound(id: String) -> void:
	var player: AudioStreamPlayer = _sound_players.get(id)
	if player:
		player.stop()
		player.play()


func _stop_sound(id: String) -> void:
	var player: AudioStreamPlayer = _sound_players.get(id)
	if player:
		player.stop()
