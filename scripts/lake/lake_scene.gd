extends Node2D

const FISH_SCENE := preload("res://scenes/fish/fish.tscn")
const FIGHT_PROFILES := [preload("res://data/fish/bluegill-fight.tres"), preload("res://data/fish/biwamasu-fight.tres"), preload("res://data/fish/bass-fight.tres"), preload("res://data/fish/crucian-fight.tres"), preload("res://data/fish/catfish-fight.tres"), preload("res://data/fish/bass-fight.tres"), preload("res://data/fish/bluegill-fight.tres")]
const DEPTH_FRACTIONS := [0.18, 0.44, 0.70, 0.31, 0.83, 0.54, 0.14]

@export var profile: LakeProfile = preload("res://data/lake/morning.tres")
@export_range(5, 10) var fish_count: int = 7
@export var spawn_seed: int = 187

var view_size := Vector2(640, 360)
var water_bounds := Rect2()
var surface_y: float = 0.0
var _previous_width: float = 0.0

func _ready() -> void:
	get_viewport().size_changed.connect(_refresh_layout)
	_refresh_layout()
	_spawn_fish()
	$FishingController.setup($Lake/Boat, $Underwater/FishContainer, $HUD/Root)

func _refresh_layout() -> void:
	layout_for_size(get_viewport_rect().size)

func layout_for_size(size: Vector2) -> void:
	view_size = size
	surface_y = floorf(size.y * profile.surface_ratio)
	water_bounds = Rect2(10, surface_y + 4, size.x - 20, size.y - surface_y - 22)
	$Background/BackgroundSky.configure(size, profile)
	$Background/BackgroundMountains.configure(size, profile)
	$Underwater/WaterBackground.configure(size, profile)
	$Lake/LakeSurface.configure(size, profile)
	$Lake/Boat.set_anchor(Vector2(floorf(size.x * 0.52), surface_y - 3))
	$HUD/Root.configure(size, surface_y, profile.displayed_depth_m)
	for fish: FishController in $Underwater/FishContainer.get_children():
		if _previous_width > 0:
			fish.position.x *= size.x / _previous_width
		fish.configure_water(water_bounds, profile.displayed_depth_m)
	$FishingController.configure_water(water_bounds, surface_y, profile.displayed_depth_m)
	_previous_width = size.x

func _spawn_fish() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = spawn_seed
	for i in range(fish_count):
		var fish: FishController = FISH_SCENE.instantiate()
		fish.name = "Fish%02d" % (i + 1)
		fish.fight_profile = FIGHT_PROFILES[i % FIGHT_PROFILES.size()]
		fish.placeholder_kind = fish.fight_profile.placeholder_kind
		match fish.placeholder_kind:
			"minnow": fish.swim_speed = rng.randf_range(28.0, 34.0)
			"bass": fish.swim_speed = rng.randf_range(11.0, 15.0)
			_: fish.swim_speed = rng.randf_range(17.0, 22.0)
		fish.swim_direction = 1 if i % 2 == 0 else -1
		fish.depth_position = clampf(DEPTH_FRACTIONS[i % DEPTH_FRACTIONS.size()] + rng.randf_range(-0.025, 0.025), 0.12, 0.88) * profile.displayed_depth_m
		fish.variation_seed = spawn_seed + i * 37
		fish.position.x = view_size.x * (0.10 + 0.80 * float(i) / maxf(1.0, fish_count - 1.0) + rng.randf_range(-0.015, 0.015))
		$Underwater/FishContainer.add_child(fish)
		fish.configure_water(water_bounds, profile.displayed_depth_m)
