extends Control
## Static decoration. Never reads fish positions or performs sonar logic.

func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("153c40"))
	draw_rect(Rect2(Vector2.ZERO, size), Color("517d77"), false, 1)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(9, 16), "SONAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("d5e2c9"))
	draw_string(font, Vector2(size.x - 29, 16), "STBY", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("83a69b"))
	for row in range(3):
		var y := 29.0 + row * 15.0
		draw_line(Vector2(9, y), Vector2(size.x - 10, y), Color("335b5d"))
		draw_string(font, Vector2(9, y - 2), ["0", "5", "15"][row], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("7fa69b"))
	for p in [Vector2(0.39, 0.48), Vector2(0.76, 0.70), Vector2(0.57, 0.84)]:
		var point: Vector2 = (p * size).floor()
		draw_rect(Rect2(point, Vector2(3, 2)), Color("c4c18c"))
