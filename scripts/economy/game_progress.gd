class_name GameProgress
extends RefCounted
## Wallet, equipment, fish records and the one-time event flag. All transactions finish before changed is emitted.

signal changed
signal depth_unlocked(previous_depth: float, next_depth: float)
const CATEGORIES := ["rod", "reel", "line", "sonar"]
var catalog: EquipmentCatalog = preload("res://data/equipment/mvp.tres")
var money: int = 0
var levels: Dictionary = {"rod": 1, "reel": 1, "line": 1, "sonar": 1}
const FISH_PROFILES := [preload("res://data/fish/bluegill-fight.tres"), preload("res://data/fish/bass-fight.tres"), preload("res://data/fish/crucian-fight.tres"), preload("res://data/fish/catfish-fight.tres"), preload("res://data/fish/biwamasu-fight.tres"), preload("res://data/fish/giant-catfish-fight.tres"), preload("res://data/fish/pale-biwamasu-fight.tres"), preload("res://data/fish/long-eel-fight.tres"), preload("res://data/fish/blind-isaza-fight.tres"), preload("res://data/fish/unknown-a-fight.tres")]
var fish_records: Dictionary = {}
var returned_unknown_a: bool = false
var anomaly_seen: bool = false
var sonar_sessions: int = 0
var last_sale_new_discovery: bool = false
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
	return null if next != null and next.level >= 4 and not lv4_unlocked() else next

func sell_catch(fish: FishFightProfile, size_cm: float, session_id: int) -> int:
	if fish == null or session_id <= _last_sold_session:
		return 0
	var price := fish.sale_price(size_cm)
	last_sale_new_discovery = record_catch(fish, size_cm, false)
	money += price
	_last_sold_session = session_id
	changed.emit()
	return price

func return_catch(fish: FishFightProfile, size_cm: float, session_id: int) -> bool:
	if fish == null or fish.id != "No.10" or session_id <= _last_sold_session:
		return false
	last_sale_new_discovery = record_catch(fish, size_cm, false)
	returned_unknown_a = true
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
