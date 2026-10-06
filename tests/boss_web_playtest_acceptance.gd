extends "res://tests/boss_acceptance.gd"
## Genuine boss cast/fight/ending with the same opt-in path as the Web URL.
func _run() -> void:
	var normal_path := "user://biwako-shindo/save.json"
	var existed := FileAccess.file_exists(normal_path)
	var normal_bytes := FileAccess.get_file_as_bytes(normal_path) if existed else PackedByteArray()
	root.size = Vector2i(1280,720)
	_new_scene();await process_frame;await process_frame
	_check(_flow.boss_playtest and _flow.save_manager.save_path == BossWebPlaytest.SAVE_PATH, "Explicit boss playtest uses separate save")
	_check(_flow.progress.can_encounter_boss() and _flow.selected_band == 6 and _flow.progress.current_area == LakeAreas.CENTER and _flow.environment.value == 2, "Night / ABYSS / boss gates ready")
	_check(_flow.progress.levels == {"rod":5,"reel":5,"line":5,"sonar":5} and not _flow.progress.boss15_defeated, "Lv5 equipment; boss undefeated")
	_check(not _flow.progress.fish_records["No.15"].discovered and _flow.state == FLOW.State.READY, "Boss unseen / CAST available")
	_check(_boss_hook(), "Natural cast reaches No15 and hooks")
	_step(0.4);_flow.set_reeling(true);_step(15)
	_check(_flow.state == FLOW.State.READY, "Hold to break / ordinary reset returns CAST")
	_check(_boss_hook() and _boss_land(), "Retry / unchanged fight can land boss")
	_step(2.6)
	_check(_flow.progress.boss15_defeated and _flow.state == FLOW.State.ENDING, "Boss defeat enters Main Ending")
	_step(9)
	_flow.story.skip();_flow.story.skip();_step(0.3)
	_check(_flow.request_continue(), "Main ending Continue works")
	var saved := GameProgress.new()
	_check(SaveManager.new(BossWebPlaytest.SAVE_PATH).load_into(saved) and saved.boss15_defeated and saved.main_ending_seen, "Boss/ending saved only in test namespace")
	_check(FileAccess.file_exists(normal_path) == existed and (not existed or FileAccess.get_file_as_bytes(normal_path) == normal_bytes), "Normal save byte-for-byte unchanged")
	print("BOSS_WEB_PLAYTEST_ACCEPTANCE ",JSON.stringify({"result":"PASS" if _failures.is_empty() else "FAIL","checks":_checks,"failures":_failures}))
	_main.free();DirAccess.remove_absolute(BossWebPlaytest.SAVE_PATH)
	await process_frame
	quit(0 if _failures.is_empty() else 1)
