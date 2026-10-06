extends "res://tests/hidden_boss_acceptance.gd"
## No debug progress grants: wallet, discoveries, equipment and events from real casts.
var journey: Array[Dictionary] = []
var sim_seconds: float = 0
var earned: int = 0
var catch_total: int = 0
var checkpoints: Array[Dictionary] = []
var _since_purchase: int = 0
var worst_stall: int = 0
var _test_choice_return: bool = true

func _step(seconds: float) -> void:
	sim_seconds += seconds
	super._step(seconds)

func _catch_real(prefer_new: bool = false) -> bool:
	if not _flow.request_cast(): return false
	var hooked := false
	for tick in range(2400):
		if _flow.state == FLOW.State.BITTEN:
			var id: String = _flow.active_fish.fight_profile.id
			if not prefer_new or not _flow.progress.fish_records[id].discovered or _flow.cast_elapsed > 24:
				hooked = _flow.request_hook()
				break
		_step(1.0/60)
	if not hooked: return false
	var hold := true
	for tick in range(5400):
		if _flow.state == FLOW.State.LANDED: break
		if _flow.state == FLOW.State.FAILED: return false
		if _flow.state == FLOW.State.FIGHTING:
			if _flow.fight.resistance == FishingFight.Resistance.RUN or _flow.fight.tension >= 76: hold = false
			elif _flow.fight.tension <= 45: hold = true
			_flow.set_reeling(hold)
		_step(1.0/60)
	if _flow.state != FLOW.State.LANDED: return false
	var record: Dictionary = _flow.last_catch.duplicate()
	var capture_depth: float = _flow.lure.depth_m
	var price: int = record.price
	if record.id in ["No.10","No.14"]:
		_step(1.6)
		if _flow.state != FLOW.State.CHOOSING: return false
		var returning: bool = _test_choice_return and not (_flow.progress.returned_unknown_a if record.id == "No.10" else _flow.progress.returned_unknown_b)
		if not _flow.resolve_unknown_catch(not returning): return false
		if returning: price = 0
		_check(not _flow.resolve_unknown_catch(true),"Choice exact once: "+record.id)
		_step(0.3)
	elif record.id == "No.15":
		_step(10.5)
		_flow.story.skip();_flow.story.skip();_step(0.3)
	else: _step(1.8)
	var persisted := GameProgress.new()
	_check(_flow.save_manager.load_into(persisted) and persisted.money == _flow.progress.money and persisted.fish_records == _flow.progress.fish_records and persisted.returned_unknown_a == _flow.progress.returned_unknown_a and persisted.returned_unknown_b == _flow.progress.returned_unknown_b,"Actual catch/choice durable save")
	catch_total += 1
	_since_purchase += 1
	earned += price
	journey.append({"id":record.id,"seconds":sim_seconds,"catch":catch_total,"money":_flow.progress.money,"earned":earned,"depth":capture_depth,"levels":_flow.progress.levels.duplicate(),"fight_s":_flow.fight.elapsed,"price":price})
	return _flow.state in [FLOW.State.READY,FLOW.State.TITLE]

func _purchase_available() -> void:
	var order := ["line","sonar","reel","rod"]
	for category in order:
		var item: EquipmentLevel = _flow.progress.next_level(category)
		if item == null or not _flow.progress.can_purchase(category,item.level): continue
		# Keep line and reel progression near each other; no pointless unspent-wallet grind.
		if item.level > _flow.progress.levels.line+1: continue
		if not _flow.request_shop(): continue
		var before: int = _flow.progress.money
		_check(_flow.progress.purchase(category,item.level),"Earned-money purchase %s Lv%d" % [category,item.level])
		_check(_flow.progress.money == before-item.price,"Purchase exact deduction")
		checkpoints.append({"category":category,"level":item.level,"price":item.price,"catches":catch_total,"money_before":before,"money_after":_flow.progress.money,"seconds":sim_seconds,"catches_since_previous":_since_purchase})
		worst_stall = maxi(worst_stall,_since_purchase)
		_since_purchase = 0
		_hud.get_node("Shop").close_shop()

func _run() -> void:
	root.size = Vector2i(1280,720)
	_new_scene(); await process_frame; await process_frame
	hidden = _flow.hidden_route
	_check(_flow.progress.money == 0 and _flow.progress.levels == {"rod":1,"reel":1,"line":1,"sonar":1},"New Save actual zero balance / all Lv1")
	_test_choice_return = not ("--sell" in OS.get_cmdline_user_args())
	var stage := 0
	for cycle in range(220):
		_purchase_available()
		var progress: GameProgress = _flow.progress
		var band := 0
		if progress.levels.line >= 2: band = 1
		if progress.levels.line >= 3: band = 2
		if progress.levels.line >= 4: band = 3 if not progress.fish_records["No.12"].discovered else 4
		if progress.levels.line >= 5 and progress.levels.rod >= 5 and progress.night_unlocked and progress.hull_knock_count == 3 and progress.zero_depth_contact_seen: band = 6
		# Complete every depth pool before moving on; ignore a repeated bite to let lure sink.
		for region in [[0,0,4],[1,5,7],[2,8,9],[3,10,11],[4,12,13]]:
			var missing := false
			for index in range(region[1],region[2]+1): missing = missing or not progress.fish_records[GameProgress.FISH_PROFILES[index].id].discovered
			if missing and DepthBands.available(region[0],progress.current("line").effect_value): band = region[0]; break
		for event_tick in range(600):
			if not _flow.anomaly.active and not _flow.hull_events.active: break
			_step(1.0/60)
		_check(_travel_for_band(band), "Travel to habitat for band %d" % band)
		if _flow.selected_band != band:
			_check(_flow.select_depth_band(band),"Selectable unlocked band %d" % band)
		_step(3.0 + (cycle%7)*0.6)
		if band >= 3: _step(9)
		if not _catch_real(true):
			_check(false,"Natural full path cast stalled at cycle%d band%d" % [cycle,band]); break
		print("JOURNEY ",JSON.stringify(journey[-1]))
		if progress.boss15_defeated: break
	var progress: GameProgress = _flow.progress
	_check(progress.boss15_defeated and progress.main_ending_seen and _flow.state == FLOW.State.TITLE,"Natural No.15 -> main ending -> title")
	var main_seconds := sim_seconds
	var main_catches := catch_total
	if progress.main_ending_seen and not _test_choice_return:
		_check(_flow.request_continue() and not progress.hidden_eligible() and progress.unknown_a_sold_first and progress.unknown_b_sold_first,"First sale still clears main / hidden denied")
	if progress.main_ending_seen and _test_choice_return:
		_check(_flow.request_continue(),"Main Continue")
		_purchase_available()
		_check(progress.hidden_eligible(),"All fifteen / returns / night / knocks / sonar5 from gameplay")
		_check(_travel_for_band(0) and _flow.select_depth_band(0), "Postgame travel to South Shore")
		for i in range(2): _check(_catch_real(),"Actual postgame lure grant cycle")
		_check(progress.anonymous_lure_obtained,"Anonymous lure within2 catches")
		_check(hidden.toggle_lure(),"Anonymous equip")
		_step(12.1); _check(_travel_for_band(6) and _flow.select_depth_band(6), "Hidden travel to North Center")
		_check(_contact() and _survive(),"Natural hidden contact -> 50s survival")
		var contact_ending := not ("--cut" in OS.get_cmdline_user_args())
		_check(hidden.choose(contact_ending),"Hidden final choice")
		_step(6.2)
		_flow.story.skip();_flow.story.skip();_step(0.3)
		_check(progress.hidden_finished() and progress.no00_contacted == contact_ending and progress.no00_record().caught_count == (2 if contact_ending else 0) and _flow.state == FLOW.State.TITLE,"Hidden ending and count2 / cut uncaught")
		_check(_flow.request_continue(),"Hidden postgame Continue")
		var saved := GameProgress.new()
		_check(_flow.save_manager.load_into(saved) and saved.money == progress.money and saved.fish_records == progress.fish_records and saved.no00_contacted == contact_ending,"Full-path save/load matches wallet/records/ending")
	var output := {"result":"PASS" if _failures.is_empty() else "FAIL","checks":_checks,"failures":_failures,"main_play_seconds":main_seconds,"hidden_play_seconds":sim_seconds,"main_catches":main_catches,"hidden_catches":catch_total,"worst_economy_stall":worst_stall,"checkpoints":checkpoints,"journey":journey}
	var file := FileAccess.open("/tmp/rc1-full-game.json",FileAccess.WRITE); file.store_string(JSON.stringify(output,"\t")); file.close(); file = null
	var route_tag := "sell" if not _test_choice_return else ("cut" if "--cut" in OS.get_cmdline_user_args() else "contact")
	file = FileAccess.open("/tmp/rc1-full-"+route_tag+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"\t")); file.close(); file = null
	print("FULL_GAME_ACCEPTANCE ",JSON.stringify({"result":output.result,"checks":_checks,"failures":_failures,"main_s":main_seconds,"hidden_s":sim_seconds,"main_catches":main_catches,"hidden_catches":catch_total,"stall":worst_stall}))
	_main.free(); DirAccess.remove_absolute(_test_save_path)
	await process_frame
	await create_timer(0.15).timeout
	quit(0 if _failures.is_empty() else 1)
