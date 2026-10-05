extends Node2D

@export var boat_art: Texture2D
@export_range(2.0, 4.0) var bob_amplitude: float = 3.0
@export_range(2.0, 3.0) var bob_period: float = 2.5

var anchor_position := Vector2.ZERO
var _time: float = 0.0
var _tension: float = 0.0
var _fighting: bool = false

func _ready() -> void:
	$Sprite.texture = boat_art if boat_art != null else RefinedPixelArt.boat_texture()
	if boat_art == null:
		$Sprite.offset = Vector2(0, -29)

func set_anchor(value: Vector2) -> void:
	anchor_position = value
	_refresh_position()

func _physics_process(delta: float) -> void:
	_time += delta
	_refresh_position()

func _refresh_position() -> void:
	position = anchor_position + Vector2(0.0, sin(_time * TAU / bob_period) * bob_amplitude)

func rod_tip_position() -> Vector2:
	# Tip of the Phase 1 placeholder rod, relative to the boat anchor.
	return position + Vector2(-40 + _tension * 0.025, -40 + _tension * 0.065)

func set_line_pull(tension: float, fighting: bool) -> void:
	_tension = tension if fighting else 0.0
	_fighting = fighting
	queue_redraw()

func _draw() -> void:
	if boat_art != null:
		return
	# Quiet contact wake and broken hull reflection; visual coordinates only.
	for i in range(4):
		var drift := floorf(sin(_time * 1.4 + i) * 2.0)
		draw_rect(Rect2(-62 + i * 9 + drift, 3 + i * 3, 110 - i * 22, 1), Color(0.68, 0.85, 0.79, 0.24 - i * 0.04))
		draw_rect(Rect2(-48 + drift, 5 + i * 3, 65 - i * 14, 2), Color(0.22, 0.42, 0.46, 0.16 - i * 0.025))
	# Same original rod pixels at rest, bent progressively under line pull.
	for x in range(15, 45):
		var bend := pow(1.0 - float(x - 15) / 29.0, 2.0)
		var pixel := Vector2(x - 55, 5 + int(float(x - 15) * 0.57) - 45) + Vector2(_tension * 0.025, _tension * 0.065) * bend
		draw_rect(Rect2(pixel.round(), Vector2.ONE), Color("344e4e"))
