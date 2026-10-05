extends "res://tests/full_game_acceptance.gd"
## 100 real fishing cycles, failures, spam, modal churn and atomic save snapshots.
func _run() -> void:
	root.size = Vector2i(1280,720)
	_new_scene(); await process_frame; await process_frame
	hidden = _flow.hidden_route
	var nodes := get_node_count()
	var catches := 0
	var failures := 0
	var sales := 0
	for cycle in range(100):
		var before: int = _flow.progress.money
		if cycle % 10 == 9:
			_check(_flow.request_cast() and _until_bite() and _flow.request_hook(),"Stress failed-fight hook")
			_step(0.35)
			_flow.set_reeling(false)
			for tick in range(2400):
				if _flow.state == FLOW.State.FAILED: break
				_step(1.0/60)
			_check(_flow.state == FLOW.State.FAILED and is_finite(_flow.fight.tension),"Complete-release escape finite / retry")
			_step(1.6)
			failures += 1
			_check(_flow.state == FLOW.State.READY and _flow.progress.money == before,"Failure resets without penalty")
		else:
			_check(_catch_real(),"Stress natural fishing cycle%d" % cycle)
			catches += 1
			sales += _flow.last_catch.price
		_check(_flow.progress.money == sales,"Wallet never corrupt / duplicate sale")
		_check(get_node_count() == nodes,"No node leak after cycle%d" % cycle)
		if cycle in [19,49,99]:
			_check(_flow.state == FLOW.State.READY,"20/50/100 reset milestones")
		for repeat in range(3):
			_check(_flow.request_shop() and not _flow.request_shop() and not _flow.request_cast() and not _flow.request_book(),"SHOP spam / lock")
			_hud.get_node("Shop").close_shop()
			_check(_flow.request_book() and not _flow.request_book() and not _flow.request_cast() and not _flow.request_shop(),"BOOK spam / lock")
			_hud.get_node("FishBook").close_book()
		_check(not paused and not _flow._book_open and not _flow._shop_open,"Modal unlock after churn")
		if cycle % 10 == 0:
			var loaded := GameProgress.new()
			_check(_flow.save_manager.load_into(loaded) and loaded.money == sales and loaded.fish_records == _flow.progress.fish_records,"Stress atomic save load")
	var count := 0
	for record: Dictionary in _flow.progress.fish_records.values(): count += record.caught_count
	_check(count == catches,"Only successful fish recorded")
	var saved: Dictionary = _flow.save_manager.snapshot(_flow.progress)
	var path := "user://tests/rc1-save-corruption.json"
	var cases: Array = ["", "{\"money\":123", "null", "[]", JSON.stringify({"save_version":99}),JSON.stringify({"money":"bad","line_level":[],"fish_caught_count":true}),JSON.stringify({"money":300,"unknown_field":{"x":5}})]
	for payload: String in cases:
		var file := FileAccess.open(path,FileAccess.WRITE); file.store_string(payload); file.close()
		var loaded := GameProgress.new()
		var manager := SaveManager.new(path)
		manager.load_into(loaded)
		if payload.contains("99"):
			_check(manager.read_only_future_version and not manager.save_progress(loaded) and FileAccess.get_file_as_string(path) == payload,"Future save cannot be overwritten by older binary")
		_check(loaded.money >= 0 and loaded.levels.line == 1 and loaded.fish_records.size() == 15 and not loaded.no00_contacted,"Corrupt / missing / future / unknown safe fallback")
	var manager := SaveManager.new(path)
	_check(manager.save_progress(_flow.progress),"Atomic full snapshot creates save")
	var temporary := FileAccess.open(path+".tmp",FileAccess.WRITE); temporary.store_string("{partial"); temporary.close()
	var after_interruption := GameProgress.new()
	_check(manager.load_into(after_interruption) and after_interruption.money == _flow.progress.money,"Interrupted temporary file preserves previous complete save")
	DirAccess.remove_absolute(path); DirAccess.remove_absolute(path+".tmp")
	# Multi-touch ownership / drag out / focus loss on hidden model with isolated fixture.
	_check(hidden.debug_setup() and hidden.debug_stage(HiddenRoute.Stage.FIGHT),"Hidden input stress fixture")
	var finite_inputs := true
	for tick in range(1800):
		_touch(hidden.reel.get_global_rect().get_center(),4,tick%2 == 0)
		_touch(Vector2(-100,-100),7,true)
		_step(1.0/60)
		finite_inputs = finite_inputs and is_finite(hidden.fight.tension) and is_finite(hidden.fight.boat_pull_depth)
		if hidden.stage == HiddenRoute.Stage.FAILURE: break
	_check(finite_inputs,"Hidden fast tap finite / no NaN")
	_touch(hidden.reel.get_global_rect().get_center(),4)
	var drag := InputEventScreenDrag.new()
	drag.index = 4; drag.position = Vector2(-100,-100)
	root.push_input(drag,true)
	_check(not hidden.fight.reeling and hidden.pointer_owner == -1,"Owned touch drag out releases REEL")
	_touch(hidden.reel.get_global_rect().get_center(),4)
	hidden._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(not hidden.fight.reeling and hidden.pointer_owner == -1,"HOME / focus loss releases REEL")
	_check(hidden.fight.failure in ["","PULL DEPTH","LINE BREAK"] and hidden.pointer_owner in [-1,4],"Input ownership bounded")
	print("FULL_GAME_STRESS ",JSON.stringify({"result":"PASS" if _failures.is_empty() else "FAIL","checks":_checks,"failures":_failures,"cycles":100,"catches":catches,"failed_fights":failures,"money":sales,"nodes":nodes,"modal_opens":600}))
	_main.free(); DirAccess.remove_absolute(_test_save_path)
	await process_frame
	await create_timer(0.15).timeout
	quit(0 if _failures.is_empty() else 1)
