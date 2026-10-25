extends Node2D
## Painterly wall props and fine atmospheric details. These never participate in tape rules or collisions.

const PORTRAITS := preload("res://assets/rewind/cinematic/portraits-oil-atlas.png")
const CANDLE := preload("res://assets/rewind/cinematic/candle.png")

enum Kind { PORTRAIT, WEB, SCONCE, SCRATCHES }

var kind := Kind.PORTRAIT
var variant := 0
var elapsed := 0.0


func _ready() -> void:
	# Keep the oil painting readable under the room's 3x camera magnification.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _process(delta: float) -> void:
	if kind == Kind.SCONCE or (kind == Kind.WEB and variant % 2 == 1):
		elapsed += delta
		queue_redraw()


func _draw() -> void:
	match kind:
		Kind.PORTRAIT:
			_portrait()
		Kind.WEB:
			_web()
		Kind.SCONCE:
			_sconce()
		Kind.SCRATCHES:
			_scratches()


func _portrait() -> void:
	var cell_width := float(PORTRAITS.get_width()) / 3.0
	var source := Rect2((variant % 3) * cell_width + 1, 0, cell_width - 2, PORTRAITS.get_height())
	var height := 34.0
	var picture_width := height * source.size.x / source.size.y
	var canvas := Rect2(-picture_width / 2.0, -18, picture_width, height)
	draw_rect(Rect2(canvas.position + Vector2(1, 1), canvas.size), Color(0.025, 0.018, 0.02, 0.45))
	draw_texture_rect_region(PORTRAITS, canvas, source, Color(0.9, 0.84, 0.76))


func _web() -> void:
	var silk := Color(0.68, 0.64, 0.57, 0.32)
	var radius := 28.0
	for ray in 6:
		var angle := ray * PI / 10.0
		draw_line(Vector2.ZERO, Vector2(cos(angle), sin(angle)) * radius, silk, 0.45, true)
	for ring in [0.25, 0.5, 0.75, 1.0]:
		var points := PackedVector2Array()
		for step in 21:
			var angle := step * PI / 40.0
			var sag := 1.0 - 0.12 * sin((step % 4) * PI / 4.0)
			points.append(Vector2(cos(angle), sin(angle)) * radius * ring * sag)
		draw_polyline(points, silk, 0.45, true)
	if variant % 2 == 1:
		var p := Vector2(17, 33 + roundf(sin(elapsed * 1.4 + position.x) * 3))
		draw_line(Vector2(17, 14), p, Color(0.76, 0.75, 0.8, 0.3))
		for side in [-1, 1]:
			for leg in 3:
				draw_polyline(PackedVector2Array([p, p + Vector2(side * 3, leg - 2), p + Vector2(side * 4, leg * 2 - 2)]), Color(0.12, 0.09, 0.14))
		draw_circle(p, 2, Color(0.08, 0.06, 0.1))


func _sconce() -> void:
	var flicker := 0.88 + 0.12 * sin(elapsed * 8.3 + position.x) * sin(elapsed * 13.1)
	for i in 5:
		draw_circle(Vector2(0, -10), 19 - i * 3, Color(1, 0.48, 0.14, 0.015 * flicker))
	# Aged metal wall plate and the same wax candle used on the foyer furniture.
	draw_ellipse_plate()
	draw_arc(Vector2(0, 1), 4, 0, PI, 12, Color(0.32, 0.23, 0.14), 1.5, true)
	draw_texture_rect(CANDLE, Rect2(-4, -16, 8, 16), false, Color(0.87, 0.8, 0.68))


func draw_ellipse_plate() -> void:
	draw_set_transform(Vector2(0, 4), 0.0, Vector2(0.6, 1.0))
	draw_circle(Vector2.ZERO, 6, Color(0.15, 0.11, 0.08))
	draw_arc(Vector2.ZERO, 5, 0, TAU, 20, Color(0.43, 0.31, 0.17), 0.8, true)
	draw_set_transform(Vector2.ZERO)


func _scratches() -> void:
	for i in 4:
		var p := Vector2(i * 3, i % 2 * 2)
		draw_line(p, p + Vector2(-3, 12 - i), Color(0.06, 0.04, 0.07, 0.8))
		draw_line(p + Vector2(1, 1), p + Vector2(-2, 11 - i), Color(0.66, 0.53, 0.42, 0.35))
