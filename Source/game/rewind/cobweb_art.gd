extends RefCounted
## Half-room-pixel silk, matching the 64 px furniture displayed at half scale.
## Cache the raster so animated spiders never regenerate the static web.

const PIXEL := 0.5
enum Shape { DRAPED, FAN, ORB, TORN }

# Each silhouette has its own off-center hub and irregular attachment points.
# Open fans and hanging sheets have no straight top or vertical side borders.
const PROFILES := [
	{"hub": Vector2(0.48, 0.18), "closed": false,
		"anchors": [Vector2(0, 0.06), Vector2(0.12, 0.53), Vector2(0.34, 0.81),
			Vector2(0.67, 0.94), Vector2(0.89, 0.59), Vector2(1, 0.13)]},
	{"hub": Vector2(0.14, 0.15), "closed": false,
		"anchors": [Vector2(0.02, 0.77), Vector2(0.28, 0.98), Vector2(0.58, 0.73),
			Vector2(0.92, 0.47), Vector2(1, 0.02)]},
	{"hub": Vector2(0.47, 0.46), "closed": true,
		"anchors": [Vector2(0.1, 0.14), Vector2(0.54, 0), Vector2(0.94, 0.18),
			Vector2(0.98, 0.66), Vector2(0.65, 0.98), Vector2(0.22, 0.88), Vector2(0, 0.51)]},
	{"hub": Vector2(0.36, 0.24), "closed": true,
		"anchors": [Vector2(0, 0.12), Vector2(0.45, 0), Vector2(0.98, 0.19),
			Vector2(0.84, 0.69), Vector2(0.48, 1), Vector2(0.12, 0.75)]},
]
static var _textures: Dictionary = {}


static func draw_web(canvas: Node2D, origin := Vector2.ZERO, small := false, shape := Shape.DRAPED) -> void:
	var key := Vector2i(posmod(shape, PROFILES.size()), int(small))
	if not _textures.has(key):
		_textures[key] = _make_texture(small, key.x)
	var texture: Texture2D = _textures[key]
	canvas.draw_texture_rect(texture, Rect2(origin, texture.get_size() * PIXEL), false)


static func spider_anchor(shape: int) -> Vector2:
	var profile: Dictionary = PROFILES[posmod(shape, PROFILES.size())]
	var lowest := Vector2.ZERO
	for anchor: Vector2 in profile.anchors:
		if anchor.y > lowest.y:
			lowest = anchor
	return (lowest * 48 * PIXEL).snapped(Vector2.ONE * PIXEL)


static func _make_texture(small: bool, shape: int) -> ImageTexture:
	var extent := 28 if small else 48
	var image := Image.create(extent + 3, extent + 3, false, Image.FORMAT_RGBA8)
	var profile: Dictionary = PROFILES[shape]
	var hub: Vector2 = profile.hub * extent
	var anchors: Array = profile.anchors
	var pixels: Dictionary = {}
	for anchor: Vector2 in anchors:
		_raster_line(pixels, hub, anchor * extent)
	for ring in [0.22, 0.46, 0.72, 1.0]:
		var segments := anchors.size() if profile.closed else anchors.size() - 1
		for i in range(segments):
			# Tears interrupt several rings; the surviving spokes become loose ends.
			if shape == Shape.TORN and ((ring >= 0.72 and i in [2, 3]) or (ring == 0.46 and i == 3)):
				continue
			if ring == 1.0 and i == 1 and shape != Shape.ORB:
				continue
			var start := hub.lerp(anchors[i] * extent, ring)
			var end := hub.lerp(anchors[(i + 1) % anchors.size()] * extent, ring)
			var control := hub + ((start + end) / 2.0 - hub) * 0.76
			var previous := start
			for step in range(1, 9):
				var t := step / 8.0
				var point := start.lerp(control, t).lerp(control.lerp(end, t), t)
				_raster_line(pixels, previous, point)
				previous = point
	# Brown shadows and dusty linen shades belong to the aged wood palette.
	for pixel: Vector2i in pixels:
		image.set_pixelv(pixel + Vector2i.ONE, Color(0.13, 0.1, 0.08, 0.2))
	for pixel: Vector2i in pixels:
		var grain := posmod(pixel.x * 13 + pixel.y * 7, 11)
		var color := Color(0.57, 0.53, 0.44, 0.38)
		if grain < 3:
			color = Color(0.68, 0.63, 0.52, 0.44)
		elif grain > 8:
			color = Color(0.43, 0.4, 0.34, 0.28)
		image.set_pixelv(pixel, color)
	return ImageTexture.create_from_image(image)


static func _raster_line(pixels: Dictionary, start: Vector2, end: Vector2) -> void:
	var p := Vector2i(start.round())
	var target := Vector2i(end.round())
	var dx := absi(target.x - p.x)
	var dy := -absi(target.y - p.y)
	var sx := 1 if p.x < target.x else -1
	var sy := 1 if p.y < target.y else -1
	var error := dx + dy
	while true:
		pixels[p] = true
		if p == target:
			break
		var doubled := error * 2
		if doubled >= dy:
			error += dy
			p.x += sx
		if doubled <= dx:
			error += dx
			p.y += sy


static func draw_thread(canvas: Node2D, start: Vector2, end: Vector2, color: Color) -> void:
	var pixels: Dictionary = {}
	_raster_line(pixels, start / PIXEL, end / PIXEL)
	for pixel: Vector2i in pixels:
		canvas.draw_rect(Rect2(Vector2(pixel) * PIXEL, Vector2.ONE * PIXEL), color)
