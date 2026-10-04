extends Node2D

@export var boat_art: Texture2D
@export_range(2.0, 4.0) var bob_amplitude: float = 3.0
@export_range(2.0, 3.0) var bob_period: float = 2.5

var anchor_position := Vector2.ZERO
var _time: float = 0.0

func _ready() -> void:
	$Sprite.texture = boat_art if boat_art != null else PlaceholderArt.boat_texture()

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
	return position + Vector2(-40, -40)
