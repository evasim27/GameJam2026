extends Node2D
## Be Kind, Rewind: you don't control the kid, you control the tape.

enum State { PLAYING, DEAD, WON, SNAPPED }

const TAPE_LENGTH := 60.0
const REWIND_SPEED := 2.0
const FF_SPEED := 3.0
const REWIND_COST := 0.012  # tape health per tape second rewound
const DEATH_COST := 0.1
const DEATH_SKIP := 2.0  # tape seconds the VCR jumps back after a death

var tape_time := 0.0
var kid_x := 0.0
var health := 1.0
var state := State.PLAYING
var history: Array[Vector2] = []  # (tape_time, kid_x) per frame, for undoing deaths
var objects: Array = []
var start_x := 0.0

@onready var level: Node2D = $Level
@onready var kid: Node2D = $Level/Kid
@onready var goal: Node2D = $Level/Goal
@onready var hud: Control = $HUD/OSD
@onready var vhs: ShaderMaterial = $VHS/Screen.material


func _ready() -> void:
	for o in $Level/Objects.get_children():
		if o is TapeObject:
			objects.append(o)
	start_x = kid.position.x
	kid_x = start_x
	hud.tape_length = TAPE_LENGTH
	for o: TapeObject in objects:
		hud.marks.append_array(o.timeline_marks(TAPE_LENGTH))
	# Short windows last, so they stay visible on top of long ones.
	hud.marks.sort_custom(func(a, b): return a.to - a.from > b.to - b.from)
	hud.message = "BE KIND, REWIND"
	hud.sub_message = "get the kid to the door. you control the tape, not the kid."
	_show_time()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _process(delta: float) -> void:
	if state != State.PLAYING:
		return

	var speed := 0.0
	var mode := "PAUSE"
	if Input.is_action_pressed("tape_rewind"):
		speed = -REWIND_SPEED
		mode = "REW"
	elif Input.is_action_pressed("tape_play"):
		var ff := Input.is_action_pressed("tape_fast")
		speed = FF_SPEED if ff else 1.0
		mode = "FF" if ff else "PLAY"
	hud.mode = mode

	if speed != 0.0:
		hud.message = ""
		_advance(speed * delta)

	_update_screen_fx(mode == "REW")


func _advance(dt: float) -> void:
	var new_t := clampf(tape_time + dt, 0.0, TAPE_LENGTH)
	dt = new_t - tape_time
	if dt == 0.0:
		if new_t >= TAPE_LENGTH:
			hud.message = "END OF TAPE"
			hud.sub_message = "rewind and try again"
		return

	history.append(Vector2(tape_time, kid_x))
	if dt < 0.0:
		health -= REWIND_COST * -dt
	var new_x := TapeSim.move_kid(objects, kid_x, dt, new_t, start_x)
	kid.step(new_x - kid_x)
	kid_x = new_x
	tape_time = new_t
	_show_time()

	if health <= 0.0:
		_snap()
		return
	var killer := TapeSim.hazard_at(objects, kid_x, tape_time)
	if killer:
		_die(killer)
	elif kid_x >= goal.position.x:
		_win()


func _show_time() -> void:
	for o: TapeObject in objects:
		o.show_time(tape_time)
	kid.position.x = kid_x
	hud.tape_time = tape_time
	hud.health = health


func _update_screen_fx(rewinding: bool) -> void:
	var tracking := 0.5 if rewinding else 0.0
	var noise := 0.12 if rewinding else 0.04
	for o: TapeObject in objects:
		var fx := o.screen_effect(tape_time)
		tracking += fx.get("tracking", 0.0)
		noise += fx.get("noise", 0.0)
	vhs.set_shader_parameter("tracking", tracking)
	vhs.set_shader_parameter("noise_amount", noise)


func _die(killer: TapeObject) -> void:
	state = State.DEAD
	hud.mode = "STOP"
	if killer is GhostBridge:
		kid.fall()
	else:
		kid.eaten()
	hud.message = "TRACKING LOST"
	hud.sub_message = "the tape skips back..."
	vhs.set_shader_parameter("noise_amount", 0.85)
	vhs.set_shader_parameter("tracking", 1.0)
	await get_tree().create_timer(1.2).timeout

	# The VCR chews the tape and jumps back a couple of seconds.
	var target := tape_time - DEATH_SKIP
	while history.size() > 0 and tape_time > target:
		var h: Vector2 = history.pop_back()
		tape_time = h.x
		kid_x = h.y
	health -= DEATH_COST
	kid.revive()
	_show_time()
	if health <= 0.0:
		_snap()
		return
	hud.message = ""
	state = State.PLAYING


func _win() -> void:
	state = State.WON
	hud.mode = "STOP"
	hud.message = "TRICK OR TREAT!"
	hud.sub_message = "tape health %d%%  ·  press R to watch again" % int(health * 100.0)
	_update_screen_fx(false)


func _snap() -> void:
	state = State.SNAPPED
	health = 0.0
	hud.health = 0.0
	hud.mode = "STOP"
	hud.message = "TAPE SNAPPED"
	hud.sub_message = "the tape-eater got it. press R"
	vhs.set_shader_parameter("noise_amount", 0.6)
