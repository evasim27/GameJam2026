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
