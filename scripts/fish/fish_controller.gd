class_name FishController
extends Node2D
## Default swimming is unchanged; one nearby fish may be reserved by fishing flow.

enum SwimState { SWIM, TURN, APPROACH_LURE, BITE, HOOKED, FIGHTING, RUN, LANDING }

@export_enum("bluegill", "bass", "minnow") var placeholder_kind: String = "bluegill"
@export var fish_art: SpriteFrames
@export var fight_profile: FishFightProfile = preload("res://data/fish/bluegill-fight.tres")
@export_range(1.0, 80.0) var swim_speed: float = 18.0
@export_enum("Left:-1", "Right:1") var swim_direction: int = 1
@export_range(0.0, 150.0, 0.1, "or_greater") var depth_position: float = 5.0
@export var variation_seed: int = 1
@export_range(10.0, 300.0) var bite_detection_radius: float = 130.0
@export_range(0.0, 1.0) var bite_probability: float = 0.65
@export_range(20.0, 140.0) var approach_speed: float = 72.0

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
var stamina: float = 20.0
var size_cm: float = 0.0
var _home_fraction: float = -1.0
var _home_depth: float = 0.0
var _lure: Node2D
var _interest_cooldown: float = 0.0
var _flee_remaining: float = 0.0

func _ready() -> void:
	_rng.seed = variation_seed
	stamina = fight_profile.max_stamina
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
	_base_y = clampf(bounds.position.y - 4.0 + depth_position / _depth_m * (bounds.size.y - 4.0), bounds.position.y + _half_height + 1.2, bounds.end.y - _half_height - 1.2)
	position.y = _base_y
	position.x = clampf(position.x, bounds.position.x + _half_width, bounds.end.x - _half_width)
	if _home_fraction < 0.0:
		_home_fraction = (position.x - bounds.position.x) / bounds.size.x
		_home_depth = depth_position

func _physics_process(delta: float) -> void:
	if water_bounds.size.x <= _half_width * 2.0:
		return
	_interest_cooldown = maxf(0.0, _interest_cooldown - delta)
	_flee_remaining = maxf(0.0, _flee_remaining - delta)
	if state in [SwimState.HOOKED, SwimState.FIGHTING, SwimState.RUN, SwimState.LANDING]:
		return
	if state in [SwimState.APPROACH_LURE, SwimState.BITE]:
		_follow_lure(delta)
		return
	_time += delta
	_variation_timer -= delta
	if _variation_timer <= 0.0:
		_target_speed_factor = _rng.randf_range(0.82, 1.18)
		_variation_timer = _rng.randf_range(0.8, 2.6)
	_speed_factor = move_toward(_speed_factor, _target_speed_factor, delta * 0.25)
	position.x += swim_speed * _speed_factor * (1.5 if _flee_remaining > 0.0 else 1.0) * swim_direction * delta
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

func can_detect_lure() -> bool:
	return state in [SwimState.SWIM, SwimState.TURN] and _interest_cooldown <= 0.0

func approach_lure(lure: Node2D) -> bool:
	if not can_detect_lure():
		return false
	_lure = lure
	state = SwimState.APPROACH_LURE
	return true

func _follow_lure(delta: float) -> void:
	if not is_instance_valid(_lure):
		release_lure(false)
		return
	var dx := _lure.position.x - position.x
	if absf(dx) > 2.0:
		swim_direction = 1 if dx > 0.0 else -1
	var target := _lure.position - Vector2(swim_direction * (_half_width - 6.0), 0)
	target.x = clampf(target.x, water_bounds.position.x + _half_width, water_bounds.end.x - _half_width)
	target.y = clampf(target.y, water_bounds.position.y + _half_height + 1.2, water_bounds.end.y - _half_height - 1.2)
	position = position.move_toward(target, (approach_speed + swim_speed * 0.35) * delta)
	depth_position = _depth_at_y(position.y)
	_update_facing()

func begin_bite() -> void:
	state = SwimState.BITE

func hook() -> void:
	state = SwimState.HOOKED

func release_lure(missed: bool) -> void:
	if missed and is_instance_valid(_lure):
		swim_direction = -1 if _lure.position.x >= position.x else 1
		_flee_remaining = 1.5
	_lure = null
	state = SwimState.SWIM
	_interest_cooldown = 4.0 if missed else 1.0
	_base_y = clampf(position.y, water_bounds.position.y + _half_height + 1.2, water_bounds.end.y - _half_height - 1.2)
	depth_position = _depth_at_y(_base_y)
	_update_facing()

func _depth_at_y(y: float) -> float:
	return clampf((y - water_bounds.position.y + 4.0) / maxf(water_bounds.size.y - 4.0, 1.0) * _depth_m, 0.0, _depth_m)

func prepare_catch_size(rng: RandomNumberGenerator) -> void:
	if size_cm <= 0.0:
		size_cm = snappedf(rng.randf_range(fight_profile.size_min_cm, fight_profile.size_max_cm), 0.1)
	stamina = fight_profile.max_stamina

func set_fight_pose(value: Vector2, resistance: int) -> void:
	state = SwimState.RUN if resistance == FishingFight.Resistance.RUN else SwimState.FIGHTING
	position = value
	depth_position = _depth_at_y(position.y)
	swim_direction = -1 if resistance == FishingFight.Resistance.RUN else 1
	sprite.speed_scale = 1.8 if resistance == FishingFight.Resistance.RUN else 0.8
	_update_facing()

func finish_session(caught: bool) -> void:
	release_lure(not caught)
	stamina = fight_profile.max_stamina
	sprite.modulate = Color.WHITE
	sprite.speed_scale = clampf(swim_speed / 18.0, 0.7, 1.8)
	visible = true
	if caught:
		# MVP replenishes the same placeholder node; no inventory or persistent save.
		depth_position = _home_depth
		position.x = water_bounds.position.x + _home_fraction * water_bounds.size.x
		configure_water(water_bounds, _depth_m)
		size_cm = 0.0
