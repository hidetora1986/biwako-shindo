extends "res://tests/phase2_acceptance.gd"
## Actual viewport inputs; targeting never bypasses the fish AI or gear gates.
func _run() -> void:
	root.size = Vector2i(1280,720)
	_new_scene(); await process_frame; await process_frame
	var water: Rect2 = _flow._water
	var point := Vector2(water.position.x + water.size.x * 0.6, _flow._surface_y + (water.end.y - 8 - _flow._surface_y) * 0.35)
	for fish: FishController in _fishes: fish.visible = false
	_touch(point)
	_check(_flow.aim_selected and is_equal_approx(_flow.aim_fraction,0.6), "Touch selects cast location")
	var depth: float = _flow.aim_depth_m
	_check(depth > 0 and depth < 10, "Water tap maps pixels to metres")
	_mouse(Vector2(water.position.x + water.size.x * 0.45,point.y))
	_check(is_equal_approx(_flow.aim_fraction,0.45), "Mouse can adjust the target")
	_mouse(Vector2(water.position.x + water.size.x * 0.45,point.y),false)
	_check(not _flow.select_cast_point(_hud.get_node("SonarPlaceholder").get_global_rect().get_center()) and not _flow.select_cast_point(Vector2(-20,-20)), "HUD and outside lake are not targets")
	_check(not _flow.select_cast_point(Vector2(NAN, INF)), "Invalid coordinates rejected")
	_check(_flow.request_book(), "Book opens with aim selected")
	_check(not _flow.select_cast_point(point + Vector2(40,0)) and not _flow.request_cast(), "Modal blocks targeting and cast")
	_hud.get_node("FishBook").close_book()
	for fish: FishController in _fishes: fish.visible = false
	_check(_flow.request_cast() and not _flow.request_cast() and not _flow.aim_selected, "Cast consumes one target; spam cannot cast twice")
	_check(not _flow.select_cast_point(point), "No retargeting during flight")
	_step(0.7)
	_check(is_equal_approx(_flow.lure.position.x,water.position.x + water.size.x * 0.45) and _flow.lure.splash_remaining > 0, "Lure lands at selected horizontal point with splash")
	_step(6)
	_check(is_equal_approx(_flow.lure.depth_m, depth) and _flow.lure.state == LureController.State.WAITING, "Lure holds selected depth instead of sinking past fish")
	_flow.lure.resume_sinking(); _step(1)
	_check(is_equal_approx(_flow.lure.depth_m,depth), "Miss/retry retains depth target")
	_check(_flow.request_retrieve(), "Targeted lure can be retrieved")
	_step(0.3)
	_check(_flow.state == FLOW.State.READY and _flow.lure.target_depth_m == -1, "Retrieve clears targeting state")
	_check(_flow.select_cast_point(Vector2(point.x,water.end.y - 10)) and is_equal_approx(_flow.aim_depth_m,10), "Line Lv1 clamps target to 10m")
	_flow.clear_aim()
	_check(_flow.select_cast_point(Vector2(point.x,_flow._surface_y)) and _flow.aim_depth_m == -1, "Surface tap selects casting point with automatic sink")
	_flow.clear_aim()
	_check(_flow.request_cast() and is_equal_approx(_flow.lure._x_fraction,0.28) and _flow.lure.target_depth_m == -1 and _flow.seek_depth_m == 0, "Untargeted cast preserves old behavior")
	_flow._begin_reset();_step(0.3)
	for ratio in [Vector2i(1280,720),Vector2i(1560,720),Vector2i(1600,720),Vector2i(640,360)]:
		root.size = ratio; await process_frame; await process_frame
		water = _flow._water
		point = Vector2(water.position.x + water.size.x*0.5,_flow._surface_y+36)
		_check(_flow.select_cast_point(point), "Target selectable at %s" % ratio)
		_check(water.grow(5).has_point(_flow.aim_position()), "Marker within water at %s" % ratio)
	_flow.clear_aim()
	_check(_flow.select_depth_band(0) and not _flow.aim_selected, "Depth change clears old target")
	_new_scene();await process_frame;await process_frame
	var targeted := false
	for fish: FishController in _fishes:
		if fish.depth_position <= 8 and _flow.select_cast_point(fish.position):
			_check(is_equal_approx(_flow.aim_depth_m,fish.depth_position), "Fish tap snaps to actual fish depth")
			targeted = true;break
	_check(targeted and _flow.request_cast(), "Aim at actual swimming fish")
	_check(_until_bite(20) and _flow.request_hook() and _finish_fight(), "Natural approach / HOOK / fight / CATCH after aimed cast")
	_flow.progress.levels["line"] = 3
	_flow._progress_changed()
	_check(_travel_for_band(2), "Travel to unlocked mid-depth band")
	var deep_target: FishController
	for fish: FishController in _fishes:
		if fish.visible and _flow.select_cast_point(fish.position):
			deep_target = fish;break
	_check(deep_target != null, "Visible deep fish can be aimed at")
	var profile: FishFightProfile = deep_target.fight_profile
	var target_depth: float = _flow.aim_depth_m
	_check(_flow.request_cast() and deep_target.fight_profile == profile, "Aimed cast keeps visible deep fish species")
	for tick in range(600): _flow.lure._physics_process(1.0/60.0)
	_check(is_equal_approx(_flow.lure.depth_m,target_depth) and _flow.lure.state == LureController.State.WAITING, "Deep target stops at metres within selected band")
	print("CAST_AIM_ACCEPTANCE ",JSON.stringify({"result":"PASS" if _failures.is_empty() else "FAIL","checks":_checks,"failures":_failures}))
	_main.free();DirAccess.remove_absolute(_test_save_path)
	await process_frame
	quit(0 if _failures.is_empty() else 1)
