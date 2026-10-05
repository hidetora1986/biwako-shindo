class_name LakeEnvironment
extends RefCounted
## Visual progression only. Mutates a scene-owned profile, never a shared Resource.
const KEYS := ["sky_top","sky_bottom","mountain_far","mountain_middle","mountain_near","surface_color","water_upper","water_middle","water_deep"]
const SUNSET := ["657f9c","d4b9a0","8c939d","6d7c8c","4c6670","658a9a","417985","2d5b70","1b394f"]
const NIGHT := ["16283f","35485d","344759","273c4f","1a303f","2e5267","315a71","25485f","183349"]
var value: float = 0.0
var target: float = 0.0
var _lake: Node2D
var _day: Array[Color] = []
var _sample_timer: float = 0.0

func setup(lake: Node2D, progress: GameProgress) -> void:
	_lake = lake
	for key: String in KEYS:
		_day.append(lake.profile.get(key))
	value = progress.time_of_day_target()
	target = value
	_apply()

func update_target(progress: GameProgress) -> void:
	target = progress.time_of_day_target()

func step(delta: float) -> void:
	if _lake == null or is_equal_approx(value, target):
		return
	value = move_toward(value, target, delta / 6.0)
	_sample_timer -= delta
	if _sample_timer <= 0 or is_equal_approx(value, target):
		_sample_timer = 0.1
		_apply()

func _apply() -> void:
	for i in range(KEYS.size()):
		var color: Color = _day[i].lerp(Color(SUNSET[i]), value) if value <= 1 else Color(SUNSET[i]).lerp(Color(NIGHT[i]), value - 1)
		_lake.profile.set(KEYS[i], color)
	for layer: Node2D in [_lake.get_node("Background/BackgroundSky"),_lake.get_node("Background/BackgroundMountains"),_lake.get_node("Underwater/WaterBackground")]:
		layer.time_of_day = value
		layer.queue_redraw()
		for child: CanvasItem in layer.get_children():
			child.time_of_day = value
			child.queue_redraw()
	_lake.get_node("Lake/LakeSurface").time_of_day = value
	_lake.get_node("Lake/Boat").modulate = Color.WHITE.lerp(Color("9db6c7"), value * 0.25)
	_lake.get_node("HUD/Root/Subtitle").text = ["LAKE BIWA / MORNING","LAKE BIWA / EVENING","LAKE BIWA / NIGHT"][int(round(value))]
