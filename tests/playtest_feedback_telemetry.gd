extends "res://tests/phase2_acceptance.gd"
## Opt-in observer records the five additional real-action milestones, never ratings.
func _run() -> void:
	var logger: Node = root.get_node("HumanPlaytest")
	_check(logger.start_session(true), "Fresh dedicated telemetry session")
	_new_scene(); await process_frame; await process_frame
	_check(_flow.request_cast() and _until_bite(), "Telemetry natural bite")
	_touch(_hud.get_node("HookButton").get_global_rect().get_center())
	_check(_flow.state == FLOW.State.HOOKED and _finish_fight(), "Telemetry actual button HOOK and catch")
	_check(_flow.request_save(), "Telemetry manual save")
	_flow.progress.levels.line = 3
	_flow.progress.anomaly_seen = true
	_flow.progress.changed.emit()
	_check(_travel_for_band(2), "Telemetry actual North Shore trip")
	_flow.progress.record_catch(GameProgress.FISH_PROFILES[9],100,false)
	_flow.progress.levels.line = 4
	_flow.progress.changed.emit()
	_check(_travel_for_band(3), "Telemetry actual North Center trip")
	for name: String in ["FIRST_HOOK_BUTTON_SUCCESS","FIRST_AREA_MOVE","FIRST_MANUAL_SAVE","NORTH_SHORE_ENTERED","NORTH_CENTER_ENTERED"]:
		_check(logger.data.seen.has(name), "Additional milestone: " + name)
	_check(logger.telemetry().current_area == LakeAreas.CENTER and logger.data.ratings.values().all(func(value): return value == null), "Area telemetry / no automatic human rating")
	print("FEEDBACK_TELEMETRY_ACCEPTANCE ",JSON.stringify({"result":"PASS" if _failures.is_empty() else "FAIL","checks":_checks,"failures":_failures}))
	_main.free(); await process_frame
	quit(0 if _failures.is_empty() else 1)
