class_name FishFightProfile
extends Resource
## Formal MVP fish data and the existing fight tuning share one Resource.

@export var id: String = "No.01"
@export var min_depth: float = 0.0
@export var max_depth: float = 5.0
@export var min_price: int = 200
@export var max_price: int = 450
@export_range(1, 6) var rarity: int = 1
@export_multiline var description: String = "湖岸の浅い水に多い小型魚。"
@export var species_id: String = "bluegill"
@export var display_name: String = "ブルーギル"
@export var placeholder_kind: String = "bluegill"
@export var stamina: float = 20.0
@export var pull_power: float = 8.0
@export var stamina_drain: float = 7.5
@export var reel_progress_speed: float = 0.36
@export var run_interval: float = 3.5
@export var run_duration: float = 0.65
@export var run_power: float = 24.0
@export var min_size_cm: float = 12.0
@export var max_size_cm: float = 22.0

# Compatibility accessors keep Phase 3's fight API; no duplicate data values.
var max_stamina: float:
	get: return stamina
var size_min_cm: float:
	get: return min_size_cm
var size_max_cm: float:
	get: return max_size_cm

func sale_price(size_cm: float) -> int:
	var ratio := clampf((size_cm - min_size_cm) / maxf(max_size_cm - min_size_cm, 0.001), 0.0, 1.0)
	return roundi(lerpf(float(min_price), float(max_price), ratio))

func allows_depth(depth_m: float) -> bool:
	return depth_m >= min_depth and depth_m <= max_depth

# Late-game tuning defaults preserve every existing fight.
@export var run_warning_seconds: float = 0.5
@export var break_grace_seconds: float = 0.65
@export var pull_pulse_power: float = 0.0
@export var stamina_recovery_after_run: float = 0.0
