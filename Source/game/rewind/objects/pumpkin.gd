class_name Pumpkin
extends TapeObject
## A jack-o'-lantern that bites anything in front of it on a fixed rhythm of room time.

const SHEET := preload("res://assets/rewind/pumpkin-styled.png")
## The generated sheet has uneven transparent margins; crop both poses to a common baseline.
const FRAME_SIZE := Vector2(540, 480)
const FRAME_ORIGINS := [Vector2(248, 232), Vector2(978, 232)]
const SPRITE_WIDTH := 16.0
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
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(FRAME_ORIGINS[0], FRAME_SIZE)
	var sprite_scale := SPRITE_WIDTH * size / FRAME_SIZE.x
	_sprite.scale = Vector2(sprite_scale, sprite_scale)
	_sprite.modulate = tint
	_sprite.position = Vector2(width / 2.0, -FRAME_SIZE.y * sprite_scale / 2.0)
	add_child(_sprite)


func zone_width() -> float:
	return width


func is_deadly(t: float) -> bool:
	return periodic(t, period, bite_from, bite_to)


func show_time(run: RoomRun) -> void:
	var t := run.room_time
	var biting := is_deadly(t)
	_sprite.region_rect = Rect2(FRAME_ORIGINS[1 if biting else 0], FRAME_SIZE)
	var until_bite := fposmod(bite_from - t, period)
	var shaking := not biting and until_bite < WARN_TIME
	_sprite.position.x = width / 2.0 + (sin(t * 80.0) if shaking else 0.0)


func timeline_marks(length: float) -> Array:
	if not show_marks:
		return []
	return periodic_marks(length, period, bite_from, bite_to, Color(1.0, 0.55, 0.15, 0.7), 1)
