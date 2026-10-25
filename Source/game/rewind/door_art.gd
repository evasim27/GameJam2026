extends RefCounted
## Shared cutscene-style door artwork, with matching crops and a floor-aligned threshold.

const SHEET := preload("res://assets/rewind/cinematic/doors.png")
const CLOSED_REGION := Rect2(104, 90, 540, 944)
const OPEN_REGION := Rect2(762, 90, 540, 944)


static func draw_door(canvas: CanvasItem, rect: Rect2, opened := false, light := Color(1.0, 0.75, 0.4), tint := Color.WHITE) -> void:
	if light.a > 0.0:
		for i in 3:
			canvas.draw_rect(rect.grow(i + 1), Color(light, light.a * 0.012 * (3 - i)), false, 1.0)
	canvas.draw_texture_rect_region(SHEET, rect, OPEN_REGION if opened else CLOSED_REGION, tint)
	canvas.draw_rect(Rect2(rect.position + Vector2(2, rect.size.y - 1), Vector2(rect.size.x - 4, 1)), Color(light, light.a * (0.4 if opened else 0.15)))
