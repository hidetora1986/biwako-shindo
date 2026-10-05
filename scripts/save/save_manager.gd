class_name SaveManager
extends RefCounted
## Versioned JSON in user://. Transactions save atomically; reads never rewrite.
const VERSION := 1
const MAX_INTEGER := 2147483647
var save_path: String = "user://biwako-shindo/save.json"
var last_error: Error = OK
var write_count: int = 0
var _progress: GameProgress

func _init(path: String = "user://biwako-shindo/save.json") -> void:
	save_path = path

func bind_progress(progress: GameProgress) -> void:
	unbind_progress()
	_progress = progress
	progress.changed.connect(_auto_save)

func unbind_progress() -> void:
	if _progress != null and _progress.changed.is_connected(_auto_save):
		_progress.changed.disconnect(_auto_save)
	_progress = null

func _auto_save() -> void:
	save_progress(_progress)

func save_progress(progress: GameProgress) -> bool:
	last_error = DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
	if last_error != OK:
		return false
	var temporary := save_path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = FileAccess.get_open_error()
		return false
	file.store_string(JSON.stringify(snapshot(progress), "\t"))
	file.flush()
	last_error = file.get_error()
	file.close()
	if last_error == OK:
		last_error = DirAccess.rename_absolute(temporary, save_path)
	if last_error != OK:
		DirAccess.remove_absolute(temporary)
		return false
	write_count += 1
	return true

func snapshot(progress: GameProgress) -> Dictionary:
	var discovered: Dictionary = {}
	var counts: Dictionary = {}
	var best: Dictionary = {}
	for id: String in progress.fish_records:
		var record: Dictionary = progress.fish_records[id]
		discovered[id] = record.discovered
		counts[id] = record.caught_count
		best[id] = record.best_size_cm
	return {"save_version": VERSION, "money": progress.money, "rod_level": progress.levels.rod, "reel_level": progress.levels.reel, "line_level": progress.levels.line, "sonar_level": progress.levels.sonar, "fish_discovered": discovered, "fish_caught_count": counts, "fish_best_size": best, "anomaly_seen": progress.anomaly_seen, "sonar_sessions": progress.sonar_sessions, "returned_unknown_a": progress.returned_unknown_a, "returned_unknown_b": progress.returned_unknown_b, "night_unlocked": progress.night_unlocked, "boss15_defeated": progress.boss15_defeated, "main_ending_seen": progress.main_ending_seen, "hull_knock_count": progress.hull_knock_count, "zero_depth_contact_seen": progress.zero_depth_contact_seen, "max_depth_reached_m": progress.max_depth_reached_m}

func load_into(progress: GameProgress) -> bool:
	var raw: Variant = null
	if FileAccess.file_exists(save_path):
		var file := FileAccess.open(save_path, FileAccess.READ)
		if file != null:
			var json := JSON.new()
			if file.get_length() <= 1048576 and json.parse(file.get_as_text()) == OK:
				raw = json.data
			file.close()
	var valid := raw is Dictionary
	var data: Dictionary = raw if valid else {}
	# A future migration dispatch belongs here. Unsupported versions start safely.
	if _integer(data.get("save_version", VERSION), -1, 0, MAX_INTEGER) != VERSION:
		data = {}
		valid = false
	progress.money = _integer(data.get("money"), 0, 0, MAX_INTEGER)
	for category: String in GameProgress.CATEGORIES:
		var level := _integer(data.get(category + "_level"), 1, 1, MAX_INTEGER)
		progress.levels[category] = level if progress.catalog.find(category, level) != null else 1
	var discovered := _dictionary(data.get("fish_discovered"))
	var counts := _dictionary(data.get("fish_caught_count"))
	var best := _dictionary(data.get("fish_best_size"))
	for fish: FishFightProfile in GameProgress.FISH_PROFILES:
		var count := _integer(counts.get(fish.id), 0, 0, MAX_INTEGER)
		var found: bool = (discovered.get(fish.id, false) == true and discovered.get(fish.id) is bool) or count > 0
		var size := _number(best.get(fish.id), 0, 0, fish.max_size_cm)
		if size > 0 and size < fish.min_size_cm:
			size = 0
		progress.fish_records[fish.id] = {"discovered": found, "caught_count": count, "best_size_cm": snappedf(size, 0.1) if found else 0.0}
	progress.anomaly_seen = data.get("anomaly_seen") is bool and data.get("anomaly_seen") == true
	progress.sonar_sessions = _integer(data.get("sonar_sessions"), 0, 0, 3)
	progress.returned_unknown_a = data.get("returned_unknown_a") is bool and data.get("returned_unknown_a") == true
	progress.returned_unknown_b = data.get("returned_unknown_b") is bool and data.get("returned_unknown_b") == true
	progress.night_unlocked = (data.get("night_unlocked") is bool and data.get("night_unlocked") == true) or progress.fish_records["No.12"].discovered
	progress.hull_knock_count = _integer(data.get("hull_knock_count"), 0, 0, 3)
	progress.zero_depth_contact_seen = data.get("zero_depth_contact_seen") is bool and data.get("zero_depth_contact_seen") == true
	progress.max_depth_reached_m = _number(data.get("max_depth_reached_m"), 0, 0, 120)
	progress.boss15_defeated = (data.get("boss15_defeated") is bool and data.get("boss15_defeated") == true) or progress.fish_records["No.15"].discovered
	progress.main_ending_seen = progress.boss15_defeated and data.get("main_ending_seen") is bool and data.get("main_ending_seen") == true
	if not progress.lv5_unlocked():
		for category: String in GameProgress.CATEGORIES:
			progress.levels[category] = mini(4, progress.levels[category])
	# Additive v1 migration: absent new records/flag default, existing progress stays.
	if not progress.lv4_unlocked():
		for category: String in GameProgress.CATEGORIES:
			progress.levels[category] = mini(3, progress.levels[category])
	return valid

func _dictionary(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}

func _integer(value: Variant, fallback: int, minimum: int, maximum: int) -> int:
	if not (value is int or value is float):
		return fallback
	var number := float(value)
	if not is_finite(number) or number < minimum or number > maximum or floorf(number) != number:
		return fallback
	return int(number)

func _number(value: Variant, fallback: float, minimum: float, maximum: float) -> float:
	if not (value is int or value is float):
		return fallback
	var number := float(value)
	return number if is_finite(number) and number >= minimum and number <= maximum else fallback
