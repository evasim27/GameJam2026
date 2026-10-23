extends Area2D

const ART := preload("res://rewind/door_art.gd")

signal reached


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	ART.draw_door(self, Rect2(-9, -18, 18, 36), true)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		reached.emit()
