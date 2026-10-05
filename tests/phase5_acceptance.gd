extends "res://tests/phase2_acceptance.gd"
## Real catch/book/purchase/restart flows plus malformed saves and sonar boundaries.
var _paths: Array[String] = []

func _load_scene_at(path: String) -> void:
	if is_instance_valid(_main):
		_main.free()
	_main = load("res://scenes/main.tscn").instantiate()
	_main.get_node("LakeScene/FishingController").save_path = path
	root.add_child(_main)
	_lake = _main.get_node("LakeScene")
	_flow = _lake.get_node("FishingController")
	_hud = _lake.get_node("HUD/Root")
	_fishes = _lake.get_node("Underwater/FishContainer").get_children()
	_boat = _lake.get_node("Lake/Boat")
	_disable_physics(_main)

func _catch_to_result(size_cm: float = 0) -> bool:
	if not _flow.request_cast() or not _until_bite() or not _flow.request_hook():
		return false
	if size_cm > 0:
		_flow.active_fish.size_cm = size_cm # Repeatable size fixture, normal fight/landing.
	var holding := true
	for tick in range(1800):
		if _flow.state in [FLOW.State.LANDED, FLOW.State.FAILED]:
			return _flow.state == FLOW.State.LANDED
		if _flow.state == FLOW.State.FIGHTING:
			if _flow.fight.resistance == FishingFight.Resistance.RUN or _flow.fight.tension >= 76:
				holding = false
			elif _flow.fight.resistance != FishingFight.Resistance.RUN and _flow.fight.tension <= 45:
				holding = true
			_flow.set_reeling(holding)
		_step(1.0 / 60.0)
	return false

func _write_raw(path: String, data: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(data)
	file.close()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	_new_scene()
	await process_frame
	await process_frame
	var path := _test_save_path
	_paths.append(path)
	var book: Control = _hud.get_node("FishBook")
	_check(_flow.progress.money == 0 and _flow.progress.levels.values() == [1, 1, 1, 1] and not _flow.progress.anomaly_seen, "No Save: default wallet/gear/anomaly")
	_check(not FileAccess.file_exists(path), "No Save: load does not create or write every frame")
	var hidden_ok := true
	for fish: FishFightProfile in GameProgress.FISH_PROFILES:
		var text: String = book.entries[fish.id].text
		hidden_ok = hidden_ok and text.contains("???") and text.contains("未発見") and not text.contains(fish.display_name) and not text.contains("BEST") and not text.contains(fish.description)
	_check(hidden_ok and book.entries.size() == GameProgress.FISH_PROFILES.size(), "Undiscovered Fish: data-backed entries hide name/details/BEST")
	_touch(_hud.get_node("BookButton").get_global_rect().get_center())
	_check(book.visible and paused and not _flow.request_cast() and not _flow.request_shop() and not _flow.request_hook() and not _flow.set_reeling(true), "Fish Book Open: touch opens and blocks all fishing/shop inputs")
	var before: Vector2 = _fishes[1].position
	_step(5)
	await physics_frame
	_check(_fishes[1].position == before and _flow.active_fish == null, "Fish Book: fish and new BITE stay paused")
	_touch(book.get_node("Panel/Close").get_global_rect().get_center())
	_check(not book.visible and not paused, "Fish Book Close: touch resumes lake")
	var writes: int = _flow.save_manager.write_count
	_step(5)
	_check(_flow.save_manager.write_count == writes, "Auto Save: idle frames never write")
	for size_cm in [42.6, 30.0, 55.0]:
		_check(_catch_to_result(size_cm), "Capture: real CAST/HIT/FIGHT/CATCH")
		var record: Dictionary = _flow.progress.fish_records["No.02"]
		_check(_flow.last_catch.id == "No.02", "Capture: deterministic nearby bass")
		if size_cm == 42.6:
			_check(record.discovered and record.caught_count == 1 and is_equal_approx(record.best_size_cm, 42.6), "New Fish Discovery: captured record with best size")
			_check(_hud.get_node("CatchPanel/New").visible and _hud.get_node("CatchPanel/New").text == "NEW!", "First Catch: NEW! on the actual catch card")
			_check(FileAccess.file_exists(path) and _flow.save_manager.write_count == writes + 1, "Save Create: one atomic capture+record+wallet save")
		else:
			_check(not _hud.get_node("CatchPanel/New").visible and not _flow.last_catch.new_discovery, "Repeat Capture: NEW! stays hidden")
			_check(record.caught_count == (2 if size_cm == 30 else 3) and record.best_size_cm == (42.6 if size_cm == 30 else 55.0), "Caught Count / Best Size: smaller fish keeps best, larger replaces it")
		var count: int = record.caught_count
		writes = _flow.save_manager.write_count
		_flow._show_catch()
		_check(record.caught_count == count and writes == _flow.save_manager.write_count, "Duplicate CATCH: no count/money/save duplication")
		_check(not _flow.request_book(), "Catch: book blocked while result shows")
		_step(1.8)
	_check(_flow.request_book() and book.entries["No.02"].text.contains("ブラックバス") and book.entries["No.02"].text.contains("捕獲数 3") and book.entries["No.02"].text.contains("BEST SIZE 55.0 cm"), "Fish Book: discovered name/count/BEST/description")
	book.close_book()
	_check(_flow.request_shop(), "Purchase: shop opens after recorded catch")
	var shop: Control = _hud.get_node("Shop")
	writes = _flow.save_manager.write_count
	_check(shop._buy("line") and _flow.save_manager.write_count == writes + 1, "Purchase: auto-save after immediate equipment update")
	shop.close_shop()
	_hud.get_node("DepthUnlock")._process(1.3)
	var money: int = _flow.progress.money
	var records: Dictionary = _flow.progress.fish_records.duplicate(true)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(saved.save_version == 1 and saved.money == money and saved.line_level == 2 and saved.fish_caught_count["No.02"] == 3, "Save Version / Schema: JSON contains wallet/gear/fish fields")
	_load_scene_at(path)
	book = _hud.get_node("FishBook")
	_check(_flow.progress.money == money and _hud.get_node("Money/Label").text == "¥" + _hud._format_money(money), "Money Restore: fresh scene loads saved wallet/HUD")
	_check(_flow.progress.levels.line == 2 and _flow.lure.max_depth_m == 25, "Equipment Restore: loaded line applied immediately")
	_check(_flow.progress.fish_records == records and book.entries["No.02"].text.contains("55.0 cm"), "Fish Records Restore: discovery/count/BEST survive restart")
	_check(_catch_to_result() and not _hud.get_node("CatchPanel/New").visible, "Restart: next real capture grows records without duplicate NEW!")
	_step(1.8)
	# Missing, malformed, invalid and old/new unsupported versions are read safely.
	var malformed := "user://tests/phase5-invalid-%d.json" % OS.get_process_id()
	_paths.append(malformed)
	var manager := SaveManager.new(malformed)
	for raw in ["{}", "{broken", "[]", JSON.stringify({"save_version": 0, "money": 999}), JSON.stringify({"save_version": 2, "money": 999}), JSON.stringify({"save_version": 1, "money": -20, "rod_level": 9, "reel_level": 2.5, "line_level": "3", "sonar_level": true, "fish_discovered": [], "fish_caught_count": {"No.02": -1}, "fish_best_size": {"No.02": "big"}, "anomaly_seen": "true"})]:
		_write_raw(malformed, raw)
		var state := GameProgress.new()
		manager.load_into(state)
		_check(state.money == 0 and state.levels.values() == [1, 1, 1, 1] and not state.anomaly_seen and not state.fish_records["No.02"].discovered, "Missing Field / Invalid / Old Version Fallback: safe defaults")
		_check(FileAccess.get_file_as_string(malformed) == raw, "Load: malformed or unsupported save not rewritten")
	_write_raw(malformed, JSON.stringify({"money": 2300, "rod_level": 2, "fish_caught_count": {"No.02": 4}, "fish_best_size": {"No.02": 51.2}}))
	var partial := GameProgress.new()
	_check(manager.load_into(partial) and partial.money == 2300 and partial.levels.rod == 2 and partial.levels.reel == 1 and partial.fish_records["No.02"].caught_count == 4 and is_equal_approx(partial.fish_records["No.02"].best_size_cm, 51.2), "Missing Fields: valid fields retained, each absent field defaults")
	for category: String in GameProgress.CATEGORIES:
		partial.levels[category] = 3
	_check(manager.save_progress(partial), "Save: all gear categories serialize")
	var roundtrip := GameProgress.new()
	_check(manager.load_into(roundtrip) and roundtrip.levels.values() == [3, 3, 3, 3], "Equipment Restore: all four Lv3 values round-trip")
	# Sonar inspects only live fish, with level-dependent privacy and depth mapping.
	_new_scene()
	var sonar: SonarDisplay = _hud.get_node("SonarPlaceholder")
	sonar.refresh_contacts()
	_check(sonar.contacts.size() == _fishes.size(), "Sonar Fish Sync: all actual lake fish represented")
	var fish_ids: Array[int] = []
	for fish: FishController in _fishes:
		fish_ids.append(fish.get_instance_id())
	var real_only := true
	for contact: Dictionary in sonar.contacts:
		real_only = real_only and fish_ids.has(contact.instance_id) and contact.size_text == "" and contact.name_text == ""
	_check(real_only and sonar.max_depth() == 15, "Sonar Lv1: real dots only, no size/species")
	var target: FishController = _fishes[1]
	target.depth_position = 5
	sonar.refresh_contacts()
	var y5 := sonar.depth_y(5)
	target.depth_position = 10
	sonar.refresh_contacts()
	_check(sonar.depth_y(10) > y5 and sonar.contacts.any(func(c: Dictionary): return c.instance_id == target.get_instance_id() and c.depth_m == 10), "Sonar Depth Sync: vertical fish depth moves the real dot")
	target.depth_position = 15
	sonar.refresh_contacts()
	_check(sonar.contacts.size() == 7, "Sonar Depth Limit: exact 15m included")
	target.depth_position = 15.1
	sonar.refresh_contacts()
	_check(sonar.contacts.size() == 6, "Sonar Depth Limit: Lv1 deeper than 15m excluded")
	_flow.progress.levels.sonar = 2
	target.depth_position = 30
	sonar.refresh_contacts()
	_check(sonar.max_depth() == 30 and sonar.contacts.size() == 7 and sonar.contacts.all(func(c: Dictionary): return c.size_text in ["SMALL", "MEDIUM", "LARGE"] and c.name_text.is_empty()), "Sonar Lv2: 30m and size estimates without species")
	target.depth_position = 30.1
	sonar.refresh_contacts()
	_check(sonar.contacts.size() == 6, "Sonar Depth Limit: Lv2 deeper than 30m excluded")
	_flow.progress.levels.sonar = 3
	_flow.progress.record_catch(target.fight_profile, 40)
	target.depth_position = 50
	sonar.refresh_contacts()
	_check(sonar.max_depth() == 50 and sonar.contacts.size() == 7 and sonar.contacts.any(func(c: Dictionary): return c.instance_id == target.get_instance_id() and c.name_text == "ブラックバス"), "Sonar Lv3: 50m with known species name")
	_check(sonar.contacts.all(func(c: Dictionary): return c.name_text == "" or c.name_text == "ブラックバス"), "Sonar Lv3: unrecorded species names stay hidden")
	target.depth_position = 50.1
	sonar.refresh_contacts()
	_check(sonar.contacts.size() == 6, "Sonar Depth Limit: Lv3 deeper than 50m excluded")
	target.depth_position = 10
	target.visible = false
	sonar.refresh_contacts()
	_check(sonar.contacts.size() == 6, "Sonar: landed/hidden fish leave contacts")
	# PC modal focus and the scrollable fourth purchase row use real mouse input.
	_new_scene()
	_flow.progress.money = 5000
	_flow.progress.changed.emit()
	_mouse(_hud.get_node("BookButton").get_global_rect().get_center())
	_mouse(_hud.get_node("BookButton").get_global_rect().get_center(), false)
	book = _hud.get_node("FishBook")
	_check(book.visible and book.z_index > _hud.get_node("BookButton").z_index, "PC Book: mouse opens above lake buttons")
	_mouse(book.get_node("Panel/Close").get_global_rect().get_center())
	_mouse(book.get_node("Panel/Close").get_global_rect().get_center(), false)
	_check(not book.visible and not paused, "PC Book: mouse closes the paused modal")
	_mouse(_hud.get_node("ShopButton").get_global_rect().get_center())
	_mouse(_hud.get_node("ShopButton").get_global_rect().get_center(), false)
	shop = _hud.get_node("Shop")
	await process_frame
	await process_frame
	_check(shop.visible and shop.z_index > _hud.get_node("BookButton").z_index, "PC Shop: modal covers book button")
	shop.get_node("Panel/Scroll").scroll_vertical = 10000
	await process_frame
	await process_frame
	_mouse(shop._buttons["sonar"].get_global_rect().get_center())
	_mouse(shop._buttons["sonar"].get_global_rect().get_center(), false)
	_check(_flow.progress.levels.sonar == 2 and _flow.progress.money == 0, "PC Sonar Purchase: fourth row mouse click after book/scroll works")
	shop.close_shop()
	# Purchase then three real sessions; only the sonar has a short return afterward.
	_new_scene()
	path = _test_save_path
	_paths.append(path)
	_flow.progress.money = 5000 # Only funds the timing fixture's real shop purchase.
	_flow.progress.changed.emit()
	_check(_flow.request_shop() and _hud.get_node("Shop")._buy("sonar"), "Anomaly: real Sonar Lv2 purchase")
	_hud.get_node("Shop").close_shop()
	_step(10)
	_check(not _flow.anomaly.active and not _flow.progress.anomaly_seen and _flow.progress.sonar_sessions == 0, "Anomaly Timing: not immediate or caused by idle seconds")
	_flow.progress.sonar_sessions = 3
	_check(_flow.request_book() and not _flow.debug_trigger_anomaly(), "Anomaly Gate: book blocks debug event")
	_hud.get_node("FishBook").close_book()
	_check(_flow.request_shop() and not _flow.debug_trigger_anomaly(), "Anomaly Gate: shop blocks debug event")
	_hud.get_node("Shop").close_shop()
	_flow.progress.sonar_sessions = 0
	writes = _flow.save_manager.write_count
	for session in range(3):
		_check(_catch_to_result(), "Anomaly Timing: normal fishing session %d" % (session + 1))
		_check(not _flow.anomaly.active and not _flow.debug_trigger_anomaly(), "Anomaly Gate: CATCH cannot trigger")
		_step(1.8)
		_check(_flow.progress.sonar_sessions == session + 1 and not _flow.progress.anomaly_seen, "Anomaly Timing: count only completed sessions, defer until READY")
		if session < 2:
			_step(1.0 / 60)
			_check(not _flow.anomaly.active, "Anomaly Timing: first two sessions stay normal")
	_step(1.0 / 60)
	sonar = _hud.get_node("SonarPlaceholder")
	_check(_flow.anomaly.active and sonar.anomaly_active and not _flow.progress.anomaly_seen, "Anomaly Trigger: starts after third session, flag not yet saved")
	var node_count := get_node_count()
	var world_before: Vector2 = _fishes[0].position
	_step(0.3)
	_check(_flow.anomaly.active and sonar.anomaly_progress > 0 and sonar.anomaly_progress < 1 and _fishes[0].position != world_before and get_node_count() == node_count, "Anomaly: crosses sonar while ordinary fish keep swimming, no giant lake node")
	_check(not _flow.debug_trigger_anomaly() and not _flow.request_shop() and not _flow.request_book(), "Anomaly: duplicate trigger and modals cannot interrupt the short return")
	_step(0.31)
	_check(not _flow.anomaly.active and not sonar.anomaly_active and _flow.progress.anomaly_seen, "Anomaly: ends in 0.6s and immediately restores normal sonar")
	saved = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(saved.anomaly_seen == true and saved.sonar_sessions == 3, "Anomaly Save: completed flag persists")
	_check(_flow.request_cast() and _until_bite() and _flow.request_hook(), "Anomaly: ordinary fishing continues afterward")
	_step(0.32)
	_check(not _flow.debug_trigger_anomaly(), "Anomaly Gate: FIGHT disallows debug trigger")
	_finish_fight()
	_load_scene_at(path)
	_step(10)
	_check(_flow.progress.anomaly_seen and not _flow.anomaly.active and not _flow.debug_trigger_anomaly(), "Anomaly One-Time / Restore: restart cannot repeat the event")
	# Debug bypasses only the three-session delay; level/state/one-time guards remain.
	_new_scene()
	_check(not _flow.debug_trigger_anomaly(), "Debug Anomaly Trigger: Lv1 guard")
	_flow.progress.levels.sonar = 2
	_check(_flow.debug_trigger_anomaly() and _flow.progress.sonar_sessions == 0, "Debug Anomaly Trigger: Lv2 forced without waiting, no formal UI")
	_step(0.65)
	_check(_flow.progress.anomaly_seen and not _flow.debug_trigger_anomaly(), "Debug Anomaly Trigger: completes, saves, and remains one-time")
	# Responsive new UI and paused active casts at supported ratios and small preview.
	for spec in [[1280, 720, "16:9"], [1560, 720, "19.5:9"], [320, 180, "320px"]]:
		root.size = Vector2i(spec[0], spec[1])
		_new_scene()
		await process_frame
		await process_frame
		_hud.layout_in_safe_area(_lake.view_size, Rect2(36, 8, _lake.view_size.x - 72, _lake.view_size.y - 24), _lake.surface_y, 15)
		_check(_hud.safe_rect.encloses(_hud.get_node("BookButton").get_global_rect()) and _hud.safe_rect.encloses(_hud.get_node("SonarPlaceholder").get_global_rect()), spec[2] + ": book button/sonar inside safe area")
		_flow.request_cast()
		_step(1.5)
		var depth: float = _flow.lure.depth_m
		_touch(_hud.get_node("BookButton").get_global_rect().get_center())
		book = _hud.get_node("FishBook")
		await process_frame
		_check(book.visible and _hud.safe_rect.encloses(book.get_node("Panel").get_global_rect()), spec[2] + ": modal fits safe area")
		_check(book.get_node("Panel/Close").size.y * float(spec[1]) / _lake.view_size.y >= 44, spec[2] + ": 44 physical px close target")
		_step(3)
		_check(_flow.lure.depth_m == depth and not _flow.request_cast() and not _flow.request_shop(), spec[2] + ": existing cast freezes in book")
		_touch(book.get_node("Panel/Close").get_global_rect().get_center())
		_check(not paused and _until_bite() and _flow.request_hook() and _finish_fight(), spec[2] + ": book close resumes the same cast to CATCH")
	print("PHASE5_ACCEPTANCE ", JSON.stringify({"result": "PASS" if _failures.is_empty() else "FAIL", "checks": _checks, "failures": _failures, "save_version": SaveManager.VERSION, "anomaly_duration_s": SonarAnomaly.DURATION}))
	_main.queue_free()
	await process_frame
	for file_path: String in _paths:
		DirAccess.remove_absolute(file_path)
	DirAccess.remove_absolute(_test_save_path)
	quit(0 if _failures.is_empty() else 1)
