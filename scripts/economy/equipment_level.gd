class_name EquipmentLevel
extends Resource

@export_enum("rod", "reel", "line", "sonar") var category: String = "rod"
@export var level: int = 1
@export var price: int = 0
@export var effect_value: float = 60.0
@export var display_name: String = "ロッド Lv.1"
@export var effect_label: String = "最大対応サイズ"
@export var effect_unit: String = "cm"
@export var capability: String = ""

func effect_text() -> String:
	if effect_unit == "×":
		return "×%.2f" % effect_value
	return "%d%s" % [int(effect_value), effect_unit]
