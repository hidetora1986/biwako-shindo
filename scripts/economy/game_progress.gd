class_name GameProgress
extends RefCounted
## Session-only economy. All transactions finish before changed is emitted.

signal changed
signal depth_unlocked(previous_depth: float, next_depth: float)
const CATEGORIES := ["rod", "reel", "line", "sonar"]
var catalog: EquipmentCatalog = preload("res://data/equipment/mvp.tres")
var money: int = 0
var levels: Dictionary = {"rod": 1, "reel": 1, "line": 1, "sonar": 1}
var _last_sold_session: int = 0

func current(category: String) -> EquipmentLevel:
	return catalog.find(category, int(levels.get(category, 1)))

func next_level(category: String) -> EquipmentLevel:
	if not levels.has(category):
		return null
	return catalog.find(category, int(levels[category]) + 1)

func sell_catch(fish: FishFightProfile, size_cm: float, session_id: int) -> int:
	if fish == null or session_id <= _last_sold_session:
		return 0
	var price := fish.sale_price(size_cm)
	money += price
	_last_sold_session = session_id
	changed.emit()
	return price

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
