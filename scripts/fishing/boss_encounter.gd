class_name BossEncounter
extends RefCounted
## Reuses a lake fish node. Depth/gear gate, one boss, next-cast retry, no grinding.
var boss: FishController
var spawned: bool = false
var encounters: int = 0

func begin_cast() -> void:
	spawned = false
	boss = null

func try_spawn(lake: Node2D, progress: GameProgress, lure_depth: float) -> bool:
	if lake.current_area != LakeAreas.CENTER or spawned or not progress.can_encounter_boss() or lure_depth < 100 or lure_depth > 120 or lake.depth_band != 6:
		return false
	boss = lake.get_node("Underwater/FishContainer").get_child(0)
	boss.repopulate(GameProgress.FISH_PROFILES[14],112,lake.view_size.x * 0.7)
	boss.swim_direction = -1
	boss.swim_speed = 6
	boss.approach_speed = 25
	boss.bite_detection_radius = 620
	boss.bite_probability = 1
	boss.configure_water(lake.water_bounds,lake.depth_span_m,lake.depth_origin_m)
	spawned = true
	encounters += 1
	return true

func reserve(container: Node2D) -> void:
	for fish: FishController in container.get_children():
		if fish != boss:
			fish.release_lure(true)
			fish.visible = false

func release(container: Node2D) -> void:
	for fish: FishController in container.get_children():
		if fish == boss:
			fish.visible = false
		elif fish.fight_profile.id == "No.14":
			fish.visible = true
