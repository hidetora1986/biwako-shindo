class_name GameProgress
extends RefCounted
## Wallet, equipment, fish records and the one-time event flag. All transactions finish before changed is emitted.

signal changed
signal depth_unlocked(previous_depth: float, next_depth: float)
const CATEGORIES := ["rod", "reel", "line", "sonar"]
var catalog: EquipmentCatalog = preload("res://data/equipment/mvp.tres")
var money: int = 0
var levels: Dictionary = {"rod": 1, "reel": 1, "line": 1, "sonar": 1}
const FISH_PROFILES := [preload("res://data/fish/bluegill-fight.tres"), preload("res://data/fish/bass-fight.tres"), preload("res://data/fish/crucian-fight.tres"), preload("res://data/fish/catfish-fight.tres"), preload("res://data/fish/biwamasu-fight.tres"), preload("res://data/fish/giant-catfish-fight.tres"), preload("res://data/fish/pale-biwamasu-fight.tres"), preload("res://data/fish/long-eel-fight.tres"), preload("res://data/fish/blind-isaza-fight.tres"), preload("res://data/fish/unknown-a-fight.tres"), preload("res://data/fish/thread-jaw-fight.tres"), preload("res://data/fish/split-belly-fight.tres"), preload("res://data/fish/reverse-scale-fight.tres"), preload("res://data/fish/unknown-b-fight.tres"), preload("res://data/fish/lake-master-fight.tres")]
var fish_records: Dictionary = {}
var returned_unknown_a: bool = false
var returned_unknown_b: bool = false
var night_unlocked: bool = false
var boss15_defeated: bool = false
var main_ending_seen: bool = false
var hull_knock_count: int = 0
var zero_depth_contact_seen: bool = false
var max_depth_reached_m: float = 0.0
var anomaly_seen: bool = false
var sonar_sessions: int = 0
var last_sale_new_discovery: bool = false
# No.00 is deliberately outside FISH_PROFILES / ordinary catch records.
var anonymous_lure_obtained: bool = false
var anonymous_lure_equipped: bool = false
var hidden_entry_seen: bool = false
var no00_contacted: bool = false
var hidden_cut_ending_seen: bool = false
var hidden_contact_ending_seen: bool = false
var hidden_postgame_sessions: int = 0
var second_playthrough_hooks: Dictionary = {}
var _last_sold_session: int = 0

func _init() -> void:
	for fish: FishFightProfile in FISH_PROFILES:
		fish_records[fish.id] = {"discovered": false, "caught_count": 0, "best_size_cm": 0.0}

func lv4_unlocked() -> bool:
	return fish_records.get("No.10", {}).get("discovered", false)

func current(category: String) -> EquipmentLevel:
	return catalog.find(category, int(levels.get(category, 1)))

func next_level(category: String) -> EquipmentLevel:
	if not levels.has(category):
		return null
	var next := catalog.find(category, int(levels[category]) + 1)
	if next != null and ((next.level == 4 and not lv4_unlocked()) or (next.level >= 5 and not lv5_unlocked())):
		return null
	return next

func sell_catch(fish: FishFightProfile, size_cm: float, session_id: int) -> int:
	if fish == null or fish.id == "00" or session_id <= _last_sold_session or (fish.is_boss and boss15_defeated):
		return 0
	var price := fish.sale_price(size_cm)
	last_sale_new_discovery = record_catch(fish, size_cm, false)
	money = mini(2147483647, money + price)
	_last_sold_session = session_id
	changed.emit()
	return price

func return_catch(fish: FishFightProfile, size_cm: float, session_id: int) -> bool:
	if fish == null or fish.id not in ["No.10", "No.14"] or session_id <= _last_sold_session:
		return false
	last_sale_new_discovery = record_catch(fish, size_cm, false)
	if fish.id == "No.10":
		returned_unknown_a = true
	else:
		returned_unknown_b = true
	_last_sold_session = session_id
	changed.emit()
	return true

func can_purchase(category: String, expected_level: int) -> bool:
	var item := next_level(category)
	return item != null and item.level == expected_level and item.price >= 0 and money >= item.price

func purchase(category: String, expected_level: int) -> bool:
	if not can_purchase(category, expected_level):
		return false
	var item := next_level(category)
	var previous := current(category).effect_value
	money -= item.price
	levels[category] = item.level
	if category == "sonar" and item.level == 2:
		sonar_sessions = 0
	changed.emit()
	if category == "line":
		depth_unlocked.emit(previous, item.effect_value)
	return true

func cheapest_next() -> EquipmentLevel:
	var cheapest: EquipmentLevel
	for category: String in CATEGORIES:
		var item := next_level(category)
		if item != null and (cheapest == null or item.price < cheapest.price):
			cheapest = item
	return cheapest

func record_catch(fish: FishFightProfile, size_cm: float, notify: bool = true) -> bool:
	if not fish_records.has(fish.id):
		return false
	var record: Dictionary = fish_records[fish.id]
	var is_new: bool = not record.discovered
	record.discovered = true
	if fish.id == "No.12":
		night_unlocked = true
	if fish.is_boss:
		boss15_defeated = true
	record.caught_count = mini(2147483647, record.caught_count + 1)
	record.best_size_cm = maxf(record.best_size_cm, snappedf(clampf(size_cm, fish.min_size_cm, fish.max_size_cm), 0.1))
	if notify:
		changed.emit()
	return is_new

func complete_normal_session() -> void:
	if levels.sonar >= 2 and not anomaly_seen and sonar_sessions < 3:
		sonar_sessions += 1
		changed.emit()

func finish_anomaly() -> void:
	if not anomaly_seen:
		anomaly_seen = true
		changed.emit()

func lv5_unlocked() -> bool:
	return fish_records.get("No.14", {}).get("discovered", false)

func time_of_day_target() -> float:
	if main_ending_seen:
		return 0.0
	return 2.0 if night_unlocked else (1.0 if fish_records["No.11"].discovered else 0.0)

func note_depth(depth_m: float) -> void:
	var previous := max_depth_reached_m
	max_depth_reached_m = maxf(previous, clampf(depth_m, 0, 120))
	# Persist the two event milestones, never every sinking frame.
	if (previous < 60 and max_depth_reached_m >= 60) or (previous < 70 and max_depth_reached_m >= 70):
		changed.emit()

func finish_hull_knock(stage: int) -> void:
	if stage == hull_knock_count + 1 and stage <= 3:
		hull_knock_count = stage
		changed.emit()

func finish_zero_contact() -> void:
	if not zero_depth_contact_seen:
		zero_depth_contact_seen = true
		changed.emit()

func finish_main_ending() -> void:
	if boss15_defeated and not main_ending_seen:
		main_ending_seen = true
		changed.emit()

func can_encounter_boss() -> bool:
	return lv5_unlocked() and levels.rod == 5 and levels.line == 5 and night_unlocked and not boss15_defeated

func hidden_eligible() -> bool:
	if not (boss15_defeated and main_ending_seen and returned_unknown_a and returned_unknown_b and hull_knock_count >= 3 and zero_depth_contact_seen and levels.sonar == 5 and night_unlocked):
		return false
	for record: Dictionary in fish_records.values():
		if not record.discovered:
			return false
	return true

func hidden_finished() -> bool:
	return hidden_cut_ending_seen or hidden_contact_ending_seen

func note_postgame_catch() -> void:
	if hidden_eligible() and not anonymous_lure_obtained:
		hidden_postgame_sessions = mini(3, hidden_postgame_sessions + 1)
		if hidden_postgame_sessions >= 2:
			anonymous_lure_obtained = true
		changed.emit()

func mark_hidden_entry() -> void:
	if hidden_eligible() and not hidden_entry_seen:
		hidden_entry_seen = true
		changed.emit()

func finish_hidden(contact: bool) -> void:
	if hidden_finished():
		return
	if contact:
		hidden_contact_ending_seen = true
		no00_contacted = true
	else:
		hidden_cut_ending_seen = true
	second_playthrough_hooks = {"first_record_count":2,"returning_dialogue":true,"sonar_depth_flash":120}
	changed.emit()

func no00_record() -> Dictionary:
	return {"id":"00","discovered":no00_contacted,"caught_count":2 if no00_contacted else 0,"description":"記録が一致しない。" if no00_contacted else "この項目は存在しない。"}
