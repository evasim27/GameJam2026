extends CharacterBody2D

const SPEED := 140.0
const JUMP_VELOCITY := -340.0
const FALL_LIMIT := 420.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	_update_animation(direction)

	if position.y > FALL_LIMIT:
		die()


func _update_animation(direction: float) -> void:
	if direction:
		sprite.flip_h = direction < 0
	if not is_on_floor():
		sprite.play("jump")
	elif direction:
		sprite.play("walk")
	else:
		sprite.play("idle")


func die() -> void:
	get_tree().call_deferred("reload_current_scene")
