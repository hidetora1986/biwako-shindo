extends "res://tests/midgame_depth_acceptance.gd"
## Real late casts plus isolated v1 saves, event timing and purchase/return guards.
var _late_cycles: Array[Dictionary] = []
var _late_seen: Dictionary = {}
var _pre5_unknown: bool = false

func _step(seconds: float) -> void:
	for tick in range(int(ceil(seconds*60))):
		super._step(1.0/60)
		if not paused:
			_hud.get_node("SonarPlaceholder")._process(1.0/60)

func _session() -> bool:
	var before_money: int = _flow.progress.money
	if not _flow.request_cast() or not _until_bite(25):
		return false
	var profile: FishFightProfile = _flow.active_fish.fight_profile
	var depth: float = _flow.lure.depth_m
	_check(profile.allows_depth(depth), "Late BITE within habitat: "+profile.id)
	_late_seen[profile.id] = true
	if profile.id == "No.14" and _flow.progress.levels.line == 4:
		_pre5_unknown = depth >= 80 and depth <= 85
	_check(_flow.request_hook(), "Late HOOK: "+profile.id)
	_check(not _flow.select_depth_band(0) and not _flow.request_shop() and not _flow.request_book(), "Late fight blocks modal / band changes")
	if not _land_deep():
		return false
	var result: Dictionary = _flow.last_catch.duplicate()
	_late_cycles.append({"id":profile.id,"depth":depth,"fight_s":_flow.fight.elapsed,"cycle_s":_flow.cast_elapsed+1.7,"price":result.price})
	if profile.id == "No.14":
		var fish: FishController = _flow.active_fish
		var sonar: SonarDisplay = _hud.get_node("SonarPlaceholder")
		sonar.refresh_contacts()
		_check(not fish.visible and sonar.lingering_remaining > 1.4 and sonar.lingering_contact.instance_id == fish.get_instance_id(), "No.14 hidden body / same instance sonar retained")
		_check(_flow.progress.money == before_money, "No.14 never auto-sells")
		_step(1.0)
		_check(sonar.lingering_remaining > 0.45, "No.14 echo persists 1.0s")
		_step(0.65)
		_check(sonar.lingering_contact.is_empty() and sonar.lingering_remaining == 0 and _flow.state == FLOW.State.CHOOSING, "Echo disappears by 1.65s; normal choice shown")
		_check(not _flow.request_cast() and not _flow.request_hook() and not _flow.request_shop() and not _flow.request_book() and not _flow.set_reeling(true), "No.14 choice isolates all input")
		var first_return: bool = not _flow.progress.returned_unknown_b
		var old_count: int = _flow.progress.fish_records[profile.id].caught_count
		var old_a: bool = _flow.progress.returned_unknown_a
		_touch(_hud.get_node("CatchPanel/ReturnChoice" if first_return else "CatchPanel/SellChoice").get_global_rect().get_center())
		_check(_flow.state == FLOW.State.RESET and not _flow.resolve_unknown_catch(not first_return), "No.14 real touch, exactly one transaction")
		_check(_flow.progress.fish_records[profile.id].caught_count == old_count+1 and _flow.progress.fish_records[profile.id].discovered and _flow.progress.lv5_unlocked(), "No.14 records + Lv5 unlock on either choice")
		_check(_flow.progress.returned_unknown_b and _flow.progress.returned_unknown_a == old_a and _flow.progress.money == before_money + (0 if first_return else result.price), "Return B flag sticky; A unaffected; exact choice money")
		_step(0.25)
	else:
		_check(_flow.progress.money == before_money + result.price, "No.11–13 auto-sell still atomically credits")
		_step(1.8)
	return _flow.state == FLOW.State.READY

func _run() -> void:
	root.size = Vector2i(1280,720)
	_new_scene()
	await process_frame
	await process_frame
	var progress: GameProgress = _flow.progress
	_check(GameProgress.FISH_PROFILES.size() == 14 and _hud.get_node("FishBook").entries.size() == 14, "Fourteen Resource fish / book entries")
	_check(not progress.night_unlocked and progress.hull_knock_count == 0 and not progress.returned_unknown_b and not progress.zero_depth_contact_seen, "New game: all new flags default")
	var values := [[50.0,65.0,90.0,160.0,40000,95000,5],[60.0,75.0,110.0,180.0,55000,120000,5],[70.0,85.0,130.0,210.0,80000,180000,5],[80.0,100.0,180.0,260.0,180000,420000,6]]
	var hashes: Dictionary = {}
	for index in range(10,14):
		var profile: FishFightProfile = GameProgress.FISH_PROFILES[index]
		_check([profile.min_depth,profile.max_depth,profile.min_size_cm,profile.max_size_cm,profile.min_price,profile.max_price,profile.rarity] == values[index-10], profile.id+": exact data")
		_check(profile.sale_price(profile.min_size_cm) == profile.min_price and profile.sale_price(profile.max_size_cm) == profile.max_price, profile.id+": exact price bounds")
		var texture := RefinedPixelArt.fish_frames(profile.species_id).get_frame_texture("swim",0)
		hashes[texture.get_image().get_data().hex_encode().sha256_text()] = true
		var model := FishingFight.new()
		model.start(profile,1.5,250,(profile.min_size_cm+profile.max_size_cm)/2)
		var holding := true
		var warnings := 0
		var recoveries := 0
		for tick in range(1800):
			if model.resistance == FishingFight.Resistance.RUN or model.tension >= 76:
				holding = false
			elif model.resistance != FishingFight.Resistance.RUN and model.tension <= 45:
				holding = true
			var before := model.stamina
			var previous := model.resistance
			model.reeling = holding
			model.step(1.0/60)
			if model.resistance == FishingFight.Resistance.WARNING and previous != model.resistance:
				warnings += 1
			if model.stamina > before:
				recoveries += 1
			if model.landed or model.failure != "": break
		var minimum: float = [8.0,9.0,10.0,12.0][index-10]
		var maximum: float = [14.0,15.0,16.0,20.0][index-10]
		_check(model.landed and model.elapsed >= minimum and model.elapsed <= maximum and warnings > 0, profile.id+": target fight window / RUN warning")
		_check(recoveries == (1 if profile.id == "No.12" else 0), profile.id+": only No.12 restores stamina once")
	_check(hashes.size() == 4, "Four distinct original unusual silhouettes")
	var background: Node2D = _lake.get_node("Underwater/WaterBackground")
	var previous_light := 1.0
	for depth in [50.0,65.0,85.0,100.0]:
		var color: Color = background.color_at_depth(depth)
		var light := color.get_luminance()
		_check(light < previous_light and light > 0.07, "Deep navy darkens without black at %dm" % depth)
		previous_light = light
	for category: String in GameProgress.CATEGORIES:
		_check(not progress.can_purchase(category,5), "Lv5 locked initially: "+category)
	# Represents a real midgame save: No.10 found, returned, all Lv4, no granted cash.
	progress.record_catch(GameProgress.FISH_PROFILES[9],112.4,false)
	progress.returned_unknown_a = true
	progress.levels = {"rod":4,"reel":4,"line":4,"sonar":4}
	progress.anomaly_seen = true
	progress.changed.emit()
	_check(_flow.lure.max_depth_m == 85 and not _flow.select_depth_band(5), "LINE4 allows 85m, blocks >85m band before Lv5")
	_check(_hud.get_node("NextUpgrade").text == "NEXT UPGRADE LOCKED" and _hud.get_node("Shop")._buttons.line.text == "LOCKED", "Locked Lv5 never mislabeled as MAX")
	var nodes: int = get_node_count()
	_check(_flow.select_depth_band(3), "50–65m select")
	var spawned: Dictionary = {}
	var rare_casts := 0
	for cast in range(1,25):
		_lake.populate_depth_band(4,85,cast)
		var seen_b := false
		for fish: FishController in _fishes:
			_check(fish.depth_position >= 65 and fish.depth_position <= 85 and fish.fight_profile.allows_depth(fish.depth_position), "Spawn: band + line + species limits")
			spawned[fish.fight_profile.id] = true
			seen_b = seen_b or fish.fight_profile.id == "No.14"
			if fish.fight_profile.id == "No.14":
				_check(fish.depth_position >= 80 and fish.depth_position <= 85, "No.14 spawns before Lv5 at 80–85m")
		if seen_b: rare_casts += 1
	_check(rare_casts > 0 and rare_casts < 16, "No.14 is uncommon across deterministic pre-Lv5 spawn samples")
	_check(_flow.select_depth_band(3), "Return to actual late fishing")
	for index in range(6):
		_check(_session(), "Natural late 50–65m session %d" % index)
		if _flow.state != FLOW.State.READY: break
		if index == 0:
			_check(_flow.environment.target == 1 and _flow.environment.value > 0 and _flow.environment.value < 1, "First No.11 begins a gradual sunset")
		_step(0.02)
	_check(_late_seen.has("No.11") and _late_seen.has("No.12") and progress.night_unlocked and _flow.environment.target == 2, "Real No.11/12 catches unlock sunset/night")
	_step(15)
	_check(is_equal_approx(_flow.environment.value,2) and _lake.profile.sky_top.is_equal_approx(Color("16283f")), "Smooth night reaches dark navy without blackout")
	_check(progress.hull_knock_count == 2 and _flow.hull_events.completed_stages == [1,2] and _flow.hull_events.strike_count == 3, "Knock 1 and 2: staged sequence and exact 1+2 strikes")
	_check(_flow.select_depth_band(4), "65–85m select")
	for index in range(12):
		_check(_session(), "Natural pre-Lv5 deep session %d" % index)
		if _flow.state != FLOW.State.READY: break
		_step(0.02)
		if _pre5_unknown and progress.fish_records["No.13"].discovered: break
	_check(_late_seen.has("No.13") and _pre5_unknown, "Natural No.13 and No.14 reached with LINE4; no unlock deadlock")
	_step(8)
	_check(progress.hull_knock_count == 3 and _flow.hull_events.completed_stages == [1,2,3] and _flow.hull_events.strike_count == 6, "Knock 3: exact three regular strikes / 0→3 completed")
	_check(progress.zero_depth_contact_seen and not _hud.get_node("SonarPlaceholder").zero_contact_active, "0.0m contact completes once, normal sonar restored")
	var events_before: int = _flow.hull_events.strike_count
	var writes_before: int = _flow.save_manager.write_count
	_step(20)
	_check(_flow.hull_events.strike_count == events_before and _flow.save_manager.write_count == writes_before, "Completed events never repeat / idle File IO zero")
	var sonar: SonarDisplay = _hud.get_node("SonarPlaceholder")
	for level in [4,5]:
		progress.levels.sonar = level
		sonar.refresh_contacts()
		var found_b := false
		for contact: Dictionary in sonar.contacts:
			var fish: FishController = instance_from_id(contact.instance_id)
			if fish.fight_profile.id == "No.14":
				found_b = true
				_check(contact.name_text == "???" and contact.dot_width == 16 and contact.dot_width < 40, "No.14 UNKNOWN / bigger than No.10 / smaller than transient anomaly")
		_check(found_b, "No.14 actual sonar contact at Lv%d" % level)
	progress.levels.sonar = 4
	# Dedicated event fixture verifies exact spacing, guards, autosaves and no replay.
	var events_progress := GameProgress.new()
	events_progress.record_catch(GameProgress.FISH_PROFILES[10],120,false)
	events_progress.levels.sonar = 4
	var owner_node := Node.new()
	root.add_child(owner_node)
	var events := HullEvents.new()
	events.setup(events_progress,_boat,sonar,owner_node)
	var event_save := SaveManager.new(_test_save_path+"-events")
	event_save.bind_progress(events_progress)
	events.step(4,false,1.0)
	_check(not events.active and events.strike_count == 0, "Knocks do not start outside idle/waiting")
	events.step(0.01,true,1.0)
	_check(events.active and events.strike_count == 1 and _boat._knock_remaining > 0 and events._audio.stream is AudioStreamWAV, "Knock 1: low generated sound / 1–2px boat micro-motion")
	events.step(0.21,true,1.0)
	events.step(8,true,2.0)
	_check(events_progress.hull_knock_count == 1 and events.strike_count == 1, "Knock 2 blocked before No.12")
	events_progress.record_catch(GameProgress.FISH_PROFILES[11],130,false)
	events_progress.max_depth_reached_m = 59.9
	events.step(5,true,2.0)
	_check(not events.active, "Knock 2 requires reached 60m")
	events_progress.max_depth_reached_m = 60
	events.step(3.1,true,2.0)
	events.step(0.3,true,2.0)
	_check(events.strike_count == 2 and events_progress.hull_knock_count == 1, "Knock 2: gap before second beat")
	events.step(0.36,true,2.0)
	events.step(0.21,true,2.0)
	_check(events.strike_count == 3 and events_progress.hull_knock_count == 2, "Knock 2 completes only after two beats")
	events_progress.record_catch(GameProgress.FISH_PROFILES[12],160,false)
	events_progress.max_depth_reached_m = 69.9
	events.step(5,true,2.0)
	_check(not events.active, "Knock 3 requires reached 70m")
	events_progress.max_depth_reached_m = 70
	events.step(3.1,true,2.0)
	events.step(0.31,true,2.0)
	events.step(0.30,true,2.0)
	events.step(0.21,true,2.0)
	_check(events.strike_count == 6 and events_progress.hull_knock_count == 3, "Knock 3 has three equally spaced strikes")
	events_progress.levels.sonar = 3
	events.step(5,true,2.0)
	_check(not events.zero_active, "0m contact requires Sonar4")
	events_progress.levels.sonar = 4
	events.step(5,true,1.0)
	_check(not events.zero_active, "0m contact requires night")
	events.step(3.1,true,2.0)
	_check(events.zero_active and sonar.zero_contact_active and not events_progress.zero_depth_contact_seen, "0m contact begins without text or fish node")
	events.step(0.4,true,2.0)
	_check(events.zero_active and not events_progress.zero_depth_contact_seen, "0m contact lasts at least 0.4s")
	events.step(0.21,true,2.0)
	_check(not events.active and not sonar.zero_contact_active and events_progress.zero_depth_contact_seen and event_save.write_count == 4, "0m ends in 0.4–0.8s; exactly four event-end saves")
	events.step(10,true,2.0)
	_check(events.strike_count == 6 and event_save.write_count == 4, "No event replays / no idle writes")
	event_save.unbind_progress()
	owner_node.free()
	DirAccess.remove_absolute(event_save.save_path)
	var expected := {"rod":[420000,500.0,"深淵ロッド"],"reel":[360000,1.7,"ABYSS 8000"],"line":[300000,120.0,"深海ライン"],"sonar":[500000,120.0,"ABYSS SCAN"]}
	for category: String in expected:
		var item := progress.next_level(category)
		_check(item != null and item.level == 5 and item.price == expected[category][0] and is_equal_approx(item.effect_value,expected[category][1]) and item.display_name == expected[category][2], "Lv5 exact unlocked data: "+category)
	var unlocked: Array = []
	progress.depth_unlocked.connect(func(a:float,b:float):unlocked.append([a,b]))
	var balance: int = progress.money
	_check(progress.purchase("line",5) and progress.money == balance-300000 and unlocked == [[85.0,120.0]], "Natural late income buys LINE5; 85→120m reward")
	_check(_hud.get_node("DepthUnlock/Label").text.contains("85m → 120m") and _flow.lure.max_depth_m == 100, "Visible 120m unlock / current fish cap 100m")
	_check(_flow.select_depth_band(5), "85–100m now accessible")
	for index in range(8):
		_check(_session(), "Natural >85m No.14 session %d" % index)
		if _flow.state != FLOW.State.READY: break
	_check(_flow.progress.returned_unknown_b and _late_cycles.any(func(cycle:Dictionary)->bool:return is_equal_approx(cycle.depth,100)), "Late casts reach >85m including 100m")
	for category: String in ["rod","reel","sonar"]:
		var before: int = progress.money
		_check(progress.purchase(category,5) and progress.money == before-expected[category][0] and progress.current(category).level == 5 and progress.next_level(category) == null, "Earned money buys / equips / MAX: "+category)
	_check(_hud.get_node("NextUpgrade").text == "ALL EQUIPMENT MAX" and _hud.get_node("Shop")._buttons.line.text == "MAX", "Actual Lv5 maximum still shown as MAX")
	var reloaded := GameProgress.new()
	_check(_flow.save_manager.load_into(reloaded) and reloaded.money == progress.money and reloaded.levels == progress.levels and reloaded.fish_records == progress.fish_records and reloaded.returned_unknown_a and reloaded.returned_unknown_b and reloaded.night_unlocked and reloaded.hull_knock_count == 3 and reloaded.zero_depth_contact_seen, "Save/load restores all old/new progress and flags")
	var old: Dictionary = _flow.save_manager.snapshot(progress)
	for field: String in ["returned_unknown_b","night_unlocked","hull_knock_count","zero_depth_contact_seen","max_depth_reached_m"]: old.erase(field)
	for category: String in GameProgress.CATEGORIES: old[category+"_level"] = 4
	for id: String in ["No.11","No.12","No.13","No.14"]:
		for field: String in ["fish_discovered","fish_caught_count","fish_best_size"]: old[field].erase(id)
	var file := FileAccess.open(_test_save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(old)); file.close()
	var bytes := FileAccess.get_file_as_bytes(_test_save_path)
	var migrated := GameProgress.new()
	_check(_flow.save_manager.load_into(migrated) and migrated.money == progress.money and migrated.levels.line == 4 and migrated.returned_unknown_a and not migrated.returned_unknown_b and not migrated.night_unlocked and migrated.hull_knock_count == 0 and not migrated.zero_depth_contact_seen and not migrated.lv5_unlocked(), "Midgame v1 migration preserves money/Lv4/A; late defaults safe")
	_check(migrated.fish_records["No.10"] == progress.fish_records["No.10"] and not migrated.fish_records["No.14"].discovered and bytes == FileAccess.get_file_as_bytes(_test_save_path), "Old records intact / No.11–14 undiscovered / read does not rewrite")
	var invalid := old.duplicate(true)
	invalid.merge({"returned_unknown_b":"true","night_unlocked":1,"hull_knock_count":4,"zero_depth_contact_seen":1,"max_depth_reached_m":101},true)
	file = FileAccess.open(_test_save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(invalid)); file.close()
	var invalid_progress := GameProgress.new()
	_check(_flow.save_manager.load_into(invalid_progress) and invalid_progress.money == progress.money and invalid_progress.returned_unknown_a and not invalid_progress.returned_unknown_b and not invalid_progress.night_unlocked and invalid_progress.hull_knock_count == 0 and not invalid_progress.zero_depth_contact_seen and invalid_progress.max_depth_reached_m == 0, "Invalid late fields fall back without resetting existing money or A")
	for dimension in [Vector2i(640,360),Vector2i(1280,720),Vector2i(1560,720),Vector2i(1600,720)]:
		root.size = dimension
		await process_frame; await process_frame
		for name: String in ["CastButton","ReelButton","DepthBandButton","SonarPlaceholder","ShopButton","BookButton"]:
			_check(_hud.safe_rect.encloses(_hud.get_node(name).get_global_rect()), "%s late UI safe: %s" % [dimension,name])
		_hud.show_unknown_choice(true)
		_check(_hud.safe_rect.encloses(_hud.get_node("CatchPanel").get_global_rect()), "%s choice panel fits" % dimension)
		_hud.show_unknown_choice(false)
	_check(get_node_count() == nodes and _late_seen.size() == 4, "Repeated real late sessions keep four species / node count stable")
	print("LATEGAME_ACCEPTANCE ",JSON.stringify({"result":"PASS" if _failures.is_empty() else "FAIL","checks":_checks,"failures":_failures,"cycles":_late_cycles,"pre_lv5_unknown":_pre5_unknown,"rare_casts":rare_casts,"knock_strikes":_flow.hull_events.strike_count,"night":_flow.environment.value}))
	_main.free(); DirAccess.remove_absolute(_test_save_path)
	quit(0 if _failures.is_empty() else 1)
