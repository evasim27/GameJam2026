extends Node2D
## Painterly wall props and fine atmospheric details. These never participate in tape rules or collisions.

const PORTRAITS := preload("res://assets/rewind/cinematic/portraits-oil-atlas.png")
const COBWEB := preload("res://rewind/cobweb_art.gd")
const SCONCE := preload("res://assets/rewind/cinematic/wall-sconce.png")

enum Kind { PORTRAIT, WEB, SCONCE, SCRATCHES }

var kind := Kind.PORTRAIT
# Web variants: shape * 2 + hanging spider (0 or 1).
var variant := 0
var elapsed := 0.0


func _ready() -> void:
	# Sconces and silk share the furniture's half-room-pixel texels; portraits keep their painted detail.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if kind in [Kind.SCONCE, Kind.WEB] else CanvasItem.TEXTURE_FILTER_LINEAR


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
	var shape := variant >> 1
	COBWEB.draw_web(self, Vector2.ZERO, false, shape)
	if variant % 2 == 1:
		var anchor := COBWEB.spider_anchor(shape)
		var p := anchor + Vector2(0, 7 + snappedf(sin(elapsed * 1.4 + position.x) * 2, 0.5))
		COBWEB.draw_thread(self, anchor, p, Color(0.58, 0.54, 0.45, 0.35))
		for side in [-1, 1]:
			for leg in 4:
				var knee := p + Vector2(side * 2, leg - 1.5)
				var foot := p + Vector2(side * 3, leg * 1.5 - 2)
				COBWEB.draw_thread(self, p, knee, Color(0.16, 0.12, 0.1))
				COBWEB.draw_thread(self, knee, foot, Color(0.16, 0.12, 0.1))
		draw_rect(Rect2(p + Vector2(-1, -1), Vector2(2, 2.5)), Color(0.1, 0.075, 0.065))
		draw_rect(Rect2(p + Vector2(-0.5, -1), Vector2(0.5, 1)), Color(0.29, 0.22, 0.16))


func _sconce() -> void:
	var flicker := 0.88 + 0.12 * sin(elapsed * 8.3 + position.x) * sin(elapsed * 13.1)
	# Light stays at the wick, above the integrated brass bracket and wall plate.
	var flame := Vector2(-1, -12)
	for i in 8:
		draw_circle(flame, (14.0 - i * 1.5) * flicker, Color(1.0, 0.57, 0.16, (0.008 + i * 0.002) * flicker))
	# Native 24x48 canvas at half scale matches the Noble Interior sprites.
	draw_texture_rect(SCONCE, Rect2(-6, -17, 12, 24), false, Color(0.87, 0.8, 0.68))


func _scratches() -> void:
	for i in 4:
		var p := Vector2(i * 3, i % 2 * 2)
		draw_line(p, p + Vector2(-3, 12 - i), Color(0.06, 0.04, 0.07, 0.8))
		draw_line(p + Vector2(1, 1), p + Vector2(-2, 11 - i), Color(0.66, 0.53, 0.42, 0.35))
