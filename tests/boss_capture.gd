extends "res://tests/boss_acceptance.gd"
## Actual Compatibility renderer, fixture gear; real spawn/fight/reward/ending/UI.
var _output: String = "/tmp/biwako-boss-captures"

func _capture(label: String) -> void:
	for fish: FishController in _fishes: fish.sprite._process(0)
	_hud.get_node("SonarPlaceholder").refresh_contacts()
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(_output.path_join(label+".png")) == OK)
	print("SCREENSHOT ",label)
	await process_frame

func _run() -> void:
	assert(DisplayServer.get_name() != "headless")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output-dir="): _output = arg.trim_prefix("--output-dir=")
	assert(DirAccess.make_dir_recursive_absolute(_output) == OK)
	for spec in [[1280,720,"16x9"],[1560,720,"19_5x9"],[1600,720,"20x9"],[640,360,"640px"]]:
		root.size = Vector2i(spec[0],spec[1])
		_new_scene()
		for frame in range(6): await process_frame
		_boss_fixture(5,5)
		await _capture(spec[2]+"-A-abyss")
		assert(_flow.request_cast())
		for tick in range(1200):
			_step(1.0/60)
			if _flow.boss_encounter.spawned: break
		assert(_flow.boss_encounter.spawned)
		await _capture(spec[2]+"-B-boss-sonar")
		assert(_until_bite(15) and _flow.request_hook())
		_step(0.32)
		await _capture(spec[2]+"-C-phase1")
		var holding := true
		var surge := false
		var phase3 := false
		var dive := false
		for tick in range(5400):
			if _flow.state == FLOW.State.LANDED: break
			assert(_flow.state != FLOW.State.FAILED)
			if _flow.state == FLOW.State.FIGHTING:
				var model: BossFishingFight = _flow.fight
				if model.resistance == FishingFight.Resistance.RUN or model.tension >= 76: holding = false
				elif model.resistance != FishingFight.Resistance.RUN and model.tension <= 45: holding = true
				if holding and not model.reeling:
					_touch(_hud.get_node("ReelButton").get_global_rect().get_center(),7)
				elif not holding and model.reeling:
					_touch(Vector2.ZERO,7,false)
				if model.resistance == FishingFight.Resistance.RUN and model.action == BossFishingFight.Action.SURGE and not surge:
					surge = true
					await _capture(spec[2]+"-D-surge")
				if model.resistance == FishingFight.Resistance.RUN and model.action == BossFishingFight.Action.DIVE and not dive:
					dive = true
					await _capture(spec[2]+"-dive")
				if model.boss_phase == 3 and not phase3:
					phase3 = true
					await _capture(spec[2]+"-E-phase3")
			_step(1.0/60)
		assert(_flow.state == FLOW.State.LANDED and surge and dive and phase3)
		await _capture(spec[2]+"-F-catch")
		_step(5.7)
		assert(_flow.state == FLOW.State.ENDING and _flow.selected_band == 0)
		await _capture(spec[2]+"-G-dawn")
		_step(4.6)
		assert(_flow.state == FLOW.State.TITLE and _flow.progress.main_ending_seen)
		await _capture(spec[2]+"-title")
		var point: Vector2 = _flow.ending_screen.get_node("Continue").get_global_rect().get_center()
		if spec[2] == "20x9":
			_mouse(point); _mouse(point,false)
		else:
			_touch(point); _touch(point,0,false)
		await process_frame
		assert(_flow.state == FLOW.State.READY and _flow.request_book())
		_hud.get_node("FishBook/Panel/Scroll").scroll_vertical = 10000
		for frame in range(6): await process_frame
		await _capture(spec[2]+"-H-book15")
		_hud.get_node("FishBook").close_book()
		var nodes: int = get_node_count()
		var writes: int = _flow.save_manager.write_count
		for frame in range(120): await process_frame
		assert(get_node_count() == nodes and _flow.save_manager.write_count == writes)
		print("IDLE_STABILITY ",spec[2]," nodes=",nodes," writes=0")
	print("BOSS_CAPTURE PASS")
	_main.free(); DirAccess.remove_absolute(_test_save_path)
	quit()
