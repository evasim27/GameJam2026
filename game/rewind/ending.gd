extends Node2D
## The kid runs out onto the porch at first light, finds a blank tape among the candy and looks
## straight into the camera (with the echoes of failed attempts behind it, if any). Then the
## viewer's empty armchair, the VCR ejecting the tape, and the results.

const FONT := preload("res://assets/fonts/VT323-Regular.ttf")
const FLOOR_TEX := preload("res://assets/rewind/floor.png")
const ARMCHAIR := preload("res://assets/noble_interior/armchair_tall.png")
const ECHO := preload("res://assets/rewind/echo.png")
const CANDY := preload("res://assets/rewind/candy.png")
const KidNode := preload("res://rewind/kid.gd")
const ALL_CANDY := ["Maja 1989", "Luka 1994", "Tina 2003"]

var _candies: Array[String] = []
var _fails := 0
var _attempts := 0
var _tape := 0.0
var _t := 0.0
var _kid: Node2D


func setup(candies: Array[String], fails: int, attempts: int, tape_used: float) -> void:
	_candies = candies
	_fails = fails
	_attempts = attempts
	_tape = tape_used


func _ready() -> void:
	_kid = KidNode.new()
	add_child(_kid)


func _process(delta: float) -> void:
	_t += delta
	_kid.visible = _t < 8.0
	var x := 40.0 + minf(_t, 2.5) * 40.0
	_kid.place(x, 150.0)
	if _t >= 2.5:
		_kid.stand()
	if _t >= 5.0:
		_kid.look_at_camera()
	queue_redraw()


func _draw() -> void:
	if _t < 8.0:
		_draw_porch()
	elif _t < 12.0:
		_draw_empty_room(_t - 8.0)
	else:
		_draw_results()


func _draw_porch() -> void:
	for i in 18:
		var c := Color(0.35, 0.4, 0.6).lerp(Color(0.95, 0.75, 0.65), i / 17.0)
		draw_rect(Rect2(0, i * 9, 320, 9), c)
	draw_rect(Rect2(0, 20, 30, 130), Color(0.2, 0.13, 0.15))
	draw_set_transform(Vector2(0, 150), 0.0, Vector2(0.5, 0.5))
	draw_texture_rect(FLOOR_TEX, Rect2(0, 0, 640, 60), true, Color(0.8, 0.7, 0.7))
	draw_set_transform(Vector2.ZERO)
	# Echoes of every failed attempt, standing behind.
	for i in mini(_fails, 6):
		var ex := 70.0 + i * 16.0
		draw_texture_rect_region(ECHO, Rect2(ex, 126, 16, 24), Rect2(16, 0, 16, 24), Color(1, 1, 1, 0.35))
	if _t > 3.0:
		var y := 112.0
		for c in _candies:
			draw_texture(CANDY, Vector2(140 + _candies.find(c) * 12, y))
		# A blank tape among the candy.
		draw_rect(Rect2(170, y - 2, 18, 11), Color(0.08, 0.08, 0.09))
		draw_rect(Rect2(172, y, 14, 4), Color(0.9, 0.88, 0.8))


func _draw_empty_room(s: float) -> void:
	draw_rect(Rect2(0, 0, 320, 180), Color(0.03, 0.03, 0.06))
	draw_set_transform(Vector2(40, 72), 0.0, Vector2(1.4, 1.4))
	draw_texture(ARMCHAIR, Vector2.ZERO, Color(0.2, 0.18, 0.26))
	draw_set_transform(Vector2.ZERO)
	_text("(prazen)", Vector2(66, 172), 10, Color(0.4, 0.4, 0.5))
	draw_rect(Rect2(180, 66, 60, 46), Color(0.12, 0.12, 0.13))
	var n := int(s * 24.0)
	for y in range(0, 36, 2):
		for x in range(0, 50, 2):
			var v := float((n * 71 + x * 13 + y * 29 + x * y) % 13) / 12.0
			draw_rect(Rect2(185 + x, 70 + y, 2, 2), Color(0.3 + v * 0.6, 0.7 + v * 0.3, 0.9))
	draw_rect(Rect2(176, 112, 68, 30), Color(0.1, 0.07, 0.05))
	draw_rect(Rect2(186, 118, 40, 6), Color(0.06, 0.06, 0.07))
	# The VCR spits the tape out.
	var out := clampf((s - 1.5) / 0.6, 0.0, 1.0) * 12.0
	draw_rect(Rect2(190, 124 + out - 6, 32, 8), Color(0.08, 0.08, 0.09))


func _draw_results() -> void:
	draw_rect(Rect2(0, 0, 320, 180), Color(0.02, 0.02, 0.04))
	_text("KONEC TRAKU", Vector2(110, 30), 24, Color(0.93, 0.95, 1.0))
	_text("SLADKARIJE  %d/3" % _candies.size(), Vector2(100, 56), 16, Color(0.9, 0.9, 1.0))
	_text("POSKUSI     %d" % _attempts, Vector2(100, 68), 16, Color(0.9, 0.9, 1.0))
	_text("PORABLJEN TRAK  %.1f s" % _tape, Vector2(100, 80), 16, Color(0.9, 0.9, 1.0))
	# The tape's label. With all three candies, its last word becomes readable.
	var label := Rect2(90, 96, 140, 50)
	draw_rect(label.grow(3), Color(0.08, 0.08, 0.09))
	draw_rect(label, Color(0.85, 0.82, 0.72))
	for i in ALL_CANDY.size():
		var name_s: String = ALL_CANDY[i].split(" ")[0]
		var p := label.position + Vector2(8 + i * 44, 14)
		_text(name_s, p, 14, Color(0.15, 0.1, 0.1))
		draw_line(p + Vector2(-1, -3), p + Vector2(24, -3), Color(0.1, 0.05, 0.05), 1.0)
	var last := "Gledalec" if _candies.size() == 3 else "G#l%d@?c"
	_text(last, label.position + Vector2(48, 36), 18, Color(0.1, 0.05, 0.05))
	_text("R — previj na začetek", Vector2(108, 168), 12, Color(0.6, 0.6, 0.72))


func _text(text: String, pos: Vector2, size: int, color: Color) -> void:
	draw_set_transform(pos, 0.0, Vector2(0.5, 0.5))
	draw_string(FONT, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size * 2, color)
	draw_set_transform(Vector2.ZERO)
