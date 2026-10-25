class_name Candy
extends TapeObject
## A memory VHS cassette with a name and a year. The kid picks it up when walking past it (optionally
## only inside a time window). It never comes back on rewind; the room confirms it on success.

const SPRITE := preload("res://assets/rewind/cinematic/memory-vhs.png")
const ICON_SIZE := Vector2(10, 5.25)
## Remove the sheet's transparent margins so all three cassettes have the same visible size.
const REGIONS := [Rect2(103, 201, 580, 303), Rect2(796, 201, 579, 303), Rect2(1490, 201, 579, 303)]

@export var candy_name := "Maja 1989"
## Room-time window when it can be picked up. period 0 means a single window [from, to).
@export var period := 0.0
@export var from := 0.0
@export var to := 9999.0
## Only reachable after this glitch, and only if it happened while the kid was at most at `glitch_before_x`.
@export var needs_glitch := ""
@export var glitch_before_x := INF
@export var lift := 12.0

var _sprite: Sprite2D
var _on := false
var _pulse := 0.0


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = SPRITE
	_sprite.region_enabled = true
	_sprite.region_rect = sprite_region(candy_name)
	_sprite.scale = ICON_SIZE / _sprite.region_rect.size
	_sprite.position = Vector2(0, -lift)
	add_child(_sprite)


## Use the same cassette for each memory in the rooms and the collected-memory display.
static func sprite_region(memory_name: String) -> Rect2:
	var index := 0
	if memory_name == "Luka 1994":
		index = 1
	elif memory_name == "Tina 2003":
		index = 2
	return REGIONS[index]


func available(run: RoomRun) -> bool:
	if needs_glitch != "":
		if not run.glitched.has(needs_glitch) or run.glitched[needs_glitch] > glitch_before_x:
			return false
	if period > 0.0:
		return periodic(run.room_time, period, from, to)
	return run.room_time >= from and run.room_time < to


func show_time(run: RoomRun) -> void:
	var hidden := needs_glitch != "" and not run.glitched.has(needs_glitch)
	_sprite.visible = not hidden and not run.taken.has(candy_name)
	_on = available(run)
	_sprite.modulate = Color(1.3, 1.25, 1.1) if _on else Color(0.55, 0.5, 0.6, 0.8)
	_sprite.position.y = -lift + (sin(run.room_time * 6.0) if _on else 0.0)
	_pulse = 0.5 + 0.5 * sin(run.room_time * 4.0)
	queue_redraw()


## A soft warm pool of light on the floor so the cassette stands out from the room.
func _draw() -> void:
	if not _sprite.visible:
		return
	var strength := (0.75 + 0.25 * _pulse) if _on else 0.35
	var glow := Color(1.0, 0.8, 0.45)
	for i in 5:
		var k := float(i) / 4.0
		var radius := lerpf(14.0, 4.0, k)
		var a := strength * lerpf(0.06, 0.3, k)
		draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.32))
		draw_circle(Vector2.ZERO, radius, Color(glow, a))
	# A faint column rising towards the cassette.
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(-5, -lift - 3, 10, lift + 2), Color(glow, strength * 0.08))


func timeline_marks(length: float) -> Array:
	if period <= 0.0 or needs_glitch != "":
		return []
	return periodic_marks(length, period, from, to, Color(1.0, 0.5, 0.75, 0.9), 2)
