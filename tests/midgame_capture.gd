extends "res://tests/midgame_depth_acceptance.gd"
## Native framebuffer evidence. Fixture gear only; catches/choices use real inputs.
var _output: String = "/tmp/biwako-midgame-captures"

func _capture(label: String) -> void:
	var sonar: SonarDisplay = _hud.get_node("SonarPlaceholder")
	sonar.refresh_contacts()
	if label.ends_with("30_50m"):
		for index in range(sonar.contacts.size()):
			if sonar.contacts[index].name_text == "???":
				sonar._focus_index = index
				sonar._focus_remaining = 2
				break
	for fish: FishController in _fishes:
		fish.sprite._process(0)
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(_output.path_join(label+".png")) == OK)
	print("SCREENSHOT ",label)
	await process_frame

func _run() -> void:
	assert(DisplayServer.get_name() != "headless")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			_output = argument.trim_prefix("--output-dir=")
	assert(DirAccess.make_dir_recursive_absolute(_output) == OK)
	for spec in [[1280,720,"16x9"],[1560,720,"19_5x9"],[1600,720,"20x9"],[640,360,"640px"]]:
		root.size = Vector2i(spec[0],spec[1])
		_new_scene()
		for frame in range(8):
			await process_frame
		_flow.progress.levels = {"rod":3,"reel":3,"line":3,"sonar":3}
		_flow.progress.anomaly_seen = true
		_flow.progress.changed.emit()
		assert(_flow.select_depth_band(1))
		await _capture(spec[2]+"-15_30m")
		assert(_flow.select_depth_band(2))
		await _capture(spec[2]+"-30_50m")
		_flow._deep_cast_count = 2 # Start the natural 50m cast in the repeatable cycle.
		_touch(_hud.get_node("CastButton").get_global_rect().get_center())
		_touch(_hud.get_node("CastButton").get_global_rect().get_center(),0,false)
		assert(_until_bite(20) and _flow.active_fish.fight_profile.id == "No.10")
		_touch(Vector2(500,180))
		_step(0.32)
		_touch(_hud.get_node("ReelButton").get_global_rect().get_center(),7)
		assert(_flow.fight.reeling)
		_step(0.6)
		await _capture(spec[2]+"-fight")
		assert(_land_deep())
		_step(1.6)
		assert(_flow.state == FLOW.State.CHOOSING)
		await _capture(spec[2]+"-choice")
		var button: Button = _hud.get_node("CatchPanel/SellChoice" if spec[2] == "20x9" else "CatchPanel/ReturnChoice")
		var money_before: int = _flow.progress.money
		var target := button.get_global_rect().get_center()
		# Mouse UI route as well as native screen touch (no touch emulation dependency).
		if spec[2] == "20x9":
			_mouse(target)
			_mouse(target,false)
		else:
			_touch(target)
			_touch(target,0,false)
		await process_frame
		assert(_flow.state == FLOW.State.RESET)
		assert(_flow.progress.money > money_before if spec[2] == "20x9" else _flow.progress.returned_unknown_a)
		_step(0.3)
		assert(_flow.state == FLOW.State.READY)
		assert(_flow.request_shop())
		for frame in range(5):
			await process_frame
		assert(_hud.get_node("Shop")._labels.line.text.contains("Lv.4"))
		await _capture(spec[2]+"-lv4-shop")
		_hud.get_node("Shop").close_shop()
		assert(_flow.request_book())
		_hud.get_node("FishBook/Panel/Scroll").scroll_vertical = 10000
		for frame in range(5):
			await process_frame
		await _capture(spec[2]+"-book-no10")
		_hud.get_node("FishBook").close_book()
		var nodes: int = get_node_count()
		var writes: int = _flow.save_manager.write_count
		for frame in range(120):
			await process_frame
		assert(nodes == get_node_count() and writes == _flow.save_manager.write_count)
		print("IDLE_STABILITY ",spec[2]," nodes=",nodes," save_writes=0")
	print("MIDGAME_CAPTURE PASS")
	_main.free()
	DirAccess.remove_absolute(_test_save_path)
	quit()
