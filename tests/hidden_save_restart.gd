extends SceneTree
## Independent processes per ending; no normal reward, startup writes or respawn.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var contact := "--contact" in OS.get_cmdline_user_args()
	var path := "user://tests/hidden-restart-%s.json" % ("contact" if contact else "cut")
	if "--write" in OS.get_cmdline_user_args():
		var progress := GameProgress.new()
		for fish: FishFightProfile in GameProgress.FISH_PROFILES: progress.record_catch(fish,fish.min_size_cm,false)
		progress.money = 1234567
		progress.levels = {"rod":5,"reel":5,"line":5,"sonar":5}
		progress.returned_unknown_a = true
		progress.returned_unknown_b = true
		progress.main_ending_seen = true
		progress.hull_knock_count = 3
		progress.zero_depth_contact_seen = true
		progress.anonymous_lure_obtained = true
		progress.anonymous_lure_equipped = true
		progress.hidden_entry_seen = true
		progress.hidden_postgame_sessions = 2
		progress.finish_hidden(contact)
		assert(SaveManager.new(path).save_progress(progress))
		print("HIDDEN_RESTART_WRITE PASS ",contact)
	else:
		var main: Node2D = load("res://scenes/main.tscn").instantiate()
		var flow: Node2D = main.get_node("LakeScene/FishingController")
		flow.save_path = path
		root.add_child(main)
		await process_frame; await process_frame
		flow.set_physics_process(false)
		assert(flow.state == flow.State.TITLE and flow.save_manager.write_count == 0)
		assert(flow.progress.money == 1234567 and flow.progress.hidden_finished() and flow.progress.hidden_postgame_sessions == 2)
		assert(flow.progress.no00_contacted == contact and flow.progress.no00_record().caught_count == (2 if contact else 0))
		assert(flow.progress.anonymous_lure_obtained and flow.progress.hidden_entry_seen and flow.progress.hidden_eligible())
		assert(flow.hidden_route.visual.title_shadow == not contact)
		assert(flow.request_continue() and flow.state == flow.State.READY and not flow.hidden_route.can_start())
		assert(flow.progress.second_playthrough_hooks.first_record_count == 2)
		assert(flow.save_manager.write_count == 0 and not flow.progress.can_encounter_boss())
		assert(DirAccess.remove_absolute(path) == OK)
		print("HIDDEN_RESTART_LOAD_CONTINUE PASS ",contact)
		main.free()
	quit()
