extends SceneTree
## Two independent Godot processes: -- --write, then -- --read. Test-only Save.
const PATH := "user://tests/midgame-restart.json"
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	if "--write" in OS.get_cmdline_user_args():
		var progress := GameProgress.new()
		progress.money = 200000
		progress.levels = {"rod":3,"reel":3,"line":3,"sonar":3}
		progress.record_catch(GameProgress.FISH_PROFILES[1],44.2,false)
		assert(progress.return_catch(GameProgress.FISH_PROFILES[9],112.4,1))
		assert(progress.purchase("line",4))
		progress.anomaly_seen = true
		assert(SaveManager.new(PATH).save_progress(progress))
		print("RESTART_WRITE PASS")
	else:
		assert(FileAccess.file_exists(PATH))
		var main: Node2D = load("res://scenes/main.tscn").instantiate()
		var flow: Node2D = main.get_node("LakeScene/FishingController")
		flow.save_path = PATH
		root.add_child(main)
		await process_frame
		assert(flow.progress.money == 135000 and flow.progress.levels.line == 4)
		assert(flow.progress.fish_records["No.02"].best_size_cm == 44.2)
		assert(flow.progress.fish_records["No.10"].caught_count == 1 and flow.progress.fish_records["No.10"].best_size_cm == 112.4)
		assert(flow.progress.anomaly_seen and flow.progress.returned_unknown_a and flow.progress.lv4_unlocked())
		assert(flow.lure.max_depth_m == 50 and flow.progress.current("line").effect_value == 85)
		assert(flow.select_depth_band(2))
		main.free()
		assert(DirAccess.remove_absolute(PATH) == OK)
		print("RESTART_READ PASS")
	quit()
