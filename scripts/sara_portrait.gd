@tool
extends Control

@export var terminal_font: Font
@export_enum("happy", "angry", "sad") var expression := "happy"

var mode := "idle"
var elapsed := 0.0
const GREEN := Color(0.45, 1.0, 0.58)
const DIM := Color(0.12, 0.4, 0.22)

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var factor := minf(size.x / 240.0, size.y / 300.0)
	if factor <= 0.0 or terminal_font == null:
		return
	draw_set_transform((size - Vector2(240, 300) * factor) / 2.0, 0.0, Vector2.ONE * factor)
	draw_rect(Rect2(8, 8, 224, 284), Color(0.012, 0.035, 0.022, 0.95))
	draw_rect(Rect2(8, 8, 224, 284), DIM, false, 1.0)
	draw_string(terminal_font, Vector2(24, 41), "S.A.R.A.", HORIZONTAL_ALIGNMENT_CENTER, 192, 23, GREEN)
	draw_line(Vector2(24, 56), Vector2(216, 56), DIM)
	var outline := PackedVector2Array([
		Vector2(60, 82), Vector2(180, 82), Vector2(180, 94), Vector2(192, 94),
		Vector2(192, 190), Vector2(180, 190), Vector2(180, 202), Vector2(60, 202),
		Vector2(60, 190), Vector2(48, 190), Vector2(48, 94), Vector2(60, 94), Vector2(60, 82)
	])
	draw_colored_polygon(outline, Color(0.025, 0.09, 0.045))
	draw_polyline(outline, GREEN, 2.0)
	var blinking := fmod(elapsed, 4.5) > 4.3
	var gaze := 3.0 * sin(elapsed * 2.0) if mode == "thinking" else 0.0
	for x in [80.0, 144.0]:
		if blinking:
			draw_rect(Rect2(x, 130, 16, 3), GREEN)
		elif mode == "thinking":
			draw_rect(Rect2(x + gaze, 123, 12, 15), GREEN)
		elif expression == "happy":
			draw_polyline(PackedVector2Array([Vector2(x, 134), Vector2(x, 126), Vector2(x + 4, 122), Vector2(x + 12, 122), Vector2(x + 16, 126), Vector2(x + 16, 134)]), GREEN, 3.0)
		else:
			draw_rect(Rect2(x, 130, 16, 9 if expression == "angry" else 7), GREEN)
	if mode == "thinking":
		draw_line(Vector2(76, 110), Vector2(100, 105), GREEN, 3.0)
		draw_line(Vector2(140, 112), Vector2(164, 112), GREEN, 3.0)
	elif expression == "angry":
		draw_line(Vector2(76, 111), Vector2(100, 123), GREEN, 3.0)
		draw_line(Vector2(140, 123), Vector2(164, 111), GREEN, 3.0)
	elif expression == "sad":
		draw_line(Vector2(76, 121), Vector2(100, 111), GREEN, 3.0)
		draw_line(Vector2(140, 111), Vector2(164, 121), GREEN, 3.0)
		draw_rect(Rect2(92, 146, 4, 8), GREEN)
	if mode == "speaking" and int(elapsed * 8.0) % 2 == 0:
		var mouth_width := 16.0 if expression == "sad" else 30.0
		draw_rect(Rect2(120 - mouth_width / 2, 164, mouth_width, 12), GREEN, false, 3.0)
	elif mode == "thinking":
		for index in range(3):
			draw_rect(Rect2(108 + index * 9, 169, 3, 3), GREEN)
	elif expression == "happy":
		draw_polyline(PackedVector2Array([Vector2(102, 161), Vector2(102, 167), Vector2(110, 175), Vector2(130, 175), Vector2(138, 167), Vector2(138, 161)]), GREEN, 3.0)
	elif expression == "sad":
		draw_polyline(PackedVector2Array([Vector2(104, 179), Vector2(112, 171), Vector2(128, 171), Vector2(136, 179)]), GREEN, 3.0)
	else:
		draw_line(Vector2(104, 174), Vector2(136, 174), GREEN, 3.0)
	var caption := "ONLINE"
	if mode == "thinking":
		caption = "PROCESSANDO"
	elif mode == "speaking":
		caption = "TRANSMITINDO"
	draw_string(terminal_font, Vector2(24, 248), caption, HORIZONTAL_ALIGNMENT_CENTER, 192, 16, GREEN)
	for index in range(3):
		var lit := mode != "thinking" or int(elapsed * 3.0) % 3 == index
		draw_rect(Rect2(99 + index * 18, 266, 6, 6), GREEN if lit else DIM)
