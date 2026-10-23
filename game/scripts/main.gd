extends Node2D

@onready var status_label: Label = $HUD/Status


func _ready() -> void:
	$ExitDoor.reached.connect(_on_exit_reached)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _on_exit_reached() -> void:
	status_label.text = "CRYPT CLEARED · press R"
