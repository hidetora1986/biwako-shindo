extends "res://tests/hidden_boss_acceptance.gd"
## Actual Compatibility screenshots, no compositing. Debug setup, real CAST and touch fight.
var output: String = "/tmp/biwako-hidden-captures"
func _capture(label: String) -> void:
	hidden.layout()
	hidden.visual.queue_redraw()
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output.path_join(label+".png")) == OK)
	print("SCREENSHOT ",label)
	await process_frame

func _run() -> void:
	assert(DisplayServer.get_name() != "headless")
	assert(DirAccess.make_dir_recursive_absolute(output) == OK)
	for spec in [[1280,720,"16x9"],[1560,720,"19_5x9"],[1600,720,"20x9"]]:
		root.size = Vector2i(spec[0],spec[1])
		_new_scene()
		for frame in range(6): await process_frame
		_hidden_fixture()
		assert(_flow.request_book())
		var book: Control = _hud.get_node("FishBook")
		book.get_node("Panel/Scroll").scroll_vertical = 10000
		for frame in range(6): await process_frame
		_touch(book.hidden_entry.get_global_rect().get_center())
		await _capture(spec[2]+"-A-no00-entry")
		book.close_book()
		_flow._refresh_ui()
		await _capture(spec[2]+"-B-anonymous-lure")
		assert(_flow.request_cast())
		_step(3.2)
		assert(hidden.depth_display == "114m")
		await _capture(spec[2]+"-C-114m")
		_step(1.2)
		assert(hidden.depth_display == "121m")
		await _capture(spec[2]+"-D-121m")
		_step(1.8)
		assert(hidden.depth_display == "---")
		await _capture(spec[2]+"-E-sonar-invalid")
		_step(1)
		assert(hidden.stage == HiddenRoute.Stage.CONTACT)
		await _capture(spec[2]+"-F-contact")
		_step(1)
		assert(hidden.stage == HiddenRoute.Stage.FIGHT)
		_touch(hidden.reel.get_global_rect().get_center(),9)
		_step(1.5)
		await _capture(spec[2]+"-G-hidden-fight")
		assert(_survive())
		await _capture(spec[2]+"-H-final-choice")
		_touch(hidden.cut.get_global_rect().get_center())
		_step(3.2)
		assert(_flow.state == FLOW.State.TITLE and _flow.progress.hidden_cut_ending_seen)
		await _capture(spec[2]+"-I-cut-ending")
		assert(_flow.request_continue())
		# Second independent session for the other ending; no ending flags erased.
		_new_scene()
		for frame in range(6): await process_frame
		_hidden_fixture()
		assert(_contact() and _survive())
		_touch(hidden.lift.get_global_rect().get_center())
		_step(3.1)
		assert(hidden.stage == HiddenRoute.Stage.REVEAL)
		await _capture(spec[2]+"-J-no00-count2")
		_step(3.1)
		assert(_flow.progress.no00_contacted and _flow.request_continue())
		assert(_flow.request_book())
		book = _hud.get_node("FishBook")
		book.get_node("Panel/Scroll").scroll_vertical = 10000
		for frame in range(6): await process_frame
		await _capture(spec[2]+"-K-persistent-book")
		book.close_book()
		var nodes: int = get_node_count()
		var writes: int = _flow.save_manager.write_count
		for frame in range(120): await process_frame
		assert(get_node_count() == nodes and _flow.save_manager.write_count == writes)
		print("IDLE_STABILITY ",spec[2]," nodes=",nodes," writes=0")
	print("HIDDEN_CAPTURE PASS")
	_main.free(); DirAccess.remove_absolute(_test_save_path)
	quit()
