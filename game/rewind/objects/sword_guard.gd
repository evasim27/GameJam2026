class_name SwordGuard
extends TapeObject
## A planted swordsman. Animation and lethal frames share the recording's clock.

enum Kind { SKELETON, KNIGHT }

const SKELETON_ART := preload("res://rewind/objects/skeleton.tscn")
const KNIGHT_ART := preload("res://rewind/objects/knight_armor.tscn")
const RAISE_END := 0.16
const STRIKE_FROM := 0.28
const SLASH_END := 0.35
const STRIKE_TO := 0.49
const RECOVER_END := 0.71

@export var kind := Kind.SKELETON
@export var width := 26.0
@export var period := 4.4
@export var swing_from := 3.4

var _sprite: AnimatedSprite2D


func _ready() -> void:
	_sprite = (KNIGHT_ART if kind == Kind.KNIGHT else SKELETON_ART).instantiate()
	_sprite.position.x = width
	add_child(_sprite)
	_sprite.stop()
	_sprite.animation = &"swing"
	_sprite.frame = frame_at(0.0)


func zone_width() -> float:
	return width


func is_deadly(t: float) -> bool:
	var elapsed := fposmod(t - swing_from, period)
	return elapsed >= STRIKE_FROM and elapsed < STRIKE_TO


func frame_at(t: float) -> int:
	var elapsed := fposmod(t - swing_from, period)
	if elapsed < RAISE_END:
		return 1
	if elapsed < STRIKE_FROM:
		return 2
	if elapsed < SLASH_END:
		return 3
	if elapsed < STRIKE_TO:
		return 4
	if elapsed < RECOVER_END:
		return 5
	return 0


func show_time(run: RoomRun) -> void:
	if is_instance_valid(_sprite):
		_sprite.frame = frame_at(run.room_time)


func timeline_marks(length: float) -> Array:
	var color := Color(0.9, 0.75, 0.45, 0.8) if kind == Kind.KNIGHT else Color(0.85, 0.9, 0.78, 0.8)
	return periodic_marks(length, period, swing_from + STRIKE_FROM, swing_from + STRIKE_TO, color, 1)
