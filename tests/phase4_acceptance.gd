extends "res://tests/phase2_acceptance.gd"
## Formal data, real catch/sale/purchase sessions and paused mobile shop input.
var _economy_catches: Array[Dictionary] = []

func _run() -> void:
	root.size = Vector2i(1280, 720)
	_new_scene()
	await process_frame
	await process_frame
	var state: GameProgress = _flow.progress
	_check(state.money == 0 and _hud.get_node("Money/Label").text == "¥0", "Money: starts at zero")
	var expected := {
		"bluegill": ["No.01", 0, 5, 12, 22, 200, 450, 20],
		"bass": ["No.02", 0, 10, 25, 55, 700, 2000, 40],
		"crucian": ["No.03", 0, 8, 18, 35, 300, 800, 30],
		"catfish": ["No.04", 5, 15, 45, 85, 1200, 3800, 60],
		"biwamasu": ["No.05", 8, 15, 30, 50, 2200, 5200, 50]}
	var species_found: Dictionary = {}
	for fish: FishController in _fishes:
		species_found[fish.fight_profile.species_id] = true
		_check(fish.fight_profile.allows_depth(fish.depth_position), "Habitat: " + fish.name + " spawns at species depth")
	_check(species_found.size() == 5, "5 Fish Species: all formal species spawn")
	var rng := RandomNumberGenerator.new()
	rng.seed = 425
	for species: String in expected:
		var profile: FishFightProfile = load("res://data/fish/%s-fight.tres" % species)
		var values: Array = expected[species]
		for key in [1, 2, 3, 4, 7]:
			values[key] = float(values[key])
		_check([profile.id, profile.min_depth, profile.max_depth, profile.min_size_cm, profile.max_size_cm, profile.min_price, profile.max_price, profile.stamina] == values and not profile.description.is_empty() and profile.pull_power > 0, "Fish Data: " + species + " exact specification")
		_check(profile.sale_price(profile.min_size_cm) == profile.min_price and profile.sale_price(profile.max_size_cm) == profile.max_price and profile.sale_price(-100) == profile.min_price and profile.sale_price(1000) == profile.max_price, "Price bounds: " + species)
		var last_price := 0
		var valid := true
		var sample: FishController = _fishes[0]
		var original := sample.fight_profile
		sample.fight_profile = profile
		for index in range(101):
			sample.size_cm = 0
			sample.prepare_catch_size(rng)
			valid = valid and sample.size_cm >= profile.min_size_cm and sample.size_cm <= profile.max_size_cm and is_equal_approx(sample.size_cm * 10, roundf(sample.size_cm * 10))
			var price := profile.sale_price(lerpf(profile.min_size_cm, profile.max_size_cm, index / 100.0))
			valid = valid and price >= last_price and price >= profile.min_price and price <= profile.max_price
			last_price = price
		sample.fight_profile = original
		sample.size_cm = 0
		_check(valid, "Size and Price: " + species + " one decimal, bounded, monotonic")
	var gear := {"rod": [[0, 4000, 18000], [60, 100, 180]], "reel": [[0, 3000, 15000], [1.0, 1.15, 1.30]], "line": [[0, 1800, 12000], [10, 25, 50]], "sonar": [[0, 5000, 25000], [15, 30, 50]]}
	for category: String in gear:
		for level in range(1, 4):
			var item := state.catalog.find(category, level)
			_check(item != null and item.price == gear[category][0][level - 1] and is_equal_approx(item.effect_value, gear[category][1][level - 1]) and not item.display_name.is_empty(), "%s Lv%d: price/effect Resource" % [category, level])
	_check(not state.purchase("line", 2) and not state.purchase("bogus", 2) and state.money == 0 and state.levels["line"] == 1, "Insufficient Money: no deduction/level change")
	_touch(_hud.get_node("ShopButton").get_global_rect().get_center())
	var shop: Control = _hud.get_node("Shop")
	_check(shop.visible and paused and not _flow.request_cast() and not _flow.request_hook(), "Shop Open: one touch pauses fishing/inputs")
	await process_frame
	_check(shop._buttons["line"].disabled and not shop._buy("line"), "Shop: insufficient purchase disabled")
	var before_position: Vector2 = _fishes[1].position
	_step(3.0)
	await physics_frame
	_check(_fishes[1].position == before_position and _flow.state == FLOW.State.READY, "Shop: fish AI and new BITE frozen")
	_touch(shop.get_node("Panel/Close").get_global_rect().get_center())
	_check(not shop.visible and not paused and _flow.state == FLOW.State.READY, "Shop Close: one touch restores lake")
	# Ten real, consecutive fishing sessions; no money injections or forced catches.
	var node_count := get_node_count()
	var first_upgrade_at := 0
	var upgrade_count := 0
	for index in range(10):
		var before_money := state.money
		var started: bool = _flow.request_cast() and _until_bite()
		_check(started, "Economy %d: natural CAST -> BITE" % (index + 1))
		if not started:
			break
		_check(not _flow.request_shop(), "Economy: BITE blocks SHOP")
		_check(_flow.request_hook(), "Economy: hook succeeds")
		_step(0.32)
		_check(not _flow.request_shop(), "Economy: FIGHT blocks SHOP")
		var holding := true
		for tick in range(1800):
			if _flow.state == FLOW.State.LANDED or _flow.state == FLOW.State.FAILED:
				break
			if _flow.state == FLOW.State.FIGHTING:
				if _flow.fight.resistance == FishingFight.Resistance.RUN or _flow.fight.tension >= 76:
					holding = false
				elif _flow.fight.resistance != FishingFight.Resistance.RUN and _flow.fight.tension <= 45:
					holding = true
				_flow.set_reeling(holding)
			_step(1.0 / 60.0)
		_check(_flow.state == FLOW.State.LANDED, "Economy: CATCH reached")
		if _flow.state != FLOW.State.LANDED:
			break
		var result: Dictionary = _flow.last_catch.duplicate()
		_economy_catches.append(result)
		var credited: int = result["price"]
		_check(state.money == before_money + credited and credited > 0, "Auto Sell: exactly one price added to wallet")
		_check(_hud.get_node("Money/Label").text == "¥" + _hud._format_money(state.money) and _hud.get_node("CatchPanel/Price").text == "+ ¥" + _hud._format_money(credited), "Catch Result and Money HUD: name/size/price/wallet displayed")
		_flow._show_catch()
		_check(state.sell_catch(_flow.active_fish.fight_profile, result["size_cm"], _flow._cast_serial) == 0 and state.money == before_money + credited, "Auto Sell: duplicate landing/session cannot pay twice")
		_check(not _flow.request_shop() and not _flow.request_cast(), "Catch: SHOP/CAST blocked")
		_step(1.8)
		_check(_flow.state == FLOW.State.READY, "Reset: fishing/economy loop restored")
		if state.cheapest_next() != null and state.money >= state.cheapest_next().price:
			if first_upgrade_at == 0:
				first_upgrade_at = index + 1
			var next := state.cheapest_next()
			var balance := state.money
			_check(_flow.request_shop(), "Economy: SHOP opens after catch")
			await process_frame
			shop._cooldown = 0
			_hud.get_node("DepthUnlock").visible = false
			shop._refresh()
			_touch(shop._buttons[next.category].get_global_rect().get_center())
			_check(state.money == balance - next.price and state.levels[next.category] == next.level, "Purchase: real touch deducts price and auto-equips next level")
			_check(not state.purchase(next.category, next.level) and not shop._buy(next.category), "Purchase: stale level/double tap blocked")
			upgrade_count += 1
			if next.category == "line":
				_check(_flow.lure.max_depth_m == next.effect_value and _hud.get_node("DepthUnlock").visible and _hud.get_node("DepthUnlock/Label").text == "DEPTH UNLOCKED\n10m → 25m", "Depth Unlock: immediate line effect and big 10m -> 25m banner")
			shop.close_shop()
			_hud.get_node("DepthUnlock")._process(1.3)
		_check(get_node_count() == node_count, "Economy: no session node leak")
	_check(_economy_catches.size() == 10 and upgrade_count > 0, "Economy Loop: ten catches/sales with upgrades and more fishing")
	_check(first_upgrade_at > 0 and first_upgrade_at <= 3, "Tempo: first upgrade affordable within 1-3 natural catches")
	# Real idle/deployed shop pause preserves a cast and lure depth.
	_flow.request_cast()
	_step(1.5)
	var frozen_depth: float = _flow.lure.depth_m
	var frozen_elapsed: float = _flow.cast_elapsed
	_check(_flow.request_shop(), "Shop: open during sinking")
	_step(3)
	_check(_flow.lure.depth_m == frozen_depth and _flow.cast_elapsed == frozen_elapsed, "Shop: existing cast/depth do not advance")
	shop.close_shop()
	_check(_until_bite() and _flow.request_hook() and _finish_fight(), "Shop: closing resumes same cast through catch")
	# Isolated funding is only for Lv3/MAX boundaries, not the 10-catch economy test.
	var isolated := GameProgress.new()
	isolated.money = 150000
	var unlocks: Array[Vector2] = []
	isolated.depth_unlocked.connect(func(a: float, b: float): unlocks.append(Vector2(a, b)))
	for category: String in GameProgress.CATEGORIES:
		_check(isolated.purchase(category, 2) and isolated.purchase(category, 3) and isolated.levels[category] == 3, "Equipment: " + category + " Lv1->Lv2->Lv3 auto-equip")
		var balance := isolated.money
		_check(isolated.next_level(category) == null and not isolated.purchase(category, 4) and isolated.money == balance, "Max Level: " + category + " cannot exceed Lv3")
	_check(unlocks == [Vector2(10, 25), Vector2(25, 50)], "Depth Unlock: exact two upgrade transitions")
	var model1 := FishingFight.new()
	var model3 := FishingFight.new()
	var bass: FishFightProfile = load("res://data/fish/bass-fight.tres")
	model1.start(bass, 1.0, 60, 50)
	model3.start(bass, isolated.current("reel").effect_value, isolated.current("rod").effect_value, 50)
	model1.reeling = true
	model3.reeling = true
	model1.step(0.5)
	model3.step(0.5)
	_check(model3.fish_distance < model1.fish_distance and model3.stamina < model1.stamina, "Auto Equip: reel multiplier improves distance and fatigue")
	model1.start(load("res://data/fish/catfish-fight.tres"), 1.0, 60, 85)
	_check(model1.rod_load > 1 and model1.rod_load <= 1.12, "Rod: oversized catfish stays catchable with mild pull penalty")
	for line_level in range(1, 4):
		_new_scene()
		_flow.progress.levels["line"] = line_level
		_flow._progress_changed()
		for fish: FishController in _fishes:
			fish.bite_detection_radius = 1
		_flow.configure_water(_lake.water_bounds, _lake.surface_y, 100)
		_flow.request_cast()
		_step(25)
		_check(is_equal_approx(_flow.lure.depth_m, minf(gear["line"][1][line_level - 1], LakeAreas.DATA[_flow.progress.current_area].max_depth)) and _flow.lure.state == LureController.State.WAITING, "Depth Limit: area and line Lv%d cap metres, extensible 100m lake" % line_level)
	# Visible shop MAX state and the second depth reward use the same purchase path.
	_new_scene()
	_flow.progress.money = 100000 # Boundary fixture, separate from real economy above.
	_flow.progress.changed.emit()
	_check(_flow.request_shop(), "Shop: funded MAX boundary fixture opens")
	shop = _hud.get_node("Shop")
	_check(shop._buy("line"), "Shop: Lv2 line purchase")
	_hud.get_node("DepthUnlock")._process(1.3)
	shop._process(0.3)
	_check(shop._buy("line") and _hud.get_node("DepthUnlock/Label").text == "DEPTH UNLOCKED\n25m → 50m", "Depth Unlock: Lv3 big 25m -> 50m banner")
	_hud.get_node("DepthUnlock")._process(1.3)
	shop._process(0.3)
	_check(shop._buttons["line"].text == "MAX" and shop._buttons["line"].disabled and not shop._buy("line") and _flow.progress.current("line").effect_value == 50 and _flow.lure.max_depth_m == 30, "Shop MAX: disabled row, no extra purchase, equipped 50m line")
	shop.close_shop()
	_check(_travel_for_band(2) and _flow.lure.max_depth_m == 50, "North Shore uses equipped 50m line")
	# Safe-area shop/catch/depth notices at all supported and small physical views.
	for spec in [[1280, 720, "16:9"], [1560, 720, "19.5:9"], [320, 180, "320px"]]:
		root.size = Vector2i(spec[0], spec[1])
		_new_scene()
		await process_frame
		await process_frame
		_hud.layout_in_safe_area(_lake.view_size, Rect2(36, 8, _lake.view_size.x - 72, _lake.view_size.y - 24), _lake.surface_y, 15)
		var safe: Rect2 = _hud.safe_rect
		var ok := true
		for node in ["Money", "ShopButton", "NextUpgrade", "CatchPanel", "DepthUnlock"]:
			ok = ok and safe.encloses(_hud.get_node(node).get_global_rect())
		_check(ok, spec[2] + ": new HUD/catch/depth notice stay in safe area")
		_touch(_hud.get_node("ShopButton").get_global_rect().get_center())
		shop = _hud.get_node("Shop")
		await process_frame
		_check(shop.visible and safe.encloses(shop.get_node("Panel").get_global_rect()), spec[2] + ": one-touch shop fits centered safe area")
		_check(shop._buttons["line"].size.y * float(spec[1]) / _lake.view_size.y >= 44.0, spec[2] + ": purchase touch target 44 physical px")
		_touch(shop.get_node("Panel/Close").get_global_rect().get_center())
		_check(not paused and not shop.visible, spec[2] + ": close touch resumes lake")
	print("PHASE4_ACCEPTANCE ", JSON.stringify({"result": "PASS" if _failures.is_empty() else "FAIL", "checks": _checks, "failures": _failures, "consecutive_catches": _economy_catches.size(), "first_upgrade_catch": first_upgrade_at, "upgrades": upgrade_count, "catches": _economy_catches}))
	_main.queue_free()
	await process_frame
	quit(0 if _failures.is_empty() else 1)
