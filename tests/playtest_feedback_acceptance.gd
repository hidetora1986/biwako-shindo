extends "res://tests/hidden_boss_acceptance.gd"
## Real inputs, actual travel/save, isolated old-save migration and endgame gates.
func _run() -> void:
	root.size = Vector2i(1280,720)
	_new_scene(); await process_frame; await process_frame
	var progress: GameProgress = _flow.progress
	_check(progress.current_area == LakeAreas.SOUTH and not _hud.get_node("HookButton").visible, "Default South / HOOK hidden at READY")
	_check(not LakeAreas.unlocked(LakeAreas.NORTH,progress) and not LakeAreas.unlocked(LakeAreas.CENTER,progress), "Fresh save area gates")
	_check(_flow.request_area() and paused, "AREA opens a paused map")
	_check(_hud.get_node("AreaMap").buttons[LakeAreas.NORTH].disabled and not _flow.request_cast() and not _flow.request_shop() and not _flow.request_book(), "Locked map / modal prevents underlying actions")
	_check(_flow.request_save(true) and _hud.get_node("SaveNotice").text == "SAVED", "Current anchor SAVE inside map succeeds")
	_hud.get_node("AreaMap").close_map()
	_check(not paused and not _flow._area_open, "AREA closes / resumes")
	_check(_flow.request_save() and FileAccess.file_exists(_test_save_path), "Manual SAVE POINT writes")
	var writes: int = _flow.save_manager.write_count
	_step(0.5)
	_check(_flow.save_manager.write_count == writes, "No per-frame save")
	_check(_flow.request_cast() and not _flow.request_travel(LakeAreas.NORTH) and not _flow.request_save() and not _flow.request_area(), "Fishing blocks travel / save / AREA")
	_check(_until_bite() and _hud.get_node("HookButton").visible and not _hud.get_node("CastButton").visible, "BITE replaces CAST with HOOK")
	_touch(Vector2(10,210)); _mouse(Vector2(10,210)); _mouse(Vector2(10,210),false)
	_check(_flow.state == FLOW.State.BITTEN, "Random touch and click cannot hook")
	_touch(_hud.get_node("ShopButton").get_global_rect().get_center())
	_check(_flow.state == FLOW.State.BITTEN, "SHOP touch never accidentally hooks")
	_touch(_hud.get_node("HookButton").get_global_rect().get_center())
	_check(_flow.state == FLOW.State.HOOKED and not _hud.get_node("HookButton").visible, "Dedicated touch HOOK succeeds once")
	_check(not _flow.request_hook() and _finish_fight(), "Repeated hook blocked / normal fight completes")
	_check(_flow.request_cast() and _until_bite(), "Second bite")
	_step(1.51)
	_check(_flow.state != FLOW.State.BITTEN and _hud.get_node("Result").text == "MISS" and not _hud.get_node("HookButton").visible, "Original hook window timeout misses")
	_check(_until_bite(), "Retry bite")
	_mouse(_hud.get_node("HookButton").get_global_rect().get_center()); _mouse(_hud.get_node("HookButton").get_global_rect().get_center(),false)
	_check(_flow.state == FLOW.State.HOOKED and _finish_fight(), "Dedicated mouse HOOK succeeds")
	progress.levels.line = 3
	progress.anomaly_seen = true
	progress.changed.emit()
	_check(LakeAreas.unlocked(LakeAreas.NORTH,progress) and not LakeAreas.unlocked(LakeAreas.CENTER,progress), "LINE3 unlocks North Shore only")
	_check(_flow.request_travel(LakeAreas.NORTH) and not _flow.request_cast() and not _flow.request_travel(LakeAreas.SOUTH), "One boat trip / travelling blocks competing inputs")
	var anchor: Vector2 = _boat.anchor_position
	_step(0.7)
	_check(_boat.anchor_position.x > anchor.x+60 and _flow.state == FLOW.State.TRAVELLING, "Boat visibly moves horizontally")
	_step(0.8)
	_check(progress.current_area == LakeAreas.NORTH and _lake.current_area == LakeAreas.NORTH and _flow.selected_band == 1 and _hud.get_node("SaveNotice").text == "SAVED", "Arrival clamps band / saves / refreshes HUD")
	_check(_flow.save_manager.write_count > writes and _hud.get_node("AreaLabel").text.begins_with("北湖沿岸"), "Arrival autosave and current area label")
	for fish: FishController in _fishes:
		_check(LakeAreas.allows_fish(LakeAreas.NORTH,fish.fight_profile) and fish.fight_profile.allows_depth(fish.depth_position), "North spawn area and habitat: "+fish.fight_profile.id)
	var sonar: SonarDisplay = _hud.get_node("SonarPlaceholder")
	_check(sonar._fishes == _flow._fish_container and sonar.contacts.all(func(c): return c.depth_m >= 15), "Sonar refresh follows area depths")
	var loaded := GameProgress.new()
	_check(_flow.save_manager.load_into(loaded) and loaded.current_area == LakeAreas.NORTH and loaded.money == progress.money, "current_area / money saved and restored")
	progress.record_catch(GameProgress.FISH_PROFILES[9],112,false)
	progress.levels.line = 4
	progress.changed.emit()
	_check(LakeAreas.unlocked(LakeAreas.CENTER,progress) and _flow.request_travel(LakeAreas.CENTER), "No10 + LINE4 unlock North Center")
	_step(1.5)
	_check(progress.current_area == LakeAreas.CENTER and _flow.selected_band == 3 and _flow.select_depth_band(4) and not _flow.select_depth_band(2), "Center arrival / only local depth bands")
	var saved_state: Dictionary = _flow.save_manager.snapshot(progress)
	_check(saved_state.current_area == LakeAreas.CENTER, "Snapshot contains current_area")
	var restored := GameProgress.new()
	_check(_flow.save_manager.load_into(restored) and restored.current_area == LakeAreas.CENTER, "Center arrival is durable")
	var old: Dictionary = saved_state.duplicate(true)
	old.erase("current_area")
	var file := FileAccess.open(_test_save_path,FileAccess.WRITE); file.store_string(JSON.stringify(old)); file.close()
	var old_bytes := FileAccess.get_file_as_bytes(_test_save_path)
	var migrated := GameProgress.new()
	_check(_flow.save_manager.load_into(migrated) and migrated.current_area == LakeAreas.SOUTH and migrated.levels == progress.levels and migrated.fish_records == progress.fish_records and LakeAreas.unlocked(LakeAreas.CENTER,migrated), "Old v1 save defaults South, retains progress and travel unlocks")
	_check(old_bytes == FileAccess.get_file_as_bytes(_test_save_path), "Migration never silently rewrites")
	for invalid: Variant in ["unknown", null, 42, {}, []]:
		old.current_area = invalid
		file = FileAccess.open(_test_save_path,FileAccess.WRITE); file.store_string(JSON.stringify(old)); file.close()
		_check(_flow.save_manager.load_into(migrated) and migrated.current_area == LakeAreas.SOUTH and migrated.money == progress.money, "Invalid area safely defaults")
	_flow.save_manager.read_only_future_version = true
	_check(not _flow.request_save() and _hud.get_node("SaveNotice").text == "SAVE FAILED", "Failed write never reports SAVED")
	_flow.save_manager.read_only_future_version = false
	# Encounter area gates augment the original progress gates.
	_boss_fixture()
	progress.current_area = LakeAreas.NORTH
	_lake.set_area(LakeAreas.NORTH)
	_check(not _flow.boss_encounter.try_spawn(_lake,progress,112), "No15 cannot spawn outside North Center")
	progress.current_area = LakeAreas.CENTER; _flow.restore_area(); _flow.select_depth_band(6)
	_check(_flow.request_cast() and _until_bite(25) and _hud.get_node("HookButton").visible and _flow._boss_bite_elapsed >= 1.5, "No15 slow bite exposes HOOK")
	_mouse(_hud.get_node("HookButton").get_global_rect().get_center()); _mouse(_hud.get_node("HookButton").get_global_rect().get_center(),false)
	_check(_flow.state == FLOW.State.HOOKED and not _hud.get_node("HookButton").visible, "No15 dedicated mouse HOOK succeeds")
	_step(0.32); _flow._fail_fight("LINE BREAK"); _step(1.6)
	hidden = _flow.hidden_route
	_check(hidden.debug_setup() and hidden.can_start(), "Hidden fixture includes North Center + night + original flags")
	progress.current_area = LakeAreas.NORTH
	_check(not hidden.can_start(), "No00 requires North Center")
	progress.current_area = LakeAreas.CENTER; _flow.restore_area(); _flow.select_depth_band(6)
	_check(_contact() and not _hud.get_node("HookButton").visible and not _flow.request_save(), "No00 remains contact / no HOOK / no SAVE")
	hidden._restore(false)
	progress.anonymous_lure_equipped = false
	progress.boss15_defeated = true
	_flow.restore_area(); _flow.select_depth_band(6)
	_check(_flow.request_cast(), "Postgame empty abyss cast")
	_step(18)
	_check(_flow.active_fish == null and _flow.request_retrieve() and not _flow.request_retrieve(), "Empty-water retrieve once / no softlock")
	_step(0.3)
	_check(_flow.can_open_area() and _travel_for_band(0), "Retrieve returns READY and allows area travel")
	for ratio in [Vector2i(1280,720),Vector2i(1560,720),Vector2i(1600,720),Vector2i(640,360)]:
		root.size = ratio
		await process_frame; await process_frame
		for name: String in ["HookButton","CastButton","ReelButton","AreaButton","SaveButton","ShopButton","BookButton"]:
			var button: Button = _hud.get_node(name)
			_check(_hud.safe_rect.encloses(button.get_global_rect()) and button.size.y*float(ratio.y)/_lake.view_size.y >= 44, "Safe 44px touch control %s at %s" % [name,ratio])
		_check(_hud.get_node("HookButton").get_global_rect() == _hud.get_node("ReelButton").get_global_rect() and _hud.get_node("CastButton").get_global_rect() == _hud.get_node("ReelButton").get_global_rect(), "Shared primary action area")
		_check(not _hud.get_node("Depth").get_global_rect().intersects(_hud.get_node("SaveButton").get_global_rect()), "Depth readout clear of SAVE")
		_check(not _hud.get_node("AreaButton").get_global_rect().intersects(_hud.get_node("SaveButton").get_global_rect()), "AREA and SAVE never overlap")
	print("PLAYTEST_FEEDBACK_ACCEPTANCE ",JSON.stringify({"result":"PASS" if _failures.is_empty() else "FAIL","checks":_checks,"failures":_failures}))
	_main.free();DirAccess.remove_absolute(_test_save_path)
	await process_frame
	quit(0 if _failures.is_empty() else 1)
