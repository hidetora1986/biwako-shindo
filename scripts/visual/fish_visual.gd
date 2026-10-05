extends AnimatedSprite2D
## Presentation only: never changes AI, hit size, RNG, position or catch data.
var _species: String = ""
var _last_size: float = -1
var _base_scale: float = 1

func _ready() -> void:
	# FishController retains its original 40×22 envelope and custom-art setup.
	call_deferred("_apply_art")

func _apply_art() -> void:
	var fish: FishController = get_parent()
	if fish.fish_art != null:
		set_process(false)
		return
	_species = fish.fight_profile.species_id
	sprite_frames = RefinedPixelArt.fish_frames(_species)
	play("swim")
	var species_scale: float = {"bluegill": 0.85, "bass": 0.97, "crucian": 0.91, "catfish": 1.0, "biwamasu": 0.98}.get(_species, 1.0)
	_base_scale = species_scale * (0.90 + float(fish.variation_seed % 7) * 0.016)
	_last_size = -1

func _process(_delta: float) -> void:
	var fish: FishController = get_parent()
	if fish.fish_art != null:
		return
	if _species != fish.fight_profile.species_id:
		_apply_art()
	if _last_size != fish.size_cm:
		_last_size = fish.size_cm
		var size_ratio := 0.5 if fish.size_cm <= 0 else inverse_lerp(fish.fight_profile.min_size_cm, fish.fight_profile.max_size_cm, fish.size_cm)
		# Nearest sampling; never extend outside the AI's unchanged frame bounds.
		var factor := clampf(_base_scale * lerpf(0.94, 1.0, clampf(size_ratio, 0, 1)), 0.7, 1.0)
		scale = Vector2.ONE * snappedf(factor, 0.025)
	var depth_tint := clampf(fish.depth_position / 15.0, 0, 1)
	self_modulate = Color(1.0 - depth_tint * 0.12, 1.0 - depth_tint * 0.05, 1.0, 1.0)
