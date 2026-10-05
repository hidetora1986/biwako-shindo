extends SceneTree
## Durable checkpoints from actual full run, atomic interruption, old/malformed snapshots.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var checks := 0
	var path := "user://tests/rc1-durable.json"
	var manager := SaveManager.new(path)
	var progress := GameProgress.new()
	manager.bind_progress(progress)
	assert(manager.save_progress(progress)); checks += 1
	for index in range(15):
		var fish: FishFightProfile = GameProgress.FISH_PROFILES[index]
		if fish.id in ["No.10","No.14"]: assert(progress.return_catch(fish,fish.min_size_cm,index+1))
		else: assert(progress.sell_catch(fish,fish.min_size_cm,index+1) > 0)
		var restored := GameProgress.new()
		assert(manager.load_into(restored) and restored.money == progress.money and restored.fish_records == progress.fish_records)
		assert(restored.returned_unknown_a == progress.returned_unknown_a and restored.returned_unknown_b == progress.returned_unknown_b)
		checks += 2
	# Hull sequences persist only completed stages; interrupted stage is retried, not skipped.
	for stage in range(1,4):
		progress.finish_hull_knock(stage)
		var restored := GameProgress.new()
		assert(manager.load_into(restored) and restored.hull_knock_count == stage); checks += 1
	progress.finish_zero_contact(); progress.finish_main_ending()
	progress.levels = {"rod":5,"reel":5,"line":5,"sonar":5}
	progress.changed.emit()
	progress.note_postgame_catch(); progress.note_postgame_catch()
	assert(progress.anonymous_lure_obtained); checks += 1
	var before := FileAccess.get_file_as_bytes(path)
	var temporary := FileAccess.open(path+".tmp",FileAccess.WRITE); temporary.store_string("partial"); temporary.close(); temporary = null
	var checkpoint := GameProgress.new()
	assert(manager.load_into(checkpoint) and checkpoint.money == progress.money and checkpoint.hidden_eligible() and not checkpoint.hidden_finished() and before == FileAccess.get_file_as_bytes(path))
	checks += 1
	progress.finish_hidden(true)
	for repeat in range(100):
		progress.finish_hidden(true)
		var restored := GameProgress.new()
		assert(manager.load_into(restored) and restored.no00_record().caught_count == 2 and restored.no00_contacted)
		checks += 1
	var sold_first := GameProgress.new()
	var serial := 0
	for index in [9,13]:
		var fish: FishFightProfile = GameProgress.FISH_PROFILES[index]
		serial += 1
		assert(sold_first.sell_catch(fish,fish.min_size_cm,serial) > 0)
		serial += 1
		assert(sold_first.return_catch(fish,fish.min_size_cm,serial))
	assert(sold_first.unknown_a_sold_first and sold_first.unknown_b_sold_first and not sold_first.hidden_eligible()); checks += 1
	assert(manager.save_progress(sold_first))
	var loaded_sale := GameProgress.new()
	assert(manager.load_into(loaded_sale) and loaded_sale.unknown_a_sold_first and loaded_sale.unknown_b_sold_first); checks += 1
	manager.unbind_progress()
	DirAccess.remove_absolute(path); DirAccess.remove_absolute(path+".tmp")
	print("RC1_SAVE_STRESS PASS ",checks)
	quit()
