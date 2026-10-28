extends Node2D
## Lost in Tape: you don't control the kid, you control the tape.
## Menu -> Intro -> The Last House (foyer tutorial) -> Static below the stairs -> End of Tape -> ending.

const StartMenu := preload("res://rewind/start_menu.gd")
const Intro := preload("res://rewind/intro.gd")
const Ending := preload("res://rewind/ending.gd")
const ForbiddenRoom := preload("res://rewind/rooms/forbidden.gd")
const ForbiddenTape := preload("res://rewind/forbidden_tape.gd")
const KidNode := preload("res://rewind/kid.gd")
const GAMEPLAY_MUSIC := preload("res://assets/audio/7-Quiet Walk Through the Mist-loop.wav")
const SECRET_MUSIC := preload("res://assets/audio/secret_room_tension.wav")
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
## Said after every failure in the boss's second phase, so it is never used up.
const LINE_SCREEN := "Rewind feeds it. The empty frame doesn't."
const MEMORY_NAMES := ["MAJA", "LUKA", "TINA"]
const MEMORY_IDS := ["Maja 1994", "Luka 1989", "Tina 2003"]
const SFX := {
	"click": preload("res://assets/audio/vhs_button_click.mp3"),
	"tape": preload("res://assets/audio/vhs_play.mp3"),
	"rewind": preload("res://assets/audio/rewind.ogg"),
	"glitch": preload("res://assets/audio/glitch.ogg"),
	"candy": preload("res://assets/audio/candy.wav"),
	"echo": preload("res://assets/audio/echo.wav"),
	"static": preload("res://assets/audio/static.mp3"),
	"door_creak": preload("res://assets/audio/door_creak.wav"),
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
const FORBIDDEN_ZOOM := 2.0
## How far from the left edge of the view the kid stays, so there is room to see what's coming.
const LOOK_AHEAD := 0.4
const CAMERA_SPEED := 6.0
const MARK_AHEAD := 200.0
## Failing this many times in one room after the foyer sends the tape back to the foyer.
const MAX_ROOM_FAILS := 6
const REWIND_SPEED := 1.0
const SCRUB_SPEED := 4.0

enum State { MENU, INTRO, ROOM, FAILING, LEAVING, ENDING, FORBIDDEN, FORBIDDEN_VIDEO, FORBIDDEN_LOST }

var state := State.MENU
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
var _start_menu: Control
var _ending: Node2D
var _forbidden: Room
var _forbidden_video: Node2D
var _secret_visited := false
var _secret_found := false
var _secret_prompted := false
var _secret_lost_t := 0.0
var _cam := Vector2.ZERO
var _sound_players := {}
var _warning_state := {}
var _jumps := 0  # bumped by the debug level picker so pending fail/leave timers don't fire
var _debug_list: VBoxContainer
var _ambient_music: AudioStreamPlayer
var _ambient_hiss: AudioStreamPlayer
var _gameplay_music_loop: AudioStreamWAV
var _secret_music_loop: AudioStreamWAV
var _audio_duck_t := 0.0

@onready var world: Node2D = $World
@onready var hud: Control = $HUD/OSD
@onready var vhs: ShaderMaterial = $VHS/Screen.material
@onready var intro_music: AudioStreamPlayer = $IntroMusic


func _ready() -> void:
	_ambient_music = AudioStreamPlayer.new()
	_gameplay_music_loop = GAMEPLAY_MUSIC.duplicate() as AudioStreamWAV
	_secret_music_loop = SECRET_MUSIC.duplicate() as AudioStreamWAV
	for loop in [_gameplay_music_loop, _secret_music_loop]:
		loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
		loop.loop_end = roundi(loop.get_length() * loop.mix_rate)
	_ambient_music.stream = _gameplay_music_loop
	_ambient_music.volume_db = -60.0
	add_child(_ambient_music)
	_ambient_hiss = AudioStreamPlayer.new()
	var hiss_loop := SFX["static"].duplicate() as AudioStreamMP3
	hiss_loop.loop = true
	_ambient_hiss.stream = hiss_loop
	_ambient_hiss.volume_db = -60.0
	add_child(_ambient_hiss)
	for id in SFX:
		var player := AudioStreamPlayer.new()
		var looping: bool = id == "rewind" or id == "tape"
		player.stream = SFX[id].duplicate() if looping else SFX[id]
		if looping:
			player.stream.set("loop", true)
		player.volume_db = -20.0 if id == "rewind" or id == "static" else -12.0
		add_child(player)
		_sound_players[id] = player
	var ping := AudioStreamPlayer.new()
	ping.stream = _ping_stream()
	ping.volume_db = -3.0
	add_child(ping)
	_sound_players["ping"] = ping
	hud.visible = false
	var menu_layer := CanvasLayer.new()
	menu_layer.layer = 3
	add_child(menu_layer)
	_start_menu = StartMenu.new()
	_start_menu.play_requested.connect(_start_intro)
	menu_layer.add_child(_start_menu)
	if OS.is_debug_build():
		_build_debug_menu()


func _dismiss_start_menu() -> void:
	if is_instance_valid(_start_menu):
		_start_menu.hide()
		_start_menu.get_parent().queue_free()
		_start_menu = null


func _start_intro() -> void:
	if state != State.MENU:
		return
	_dismiss_start_menu()
	state = State.INTRO
	intro_music.play()
	_intro = Intro.new()
	_intro.finished.connect(_on_intro_finished)
	world.add_child(_intro)


## Debug builds only: a corner button that opens a list of levels to jump straight into.
func _build_debug_menu() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var box := VBoxContainer.new()
	box.position = Vector2(202, 14)
	layer.add_child(box)
	var toggle := _debug_button("DEBUG")
	toggle.pressed.connect(func(): _debug_list.visible = not _debug_list.visible)
	box.add_child(toggle)
	_debug_list = VBoxContainer.new()
	_debug_list.visible = false
	box.add_child(_debug_list)
	var levels := ["Start Menu", "1 · The Last House", "2 · Static Below the Stairs", "3 · End of Tape", "Ending"]
	for i in levels.size():
		var b := _debug_button(levels[i])
		b.pressed.connect(_debug_jump.bind(i - 1))
		_debug_list.add_child(b)
	# One button per rescue combination, ordered like the ending masks.
	var names: Array = Ending.SEQUENCES.NAMES
	for mask in 1 << names.size():
		var kids := []
		var labels := []
		for i in names.size():
			if mask & (1 << i):
				kids.append(names[i])
				labels.append(names[i].get_slice(" ", 0))
		var label := "None Rescued"
		if kids.size() == names.size():
			label = "All Rescued"
		elif kids.size() == 1:
			label = "Only %s" % labels[0]
		elif not kids.is_empty():
			label = " + ".join(PackedStringArray(labels))
		var b := _debug_button("Ending · %s" % label)
		b.pressed.connect(_debug_jump_rescued.bind(kids))
		_debug_list.add_child(b)


func _debug_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 12)
	b.modulate = Color(0.75, 0.76, 0.83, 0.8)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	# Never take focus, or the deck keys would press it.
	b.focus_mode = Control.FOCUS_NONE
	return b


## Plays the ending as if exactly these kids made it out.
func _debug_jump_rescued(kid_names: Array) -> void:
	candies.clear()
	for kid_name in kid_names:
		candies.append(kid_name)
	_debug_jump(ROOMS.size())


## -1 returns to the start menu, 0.. enters that room, ROOMS.size() plays the ending.
func _debug_jump(target: int) -> void:
	_debug_list.visible = false
	if target < 0:
		get_tree().reload_current_scene()
		return
	_dismiss_start_menu()
	_jumps += 1
	_cleanup_forbidden()
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
	_cleanup_forbidden()
	hud.cinematic_mode = false
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
	run.view_width = get_viewport_rect().size.x / ROOM_ZOOM
	run.camera_right = _cam.x + run.view_width
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
			if not m.has("from_x"):
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
	_secret_prompted = false
	state = State.ROOM
	_show()
	_update_ambience(0.0)


## Lights up the VCR panel buttons the player has learned so far.
func _update_controls() -> void:
	hud.unlocked = {"rew": _rewind_unlocked, "ff": _rewind_unlocked, "track": _glitch_unlocked}


func _unhandled_input(event: InputEvent) -> void:
	if state == State.FORBIDDEN_VIDEO:
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE:
			_forbidden_video.skip()
			get_viewport().set_input_as_handled()
		return
	if state == State.FORBIDDEN:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode == KEY_D and not _forbidden.at_tape:
				_forbidden.playing = not _forbidden.playing
				hud.mode = "PLAY" if _forbidden.playing else "PAUSE"
				_sound("click")
			elif event.physical_keycode == KEY_E and _forbidden.at_tape:
				_start_forbidden_video()
			get_viewport().set_input_as_handled()
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
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E and _can_enter_forbidden():
		_enter_forbidden()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("tape_glitch") and _glitch_unlocked:
		_glitch()
	elif event.is_action_pressed("restart"):
		_enter_room(room_index, false)


func _process(delta: float) -> void:
	hud.date = "31/10/%d" % YEARS[mini(total_fails, YEARS.size() - 1)]
	hud.candies = candies.size() + (run.taken.size() if state == State.ROOM else 0)
	if state == State.ROOM:
		run.view_width = get_viewport_rect().size.x / ROOM_ZOOM
		run.camera_right = (-world.position.x + get_viewport_rect().size.x) / ROOM_ZOOM
		_tick(delta)
	if state == State.FORBIDDEN and _forbidden:
		var view := get_viewport_rect().size / FORBIDDEN_ZOOM
		var target_x := clampf(_forbidden.walk_x - view.x * LOOK_AHEAD, 0.0, maxf(_forbidden.width - view.x, 0.0))
		_cam = _cam.lerp(Vector2(target_x, 0.0), minf(CAMERA_SPEED * delta, 1.0))
		world.position = (-_cam * FORBIDDEN_ZOOM).round()
	elif state == State.FORBIDDEN_LOST:
		_secret_lost_t -= delta
		if _secret_lost_t <= 0.0:
			_return_from_forbidden()
	elif room and state != State.FORBIDDEN_VIDEO:
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
	if state == State.FORBIDDEN:
		vhs.set_shader_parameter("tracking", _forbidden.tracking_flash())
		vhs.set_shader_parameter("noise_amount", 0.04 + _forbidden.tracking_flash() * 0.35)
		vhs.set_shader_parameter("rewind_amount", 0.0)
	elif state == State.ROOM or state == State.LEAVING:
		_update_screen_fx()
	_update_ambience(delta)


## A separate quiet bed keeps the loud static bursts and boss cues independent.
func _update_ambience(delta: float) -> void:
	_audio_duck_t = maxf(0.0, _audio_duck_t - delta)
	var active := state in [State.ROOM, State.LEAVING, State.FAILING, State.FORBIDDEN, State.FORBIDDEN_LOST]
	if not active:
		_ambient_music.stop()
		_ambient_hiss.stop()
		_ambient_music.volume_db = -60.0
		_ambient_hiss.volume_db = -60.0
		return
	var music_loop := _secret_music_loop if state in [State.FORBIDDEN, State.FORBIDDEN_LOST] else _gameplay_music_loop
	if _ambient_music.stream != music_loop:
		_ambient_music.stop()
		_ambient_music.stream = music_loop
		_ambient_music.volume_db = -60.0
	if not _ambient_music.playing:
		_ambient_music.play()
	if not _ambient_hiss.playing:
		_ambient_hiss.play()
	var quiet: bool = _audio_duck_t > 0.0 or hud._subtitle_t > 0.0
	var paused: bool = state == State.ROOM and hud.mode == "PAUSE"
	var music_db := -36.0 if quiet else (-31.0 if paused else -27.0)
	var hiss_db := -46.0 if quiet else (-42.0 if paused else -38.0)
	if state == State.FAILING or state == State.FORBIDDEN_LOST:
		music_db = -42.0
		hiss_db = -48.0
	var fade_speed := 90.0 if quiet else 32.0
	_ambient_music.volume_db = move_toward(_ambient_music.volume_db, music_db, delta * fade_speed)
	_ambient_hiss.volume_db = move_toward(_ambient_hiss.volume_db, hiss_db, delta * fade_speed)


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
		hud.recover_memory(run.taken.keys()[-1], int(RoomRun.CANDY_BONUS))
		_sound("candy")
	_show()
	_update_warning_sounds(mode)
	_update_boss_cues()
	if not _glitch_unlocked and run.kid_x >= room.glitch_from_x:
		_glitch_unlocked = true
		_update_controls()
	_check_hints()
	if _can_enter_forbidden() and not _secret_prompted:
		_secret_prompted = true
		hud.hint("The clock hides an unlisted room. E = ENTER; PLAY continues forward.")
	elif not _can_enter_forbidden():
		_secret_prompted = false
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
	hud.hint("House rewinds.")
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
				hud.say(room.echo.line, "ECHO", room.echo)


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
	if id == "reel":
		hud.hint("The tape jammed. It fled into the TV.")
	elif id == "screen":
		for object in room.objects:
			if object is ScreenSpot:
				hud.say("THE PICTURE SWALLOWED IT", "THE TAPE", object, Vector2(0, -52))
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
	hud.saved_memories.assign(candies)
	for id: String in run.taken:
		if not hud.saved_memories.has(id):
			hud.saved_memories.append(id)
	hud.candies = hud.saved_memories.size()


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


## The boss fight is also heard: a chime the moment a glitch window opens, and the hiss of the
## static wave for exactly as long as it rolls. Works in every mode, the wave is met by rewinding.
func _update_boss_cues() -> void:
	for o in room.objects:
		var cue := ""
		var on := false
		if o is GlitchSpot:
			# Every moment E really works is heard, not just seen.
			cue = "ping"
			on = o.can_glitch(run)
		elif o is TapeEater:
			cue = "static"
			on = (o as TapeEater).static_wave(run)
		if cue == "":
			continue
		var key := "cue%d" % o.get_instance_id()
		var was: bool = _warning_state.get(key, false)
		if on and not was:
			_sound(cue)
		elif was and not on and cue == "static":
			_stop_sound(cue)
		_warning_state[key] = on


## "Press E now": a bright rising three-note chime, made here so it needs no asset.
## A touch of third harmonic lets it cut through the rewind whirr and the static.
static func _ping_stream() -> AudioStreamWAV:
	var rate := 22050
	var notes := [880.0, 1175.0, 1760.0]
	var note_len := 0.07
	var length := note_len * notes.size() + 0.18
	var n := int(rate * length)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / rate
		var k := mini(int(t / note_len), notes.size() - 1)
		phase += TAU * notes[k] / rate
		var local := t - k * note_len
		var env := minf(local * 400.0, 1.0) * (exp(-local * 9.0) if k < notes.size() - 1 else exp(-local * 6.0))
		var v := sin(phase) + 0.3 * sin(phase * 3.0)
		data.encode_s16(i * 2, int(clampf(v * env * 15000.0, -32767.0, 32767.0)))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.data = data
	return s


## Top-left corner of the view, in room pixels, keeping the kid in sight and the view inside the room.
func _camera_target() -> Vector2:
	var view := get_viewport_rect().size / ROOM_ZOOM
	var x := clampf(run.kid_x - view.x * LOOK_AHEAD, 0.0, maxf(room.width - view.x, 0.0))
	var y := clampf(run.kid_y() - view.y * 0.62, 0.0, maxf(180.0 - view.y, 0.0))
	return Vector2(x, y)


func _can_enter_forbidden() -> bool:
	return room_index == 0 and not _secret_visited and state == State.ROOM \
		and run.kid_x >= 285.0 and run.kid_x <= 342.0 \
		and run.room_time >= 5.0 and run.room_time < 8.0


func _enter_forbidden() -> void:
	_stop_sound("rewind")
	_secret_visited = true
	_playing = false
	room.visible = false
	_forbidden = ForbiddenRoom.new()
	_forbidden.setup(0, 0)
	_forbidden.thought.connect(_forbidden_thought)
	_forbidden.tape_reached.connect(_forbidden_tape_reached)
	world.add_child(_forbidden)
	world.scale = Vector2(FORBIDDEN_ZOOM, FORBIDDEN_ZOOM)
	_cam = Vector2.ZERO
	state = State.FORBIDDEN
	_update_ambience(0.0)
	hud.clear_texts()
	hud.cinematic_mode = true
	hud.mode = "PAUSE"
	hud.hint("THE FORBIDDEN ROOM  ·  D = PLAY / PAUSE")
	_sound("door_creak")


func _forbidden_thought(text: String) -> void:
	hud.say(text, "LEA", _forbidden.kid)


func _forbidden_tape_reached() -> void:
	hud.mode = "PAUSE"
	hud.hint("An unlisted VHS tape. E = PICK UP AND INSERT.")
	_sound("static")


func _start_forbidden_video() -> void:
	state = State.FORBIDDEN_VIDEO
	_update_ambience(0.0)
	_secret_found = true
	_stop_sound("static")
	_sound("click")
	_sound("static")
	_forbidden.visible = false
	_forbidden_video = ForbiddenTape.new()
	_forbidden_video.finished.connect(_forbidden_signal_lost)
	world.add_child(_forbidden_video)
	world.scale = Vector2(FULL_ZOOM, FULL_ZOOM)
	world.position = Vector2.ZERO
	hud.visible = false
	vhs.set_shader_parameter("noise_amount", 0.28)
	vhs.set_shader_parameter("tracking", 0.16)


func _forbidden_signal_lost() -> void:
	if state != State.FORBIDDEN_VIDEO:
		return
	state = State.FORBIDDEN_LOST
	_secret_lost_t = 2.2
	_forbidden_video.skip()
	_forbidden_video.visible = false
	hud.visible = true
	hud.cinematic_mode = false
	hud.clear_texts()
	hud.mode = "STOP"
	hud.message = "YOU WEREN'T MEANT TO SEE THAT"
	hud.sub_message = ""
	vhs.set_shader_parameter("noise_amount", 0.85)
	vhs.set_shader_parameter("tracking", 1.0)
	_sound("echo")
	_sound("static")


func _return_from_forbidden() -> void:
	if state != State.FORBIDDEN_LOST:
		return
	_cleanup_forbidden()
	room.visible = true
	run.kid_x = 313.0
	run.room_time = 6.5
	run.seen_time = maxf(run.seen_time, 6.5)
	_playing = false
	state = State.ROOM
	world.scale = Vector2(ROOM_ZOOM, ROOM_ZOOM)
	_cam = _camera_target()
	hud.visible = true
	hud.cinematic_mode = false
	hud.mode = "PAUSE"
	hud.message = "UNLISTED TAPE FOUND"
	hud.sub_message = "The clock door is still open. D = PLAY."
	hud.hint("That recording wasn't meant for this house.")
	_show()
	_sound("glitch")


func _cleanup_forbidden() -> void:
	_stop_sound("static")
	if is_instance_valid(_forbidden_video):
		_forbidden_video.queue_free()
		_forbidden_video = null
	if is_instance_valid(_forbidden):
		_forbidden.queue_free()
		_forbidden = null


func _update_screen_fx() -> void:
	var tracking := 0.0
	var bat_tracking := 0.0
	var noise := 0.04
	if hud.mode == "REW" or hud.mode.begins_with("SCRUB"):
		tracking = 0.5
		noise = 0.12
	for o in room.objects:
		var fx := o.screen_effect(run)
		tracking += fx.get("tracking", 0.0)
		bat_tracking = maxf(bat_tracking, fx.get("bat_tracking", 0.0))
		noise += fx.get("noise", 0.0)
	if _fx_burst > 0.0:
		tracking = 1.5
		noise = 0.5
	vhs.set_shader_parameter("tracking", tracking)
	vhs.set_shader_parameter("bat_tracking", bat_tracking)
	vhs.set_shader_parameter("noise_amount", noise)
	vhs.set_shader_parameter("rewind_amount", 1.0 if hud.mode == "REW" or hud.mode == "SCRUB-" else 0.0)


func _fail() -> void:
	vhs.set_shader_parameter("bat_tracking", 0.0)
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
	hud.clear_texts()

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
		hud.message = "SIGNAL LOST"
		hud.sub_message = "the tape monster reached the playhead"
		line = LINE_SCREEN if (run.cause as TapeEater).phase(run) == TapeEater.Phase.SCREEN else LINE_EATER
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
	if line == "" or (_used_lines.has(line) and line != LINE_SCREEN):
		line = LINES[mini(total_fails - 1, LINES.size() - 1)]
	if _used_lines.has(line) and line != LINE_SCREEN:
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
	_cleanup_forbidden()
	vhs.set_shader_parameter("bat_tracking", 0.0)
	state = State.ENDING
	_update_ambience(0.0)
	intro_music.stop()
	_stop_sound("tape")
	_stop_sound("rewind")
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
	_ending.setup(candies, total_fails, attempts, tape_used, _secret_found)
	_ending.exit_requested.connect(get_tree().quit)
	world.add_child(_ending)


func _sound(id: String) -> void:
	var player: AudioStreamPlayer = _sound_players.get(id)
	if player:
		if id == "ping" or id == "echo" or id.ends_with("_warning"):
			_audio_duck_t = maxf(_audio_duck_t, player.stream.get_length() + 0.25)
		player.stop()
		player.play()


func _stop_sound(id: String) -> void:
	var player: AudioStreamPlayer = _sound_players.get(id)
	if player:
		player.stop()
