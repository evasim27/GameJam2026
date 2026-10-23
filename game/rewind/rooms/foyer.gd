extends Room
## The Last House: the foyer. The tutorial for Play, Pause and Rewind.
## The first pumpkin always catches the kid on the first play (a planned lesson). Rewinding the
## house about 1.5-2 s makes it bite too early. The second pumpkin is faster, has no marked window
## and holds the Maja 1989 candy between its teeth.

const WALL := preload("res://assets/rewind/wall.png")
const WAINSCOT := preload("res://assets/rewind/wainscot.png")
const FLOOR_TEX := preload("res://assets/rewind/floor.png")
const CLOCK := preload("res://assets/noble_interior/clock_tall.png")
const TABLE := preload("res://assets/noble_interior/table_side.png")
const CABINET := preload("res://assets/noble_interior/cabinet_tall.png")

const WARM := Color(0.8, 0.72, 0.88)


func build() -> void:
	title = "THE LAST HOUSE"
	tape_budget = 18.0
	timeline_length = 24.0
	free_first_rewind = true

	add_tiled(WALL, Rect2(0, 0, WIDTH, 104), Color(0.42, 0.3, 0.46))  # faded wallpaper
	add_tiled(WAINSCOT, Rect2(0, 104, WIDTH, 32), Color(0.62, 0.45, 0.45))
	add_tiled(FLOOR_TEX, Rect2(0, FLOOR, WIDTH, 44), Color(0.8, 0.66, 0.72))
	add_drawing(_entrance_door, Vector2(0, FLOOR))
	add_drawing(_coat_rack, Vector2(44, FLOOR))
	add_furniture(CLOCK, 140, WARM)
	add_furniture(TABLE, 168, WARM)
	add_furniture(CABINET, 262, WARM)
	add_drawing(_candle, Vector2(160, FLOOR - 21))
	add_drawing(_candle, Vector2(176, FLOOR - 21))
	add_drawing(_candle, Vector2(258, FLOOR - 31))
	add_text("31/10", Vector2(178, 28), Color(0.95, 0.95, 0.95))

	add_object(_pumpkin(4.0, 2.8, 4.0, true, 1.0, Color.WHITE), 100)
	add_object(_pumpkin(2.2, 0.0, 1.0, false, 1.5, Color(1.0, 0.82, 0.62)), 210)
	var maja := Candy.new()
	maja.candy_name = "Maja 1989"
	maja.period = 2.2
	maja.from = 1.35
	maja.to = 1.6
	maja.lift = 9.0
	add_object(maja, 218)
	add_object(Door.new(), 296)


func idle_hint_target(_run: RoomRun) -> float:
	return 304.0


func _pumpkin(period: float, from: float, to: float, marks: bool, size: float, tint: Color) -> Pumpkin:
	var p := Pumpkin.new()
	p.period = period
	p.bite_from = from
	p.bite_to = to
	p.show_marks = marks
	p.size = size
	p.tint = tint
	return p


func _entrance_door(d: Node2D) -> void:
	d.draw_rect(Rect2(-2, -36, 14, 36), Color(0.14, 0.08, 0.07))
	d.draw_rect(Rect2(0, -34, 10, 34), Color(0.3, 0.17, 0.12))
	d.draw_rect(Rect2(7, -18, 2, 2), Color(1.0, 0.7, 0.3))


## Old children's costumes on hooks. One more hangs there after the second failure.
func _coat_rack(d: Node2D) -> void:
	var wood := Color(0.28, 0.16, 0.1)
	d.draw_rect(Rect2(-1, -50, 2, 50), wood)
	d.draw_rect(Rect2(-6, -2, 12, 2), wood)
	d.draw_rect(Rect2(-12, -48, 24, 2), wood)
	var costumes := [Color(0.35, 0.2, 0.5), Color(0.85, 0.85, 0.82), Color(0.85, 0.45, 0.15)]
	if total_fails >= 2:
		costumes.append(Color(0.45, 0.6, 0.35))
	for i in costumes.size():
		var x := -12.0 + i * 24.0 / maxf(costumes.size() - 1, 1)
		var c: Color = costumes[i] * Color(0.7, 0.65, 0.75)
		d.draw_colored_polygon(PackedVector2Array([
			Vector2(x - 2, -46), Vector2(x + 2, -46), Vector2(x + 5, -24), Vector2(x - 5, -24)]), c)


func _candle(d: Node2D) -> void:
	d.draw_rect(Rect2(-1, -6, 2, 6), Color(0.95, 0.92, 0.85))
	var f := 0.8 + 0.2 * sin(d.t * 13.0) * sin(d.t * 7.3)
	for i in 3:
		d.draw_circle(Vector2(0, -8), (12.0 - i * 4.0) * f, Color(1.0, 0.65, 0.25, 0.05 + i * 0.04))
	d.draw_rect(Rect2(-1, -9, 2, 2), Color(1.0, 0.8, 0.3))
