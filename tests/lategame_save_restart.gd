extends SceneTree
## Two processes: -- --write, then -- --read. Separate player Save.
const PATH := "user://tests/lategame-restart.json"
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	if "--write" in OS.get_cmdline_user_args():
		var progress := GameProgress.new()
		progress.opening_seen = true # This fixture is an established fishing session.
		progress.night_page_seen = true
		for index in [9,10,11,12]:
			var profile: FishFightProfile = GameProgress.FISH_PROFILES[index]
			progress.record_catch(profile,(profile.min_size_cm+profile.max_size_cm)/2,false)
		assert(progress.return_catch(GameProgress.FISH_PROFILES[13],221.5,1))
		progress.returned_unknown_a = true
		progress.anomaly_seen = true
		progress.hull_knock_count = 3
		progress.zero_depth_contact_seen = true
		progress.max_depth_reached_m = 100
		progress.money = 2000000
		progress.levels = {"rod":4,"reel":4,"line":4,"sonar":4}
		assert(progress.purchase("line",5))
		progress.current_area = LakeAreas.CENTER # Resume within the depth band under the existing area gates.
		assert(SaveManager.new(PATH).save_progress(progress))
		print("LATE_RESTART_WRITE PASS")
	else:
		assert(FileAccess.file_exists(PATH))
		var main: Node2D = load("res://scenes/main.tscn").instantiate()
		var flow: Node2D = main.get_node("LakeScene/FishingController")
		flow.save_path = PATH
		root.add_child(main)
		await process_frame
		assert(flow.progress.money == 1700000 and flow.progress.levels.line == 5)
		assert(flow.progress.returned_unknown_a and flow.progress.returned_unknown_b and flow.progress.night_unlocked)
		assert(flow.progress.hull_knock_count == 3 and flow.progress.zero_depth_contact_seen and flow.progress.anomaly_seen)
		assert(flow.progress.fish_records["No.14"].caught_count == 1 and flow.progress.fish_records["No.14"].best_size_cm == 221.5)
		assert(flow.environment.value == 2 and flow.lure.max_depth_m == 120 and flow.progress.current("line").effect_value == 120)
		assert(flow.select_depth_band(5))
		assert(flow.save_manager.write_count == 0 and flow.hull_events.strike_count == 0)
		main.free(); assert(DirAccess.remove_absolute(PATH) == OK)
		print("LATE_RESTART_READ PASS")
	quit()
