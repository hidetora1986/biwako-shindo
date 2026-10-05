extends "res://tests/full_game_acceptance.gd"
## Instrumentation-only fixtures; not Human Feel or pacing evidence.
var logger: Node

func _run() -> void:
	logger = root.get_node("HumanPlaytest")
	_check(not logger.enabled, "Logger opt-in, disabled by default")
	_check(logger.test_save_path("user://biwako-shindo/save.json") == "user://biwako-shindo/save.json", "Normal save path unchanged when disabled")
	var normal := "user://biwako-shindo/save.json"
	var normal_existed := FileAccess.file_exists(normal)
	var original := FileAccess.get_file_as_bytes(normal) if normal_existed else PackedByteArray()
	_check(logger.start_session(true), "Fresh dedicated test session")
	_check(FileAccess.file_exists(logger.TEST_SAVE), "Fresh test save created")
	_check(FileAccess.file_exists(normal) == normal_existed and (not normal_existed or FileAccess.get_file_as_bytes(normal) == original), "Normal user save byte-for-byte untouched")
	_new_scene(); await process_frame; await process_frame
	_check(_flow.save_path == logger.TEST_SAVE and _flow.progress.money == 0, "Actual scene uses isolated fresh save")
	logger.set_process(false)
	var before: float = logger.data.active_seconds
	logger.advance_clock(2, false)
	_check(is_equal_approx(logger.data.active_seconds, before + 2), "Active time increments monotonic seconds")
	logger.advance_clock(3, true)
	logger.advance_clock(60, false)
	logger.advance_clock(NAN, false)
	_check(is_equal_approx(logger.data.active_seconds, before + 2), "Pause, suspend gap and NaN excluded")
	logger._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	logger._last_tick -= 2000000
	before = logger.data.active_seconds
	logger._tick()
	_check(logger.data.active_seconds == before, "Focus lost excluded")
	logger._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	logger._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_check(logger.background and not logger.focus_lost, "Background and focus use independent locks")
	logger._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	logger.set_manual_pause(true)
	logger._last_tick -= 2000000
	before = logger.data.active_seconds
	logger._tick()
	_check(logger.data.active_seconds == before, "Manual timer pause excluded")
	logger.set_manual_pause(false)
	var marker_key := InputEventKey.new()
	marker_key.keycode = KEY_F6; marker_key.pressed = true
	var events_before: int = logger.data.events.size()
	logger._input(marker_key); marker_key.echo = true; logger._input(marker_key)
	_check(logger.data.events.size() == events_before+1, "Marker key press recorded; key repeat ignored")
	_check(not logger._valid_session({"session_version":1,"events":[],"seen":{},"ratings":{},"active_seconds":0,"started_unix":0}), "Incomplete log falls back, no invalid counter load")
	for name: String in ["BORED", "GOOD MOMENT", "CONFUSED"]: logger.record(name, {}, false)
	_check(logger.data.ratings.values().all(func(v): return v == null), "Human Feel remains unrated")
	_check(not logger.rate("Overall", 0) and not logger.rate("Overall", 6) and logger.rate("Overall", 4), "Human-supplied scores only, 1-5 validation")
	# Fixture events exercise observer fields without changing any catalog/balance.
	_flow.progress.sell_catch(GameProgress.FISH_PROFILES[0], 18, 101)
	for pair: Array in [["line",2],["sonar",2],["line",4],["line",5]]:
		_flow.progress.levels[pair[0]] = pair[1]; _flow.progress.changed.emit()
	_flow.progress.finish_anomaly()
	for id: String in ["No.06","No.10","No.11","No.14"]:
		_flow.progress.fish_records[id].discovered = true; _flow.progress.changed.emit()
	logger.choice("No.10", "RETURN"); logger.choice("No.14", "SELL")
	_flow.environment.value = 2; logger.sample()
	for i in range(1,4): _flow.progress.finish_hull_knock(i)
	_flow.state = FLOW.State.BOSS_BITE; logger.sample(); logger.sample()
	_flow.progress.boss15_defeated = true; _flow.progress.finish_main_ending()
	logger.record("POST GAME CONTINUE")
	_flow.progress.anonymous_lure_obtained = true; _flow.progress.changed.emit()
	_flow.hidden_route.stage = HiddenRoute.Stage.DEPTH; logger.sample()
	_flow.hidden_route.stage = HiddenRoute.Stage.CONTACT; logger.sample()
	logger.record("NO00 FINAL CHOICE", {"choice":"CONTACT"})
	_flow.hidden_route.stage = HiddenRoute.Stage.FAILURE; logger.sample(); logger.sample()
	_flow.state = FLOW.State.FAILED; logger.sample(); logger.sample()
	_flow.progress.finish_hidden(true)
	for name: String in ["SESSION START","FIRST CATCH","LINE LV2","SONAR LV2","FIRST SONAR ANOMALY","NO06 DISCOVERED","NO10 DISCOVERED","NO10 CHOICE","LINE LV4","NO11 DISCOVERED","NIGHT","HULL KNOCK 1","HULL KNOCK 2","HULL KNOCK 3","NO14 DISCOVERED","NO14 CHOICE","LINE LV5","NO15 ENCOUNTER","NO15 DEFEATED","MAIN ENDING","POST GAME CONTINUE","ANONYMOUS LURE","NO00 CONTACT","NO00 FINAL CHOICE","HIDDEN ENDING"]:
		_check(logger.data.seen.has(name), "Milestone " + name)
	_check(logger.data.boss15_attempts == 1 and logger.data.no00_attempts == 1 and logger.data.failed_fights == 2, "Attempts and failures edge-triggered, no duplicates")
	for event: Dictionary in logger.data.events:
		for key: String in ["elapsed_seconds","wall_clock_seconds","money","total_fish_caught","rod_level","reel_level","line_level","sonar_level","current_depth","failed_fights","boss15_attempts","no00_attempts"]:
			_check(event.has(key), "Telemetry " + key)
	_check(logger.flush(), "Atomic JSON flush")
	var stored: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(logger.SESSION_FILE))
	_check(stored.events.size() == logger.data.events.size() and stored.ratings.Overall == 4, "Session file persists markers and ratings")
	var active: float = stored.active_seconds
	var count: int = stored.events.size()
	_main.free(); logger.flow = null; await process_frame
	_check(logger.start_session(false), "Resume logger after restart")
	_check(logger.data.active_seconds >= active and logger.data.events.size() == count+1, "Resume retains active time and prior milestones")
	_check(logger.start_session(true) and logger.data.events.size() == 1 and logger.data.ratings.Overall == null, "Fresh resets only QA session")
	logger.enabled = false
	logger.set_process(false)
	print("HUMAN_PLAYTEST_ACCEPTANCE ", JSON.stringify({"result":"PASS" if _failures.is_empty() else "FAIL","checks":_checks,"failures":_failures,"human_feel":"MANUAL TEST REQUIRED"}))
	quit(0 if _failures.is_empty() else 1)
