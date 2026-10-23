@tool
class_name Pumpkin
extends TapeObject
## A jack-o'-lantern that snaps at anything in front of it on a fixed rhythm.

const SHEET := preload("res://assets/rewind/pumpkin.png")
const WARN_TIME := 0.5

@export var width := 16.0
@export var period := 4.0
## Bites while (t mod period) is between these two values.
@export var bite_from := 0.0
@export var bite_to := 2.0

var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = SHEET
	_sprite.hframes = 2
	_sprite.position = Vector2(width / 2.0, -8)
	add_child(_sprite)
	show_time(0.0)


func zone_width() -> float:
	return width


func is_deadly(t: float) -> bool:
	var phase := fposmod(t, period)
	return phase >= bite_from and phase < bite_to


func show_time(t: float) -> void:
	if not _sprite:
		return
	var biting := is_deadly(t)
	_sprite.frame = 1 if biting else 0
	var until_bite := fposmod(bite_from - t, period)
	var shaking := not biting and until_bite < WARN_TIME
	_sprite.offset = Vector2(sin(t * 80.0) * 1.0, 0) if shaking else Vector2.ZERO


func timeline_marks(tape_length: float) -> Array:
	var marks := []
	var start := 0.0
	while start < tape_length:
		marks.append({"from": start + bite_from, "to": minf(start + bite_to, tape_length), "color": Color(1.0, 0.45, 0.1, 0.55), "row": 1})
		start += period
	return marks
