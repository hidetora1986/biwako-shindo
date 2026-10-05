extends Node2D

const FISH_SCENE := preload("res://scenes/fish/fish.tscn")
const FIGHT_PROFILES := [preload("res://data/fish/bluegill-fight.tres"), preload("res://data/fish/bass-fight.tres"), preload("res://data/fish/crucian-fight.tres"), preload("res://data/fish/bass-fight.tres"), preload("res://data/fish/catfish-fight.tres"), preload("res://data/fish/biwamasu-fight.tres"), preload("res://data/fish/bluegill-fight.tres")]
const DEPTH_FRACTIONS := [0.18, 0.44, 0.70, 0.31, 0.83, 0.54, 0.14]

@export var profile: LakeProfile = preload("res://data/lake/morning.tres")
@export_range(5, 10) var fish_count: int = 7
@export var spawn_seed: int = 187

var view_size := Vector2(640, 360)
var water_bounds := Rect2()
var surface_y: float = 0.0
var depth_band: int = 0
var depth_origin_m: float = 0.0
var depth_span_m: float = 15.0
var _previous_width: float = 0.0

func _ready() -> void:
	get_viewport().size_changed.connect(_refresh_layout)
	profile = profile.duplicate()
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
	$Underwater/WaterBackground.set_depth_band(depth_origin_m, depth_span_m)
	$Lake/LakeSurface.configure(size, profile)
	$Lake/Boat.set_anchor(Vector2(floorf(size.x * 0.52), surface_y - 3))
	$HUD/Root.configure(size, surface_y, depth_span_m)
	$HUD/Root.set_area_range(depth_origin_m, depth_span_m)
	for fish: FishController in $Underwater/FishContainer.get_children():
		if _previous_width > 0:
			fish.position.x *= size.x / _previous_width
		fish.configure_water(water_bounds, depth_span_m, depth_origin_m)
	$FishingController.configure_water(water_bounds, surface_y, depth_span_m, depth_origin_m)
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
		fish.depth_position = lerpf(fish.fight_profile.min_depth, fish.fight_profile.max_depth, clampf(DEPTH_FRACTIONS[i % DEPTH_FRACTIONS.size()] + rng.randf_range(-0.025, 0.025), 0.12, 0.88))
		fish.variation_seed = spawn_seed + i * 37
		fish.position.x = view_size.x * (0.10 + 0.80 * float(i) / maxf(1.0, fish_count - 1.0) + rng.randf_range(-0.015, 0.015))
		$Underwater/FishContainer.add_child(fish)
		fish.configure_water(water_bounds, depth_span_m, depth_origin_m)

func populate_depth_band(band: int, line_depth: float, cast_number: int = 0) -> void:
	if not DepthBands.available(band, line_depth):
		return
	depth_band = band
	depth_origin_m = DepthBands.STARTS[band]
	depth_span_m = DepthBands.ENDS[band] - depth_origin_m
	var pool := DepthBands.pool(band, line_depth)
	if band == 4:
		var rng := RandomNumberGenerator.new()
		rng.seed = spawn_seed + cast_number * 1009
		# Rare at 80–85m before Lv5, with a bounded six-cast encounter opportunity.
		if rng.randf() >= 0.28 and (cast_number == 0 or cast_number % 6 != 0):
			pool = pool.filter(func(entry: FishFightProfile) -> bool: return entry.id != "No.14")
	var fishes := $Underwater/FishContainer.get_children()
	for i in range(fishes.size()):
		var fish: FishController = fishes[i]
		var entry: FishFightProfile = FIGHT_PROFILES[i % FIGHT_PROFILES.size()] if band == 0 else pool[posmod(i + cast_number, pool.size())]
		var lo := maxf(entry.min_depth, depth_origin_m)
		var hi := minf(entry.max_depth, minf(DepthBands.ENDS[band], line_depth))
		var depth := lerpf(lo, hi, 0.18 + 0.64 * float((i + cast_number) % 7) / 6)
		fish.swim_direction = 1 if i % 2 == 0 else -1
		fish.repopulate(entry, depth, view_size.x * (0.10 + 0.80 * float(i) / maxf(1, fishes.size() - 1)))
		fish.swim_speed = 10 if entry.rarity >= 5 and entry.min_depth >= 50 else (12 if entry.id == "No.06" else (29 if entry.id == "No.07" else (14 if entry.id == "No.08" else 18)))
		fish.sprite.speed_scale = clampf(fish.swim_speed / 18.0, 0.7, 1.8)
		fish.bite_detection_radius = 280 if band > 2 else (240 if band > 0 else 130)
		fish.approach_speed = 85 if entry.id in ["No.07", "No.10"] else 72
		fish.configure_water(water_bounds, depth_span_m, depth_origin_m)
	layout_for_size(view_size)
