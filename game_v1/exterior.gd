extends Node2D

@onready var background: Sprite2D = $Background
@onready var child: AnimatedSprite2D = $Child

var dialogue: Label


func _ready() -> void:
	dialogue = Label.new()
	dialogue.position = Vector2(325, 115)
	dialogue.add_theme_font_size_override("font_size", 12)
	dialogue.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72))
	add_child(dialogue)
	dialogue.hide()

	child.position = Vector2(75, 196)
	child.play("walk")

	var path := create_tween()
	path.tween_property(child, "position", Vector2(350, 196), 5.1)
	path.tween_property(child, "position", Vector2(380, 176), 1.4)
	path.tween_callback(_at_door)


func _at_door() -> void:
	child.stop()
	child.frame = 0
	dialogue.text = "Trick or treat!"
	dialogue.show()
	await get_tree().create_timer(1.5).timeout

	dialogue.text = "*knock knock*"
	for i in range(2):
		var knock := create_tween()
		knock.tween_property(child, "position", Vector2(382, 176), 0.09)
		knock.tween_property(child, "position", Vector2(380, 176), 0.12)
		await knock.finished
		if i == 0:
			await get_tree().create_timer(0.2).timeout

	await get_tree().create_timer(0.5).timeout
	dialogue.hide()
	background.texture = preload("res://exterior_background_open.png")
	await get_tree().create_timer(0.45).timeout

	child.play("walk")
	var enter := create_tween()
	enter.tween_property(child, "position", Vector2(395, 176), 0.7)
	await enter.finished
	child.hide()
