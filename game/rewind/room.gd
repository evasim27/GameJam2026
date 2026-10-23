class_name Room
extends Node2D
## One room of the house. Subclasses lay out decor and tape objects in `build()`.
## Coordinates are in level pixels: the room is 320x180 and the floor is at y = 136.

const WIDTH := 320.0
const FLOOR := 136.0
const KidScene := preload("res://rewind/kid.gd")
const EchoScene := preload("res://rewind/echo.gd")

var title := ""
## Rooms wider than the screen scroll with the kid.
var width := WIDTH
var tape_budget := 20.0
var timeline_length := 30.0
var start_x := 16.0
var free_first_rewind := false
## Glitch (E) unlocks once the kid passes this x; 0 means it is available from the start.
var glitch_from_x := 0.0
var objects: Array[TapeObject] = []

## Set by the game before build(): how often the player failed here and in total.
var fails := 0
var total_fails := 0

var kid: Node2D
var echo: Node2D
var _deco: Node2D
var _obj: Node2D


func setup(room_fails: int, all_fails: int) -> void:
	fails = room_fails
	total_fails = all_fails
	_deco = Node2D.new()
	add_child(_deco)
	_obj = Node2D.new()
	add_child(_obj)
	build()
	echo = EchoScene.new()
	echo.visible = false
	add_child(echo)
	kid = KidScene.new()
	add_child(kid)
	for o in objects:
		if o is GlitchSpot:
			o.strength = minf(fails * 0.5, 1.5)


func build() -> void:
	pass


func floor_y(_x: float) -> float:
	return FLOOR


## Text shown once when the kid first passes x, e.g. a tutorial hint. [{x, text}]
func trigger_hints() -> Array:
	return []


## Hint shown when this attempt starts, based on how often the player failed here.
func retry_hint() -> String:
	return ""


## Where the echo points after a failure, if no object caused it (tape ran out, kid blocked):
## the next thing blocking the kid, or the way out.
func idle_hint_target(run: RoomRun) -> float:
	for o in objects:
		if o.blocks(run) and o.position.x > run.kid_x:
			return o.position.x
	return width - 24.0


func show_run(run: RoomRun) -> void:
	for o in objects:
		o.show_time(run)


# --- building helpers -------------------------------------------------------

func add_object(o: TapeObject, x: float, y := FLOOR) -> TapeObject:
	o.position = Vector2(x, y)
	o.room = self
	_obj.add_child(o)
	objects.append(o)
	return o


## Tiles a 32x32 house texture over `rect` at half scale (16 level px per tile).
func add_tiled(tex: Texture2D, rect: Rect2, tint: Color) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	r.stretch_mode = TextureRect.STRETCH_TILE
	r.position = rect.position
	r.size = rect.size * 2.0
	r.scale = Vector2(0.5, 0.5)
	r.modulate = tint
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_deco.add_child(r)
	return r


## Places a 64x64 Noble Interior sprite at half scale, standing on (x, y).
func add_furniture(tex: Texture2D, x: float, tint: Color, y := FLOOR, flip := false) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.scale = Vector2(0.5, 0.5)
	s.offset = Vector2(0, -32)
	s.position = Vector2(x, y)
	s.modulate = tint
	s.flip_h = flip
	_deco.add_child(s)
	return s


func add_rect(rect: Rect2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = rect.position
	r.size = rect.size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_deco.add_child(r)
	return r


## Small crisp wall text: a 16 px font drawn at half scale.
func add_text(text: String, pos: Vector2, color: Color, font_size := 16) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.scale = Vector2(0.5, 0.5)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	_deco.add_child(l)
	return l


func add_drawing(draw: Callable, pos := Vector2.ZERO, z := 0) -> Node2D:
	var d := Drawing.new()
	d.draw_fn = draw
	d.position = pos
	d.z_index = z
	_deco.add_child(d)
	return d


## A node that draws with a callable and redraws every frame (for flicker and static).
class Drawing:
	extends Node2D
	var draw_fn: Callable
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		draw_fn.call(self)
