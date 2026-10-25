extends Node2D
## A deliberately out-of-place Saw cameo on an unlisted cassette.

signal finished

const HOST := preload("res://assets/forbidden/billy_tv_still.jpg")
const FONT := preload("res://assets/fonts/VT323-Regular.ttf")
const DialogueBox := preload("res://rewind/dialogue_box.gd")
const VOICE := preload("res://assets/audio/jigsaw_voice.mp3")
const VOICE_START := 0.7
const END_PAUSE := 0.6
const LINES := [
	{"at": VOICE_START, "text": "Hello. I want to play a game."},
	{"at": VOICE_START + 3.4, "text": "Wait. This isn't my tape."},
	{"at": VOICE_START + 6.5, "text": "Oh no. Wrong game. Sorry."},
]

var _t := 0.0
var _line := ""
var _next_line := 0
var _voice: AudioStreamPlayer
var _voice_started := false
var _duration := 0.0


func _ready() -> void:
	_voice = AudioStreamPlayer.new()
	_voice.stream = VOICE
	_voice.volume_db = 3.0
	_duration = VOICE_START + VOICE.get_length() + END_PAUSE
	add_child(_voice)


func skip() -> void:
	_voice.stop()
	finished.emit()


func _process(delta: float) -> void:
	_t += delta
	if not _voice_started and _t >= VOICE_START:
		_voice_started = true
		_voice.play()
	while _next_line < LINES.size() and _t >= LINES[_next_line].at:
		var entry: Dictionary = LINES[_next_line]
		_line = entry.text
		_next_line += 1
	if _t >= _duration and not _voice.playing:
		finished.emit()
	else:
		queue_redraw()


func _draw() -> void:
	draw_texture_rect(HOST, Rect2(0, 0, 320, 180), false)
	var interference := 0.0
	if _t < 0.6 or (_t > 6.8 and _t < 7.2) or _t > _duration - 0.6:
		interference = 0.5
	for i in 7:
		var y := fposmod(float(i * 29) + _t * 43.0, 180.0)
		draw_rect(Rect2(0, y, 320, 1), Color(0.47, 0.89, 0.97, 0.07 + interference * 0.13))
	if _line != "":
		var lines := DialogueBox.wrap(FONT, _line, 282, 13)
		var h := DialogueBox.height(lines.size(), 13)
		var box_width := DialogueBox.width(FONT, lines, 13, 300.0)
		DialogueBox.draw_lines(self, FONT, lines, "JIGSAW", Rect2((320 - box_width) / 2.0, 172 - h, box_width, h), Color(0.98, 0.48, 0.40), 13)
	draw_string(FONT, Vector2(274, 16), "SPACE  >>", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.75, 0.91, 0.94))
