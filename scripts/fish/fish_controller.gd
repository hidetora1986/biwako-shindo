class_name FishController
extends Node2D
## Visual swimming only; no fishing interactions.

enum SwimState { SWIM, TURN }

@export_enum("bluegill", "bass", "minnow") var placeholder_kind: String = "bluegill"
@export var fish_art: SpriteFrames
@export_range(1.0, 80.0) var swim_speed: float = 18.0
@export_enum("Left:-1", "Right:1") var swim_direction: int = 1
@export_range(0.0, 150.0, 0.1, "or_greater") var depth_position: float = 5.0
@export var variation_seed: int = 1

@onready var sprite: AnimatedSprite2D = $Sprite

var state: SwimState = SwimState.SWIM
var water_bounds := Rect2()
var _depth_m: float = 15.0
var _rng := RandomNumberGenerator.new()
var _variation_timer: float = 0.0
var _speed_factor: float = 1.0
var _target_speed_factor: float = 1.0
var _time: float = 0.0
var _base_y: float = 0.0
var _half_width: float = 20.0
var _half_height: float = 11.0

func _ready() -> void:
	_rng.seed = variation_seed
	swim_direction = -1 if swim_direction < 0 else 1
	sprite.sprite_frames = fish_art if fish_art != null else PlaceholderArt.fish_frames(placeholder_kind)
	sprite.play("swim")
	sprite.speed_scale = clampf(swim_speed / 18.0, 0.7, 1.8)
	var frame_size := sprite.sprite_frames.get_frame_texture("swim", 0).get_size()
	_half_width = frame_size.x * 0.5
	_half_height = frame_size.y * 0.5
	_update_facing()

func configure_water(bounds: Rect2, depth_m: float) -> void:
	water_bounds = bounds
	_depth_m = maxf(depth_m, 0.1)
	depth_position = clampf(depth_position, 0.0, _depth_m)
	var top := bounds.position.y + _half_height + 1.2
	var bottom := bounds.end.y - _half_height - 1.2
	_base_y = lerpf(top, bottom, depth_position / _depth_m)
	position.y = _base_y
	position.x = clampf(position.x, bounds.position.x + _half_width, bounds.end.x - _half_width)

func _physics_process(delta: float) -> void:
	if water_bounds.size.x <= _half_width * 2.0:
		return
	_time += delta
	_variation_timer -= delta
	if _variation_timer <= 0.0:
		_target_speed_factor = _rng.randf_range(0.82, 1.18)
		_variation_timer = _rng.randf_range(0.8, 2.6)
	_speed_factor = move_toward(_speed_factor, _target_speed_factor, delta * 0.25)
	position.x += swim_speed * _speed_factor * swim_direction * delta
	var left := water_bounds.position.x + _half_width
	var right := water_bounds.end.x - _half_width
	state = SwimState.SWIM
	if position.x <= left:
		position.x = left
		swim_direction = 1
		state = SwimState.TURN
	elif position.x >= right:
		position.x = right
		swim_direction = -1
		state = SwimState.TURN
	position.y = _base_y + sin(_time * 1.3 + variation_seed) * 1.2
	_update_facing()

func _update_facing() -> void:
	sprite.flip_h = swim_direction < 0
