extends "res://tests/phase5_acceptance.gd"
## Full real fishing flow, viewport input, transactions and cold-scene restoration.
## Uses an isolated user:// test save; no grants in the twenty-catch economy loop.
var _cycles: Array[float] = []
var _fight_times: Array[float] = []
var _purchases: Array[String] = []
var _first_upgrade: int = 0
var _anomaly_completed: bool = false

func _advance(seconds: float) -> void:
	for tick in range(int(ceil(seconds * 60))):
		_step(1.0 / 60)
		# Match the always-processing modal reward and sampled sonar as well.
		_hud.get_node("DepthUnlock")._process(1.0 / 60)
		if not paused:
			_hud.get_node("SonarPlaceholder")._process(1.0 / 60)

func _buy_next(category: String, catch_number: int) -> void:
	var next: Resource = _flow.progress.next_level(category)
	if next == null or not _flow.progress.can_purchase(category, next.level):
		return
	_check(_flow.request_shop(), "Shop: one-tap modal after catch %d" % catch_number)
	var shop: Control = _hud.get_node("Shop")
	var previous_money: int = _flow.progress.money
	var old_level: int = _flow.progress.levels[category]
	var writes: int = _flow.save_manager.write_count
	_check(shop._buy(category), "Purchase: sufficient balance / immediate equip " + category)
	_check(_flow.progress.money == previous_money - next.price and _flow.progress.levels[category] == old_level + 1 and _flow.save_manager.write_count == writes + 1, "Purchase: exactly one deduction, level and save")
	_check(not shop._buy(category), "Purchase: duplicate tap blocked during reward")
	var notice: Panel = _hud.get_node("DepthUnlock")
	_check(notice.visible and notice.get_node("Label").text.contains("DEPTH UNLOCKED" if category == "line" else "UPGRADE!"), "Upgrade: visible short reward")
	_advance(1.3)
	shop.close_shop()
	_check(not paused and _flow.state == FLOW.State.READY, "Shop: close restores input / no new bite")
	_purchases.append(category)
	if _first_upgrade == 0:
		_first_upgrade = catch_number

func _session(number: int) -> void:
	var count: int = get_node_count()
	var before_money: int = _flow.progress.money
	_touch(_hud.get_node("CastButton").get_global_rect().get_center())
	_touch(_hud.get_node("CastButton").get_global_rect().get_center(), 0, false)
	_check(_flow.state == FLOW.State.CASTING and _flow.lure.visible and _flow.line.visible, "Cycle %d: immediate CAST feedback" % number)
	_check(not _flow.request_cast() and not _flow.request_shop(), "Cycle %d: cast spam / shop during flight blocked" % number)
	var elapsed := 0.0
	var fight_time := 0.0
	var approach_time := 0.0
	var catch_time := 0.0
	var caught := false
	var holding := true
	var saw_bite := false
	for tick in range(1800):
		if _flow.active_fish != null and _flow.active_fish.state == FishController.SwimState.APPROACH_LURE:
			approach_time += 1.0 / 60
		if _flow.state == FLOW.State.BITTEN:
			saw_bite = true
			_check(not _flow.request_book() and _hud.get_node("Bite").visible, "Cycle %d: bite cue / modal guard" % number)
			_touch(Vector2(560, 180))
			_touch(Vector2(560, 180), 0, false)
			_check(_flow.state == FLOW.State.HOOKED and not _flow.request_hook(), "Cycle %d: broad hook / duplicate guard" % number)
		if _flow.state == FLOW.State.FIGHTING:
			fight_time += 1.0 / 60
			if _flow.fight.resistance == FishingFight.Resistance.RUN or _flow.fight.tension >= 76:
				holding = false
			elif _flow.fight.resistance != FishingFight.Resistance.RUN and _flow.fight.tension <= 45:
				holding = true
			var point: Vector2 = _hud.get_node("ReelButton").get_global_rect().get_center()
			if holding and not _flow.fight.reeling:
				_touch(point, 7)
			elif not holding and _flow.fight.reeling:
				_touch(point, 7, false)
			if tick == 400:
				_check(not _flow.request_shop() and not _flow.request_book(), "Fight modal guard")
		if _flow.state == FLOW.State.LANDED:
			if not caught:
				caught = true
				_check(_flow.progress.money == before_money + _flow.last_catch.price and _hud.get_node("CatchPanel").visible, "Cycle %d: automatic sale / catch result" % number)
				_check(not _flow.request_cast() and not _flow.set_reeling(true), "Cycle %d: catch inputs blocked" % number)
			catch_time += 1.0 / 60
		if _flow.state == FLOW.State.READY:
			break
		if _flow.state == FLOW.State.FAILED:
			break
		_advance(1.0 / 60)
		elapsed += 1.0 / 60
	_check(caught and saw_bite and _flow.state == FLOW.State.READY, "Cycle %d: full CAST → HIT → FIGHT → CATCH → CAST" % number)
	_check(elapsed <= 20 and fight_time <= 10 and approach_time <= 4 and catch_time >= 1.2 and catch_time <= 1.8, "Cycle %d: tempo / fight / approach / short result" % number)
	_check(get_node_count() == count and _flow.active_fish == null and not _flow.line.visible and _flow._reel_owner == -1, "Cycle %d: stable node count / reusable lure / released pointer" % number)
	_cycles.append(elapsed)
	_fight_times.append(fight_time)
	_advance(0.7) # Also completes the sole 0.6s sonar event between sessions.
	_anomaly_completed = _anomaly_completed or _flow.progress.anomaly_seen

func _failure_session(message: String) -> void:
	var balance: int = _flow.progress.money
	_check(_flow.request_cast() and _until_bite() and _flow.request_hook(), "Failure path: natural cast / bite / hook")
	_advance(0.35)
	if message == "LINE BREAK":
		# Boundary fixture: verify the grace at 99, rather than instant failure.
		_flow.fight.tension = 99
		_flow.set_reeling(true)
		_advance(0.3)
		_check(_flow.state == FLOW.State.FIGHTING, "Line Break: brief danger has grace")
	else:
		_flow.set_reeling(false)
	for tick in range(600):
		if _flow.state == FLOW.State.FAILED:
			break
		_advance(1.0 / 60)
	_check(_flow.state == FLOW.State.FAILED and _hud.get_node("Result").text == message, "Failure path: " + message)
	_check(not _flow.request_cast() and not _flow.set_reeling(true), "Failure path: input blocked")
	_advance(1.6)
	_check(_flow.state == FLOW.State.READY and _flow.progress.money == balance and _flow.active_fish == null, "Failure path: reset without sale / stale fish")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	_new_scene()
	await process_frame
	await process_frame
	var path := _test_save_path
	for number in range(1, 21):
		_session(number)
		if number % 2 == 0:
			_touch(_hud.get_node("BookButton").get_global_rect().get_center())
			_check(paused and not _flow.request_cast() and not _flow.request_shop() and not _flow.set_reeling(true), "Book: modal blocks all other input")
			var writes: int = _flow.save_manager.write_count
			_advance(2)
			_check(_flow.save_manager.write_count == writes, "Book: no frame file I/O")
			_touch(_hud.get_node("FishBook/Panel/Close").get_global_rect().get_center())
			_check(not paused, "Book: one-tap close resumes")
		if _flow.progress.levels.line == 1:
			_buy_next("line", number)
		elif _flow.progress.levels.reel == 1:
			_buy_next("reel", number)
		elif _flow.progress.levels.sonar == 1:
			_buy_next("sonar", number)
		elif _flow.progress.levels.rod == 1:
			_buy_next("rod", number)
	_check(_first_upgrade >= 1 and _first_upgrade <= 3 and _flow.progress.levels.line == 2, "Upgrade Tempo: LINE Lv2 within first three real catches")
	_check(_purchases.size() == 4 and _anomaly_completed, "Economy / Equipment / Anomaly: all four upgrades, event after three sessions")
	var money: int = _flow.progress.money
	var levels: Dictionary = _flow.progress.levels.duplicate()
	var records: Dictionary = _flow.progress.fish_records.duplicate(true)
	var writes: int = _flow.save_manager.write_count
	_advance(30)
	_check(_flow.save_manager.write_count == writes, "Performance: 1,800 idle frames perform zero file writes")
	_load_scene_at(path)
	await process_frame
	await process_frame
	_check(_flow.progress.money == money and _flow.progress.levels == levels and _flow.progress.fish_records == records and _flow.progress.anomaly_seen, "Save / Load: fresh scene restores money / gear / twenty records / anomaly")
	_check(not _flow.debug_trigger_anomaly(), "Anomaly: saved flag prevents debug and normal repetition")
	_failure_session("LINE BREAK")
	_failure_session("ESCAPED")
	_session(21) # Successful full loop after both failures and a cold-scene load.
	var sonar: SonarDisplay = _hud.get_node("SonarPlaceholder")
	sonar.refresh_contacts()
	_check(sonar.contacts.size() == 7 and not sonar.contacts[0].size_text.is_empty(), "Sonar: actual seven fish / Lv2 readable size data")
	for dimension in [Vector2i(640, 360), Vector2i(1560, 720), Vector2i(1600, 720)]:
		root.size = dimension
		await process_frame
		await process_frame
		_hud.layout_in_safe_area(_lake.view_size, Rect2(28, 6, _lake.view_size.x - 56, _lake.view_size.y - 18), _lake.surface_y, 15)
		for node_name in ["CastButton", "ReelButton", "ShopButton", "BookButton", "SonarPlaceholder"]:
			var control: Control = _hud.get_node(node_name)
			_check(_hud.safe_rect.encloses(control.get_global_rect()), "%s: %s inside simulated notch / home inset" % [dimension, node_name])
			if node_name != "SonarPlaceholder":
				_check(control.size.y * float(dimension.y) / _lake.view_size.y >= 44, "%s: %s ≥44px physical touch target" % [dimension, node_name])
		_check(not _hud.get_node("BookButton").get_global_rect().intersects(sonar.get_global_rect()), "%s: book and readable sonar do not overlap" % dimension)
		_check(_flow.request_shop(), "Shop opens after aspect change")
		await process_frame
		await process_frame
		var shop: Control = _hud.get_node("Shop")
		var rows_fit := true
		for category: String in shop._buttons:
			rows_fit = rows_fit and shop.get_node("Panel/Scroll").get_global_rect().encloses(shop._buttons[category].get_global_rect())
		_check(rows_fit, "%s: all four shop categories visible without scrolling" % dimension)
		shop.close_shop()
	# Future unlocked depths remain fast, independent of the current 15m art scene.
	var lure := LureController.new()
	root.add_child(lure)
	lure.configure_water(Rect2(0, 100, 640, 220), 100, 50)
	lure.max_depth_m = 50
	lure.state = LureController.State.SINKING
	var sinking := 0.0
	var ten_m_time := 0.0
	while lure.state == LureController.State.SINKING and sinking < 12:
		lure._physics_process(1.0 / 60)
		sinking += 1.0 / 60
		if ten_m_time == 0 and lure.depth_m >= 10:
			ten_m_time = sinking
	_check(ten_m_time >= 4 and ten_m_time <= 6 and sinking <= 9 and lure.depth_m == 50, "Sinking: initial 10m in 4–6s; future 50m not a proportional wait")
	lure.free()
	print("MVP_ACCEPTANCE ", JSON.stringify({"result": "PASS" if _failures.is_empty() else "FAIL", "checks": _checks, "failures": _failures, "real_catches": _cycles.size(), "cycle_seconds": _cycles, "fight_seconds": _fight_times, "first_upgrade_catch": _first_upgrade, "purchases": _purchases, "future_50m_sink_s": sinking}))
	_main.free()
	DirAccess.remove_absolute(path)
	quit(0 if _failures.is_empty() else 1)
