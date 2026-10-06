extends "res://tests/lategame_depth_acceptance.gd"
## Real depth-gated casts, hold/release fights, failure/retry, ending and isolated v1 saves.
var _boss_fight_seconds: float = 0
var _boss_phases: Dictionary = {}
var _boss_actions: Dictionary = {}
var _warning_durations: Array[float] = []
var _dive_retreat_seen: bool = false
var _dive_offset_seen: bool = false
var _phase3_surge_seen: bool = false

func _boss_fixture(reel_level: int = 4, sonar_level: int = 5) -> void:
	var progress: GameProgress = _flow.progress
	for index in [9,10,11,12,13]:
		var profile: FishFightProfile = GameProgress.FISH_PROFILES[index]
		progress.record_catch(profile,(profile.min_size_cm+profile.max_size_cm)/2,false)
	progress.levels = {"rod":5,"reel":reel_level,"line":5,"sonar":sonar_level}
	progress.money = 12345
	progress.returned_unknown_a = true
	progress.returned_unknown_b = true
	progress.hull_knock_count = 3
	progress.zero_depth_contact_seen = true
	progress.anomaly_seen = true
	progress.changed.emit()
	_step(12.1)
	assert(_travel_for_band(6) and _flow.select_depth_band(6))

func _boss_hook() -> bool:
	if not _flow.request_cast() or not _until_bite(25): return false
	_check(_flow.active_fish.fight_profile.id == "No.15" and _flow.lure.depth_m >= 100 and _flow._boss_bite_elapsed >= 1.5, "Real encounter at >=100m; slow 1.5s line draw before hook")
	_check(_flow.line.get_point_position(1).y-_flow._boss_bite_start.y >= 2.9, "Slow BITE visibly draws line down before tap window")
	_check(_flow._bite_remaining > 1.7 and not _flow.request_shop() and not _flow.request_book(), "Boss generous hook window / modal exclusion")
	return _flow.request_hook()

func _boss_land() -> bool:
	var holding := true
	var warning_time := 0.0
	var before_resistance: int = FishingFight.Resistance.CALM
	var pointer := 7
	for tick in range(5400):
		if _flow.state == FLOW.State.LANDED:
			_boss_fight_seconds = _flow.fight.elapsed
			return true
		if _flow.state == FLOW.State.FAILED: return false
		if _flow.state == FLOW.State.FIGHTING:
			var model: BossFishingFight = _flow.fight
			_boss_phases[model.boss_phase] = true
			_phase3_surge_seen = _phase3_surge_seen or (model.boss_phase == 3 and model.resistance == FishingFight.Resistance.RUN and model.action == BossFishingFight.Action.SURGE)
			if model.resistance == FishingFight.Resistance.WARNING:
				warning_time += 1.0/60
			elif model.resistance == FishingFight.Resistance.RUN:
				if before_resistance == FishingFight.Resistance.WARNING:
					_warning_durations.append(warning_time)
					warning_time = 0
				_boss_actions[model.action] = true
			before_resistance = model.resistance
			if model.resistance == FishingFight.Resistance.RUN or model.tension >= 76: holding = false
			elif model.resistance != FishingFight.Resistance.RUN and model.tension <= 45: holding = true
			if holding and not model.reeling:
				_touch(_hud.get_node("ReelButton").get_global_rect().get_center(),pointer)
			elif not holding and model.reeling:
				_touch(Vector2.ZERO,pointer,false)
			if _flow.lure.depth_m > 120: return false
		var diving: bool = _flow.state == FLOW.State.FIGHTING and _flow.fight.resistance == FishingFight.Resistance.RUN and _flow.fight.action == BossFishingFight.Action.DIVE
		var previous_distance: float = _flow.fight.fish_distance
		_step(1.0/60)
		if diving:
			_dive_retreat_seen = _dive_retreat_seen or _flow.fight.fish_distance > previous_distance
			_dive_offset_seen = _dive_offset_seen or _flow.fight.depth_offset > 0
	return false

func _run() -> void:
	root.size = Vector2i(1280,720)
	_new_scene(); await process_frame; await process_frame
	var profile: FishFightProfile = GameProgress.FISH_PROFILES[14]
	_check(GameProgress.FISH_PROFILES.size() == 15 and profile.id == "No.15" and profile.is_boss and profile.rarity == 7 and profile.display_name == "湖底の主", "No.15 Resource boss identity, fifteen fish / no No.00")
	_check([profile.min_depth,profile.max_depth,profile.min_size_cm,profile.max_size_cm,profile.min_price,profile.max_price] == [100.0,120.0,300.0,500.0,800000,2800000], "No.15 exact depth, size, price data")
	_check(profile.sale_price(300) == 800000 and profile.sale_price(500) == 2800000 and profile.sale_price(400) == 1800000, "Boss bounded monotonic price")
	var frame := RefinedPixelArt.fish_frames(profile.species_id).get_frame_texture("swim",0)
	_check(frame.get_width() == 288 and frame.get_height() == 96 and RefinedPixelArt.fish_frames(profile.species_id).get_frame_count("swim") == 3, "Huge cached original body / three frames")
	_check(not _flow.progress.boss15_defeated and not _flow.progress.main_ending_seen and not _flow.progress.can_encounter_boss(), "Default boss/ending flags false, gate closed")
	var book: Control = _hud.get_node("FishBook")
	_check(book.entries.size() == 15 and book.entries["No.15"].text.contains("???") and not book.entries["No.15"].text.contains("湖底の主"), "Book No.15 undiscovered / identity hidden")
	_boss_fixture()
	var progress: GameProgress = _flow.progress
	_check(_flow.lure.max_depth_m == 120 and _lake.depth_origin_m == 100 and _hud.get_node("DepthBandButton").text == "ABYSS 100–120m", "120m content / actual ABYSS viewport")
	var background: Node2D = _lake.get_node("Underwater/WaterBackground")
	_check(background.color_at_depth(120).get_luminance() < background.color_at_depth(100).get_luminance() and background.color_at_depth(120).get_luminance() > 0.04, "ABYSS darkens, never black")
	_check(not _flow.boss_encounter.try_spawn(_lake,progress,99.9), "No spawn below 100m")
	_check(not _flow.boss_encounter.try_spawn(_lake,progress,121), "No encounter or anomalous depth beyond 120m")
	for field: String in ["rod","line"]:
		progress.levels[field] = 4
		_check(not _flow.boss_encounter.try_spawn(_lake,progress,110), "Gate requires Lv5: "+field)
		progress.levels[field] = 5
	progress.night_unlocked = false
	_check(not _flow.boss_encounter.try_spawn(_lake,progress,110), "Gate requires night unlock")
	progress.night_unlocked = true
	progress.fish_records["No.14"].discovered = false
	_check(not _flow.boss_encounter.try_spawn(_lake,progress,110), "Gate requires No.14 discovery")
	progress.fish_records["No.14"].discovered = true
	progress.levels.reel = 4; progress.levels.sonar = 4
	_check(progress.can_encounter_boss(), "Reel5 and Sonar5 optional")
	progress.levels.sonar = 5
	_check(_boss_hook(), "First natural CAST encounters and hooks No.15, no extra grind")
	var sonar: SonarDisplay = _hud.get_node("SonarPlaceholder")
	sonar.refresh_contacts()
	_check(sonar.contacts.size() == 1 and sonar.contacts[0].dot_width == 30 and sonar.contacts[0].name_text == "???" and sonar.contacts[0].depth_m >= 100, "Stable large Lv5 sonar, hidden name; normal fish leave")
	_check(not _flow.request_cast() and not _flow.request_hook() and not _flow.request_shop(), "Boss HOOK blocks repeated cast/hook/modal")
	_step(0.32)
	_flow.set_reeling(true)
	var initial: float = _flow.fight.tension
	_step(0.2)
	_check(_flow.fight.tension > initial and _flow.fight.fish_distance < 1, "Hold reels closer and raises tension")
	_flow.set_reeling(false)
	var high: float = _flow.fight.tension
	_step(0.2)
	_check(_flow.fight.tension < high, "Release recovers tension")
	# Hold recklessly: failure has grace, no game-over or economic damage.
	_flow.set_reeling(true)
	for tick in range(600):
		_step(1.0/60)
		if _flow.state == FLOW.State.FAILED: break
	_check(_flow.state == FLOW.State.FAILED and _flow.fight.failure == "LINE BREAK" and _flow.fight.break_time >= 0.99 and progress.money == 12345 and not progress.boss15_defeated, "Reckless hold breaks after 1s grace, money/gear intact")
	_step(1.6)
	_check(_flow.state == FLOW.State.READY and _boss_hook(), "Next cast retry, no long preparation")
	_step(0.32)
	for tick in range(600):
		_step(1.0/60)
		if _flow.state == FLOW.State.FAILED: break
	_check(_flow.state == FLOW.State.FAILED and _flow.fight.failure == "ESCAPED" and progress.money == 12345 and not progress.boss15_defeated, "Slack escape, no reward or equipment loss")
	_step(1.6)
	_check(_boss_hook() and _boss_land(), "Third real retry with guided touch hold/release catches boss")
	_check(_boss_phases.size() == 3 and _boss_actions.has(BossFishingFight.Action.SURGE) and _boss_actions.has(BossFishingFight.Action.DIVE), "Real fight visits all phases / SURGE / DIVE")
	_check(_dive_retreat_seen and _dive_offset_seen, "DIVE increases distance and visible depth, bounded by 120m")
	_check(_phase3_surge_seen, "Phase3 retains short SURGE attacks")
	_check(_warning_durations.size() > 2 and _warning_durations.all(func(t:float)->bool:return t >= 0.6 and t <= 1.0), "Every heavy/SURGE/DIVE warning lasts 0.6–1.0s")
	_check(_boss_fight_seconds >= 30 and _boss_fight_seconds <= 60 and is_equal_approx(_flow.fight.fish_distance,0) and _flow.fight.stamina == 0, "30–60s fight / exact zero stamina + distance landing")
	var reward: int = _flow.last_catch.price
	_check(progress.boss15_defeated and not progress.main_ending_seen and progress.money == 12345+reward and reward >= 800000 and reward <= 2800000, "Boss reward atomically auto-sells and saves defeated before ending")
	var wallet: Label = _hud.get_node("Money/Label")
	_check(wallet.get_theme_font("font").get_string_size(wallet.text,HORIZONTAL_ALIGNMENT_LEFT,-1,wallet.get_theme_font_size("font_size")).x <= wallet.size.x, "Seven-figure wallet fits HUD")
	_check(_hud.get_node("CatchPanel/Name").text == "湖底の主" and not _hud.get_node("CatchPanel/SellChoice").visible and not _flow.resolve_unknown_catch(true), "CATCH reveals full identity/body; no sell/return choice")
	_check(sonar._fish_contact(_flow.active_fish).name_text == "湖底の主", "Known boss sonar identity unlocks only after catch")
	_check(book.entries["No.15"].text.contains("湖底の主") and book.entries["No.15"].text.contains("捕獲数 1") and book.entries["No.15"].text.contains("BEST SIZE"), "Book15 updates discovery, caught and best")
	var saved := GameProgress.new()
	_check(_flow.save_manager.load_into(saved) and saved.boss15_defeated and not saved.main_ending_seen and saved.money == progress.money, "Interruption after CATCH: reward/defeat safely persisted")
	_step(2.3)
	_check(_flow.state == FLOW.State.ENDING and not _flow.request_cast() and not _flow.request_shop() and not _flow.request_book() and not _flow.request_continue(), "Ending begins only after short CATCH, all competing input blocked")
	_step(4)
	_check(_flow.selected_band == 0 and _flow.environment.value < 2 and _flow.environment.value > 0 and not _flow.line.visible, "Fade returns to surface; no stale line, dawn without black screen")
	_step(4.1)
	_check(_flow.state == FLOW.State.TITLE and progress.main_ending_seen and is_equal_approx(_flow.environment.value,0) and _flow.ending_screen.get_node("Continue").visible, "Eight-second dawn ends at morning title, seen saved")
	var all_records: Dictionary = progress.fish_records.duplicate(true)
	var amount: int = progress.money
	_touch(_flow.ending_screen.get_node("Continue").get_global_rect().get_center())
	_check(_flow.state == FLOW.State.READY and progress.money == amount and progress.fish_records == all_records and progress.returned_unknown_a and progress.returned_unknown_b and progress.hull_knock_count == 3 and progress.zero_depth_contact_seen, "Real touch CONTINUE retains money/gear/book/all prior flags")
	_check(_flow.request_book(), "Postgame Fish Book opens")
	book.close_book()
	_check(_flow.request_shop(), "Postgame SHOP opens")
	_check(progress.purchase("reel",5) and progress.money == amount-360000, "Earned boss reward buys optional REEL5 in postgame")
	_hud.get_node("Shop").close_shop()
	var before_normal: int = progress.money
	_check(_travel_for_band(0) and _flow.select_depth_band(0) and _flow.request_cast() and _until_bite() and _flow.request_hook() and _finish_fight() and progress.money > before_normal and progress.main_ending_seen and progress.fish_records["No.15"].caught_count == 1, "Postgame normal fishing/economy still works; no repeated ending")
	_check(_travel_for_band(6) and _flow.select_depth_band(6) and _flow.request_cast(), "Postgame ABYSS remains accessible")
	_step(18)
	_check(_flow.active_fish == null and not _flow.boss_encounter.spawned and not _fishes.any(func(f:FishController)->bool:return f.visible and f.fight_profile.is_boss), "Defeated boss never respawns, no farming")
	# Old save lacks boss fields/record. Load preserves all previous progress.
	var legacy: Dictionary = _flow.save_manager.snapshot(progress)
	for key: String in ["boss15_defeated","main_ending_seen"]: legacy.erase(key)
	for key: String in ["fish_discovered","fish_caught_count","fish_best_size"]: legacy[key].erase("No.15")
	var file := FileAccess.open(_test_save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy)); file.close()
	var old_bytes := FileAccess.get_file_as_bytes(_test_save_path)
	var migrated := GameProgress.new()
	_check(_flow.save_manager.load_into(migrated) and not migrated.boss15_defeated and not migrated.main_ending_seen and not migrated.fish_records["No.15"].discovered and migrated.money == progress.money and migrated.levels == progress.levels and migrated.returned_unknown_a and migrated.returned_unknown_b and migrated.night_unlocked and migrated.hull_knock_count == 3 and migrated.zero_depth_contact_seen, "Additive v1 migration defaults boss flags; all late save fields intact")
	_check(old_bytes == FileAccess.get_file_as_bytes(_test_save_path), "Migration never rewrites on load")
	legacy.boss15_defeated = "true"
	legacy.main_ending_seen = 1
	file = FileAccess.open(_test_save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy)); file.close()
	var invalid := GameProgress.new()
	_check(_flow.save_manager.load_into(invalid) and not invalid.boss15_defeated and not invalid.main_ending_seen and invalid.money == progress.money and invalid.returned_unknown_b, "Invalid boss flag types fall back, preserve previous state")
	for speed in [1.0,1.15,1.3,1.5,1.7]:
		var model := BossFishingFight.new()
		model.start(profile,speed,500,500)
		var held := true
		for tick in range(5400):
			if model.resistance == FishingFight.Resistance.RUN or model.tension >= 76: held = false
			elif model.resistance != FishingFight.Resistance.RUN and model.tension <= 45: held = true
			model.reeling = held
			model.step(1.0/60)
			if model.landed or model.failure != "": break
		_check(model.landed and model.elapsed >= 30 and model.elapsed <= 60 and (speed < 1.7 or model.elapsed <= 45), "Boss guided time with REEL ×%.2f: %.2fs" % [speed,model.elapsed])
	var overflow := GameProgress.new()
	overflow.money = 2147483640
	_check(overflow.sell_catch(profile,500,1) == 2800000 and overflow.money == 2147483647 and overflow.sell_catch(profile,500,2) == 0, "Wallet ceiling prevents save overflow; boss cannot sell twice")
	var overflow_load := GameProgress.new()
	_check(_flow.save_manager.save_progress(overflow) and _flow.save_manager.load_into(overflow_load) and overflow_load.money == 2147483647 and overflow_load.boss15_defeated, "Maximum wallet survives Save/Load without overflow fallback")
	for ratio in [Vector2i(1280,720),Vector2i(1560,720),Vector2i(1600,720),Vector2i(640,360),Vector2i(320,180)]:
		root.size = ratio
		await process_frame; await process_frame
		_flow.ending_screen.configure(_hud.size,_hud.safe_rect)
		_check(_hud.safe_rect.encloses(_hud.get_node("ReelButton").get_global_rect()) and _hud.safe_rect.encloses(_flow.ending_screen.get_node("Continue").get_global_rect()), "%s REEL / CONTINUE in safe area" % ratio)
		var physical_scale := float(ratio.y)/_hud.size.y
		_check(_flow.ending_screen.get_node("Continue").size.y*physical_scale >= 44, "%s CONTINUE touch target >=44px" % ratio)
	print("BOSS_ACCEPTANCE ",JSON.stringify({"result":"PASS" if _failures.is_empty() else "FAIL","checks":_checks,"failures":_failures,"fight_s":_boss_fight_seconds,"phases":_boss_phases.keys(),"actions":_boss_actions.keys(),"warnings_s":_warning_durations,"reward":reward,"encounters":_flow.boss_encounter.encounters}))
	_main.free(); DirAccess.remove_absolute(_test_save_path)
	quit(0 if _failures.is_empty() else 1)
