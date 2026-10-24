class_name Candy
extends TapeObject
## A memory VHS cassette with a name and a year. The kid picks it up when walking past it inside
## a narrow optional window. It never comes back on rewind; the room confirms it on success.

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
	var on := available(run)
	_sprite.modulate = Color(1.3, 1.25, 1.1) if on else Color(0.55, 0.5, 0.6, 0.8)
	_sprite.position.y = -lift + (sin(run.room_time * 6.0) if on else 0.0)


func timeline_marks(length: float) -> Array:
	if period <= 0.0 or needs_glitch != "":
		return []
	return periodic_marks(length, period, from, to, Color(1.0, 0.5, 0.75, 0.9), 2)
