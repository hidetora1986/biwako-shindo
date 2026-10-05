extends SceneTree
## Native-render screenshot acceptance. Uses an isolated test Save and real input.
## godot --path . --script res://tests/visual_capture.gd -- --output-dir=/tmp/visual
const FLOW := preload("res://scripts/fishing/fishing_controller.gd")
var _main: Node2D
var _flow: Node2D
var _hud: Control
var _output: String = "user://tests/visual-v1-captures"

func _initialize() -> void:
	call_deferred("_run")

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var target := _output.path_join(label + ".png")
	assert(root.get_texture().get_image().save_png(target) == OK)
	print("SCREENSHOT ", ProjectSettings.globalize_path(target))
	# GUI input is deferred beyond the render callback.
	await process_frame

func _touch(point: Vector2, index: int = 0, pressed: bool = true) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.index = index
	event.pressed = pressed
	root.push_input(event, true)

func _tap(point: Vector2) -> void:
	_touch(point)
	_touch(point, 0, false)

func _run() -> void:
	assert(DisplayServer.get_name() != "headless", "Screenshots require a native renderer")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			_output = argument.trim_prefix("--output-dir=")
	assert(DirAccess.make_dir_recursive_absolute(_output) == OK)
	Engine.time_scale = 2.0
	for spec in [[1280, 720, "16x9"], [1560, 720, "19_5x9"], [1600, 720, "20x9"], [640, 360, "640px"]]:
		root.size = Vector2i(spec[0], spec[1])
		var save_path := "user://tests/visual-v1-%s.json" % spec[2]
		DirAccess.remove_absolute(save_path)
		_main = load("res://scenes/main.tscn").instantiate()
		_main.get_node("LakeScene/FishingController").save_path = save_path
		root.add_child(_main)
		_flow = _main.get_node("LakeScene/FishingController")
		_hud = _main.get_node("LakeScene/HUD/Root")
		for frame in range(10):
			await process_frame
		await _capture(spec[2] + "-A-lake")
		_tap(_hud.get_node("CastButton").get_global_rect().get_center())
		var deadline := Time.get_ticks_msec() + 15000
		while _flow.state != FLOW.State.BITTEN and Time.get_ticks_msec() < deadline:
			await process_frame
		assert(_flow.state == FLOW.State.BITTEN)
		_tap(Vector2(560, 180))
		while _flow.state != FLOW.State.FIGHTING:
			await process_frame
		var holding := true
		_touch(_hud.get_node("ReelButton").get_global_rect().get_center(), 7)
		await create_timer(0.6).timeout
		assert(_flow.fight.reeling)
		await _capture(spec[2] + "-B-fight")
		deadline = Time.get_ticks_msec() + 15000
		while _flow.state != FLOW.State.LANDED and Time.get_ticks_msec() < deadline:
			assert(_flow.state != FLOW.State.FAILED)
			if _flow.state == FLOW.State.FIGHTING:
				if _flow.fight.resistance == FishingFight.Resistance.RUN or _flow.fight.tension >= 76:
					holding = false
				elif _flow.fight.resistance != FishingFight.Resistance.RUN and _flow.fight.tension <= 45:
					holding = true
				if holding and not _flow.fight.reeling:
					_touch(_hud.get_node("ReelButton").get_global_rect().get_center(), 7)
				elif not holding and _flow.fight.reeling:
					_touch(Vector2(560, 180), 7, false)
			await process_frame
		assert(_flow.state == FLOW.State.LANDED)
		await _capture(spec[2] + "-catch")
		while _flow.state != FLOW.State.READY:
			await process_frame
		_tap(_hud.get_node("ShopButton").get_global_rect().get_center())
		assert(paused)
		for frame in range(10):
			await process_frame
		await _capture(spec[2] + "-C-shop")
		_tap(_hud.get_node("Shop/Panel/Close").get_global_rect().get_center())
		_tap(_hud.get_node("BookButton").get_global_rect().get_center())
		assert(paused)
		for frame in range(10):
			await process_frame
		await _capture(spec[2] + "-C-book")
		_tap(_hud.get_node("FishBook/Panel/Close").get_global_rect().get_center())
		assert(not paused)
		var node_count: int = get_node_count()
		var writes: int = _flow.save_manager.write_count
		var started := Time.get_ticks_usec()
		for frame in range(120):
			await process_frame
		assert(node_count == get_node_count() and writes == _flow.save_manager.write_count)
		print("RENDER_SAMPLE ", spec[2], " 120_frames_ms=", float(Time.get_ticks_usec() - started) / 1000, " nodes=", node_count, " idle_save_writes=0")
		_main.queue_free()
		await process_frame
		DirAccess.remove_absolute(save_path)
	print("VISUAL_CAPTURE PASS")
	quit()
