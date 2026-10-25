extends RefCounted
## Shared, resolution-independent dialogue cards for the tape and its on-screen voices.

static func wrap(font: Font, text: String, width: float, font_size: int) -> Array[String]:
	var lines: Array[String] = []
	for paragraph in text.split("\n"):
		var line := ""
		for word in paragraph.split(" ", false):
			var candidate: String = word if line.is_empty() else line + " " + word
			if not line.is_empty() and font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size * 2).x / 2.0 > width:
				lines.append(line)
				line = word
			else:
				line = candidate
		lines.append(line)
	return lines


static func height(line_count: int, font_size: int, has_speaker := true) -> float:
	return (8.0 + (10.0 if has_speaker else 0.0) + line_count * 13.0) * font_size / 12.0


static func width(font: Font, lines: Array, font_size: int, max_width: float) -> float:
	var text_width := 0.0
	for line: String in lines:
		text_width = maxf(text_width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size * 2).x / 2.0)
	return minf(max_width, maxf(80.0, text_width + 14.0 * font_size / 12.0))


static func draw_lines(canvas: CanvasItem, font: Font, lines: Array, speaker: String, rect: Rect2, accent: Color, font_size := 12, shown: Array = [], tail := false) -> void:
	var unit := font_size / 12.0
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.035, 0.025, 0.065, 0.58)
	panel.border_color = Color(accent, 0.45)
	panel.set_border_width_all(maxi(1, int(unit)))
	panel.set_corner_radius_all(int(3 * unit))
	panel.shadow_color = Color(0, 0, 0, 0.2)
	panel.shadow_size = int(2 * unit)
	panel.shadow_offset = Vector2(0, unit)
	canvas.draw_style_box(panel, rect)
	var inset := Vector2(7, 4) * unit
	var header_height := 0.0 if speaker.is_empty() else 10.0
	canvas.draw_rect(Rect2(rect.position + Vector2(0, 4) * unit, Vector2(1, rect.size.y / unit - 8) * unit), Color(accent, 0.75))
	if not speaker.is_empty():
		text(canvas, font, speaker, rect.position + inset + Vector2(0, 6 * unit), maxi(8, int(font_size * 0.75)), accent)
	for i in lines.size():
		var line: String = lines[i] if shown.is_empty() else shown[i]
		text(canvas, font, line, rect.position + inset + Vector2(0, (10 + header_height + i * 13) * unit), font_size, Color(0.95, 0.95, 1.0))
	if tail:
		var p := Vector2(rect.end.x - 25 * unit, rect.end.y)
		canvas.draw_colored_polygon(PackedVector2Array([p, p + Vector2(8, 0) * unit, p + Vector2(4, 5) * unit]), panel.bg_color)
		canvas.draw_polyline(PackedVector2Array([p, p + Vector2(4, 5) * unit, p + Vector2(8, 0) * unit]), Color(accent, 0.45), unit)


static func text(canvas: CanvasItem, font: Font, value: String, pos: Vector2, font_size: int, color: Color) -> void:
	canvas.draw_set_transform(pos, 0.0, Vector2(0.5, 0.5))
	canvas.draw_string(font, Vector2.ZERO, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size * 2, color)
	canvas.draw_set_transform(Vector2.ZERO)


## Shared tape-overlay frame: smoked glass, clipped corners and worn scan lines.
static func draw_tape_panel(canvas: CanvasItem, rect: Rect2, font_size := 12) -> void:
	var unit := font_size / 12.0
	var background := Color(0.025, 0.025, 0.03, 0.48)
	var edge := Color(0.77, 0.79, 0.73, 0.38)
	var cut := 3.0 * unit
	var p := rect.position
	var q := rect.end
	var outline := PackedVector2Array([Vector2(p.x + cut, p.y), Vector2(q.x - cut, p.y), Vector2(q.x, p.y + cut), Vector2(q.x, q.y - cut), Vector2(q.x - cut, q.y), Vector2(p.x + cut, q.y), Vector2(p.x, q.y - cut), Vector2(p.x, p.y + cut)])
	canvas.draw_colored_polygon(outline, background)
	outline.append(outline[0])
	canvas.draw_polyline(outline, edge, 1.0)
	for i in range(1, int(rect.size.y / (3 * unit))):
		var y := p.y + i * 3 * unit
		canvas.draw_line(Vector2(p.x + cut, y), Vector2(q.x - cut, y), Color(0.8, 0.81, 0.76, 0.025))


## The recorder's faint overlay, shared by status fields and instructions.
static func draw_osd_panel(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_rect(rect, Color(0.025, 0.025, 0.03, 0.18))
	for p: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		var inward := (rect.get_center() - p).sign()
		canvas.draw_line(p, p + Vector2(inward.x * 7, 0), Color(0.85, 0.86, 0.82, 0.14))
		canvas.draw_line(p, p + Vector2(0, inward.y * 5), Color(0.85, 0.86, 0.82, 0.14))


## Instructions look like recorder OSD text rather than a dialogue card.
static func draw_instruction(canvas: CanvasItem, font: Font, lines: Array, rect: Rect2, font_size := 12) -> void:
	var unit := font_size / 12.0
	draw_osd_panel(canvas, rect)
	for i in lines.size():
		text(canvas, font, lines[i], rect.position + Vector2(7, 14 + i * 13) * unit, font_size, Color(0.91, 0.92, 0.88, 0.86))


## A worn VHS caption with clipped corners, faint scan lines and a pointer to the speaker.
static func draw_speech(canvas: CanvasItem, font: Font, lines: Array, speaker: String, rect: Rect2, accent: Color, font_size: int, tip := Vector2.INF) -> void:
	var unit := font_size / 12.0
	var background := Color(0.025, 0.025, 0.03, 0.48)
	var edge := Color(0.77, 0.79, 0.73, 0.38)
	var p := rect.position
	draw_tape_panel(canvas, rect, font_size)
	if tip.is_finite():
		var base_x := clampf(tip.x, rect.position.x + 12, rect.end.x - 12)
		var left := Vector2(base_x - 5, rect.end.y - 1)
		var right := Vector2(base_x + 5, rect.end.y - 1)
		canvas.draw_colored_polygon(PackedVector2Array([left, tip, right]), background)
		canvas.draw_polyline(PackedVector2Array([left, tip, right]), edge, 1.0)
	var label_ink := Color(accent.lerp(Color(0.84, 0.83, 0.74), 0.8), 0.84)
	var cassette := Rect2(p + Vector2(7, 4) * unit, Vector2(11, 6) * unit)
	canvas.draw_rect(cassette, Color(label_ink, 0.55), false, 1.0)
	canvas.draw_circle(cassette.position + Vector2(3, 3) * unit, unit, label_ink)
	canvas.draw_circle(cassette.position + Vector2(8, 3) * unit, unit, label_ink)
	text(canvas, font, speaker, rect.position + Vector2(22, 10) * unit, maxi(8, int(font_size * 0.7)), label_ink)
	for i in lines.size():
		text(canvas, font, lines[i], rect.position + Vector2(7, 24 + i * 13) * unit, font_size, Color(0.93, 0.97, 0.96))
