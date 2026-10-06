extends "res://tests/full_game_acceptance.gd"
## Legitimate missed-content save: main clear before No11/13/knocks. No anonymous lure.
func _run() -> void:
	var path := "user://tests/rc1-postgame-missed.json"
	var saved := GameProgress.new()
	for index in [9,11,13,14]: saved.record_catch(GameProgress.FISH_PROFILES[index],GameProgress.FISH_PROFILES[index].min_size_cm,false)
	saved.levels = {"rod":5,"reel":5,"line":5,"sonar":5}
	saved.main_ending_seen = true
	saved.main_story_ending_seen = true
	saved.opening_seen = true
	saved.returned_unknown_a = true
	saved.returned_unknown_b = true
	saved.max_depth_reached_m = 110
	assert(SaveManager.new(path).save_progress(saved))
	_main = load("res://scenes/main.tscn").instantiate()
	_main.get_node("LakeScene/FishingController").save_path = path
	root.add_child(_main)
	_lake = _main.get_node("LakeScene")
	_flow = _lake.get_node("FishingController")
	_hud = _lake.get_node("HUD/Root")
	_fishes = _lake.get_node("Underwater/FishContainer").get_children()
	_boat = _lake.get_node("Lake/Boat")
	hidden = _flow.hidden_route
	_disable_physics(_main)
	await process_frame; await process_frame
	_check(_flow.state == FLOW.State.TITLE and _flow.request_continue(),"Missed-content save continues from main title")
	_check(not saved.anonymous_lure_obtained and hidden.night_button.visible and not hidden.lure_button.visible,"NIGHT available without anonymous lure")
	_check(hidden.toggle_night(),"Postgame night selectable")
	_step(12.1)
	_check(_travel_for_band(3) and _flow.environment.value >= 1.95 and _flow.select_depth_band(3),"Night / first missing depth area accessible")
	_check(_catch_real() and _flow.progress.fish_records["No.11"].discovered,"No.11 genuinely recaught after main ending")
	_step(8)
	_check(_flow.progress.hull_knock_count == 2,"Missed first two knock sequences complete in postgame")
	_check(_flow.select_depth_band(4) and _catch_real() and _flow.progress.fish_records["No.13"].discovered,"No.13 genuinely recaught after main ending")
	_step(8)
	_check(_flow.progress.hull_knock_count == 3 and _flow.progress.zero_depth_contact_seen,"Third knock / zero contact recoverable without anonymous lure")
	var loaded := GameProgress.new()
	_check(_flow.save_manager.load_into(loaded) and loaded.hull_knock_count == 3 and loaded.zero_depth_contact_seen,"Recovery persists")
	print("RC1_POSTGAME_RECOVERY ",JSON.stringify({"checks":_checks,"failures":_failures}))
	_main.free();DirAccess.remove_absolute(path)
	await create_timer(0.15).timeout
	quit(0 if _failures.is_empty() else 1)
