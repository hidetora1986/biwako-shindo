extends SceneTree
## Explicit assumptions, measured full-game telemetry, no wall-clock wait or target multiplier.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var raw := FileAccess.get_file_as_string("/tmp/rc1-full-contact.json")
	assert(not raw.is_empty(), "Run full_game_acceptance before this simulation")
	var data: Dictionary = JSON.parse_string(raw)
	assert(data.result == "PASS")
	# Learning / reading / retries are separate hypotheses, never measured human play.
	var main_active: float = data.main_play_seconds/60.0
	var hidden_active: float = data.hidden_play_seconds/60.0
	var assumptions := {"new_controls_learning_min":6,"reading_and_shops_min":6,"exploration_per_catch_s":20,"normal_success_rate":0.85,"mid_success_rate":0.70,"late_success_rate":0.65,"boss_retries":2,"boss_retry_cycle_s":60,"postgame_search_min":8}
	var retry_seconds := 0.0
	for row: Dictionary in data.journey:
		var number := int(str(row.id).trim_prefix("No."))
		var success := 0.85 if number <= 5 else (0.70 if number <= 10 else 0.65)
		if number == 15: continue
		retry_seconds += (1.0/success-1.0)*(row.fight_s+6.0)
	var estimate_main: float = main_active + 12 + data.main_catches*20.0/60 + retry_seconds/60 + 2
	var estimate_hidden: float = estimate_main + (hidden_active-main_active) + 8 + 50.0/60.0
	var checks: Array[Dictionary] = []
	for cp: Dictionary in data.checkpoints:
		if cp.category == "line": checks.append(cp)
	# Minimum-value progression chooses the deepest legal ordinary pool, not unavailable future fish.
	var progress := GameProgress.new()
	var minimum_route: Array[Dictionary] = []
	var catches := 0
	var worst := 0
	for level in range(2,6):
		var profile: FishFightProfile = GameProgress.FISH_PROFILES[[0,5,8,10][level-2]]
		if level == 4: progress.record_catch(GameProgress.FISH_PROFILES[9],GameProgress.FISH_PROFILES[9].min_size_cm,false)
		if level == 5: progress.record_catch(GameProgress.FISH_PROFILES[13],GameProgress.FISH_PROFILES[13].min_size_cm,false)
		var item := progress.next_level("line")
		var waiting := 0
		while progress.money < item.price:
			catches += 1; waiting += 1
			progress.sell_catch(profile,profile.min_size_cm,catches)
		assert(progress.purchase("line",level))
		worst = maxi(worst,waiting)
		minimum_route.append({"line_level":level,"catches_for_purchase":waiting,"minimum_fish":profile.id,"price":item.price,"money_after":progress.money})
	var low_gear := GameProgress.new()
	var low_serial := 0
	var since_upgrade := 0
	var low_gear_worst := 0
	var gear_ledger: Array[Dictionary] = []
	for iteration in range(300):
		if low_gear.levels.line >= 3 and not low_gear.lv4_unlocked(): low_gear.return_catch(GameProgress.FISH_PROFILES[9],80,low_serial+1); low_serial += 1
		if low_gear.levels.line >= 4 and not low_gear.lv5_unlocked(): low_gear.return_catch(GameProgress.FISH_PROFILES[13],180,low_serial+1); low_serial += 1
		for category in ["line","sonar","reel","rod"]:
			var item := low_gear.next_level(category)
			if item != null and item.level <= low_gear.levels.line+1 and low_gear.can_purchase(category,item.level):
				assert(low_gear.purchase(category,item.level))
				gear_ledger.append({"category":category,"level":item.level,"price":item.price,"catches_since_previous":since_upgrade,"money_after":low_gear.money})
				low_gear_worst = maxi(low_gear_worst,since_upgrade)
				since_upgrade = 0
		if gear_ledger.size() == 16: break
		var low_fish: FishFightProfile = GameProgress.FISH_PROFILES[{1:0,2:5,3:8,4:12,5:13}[low_gear.levels.line]]
		low_serial += 1
		low_gear.sell_catch(low_fish,low_fish.min_size_cm,low_serial)
		since_upgrade += 1
	assert(gear_ledger.size() == 16 and low_gear_worst < 10)
	var output := {"main_active_minutes":main_active,"hidden_active_minutes":hidden_active,"estimated_main_minutes":estimate_main,"estimated_hidden_minutes":estimate_hidden,"main_catches":data.main_catches,"hidden_catches":data.hidden_catches,"normal_worst_stall":data.worst_economy_stall,"low_value_worst_stall":worst,"assumptions":assumptions,"line_checkpoints":checks,"minimum_line_route":minimum_route,"low_value_equipment_route":gear_ledger,"low_value_equipment_worst_stall":low_gear_worst,"pacing_target_met":estimate_main >= 60 and estimate_main <= 80 and estimate_hidden >= 80 and estimate_hidden <= 100,"human_validation":"MANUAL TEST REQUIRED"}
	var file := FileAccess.open("/tmp/rc1-pacing.json",FileAccess.WRITE); file.store_string(JSON.stringify(output,"\t")); file.close(); file = null
	print("PACING_SIMULATION ",JSON.stringify(output))
	assert(worst < 10,"Worst same-fish gate should not require ten consecutive catches")
	quit()
