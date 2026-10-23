class_name Pumpkin
extends TapeObject
## A jack-o'-lantern that bites anything in front of it on a fixed rhythm of room time.

const SHEET := preload("res://assets/rewind/pumpkin.png")
const WARN_TIME := 0.5

@export var width := 16.0
@export var period := 4.0
## Bites while (room_time mod period) is between these two values.
@export var bite_from := 0.0
@export var bite_to := 2.0
## The second pumpkin has no exact window on the timeline; the player reads its warning shake.
@export var show_marks := true
@export var size := 1.0
@export var tint := Color.WHITE

var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = SHEET
	_sprite.hframes = 2
	_sprite.scale = Vector2(size, size)
	_sprite.modulate = tint
	_sprite.position = Vector2(width / 2.0, -8.0 * size)
	add_child(_sprite)


func zone_width() -> float:
	return width


func is_deadly(t: float) -> bool:
	return periodic(t, period, bite_from, bite_to)


func show_time(run: RoomRun) -> void:
	var t := run.room_time
	var biting := is_deadly(t)
	_sprite.frame = 1 if biting else 0
	var until_bite := fposmod(bite_from - t, period)
	var shaking := not biting and until_bite < WARN_TIME
	_sprite.offset = Vector2(sin(t * 80.0), 0) if shaking else Vector2.ZERO


func timeline_marks(length: float) -> Array:
	if not show_marks:
		return []
	return periodic_marks(length, period, bite_from, bite_to, Color(1.0, 0.55, 0.15, 0.7), 1)
