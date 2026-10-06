extends SceneTree
## Four fresh processes: write → interrupted dawn → finish → postgame boot/continue.
const PATH := "user://tests/boss-restart.json"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if "--write" in OS.get_cmdline_user_args():
		var progress := GameProgress.new()
		for index in [9,10,11,12,13]:
			var profile: FishFightProfile = GameProgress.FISH_PROFILES[index]
			progress.record_catch(profile,(profile.min_size_cm+profile.max_size_cm)/2,false)
		progress.levels = {"rod":5,"reel":4,"line":5,"sonar":5}
		progress.money = 12345
		progress.returned_unknown_a = true
		progress.returned_unknown_b = true
		progress.hull_knock_count = 3
		progress.zero_depth_contact_seen = true
		progress.anomaly_seen = true
		assert(progress.sell_catch(GameProgress.FISH_PROFILES[14],438.6,1) == 2186000)
		assert(SaveManager.new(PATH).save_progress(progress))
		print("BOSS_RESTART_WRITE PASS")
	else:
		var main: Node2D = load("res://scenes/main.tscn").instantiate()
		var flow: Node2D = main.get_node("LakeScene/FishingController")
		flow.save_path = PATH
		root.add_child(main)
		await process_frame; await process_frame
		flow.set_physics_process(false)
		assert(flow.progress.money == 2198345 and flow.progress.boss15_defeated)
		assert(flow.progress.levels.line == 5 and flow.progress.levels.rod == 5 and flow.progress.levels.reel == 4 and flow.progress.levels.sonar == 5)
		assert(flow.progress.returned_unknown_a and flow.progress.returned_unknown_b and flow.progress.night_unlocked and flow.progress.hull_knock_count == 3 and flow.progress.zero_depth_contact_seen and flow.progress.anomaly_seen)
		assert(flow.progress.fish_records["No.15"].caught_count == 1 and flow.progress.fish_records["No.15"].best_size_cm == 438.6)
		if "--interrupt" in OS.get_cmdline_user_args():
			assert(flow.state == flow.State.ENDING and not flow.progress.main_ending_seen)
			flow._physics_process(4)
			assert(flow.state == flow.State.ENDING and flow.selected_band == 0 and not flow.progress.main_ending_seen and flow.save_manager.write_count == 0)
			print("BOSS_RESTART_INTERRUPTED_DAWN PASS")
		elif "--finish" in OS.get_cmdline_user_args():
			assert(flow.state == flow.State.ENDING)
			flow._physics_process(8.1)
			flow.story.skip();flow.story.skip();flow._physics_process(0.3)
			assert(flow.state == flow.State.TITLE and flow.progress.main_ending_seen and flow.save_manager.write_count == 1 and flow.environment.value == 0)
			print("BOSS_RESTART_FINISH PASS")
		else:
			assert(flow.state == flow.State.TITLE and flow.progress.main_ending_seen and flow.environment.value == 0 and flow.save_manager.write_count == 0)
			assert(flow.request_continue() and flow.state == flow.State.READY)
			assert(flow.progress.money == 2198345 and flow.progress.fish_records["No.15"].caught_count == 1 and not flow.progress.can_encounter_boss())
			assert(not flow.boss_encounter.try_spawn(main.get_node("LakeScene"),flow.progress,120))
			assert(DirAccess.remove_absolute(PATH) == OK)
			print("BOSS_RESTART_POSTGAME_CONTINUE PASS")
		main.free()
	quit()
