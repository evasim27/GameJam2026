extends Node2D
## The kid on the tape. Doesn't move on its own; the game sets `position.x` from the tape.

var _walk := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func step(dx: float) -> void:
	_walk += absf(dx)
	sprite.offset.y = -absf(sin(_walk * 0.6)) * 2.0 if dx != 0.0 else 0.0


func fall() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "position:y", 60.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


func eaten() -> void:
	sprite.visible = false


func revive() -> void:
	sprite.position.y = 0.0
	sprite.visible = true
