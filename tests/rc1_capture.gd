extends "res://tests/full_game_acceptance.gd"
## Current-RC native evidence for early UI and the existing one-time sonar reaction.
func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("/tmp/rc1-captures/"+label+".png") == OK)
	print("SCREENSHOT ",label)
	await process_frame
func _run() -> void:
	assert(DisplayServer.get_name() != "headless")
	DirAccess.make_dir_recursive_absolute("/tmp/rc1-captures")
	root.size = Vector2i(1280,720)
	_new_scene()
	for frame in range(8): await process_frame
	hidden = _flow.hidden_route
	await _capture("01-early-lake")
	assert(_flow.request_cast() and _until_bite() and _flow.request_hook() and _land_deep())
	await _capture("02-normal-catch")
	_step(1.8)
	assert(_flow.request_shop())
	for frame in range(6): await process_frame
	await _capture("03-shop")
	_hud.get_node("Shop").close_shop()
	assert(_flow.request_book())
	for frame in range(6): await process_frame
	await _capture("04-fish-book")
	_hud.get_node("FishBook").close_book()
	# Render-only setup, never used by full-game progression proof.
	_flow.progress.levels.sonar = 2
	_flow.progress.changed.emit()
	assert(_flow.debug_trigger_anomaly())
	_step(0.3)
	await _capture("05-sonar-anomaly")
	_step(0.4)
	print("RC1_CAPTURE PASS")
	_main.free(); DirAccess.remove_absolute(_test_save_path)
	await create_timer(0.15).timeout
	quit()
