extends "res://tests/lategame_depth_acceptance.gd"
## Native screenshots, isolated gear fixture; real detection, fights and choices.
var _output: String = "/tmp/biwako-lategame-captures"

func _capture(label: String) -> void:
	for fish: FishController in _fishes:
		fish.sprite._process(0)
	var sonar: SonarDisplay = _hud.get_node("SonarPlaceholder")
	sonar.refresh_contacts()
	for index in range(sonar.contacts.size()):
		if sonar.contacts[index].name_text == "???":
			sonar._focus_index = index
			sonar._focus_remaining = 2
			break
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(_output.path_join(label+".png")) == OK)
	print("SCREENSHOT ",label)
	await process_frame

func _finish_normal() -> void:
	assert(_flow.request_hook())
	assert(_land_deep())
	_step(1.8)
	assert(_flow.state == FLOW.State.READY)

func _run() -> void:
	assert(DisplayServer.get_name() != "headless")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output-dir="):
			_output = arg.trim_prefix("--output-dir=")
	assert(DirAccess.make_dir_recursive_absolute(_output) == OK)
	for spec in [[1280,720,"16x9"],[1560,720,"19_5x9"],[1600,720,"20x9"],[640,360,"640px"]]:
		root.size = Vector2i(spec[0],spec[1])
		_new_scene()
		for frame in range(8): await process_frame
		var progress: GameProgress = _flow.progress
		progress.record_catch(GameProgress.FISH_PROFILES[9],112.4,false)
		progress.returned_unknown_a = true
		progress.levels = {"rod":4,"reel":4,"line":4,"sonar":4}
		progress.anomaly_seen = true
		progress.changed.emit()
		assert(_flow.select_depth_band(3))
		await _capture(spec[2]+"-A-50_65m-no11")
		assert(_session())
		_step(4.5)
		await _capture(spec[2]+"-sunset")
		assert(_session())
		_step(15)
		assert(progress.night_unlocked and progress.hull_knock_count == 2)
		assert(_flow.select_depth_band(4))
		await _capture(spec[2]+"-B-night-65_85m")
		assert(_flow.request_cast() and _until_bite(25) and _flow.active_fish.fight_profile.id == "No.13")
		assert(_flow.request_hook())
		_step(0.32)
		_touch(_hud.get_node("ReelButton").get_global_rect().get_center(),7)
		_step(0.4)
		assert(_flow.fight.reeling)
		await _capture(spec[2]+"-C-no13-fight")
		assert(_land_deep())
		_step(1.8)
		for tick in range(600):
			_step(1.0/60)
			if _flow.hull_events.zero_active: break
		assert(progress.hull_knock_count == 3 and _flow.hull_events.zero_active)
		await _capture(spec[2]+"-G-zero-depth-contact")
		_step(0.7)
		assert(progress.zero_depth_contact_seen)
		_flow._deep_cast_count = 5 # Repeatable rare encounter opportunity, still depth/distance driven.
		var unknown_found := false
		for attempt in range(12):
			assert(_flow.request_cast() and _until_bite(25))
			if _flow.active_fish.fight_profile.id == "No.14":
				unknown_found = true
				break
			_finish_normal()
		assert(unknown_found and _flow.lure.depth_m <= 85)
		assert(_flow.request_hook())
		_step(0.32)
		_touch(_hud.get_node("ReelButton").get_global_rect().get_center(),7)
		for tick in range(240):
			_flow.set_reeling(_flow.fight.resistance != FishingFight.Resistance.RUN and _flow.fight.tension < 76)
			_step(1.0/60)
		await _capture(spec[2]+"-D-no14")
		assert(_land_deep())
		await _capture(spec[2]+"-no14-lingering-sonar")
		_step(1.6)
		assert(_flow.state == FLOW.State.CHOOSING)
		await _capture(spec[2]+"-E-no14-choice")
		var selling: bool = spec[2] == "20x9"
		var target: Vector2 = _hud.get_node("CatchPanel/SellChoice" if selling else "CatchPanel/ReturnChoice").get_global_rect().get_center()
		if selling:
			_mouse(target); _mouse(target,false)
		else:
			_touch(target); _touch(target,0,false)
		await process_frame
		assert(_flow.state == FLOW.State.RESET and progress.lv5_unlocked())
		_step(0.25)
		assert(_flow.request_shop())
		for frame in range(5): await process_frame
		assert(_hud.get_node("Shop")._labels.line.text.contains("Lv.5"))
		await _capture(spec[2]+"-F-lv5-shop")
		_hud.get_node("Shop").close_shop()
		assert(_flow.request_book())
		_hud.get_node("FishBook/Panel/Scroll").scroll_vertical = 10000
		for frame in range(5): await process_frame
		await _capture(spec[2]+"-book-no14")
		_hud.get_node("FishBook").close_book()
		var nodes: int = get_node_count()
		var writes: int = _flow.save_manager.write_count
		for frame in range(120): await process_frame
		assert(nodes == get_node_count() and writes == _flow.save_manager.write_count)
		print("IDLE_STABILITY ",spec[2]," nodes=",nodes," writes=0")
	print("LATEGAME_CAPTURE PASS")
	_main.free(); DirAccess.remove_absolute(_test_save_path)
	quit()
