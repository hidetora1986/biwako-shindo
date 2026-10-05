extends "res://tests/boss_acceptance.gd"
## Isolated saves and genuine casts, touch hold/release, both endings and ordinary return.
var hidden: HiddenRoute
var readings_seen: Dictionary = {}
var phases_seen: Dictionary = {}

func _hidden_fixture() -> void:
	hidden = _flow.hidden_route
	_check(hidden.debug_setup(),"Debug eligibility / lure setup only in debug build")

func _step(seconds: float) -> void:
	if paused: return
	for tick in range(int(ceil(seconds*60))):
		if _flow.state == FLOW.State.HIDDEN:
			_boat._physics_process(1.0/60)
			_flow._physics_process(1.0/60)
		else:
			for fish: FishController in _fishes: fish._physics_process(1.0/60)
			_boat._physics_process(1.0/60)
			_flow.lure._physics_process(1.0/60)
			_flow._physics_process(1.0/60)

func _contact() -> bool:
	if not _flow.request_cast(): return false
	for tick in range(600):
		readings_seen[hidden.depth_display] = true
		if hidden.stage == HiddenRoute.Stage.FIGHT: return true
		_step(1.0/60)
	return false

func _survive() -> bool:
	for tick in range(4200):
		if hidden.stage == HiddenRoute.Stage.CHOICE: return true
		if hidden.stage == HiddenRoute.Stage.FAILURE: return false
		if hidden.stage == HiddenRoute.Stage.FIGHT:
			phases_seen[hidden.fight.phase] = true
			var model := hidden.fight
			if model.reeling and (model.tension >= 75 or model.warning): _touch(Vector2.ZERO,9,false)
			elif not model.reeling and model.tension <= 42 and not model.warning: _touch(hidden.reel.get_global_rect().get_center(),9)
		_step(1.0/60)
	return false

func _run() -> void:
	root.size = Vector2i(1280,720)
	_new_scene(); await process_frame; await process_frame
	hidden = _flow.hidden_route
	var progress: GameProgress = _flow.progress
	_check(not progress.hidden_eligible() and not progress.anonymous_lure_obtained and not hidden.lure_button.visible,"Fresh save no hidden hints/lure/eligibility")
	_hidden_fixture()
	_check(progress.hidden_eligible() and GameProgress.FISH_PROFILES.size() == 15 and not progress.fish_records.has("00"),"All fifteen discoveries qualify; No.00 outside fish catalog")
	for field: String in ["boss15_defeated","main_ending_seen","returned_unknown_a","returned_unknown_b","zero_depth_contact_seen","night_unlocked"]:
		progress.set(field,false)
		_check(not progress.hidden_eligible(),"Required condition "+field)
		progress.set(field,true)
	progress.hull_knock_count = 2
	_check(not progress.hidden_eligible(),"Three knock gate")
	progress.hull_knock_count = 3
	progress.levels.sonar = 4
	_check(not progress.hidden_eligible(),"Sonar5 gate")
	progress.levels.sonar = 5
	for fish: FishFightProfile in GameProgress.FISH_PROFILES:
		progress.fish_records[fish.id].discovered = false
		_check(not progress.hidden_eligible(),"Individual discovery gate "+fish.id)
		progress.fish_records[fish.id].discovered = true
	progress.anonymous_lure_obtained = false
	_check(not hidden.can_start(),"No encounter without obtained lure")
	progress.anonymous_lure_obtained = true
	progress.anonymous_lure_equipped = false
	_check(not hidden.can_start(),"No encounter without equipped lure")
	progress.anonymous_lure_equipped = true
	_flow.environment.value = 0
	_check(not hidden.can_start(),"No encounter during morning")
	_flow.environment.value = 2
	_flow.select_depth_band(5)
	_check(not hidden.can_start(),"No encounter below100m / ordinary band")
	_flow.select_depth_band(6)
	var book: Control = _hud.get_node("FishBook")
	progress.changed.emit()
	_check(book.hidden_entry.visible and book.hidden_entry.text == "No.00" and not progress.no00_contacted,"Faint No.00 entry is not discovered")
	_check(_flow.request_book(),"Fish Book opens")
	book.hidden_entry.pressed.emit()
	_check(book.hidden_entry.text == "No.00\nこの項目は存在しない。" and progress.hidden_entry_seen,"Missing entry text only / separate saved flag")
	book.close_book()
	_check(not paused and _flow.state == FLOW.State.READY,"Fish Book closes / fishing resumes")
	# Natural two post-CONTINUE ordinary catches grant, never a purchase.
	progress.anonymous_lure_obtained = false
	progress.anonymous_lure_equipped = false
	progress.hidden_postgame_sessions = 0
	_flow.select_depth_band(0)
	for number in range(2):
		_check(_flow.request_cast() and _until_bite() and _flow.request_hook() and _finish_fight(),"Actual postgame fishing cycle %d" % (number+1))
		_check(progress.anonymous_lure_obtained == (number == 1),"Lure appears after second normal catch")
	_check(progress.hidden_postgame_sessions == 2 and hidden.lure_button.visible,"No cost or acquisition popup / two catch grant")
	_check(hidden.toggle_lure(),"Anonymous equip with one tap")
	var early_restore := GameProgress.new()
	_check(_flow.save_manager.load_into(early_restore) and early_restore.anonymous_lure_obtained and early_restore.anonymous_lure_equipped and early_restore.hidden_postgame_sessions == 2,"Anonymous lure and two-session timing restored")
	_step(12.1)
	_flow.select_depth_band(6)
	_check(hidden.can_start() and _flow.lure.max_depth_m == 120,"Night anonymous >=100 gate with unchanged line120")
	var money_before := progress.money
	var record_before := progress.fish_records.duplicate(true)
	_check(_contact(),"Real CAST to depth sequence / 接触 / dedicated fight")
	_check(readings_seen.has("104m") and readings_seen.has("108m") and readings_seen.has("114m") and readings_seen.has("121m") and readings_seen.has("---"),"104 108 114 121 invalid pauses")
	_check(_flow.lure.depth_m <= 120 and _flow.lure.max_depth_m == 120 and DepthBands.MAX_PLAYABLE_DEPTH == 120,"Hidden displayed121 never alters normal depth physics")
	var suppressed := true
	for fish: FishController in _fishes: suppressed = suppressed and not fish.visible and not fish.is_physics_processing()
	_check(suppressed and _flow.active_fish == null,"Normal fish suppressed / no No.00 body node")
	_check(not _flow.request_hook() and not _flow.request_cast() and not _flow.request_shop() and not _flow.request_book(),"No HIT/hook/double cast/modals during contact/fight")
	_check(hidden.visual.amount == 1 and hidden.visual.depth_text == "---","Sonar unbounded red returns / invalid reading")
	_touch(hidden.reel.get_global_rect().get_center(),9)
	_step(0.6)
	_check(hidden.fight.reeling and hidden.fight.tension > 35,"Real touch hold resists and raises tension")
	_touch(Vector2.ZERO,9,false)
	var before_tension := hidden.fight.tension
	var before_pull := hidden.fight.boat_pull_depth
	_step(0.5)
	_check(not hidden.fight.reeling and hidden.fight.tension < before_tension and hidden.fight.boat_pull_depth > before_pull,"Release relieves tension / boat sinks more")
	hidden.set_reeling(true)
	_step(6)
	_check(hidden.stage == HiddenRoute.Stage.FAILURE and hidden.fight.failure == "LINE BREAK","Holding forever breaks line with grace")
	_step(3.1)
	_check(_flow.state == FLOW.State.READY and progress.anonymous_lure_obtained and progress.money == money_before and progress.fish_records == record_before and _flow.environment.value == 0,"Failure returns dawn without loss / lure retained")
	_check(hidden.toggle_night(),"Retry night selectable without recollecting flags")
	_step(12.1); _flow.select_depth_band(6)
	_check(_contact(),"Fresh CAST retries same unlocked route")
	for tick in range(2100):
		if hidden.stage == HiddenRoute.Stage.FAILURE: break
		_step(1.0/60)
	_check(hidden.stage == HiddenRoute.Stage.FAILURE and hidden.fight.failure == "PULL DEPTH","Release forever reaches critical boat depth")
	_step(3.1); hidden.toggle_night(); _step(12.1); _flow.select_depth_band(6)
	_check(_contact() and _survive(),"Hold/release survives 50s to silent final choice")
	_check(phases_seen.size() == 3 and absf(hidden.fight.elapsed-50) < 0.02 and hidden.fight.tension == 0,"Three phases / 50s / stopped tension")
	_check(hidden.cut.visible and hidden.lift.visible and not hidden.reel.visible and not hidden.set_reeling(true),"Two large choices only, REEL disabled")
	_check(hidden.choose(false) and not hidden.choose(true),"Cut / duplicate choice blocked")
	_step(3.2)
	_check(progress.hidden_cut_ending_seen and not progress.no00_contacted and _flow.state == FLOW.State.TITLE and hidden.visual.title_shadow,"Cut ending dawn/title faint unbounded shadow, not caught")
	_check(_flow.request_continue() and not hidden.visual.title_shadow,"Post-cut CONTINUE ordinary fishing")
	_step(12.1); _flow.select_depth_band(6)
	_check(not hidden.can_start() and progress.no00_record().caught_count == 0,"Cut no respawn / nonexistent entry remains")
	# Independent contact-ending save/session, not a cut-save rewrite.
	_new_scene(); await process_frame; await process_frame; _hidden_fixture()
	progress = _flow.progress
	_check(_contact() and _survive(),"Independent contact route full encounter and survival")
	_check(hidden.choose(true),"Reel up, no ordinary catch")
	_step(3.1)
	_check(hidden.stage == HiddenRoute.Stage.REVEAL and hidden.message.text.contains("捕獲数: 2") and hidden.message.text.contains("記録不能") and hidden.message.text.contains("売値: ---"),"No.00 book reveal / unknown size-depth-price / count2")
	_step(3.1)
	_check(progress.hidden_contact_ending_seen and progress.no00_contacted and progress.no00_record().caught_count == 2 and _flow.state == FLOW.State.TITLE,"Contact ending flags / immutable synthetic count2")
	var secret := FishFightProfile.new()
	secret.id = "00"
	_check(progress.sell_catch(secret,1,9999) == 0 and not progress.record_catch(secret,1) and not progress.fish_records.has("00"),"No.00 unsellable / no normal records")
	var restored := GameProgress.new()
	_check(_flow.save_manager.load_into(restored) and restored.no00_contacted and restored.no00_record().caught_count == 2 and restored.anonymous_lure_obtained and restored.hidden_contact_ending_seen,"Save load hidden contact / lure / fixed count")
	_check(_flow.request_continue() and _flow.select_depth_band(6) and not hidden.can_start(),"Post-contact continue / no refarm")
	_check(_flow.select_depth_band(0) and _flow.request_cast() and _until_bite() and _flow.request_hook() and _finish_fight(),"After hidden ending real ordinary fishing still sells")
	var old: Dictionary = _flow.save_manager.snapshot(progress)
	for field in ["anonymous_lure_obtained","anonymous_lure_equipped","hidden_entry_seen","no00_contacted","hidden_cut_ending_seen","hidden_contact_ending_seen","hidden_postgame_sessions","second_playthrough_hooks"]: old.erase(field)
	var path := "user://tests/hidden-migration.json"
	var file := FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(old)); file.close()
	var manager := SaveManager.new(path)
	var migrated := GameProgress.new()
	_check(manager.load_into(migrated) and migrated.money == progress.money and migrated.levels == progress.levels and migrated.fish_records == progress.fish_records and not migrated.anonymous_lure_obtained and not migrated.no00_contacted,"Old v1 save preserves all normal state and defaults new flags")
	for field in ["anonymous_lure_obtained","hidden_entry_seen","no00_contacted","hidden_cut_ending_seen","hidden_contact_ending_seen"]: old[field] = "true"
	file = FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(old)); file.close()
	manager.load_into(migrated)
	_check(not migrated.anonymous_lure_obtained and not migrated.hidden_finished() and not migrated.no00_contacted,"Malformed hidden bool fallback")
	DirAccess.remove_absolute(path)
	for resolution in [Vector2i(1280,720),Vector2i(1560,720),Vector2i(1600,720),Vector2i(640,360)]:
		root.size = resolution; await process_frame; await process_frame
		hidden.layout()
		var safe: Rect2 = _hud.safe_rect
		for button: Button in [hidden.cut,hidden.lift,hidden.reel,hidden.lure_button,hidden.night_button]:
			_check(safe.encloses(button.get_global_rect()) and button.size.y >= 44,"Safe touch bounds %s / %s" % [resolution,button.text])
	_check(not hidden.lure_button.get_global_rect().intersects(_hud.get_node("DepthBandButton").get_global_rect()) and not hidden.lure_button.get_global_rect().intersects(_hud.get_node("CastButton").get_global_rect()), "Anonymous lure does not overlap CAST / depth selector")
	_check(hidden.debug_stage(HiddenRoute.Stage.CONTACT) and hidden.message.text == "接触", "Debug replay after ending, contact individually reproducible")
	_check(hidden.debug_stage(HiddenRoute.Stage.FIGHT) and hidden.set_reeling(true), "Debug fight individually reproducible")
	_check(hidden.debug_stage(HiddenRoute.Stage.CHOICE) and hidden.cut.visible, "Debug final choice individually reproducible")
	_check(hidden.debug_stage(HiddenRoute.Stage.REVEAL) and hidden.message.text.contains("捕獲数: 2"), "Debug contact reveal individually reproducible")
	_check(GameProgress.FISH_PROFILES.size() == 15 and DepthBands.MAX_PLAYABLE_DEPTH == 120,"Ordinary catalog/depth intact")
	print("HIDDEN_ACCEPTANCE ",JSON.stringify({"checks":_checks,"failures":_failures,"fight_seconds":50,"ratios":["16:9","19.5:9","20:9","640x360"]}))
	_main.free(); DirAccess.remove_absolute(_test_save_path)
	quit(0 if _failures.is_empty() else 1)
