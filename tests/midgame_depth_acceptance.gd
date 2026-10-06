extends "res://tests/phase2_acceptance.gd"
## Isolated user:// fixtures; deep catches follow real CAST/detection/fight paths.
var _deep_cycles: Array[Dictionary] = []
var _seen: Dictionary = {}

func _land_deep() -> bool:
	var holding := true
	for tick in range(2400):
		if _flow.state == FLOW.State.LANDED:
			return true
		if _flow.state == FLOW.State.FAILED:
			return false
		if _flow.state == FLOW.State.FIGHTING:
			if _flow.fight.resistance == FishingFight.Resistance.RUN or _flow.fight.tension >= 76:
				holding = false
			elif _flow.fight.resistance != FishingFight.Resistance.RUN and _flow.fight.tension <= 45:
				holding = true
			_flow.set_reeling(holding)
		_step(1.0 / 60)
	return false

func _run() -> void:
	root.size = Vector2i(1280, 720)
	_new_scene()
	await process_frame
	await process_frame
	var progress: GameProgress = _flow.progress
	var expected := [[15,25,100,160,6000,18000,3], [20,30,35,60,8000,20000,4], [20,35,120,220,10000,28000,4], [30,40,18,28,12000,24000,5], [35,50,80,140,28000,60000,5]]
	_check(GameProgress.FISH_PROFILES.size() >= 10 and progress.fish_records.size() == GameProgress.FISH_PROFILES.size(), "Ten Resource fish and default records")
	var art_hashes: Dictionary = {}
	for i in range(5, 10):
		var profile: FishFightProfile = GameProgress.FISH_PROFILES[i]
		for key in range(4):
			expected[i-5][key] = float(expected[i-5][key])
		var values: Array = [profile.min_depth,profile.max_depth,profile.min_size_cm,profile.max_size_cm,profile.min_price,profile.max_price,profile.rarity]
		_check(values == expected[i-5] and profile.id == "No.%02d" % (i+1) and profile.stamina > 0 and not profile.description.is_empty(), profile.id + ": exact midgame data")
		_check(profile.sale_price(profile.min_size_cm) == profile.min_price and profile.sale_price(profile.max_size_cm) == profile.max_price, profile.id + ": bounded monotonic prices")
		var frame := RefinedPixelArt.fish_frames(profile.species_id).get_frame_texture("swim", 1)
		art_hashes[frame.get_image().get_data().hex_encode().sha256_text()] = true
	_check(art_hashes.size() == 5, "Five distinct normal / understated midgame sprites")
	_check(not _flow.select_depth_band(1) and not _flow.select_depth_band(2), "Initial line blocks inaccessible bands")
	for category: String in GameProgress.CATEGORIES:
		progress.levels[category] = 3
		_check(progress.next_level(category) == null and not progress.can_purchase(category, 4), "Lv4 hidden before No.10: " + category)
	progress.changed.emit()
	progress.anomaly_seen = true # Deterministic stress fixture; existing event separately regressed.
	var boat_anchor: Vector2 = _boat.anchor_position
	var sky_color: Color = _lake.profile.sky_top
	var background: Node2D = _lake.get_node("Underwater/WaterBackground")
	_check(background.color_at_depth(15).get_luminance() > background.color_at_depth(30).get_luminance() and background.color_at_depth(30).get_luminance() > background.color_at_depth(50).get_luminance() and background.color_at_depth(50).get_luminance() > 0.02, "Depth visual: descending luminance without black / red")
	for band in [1, 2, 0]:
		_check(_travel_for_band(band) and _flow.select_depth_band(band), "Select actual depth band %d" % band)
		_check(_boat.anchor_position == boat_anchor and _lake.profile.sky_top == sky_color and is_equal_approx(_lake.surface_y, 136), "Surface / boat / sky fixed across depth bands")
		for fish: FishController in _fishes:
			_check(fish.fight_profile.allows_depth(fish.depth_position) and fish.depth_position >= DepthBands.STARTS[band] and fish.depth_position <= DepthBands.ENDS[band], "Spawn restricted by habitat and band: " + fish.fight_profile.id)
	var nodes: int = get_node_count()
	var money_earned := 0
	var returns := 0
	var unknown_sales := 0
	var reached_50 := false
	for cycle in range(24):
		var band := 1 if cycle < 12 else 2
		if cycle == 0 or cycle == 12:
			_check(_travel_for_band(band) and _flow.select_depth_band(band), "Stress: select band " + str(band))
		var money_before: int = progress.money
		_check(_flow.request_cast(), "Deep %d: CAST" % cycle)
		_check(not _flow.request_cast() and not _flow.select_depth_band(0), "Deep cast: duplicate / depth change rejected")
		var bite := _until_bite(20)
		_check(bite, "Deep %d: natural BITE within 20s" % cycle)
		if not bite:
			print("DEBUG_STALL ", _flow.lure.depth_m, " ", _flow.seek_depth_m, " ", _flow.active_fish)
			break
		var fish: FishController = _flow.active_fish
		var bite_depth: float = _flow.lure.depth_m
		var id: String = fish.fight_profile.id
		_seen[id] = true
		reached_50 = reached_50 or is_equal_approx(bite_depth, 50)
		_check(fish.fight_profile.allows_depth(bite_depth) and bite_depth >= _flow.seek_depth_m, "BITE respects selected depth and habitat: " + id)
		_check(_flow.request_hook(), "Deep: HOOK")
		_check(not _flow.request_shop() and not _flow.request_book(), "Deep: hooked fish blocks modals")
		_check(_land_deep(), "Deep: guided REEL reaches CATCH: " + id)
		if _flow.state != FLOW.State.LANDED:
			break
		var result: Dictionary = _flow.last_catch.duplicate()
		var duration: float = _flow.cast_elapsed
		_deep_cycles.append({"id":id,"depth":bite_depth,"cycle_s":duration+1.7,"fight_s":_flow.fight.elapsed,"price":result.price})
		if id == "No.10":
			_check(progress.money == money_before, "No.10: CATCH does not auto-sell")
			_step(1.6)
			_check(_flow.state == FLOW.State.CHOOSING and _hud.get_node("CatchPanel/SellChoice").visible and _hud.get_node("CatchPanel/ReturnChoice").visible, "No.10: two large choices after normal CATCH")
			_step(8)
			_check(_flow.state == FLOW.State.CHOOSING and progress.money == money_before and not _flow.request_cast() and not _flow.request_shop() and not _flow.request_book() and not _flow.request_hook() and not _flow.set_reeling(true), "Choice has no timeout / input conflicts / auto-sale")
			var returning := returns == 0
			var count_before: int = progress.fish_records[id].caught_count
			_touch(_hud.get_node("CatchPanel/ReturnChoice" if returning else "CatchPanel/SellChoice").get_global_rect().get_center())
			_check(_flow.state == FLOW.State.RESET and not _flow.resolve_unknown_catch(not returning), "Choice: real touch; duplicate callback rejected")
			_check(progress.fish_records[id].caught_count == count_before + 1 and progress.fish_records[id].discovered and progress.fish_records[id].best_size_cm >= result.size_cm, "Choice updates discovery / count / BEST once")
			if returning:
				returns += 1
				_check(progress.money == money_before and progress.returned_unknown_a, "Return: no money; sticky returned_unknown_a")
			else:
				unknown_sales += 1
				_check(progress.money == money_before + result.price and progress.returned_unknown_a, "Sell: exact price once; earlier return flag retained")
			_step(0.25)
		else:
			_check(progress.money == money_before + result.price, "Normal deep fish still auto-sells")
			_step(1.8)
		money_earned += progress.money - money_before
		_check(_flow.state == FLOW.State.READY and not _flow.line.visible and not _flow.lure.visible and get_node_count() == nodes, "Stress: reset / no node leaks")
	_check(_deep_cycles.size() == 24 and _seen.size() == 5 and reached_50, "24 real deep catches, all No.06–10, actual 50m BITE")
	var average_cycle := 0.0
	for cycle: Dictionary in _deep_cycles:
		average_cycle += cycle.cycle_s / maxf(_deep_cycles.size(),1)
	_check(average_cycle >= 10 and average_cycle <= 20, "Deep guided average cycle: 10–20s")
	_check(returns == 1 and unknown_sales > 0, "Both No.10 choices naturally exercised")
	var book: Control = _hud.get_node("FishBook")
	_check(book.entries.size() == GameProgress.FISH_PROFILES.size() and _flow.request_book(), "Fish Book 1–10 opens")
	_check(book.entries["No.10"].text.contains("分類: 不明") and book.entries["No.10"].text.contains("BEST SIZE") and not _flow.request_cast() and not _flow.select_depth_band(0), "Unknown book: restrained classification, records, paused inputs")
	book.close_book()
	_check(not paused, "Book closes and resumes")
	_check(money_earned >= 90000 and progress.lv4_unlocked(), "High-value midgame enables rapid Lv4 progression")
	var expected_gear := {"rod":[90000,250.0],"reel":[75000,1.5],"line":[65000,85.0],"sonar":[120000,90.0]}
	for category: String in expected_gear:
		var item := progress.next_level(category)
		_check(item != null and item.level == 4 and item.price == expected_gear[category][0] and is_equal_approx(item.effect_value, expected_gear[category][1]), "Unlocked Lv4 exact Resource: " + category)
	var old_money: int = progress.money
	var unlocked: Array = []
	progress.depth_unlocked.connect(func(a: float,b: float): unlocked.append([a,b]))
	_check(progress.purchase("line",4) and progress.money == old_money - 65000 and unlocked == [[50.0,85.0]], "LINE4 purchase: 50m → 85m reward and exact deduction")
	_check(_travel_for_band(2) and progress.current("line").effect_value == 85 and _flow.lure.max_depth_m == 85 and not _flow.select_depth_band(6), "85m equipment retained; out-of-range band rejected")
	_check(not progress.purchase("line",4) and progress.next_level("line") == null, "No double purchase / level overflow")
	for category: String in ["rod","reel","sonar"]:
		var balance: int = progress.money
		_check(progress.purchase(category,4) and progress.levels[category] == 4 and progress.money == balance - expected_gear[category][0] and progress.next_level(category) == null, "Lv4 purchases immediately equip / debit / MAX: " + category)
	var restored := GameProgress.new()
	_check(_flow.save_manager.load_into(restored) and restored.money == progress.money and restored.levels == progress.levels and restored.fish_records == progress.fish_records and restored.returned_unknown_a and restored.anomaly_seen and restored.lv4_unlocked(), "Atomic save/load restores economy, Lv4, all records and flags")
	# Build a real legacy v1 fixture, verify read-only additive migration.
	var legacy: Dictionary = _flow.save_manager.snapshot(progress)
	legacy.erase("returned_unknown_a")
	legacy.line_level = 3
	legacy.rod_level = 2
	legacy.reel_level = 3
	legacy.sonar_level = 2
	legacy.fish_discovered["No.02"] = true
	legacy.fish_caught_count["No.02"] = 8
	legacy.fish_best_size["No.02"] = 44.2
	for id: String in ["No.06","No.07","No.08","No.09","No.10"]:
		for field: String in ["fish_discovered","fish_caught_count","fish_best_size"]:
			legacy[field].erase(id)
	var file := FileAccess.open(_test_save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var bytes_before := FileAccess.get_file_as_bytes(_test_save_path)
	var migrated := GameProgress.new()
	_check(_flow.save_manager.load_into(migrated) and migrated.money == progress.money and migrated.levels.line == 3 and not migrated.returned_unknown_a and not migrated.lv4_unlocked() and migrated.anomaly_seen, "Legacy v1: wallet / Lv3 / old anomaly survive, additive defaults")
	_check(migrated.fish_records["No.02"] == {"discovered":true,"caught_count":8,"best_size_cm":44.2} and migrated.levels.rod == 2 and migrated.levels.reel == 3 and migrated.levels.sonar == 2 and not migrated.fish_records["No.10"].discovered and migrated.fish_records["No.10"].caught_count == 0 and bytes_before == FileAccess.get_file_as_bytes(_test_save_path), "Migration: old records preserved; new records unknown; no read-time rewrite")
	var sonar: SonarDisplay = _hud.get_node("SonarPlaceholder")
	for level in [1,2,3,4]:
		progress.levels.sonar = level
		sonar.refresh_contacts()
		for contact: Dictionary in sonar.contacts:
			_check(contact.depth_m <= sonar.max_depth(), "Sonar obeys equipment depth")
			var actual: FishController = instance_from_id(contact.instance_id)
			if actual.fight_profile.id == "No.10":
				_check(contact.name_text == ("???" if level >= 3 else "") and contact.dot_width == 8, "No.10 stays UNKNOWN even discovered / higher sonar")
	for dimension in [Vector2i(640,360),Vector2i(1280,720),Vector2i(1560,720),Vector2i(1600,720)]:
		root.size = dimension
		await process_frame
		await process_frame
		for name: String in ["CastButton","ReelButton","DepthBandButton","SonarPlaceholder","ShopButton","BookButton"]:
			_check(_hud.safe_rect.encloses(_hud.get_node(name).get_global_rect()), "%s: safe-area %s" % [dimension,name])
		_hud.show_unknown_choice(true)
		_check(_hud.safe_rect.encloses(_hud.get_node("CatchPanel").get_global_rect()), "%s: complete choice panel fits" % dimension)
		for name: String in ["SellChoice","ReturnChoice"]:
			_check(_hud.get_node("CatchPanel/"+name).size.y * float(root.size.y) / _hud.size.y >= 44, "%s: choice 44px+" % dimension)
		_hud.show_unknown_choice(false)
	print("MIDGAME_ACCEPTANCE ",JSON.stringify({"result":"PASS" if _failures.is_empty() else "FAIL","checks":_checks,"failures":_failures,"deep_catches":_deep_cycles,"money_earned":money_earned,"species":_seen.keys(),"returns":returns,"unknown_sales":unknown_sales}))
	_main.free()
	DirAccess.remove_absolute(_test_save_path)
	quit(0 if _failures.is_empty() else 1)
