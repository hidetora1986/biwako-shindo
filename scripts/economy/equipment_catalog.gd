class_name EquipmentCatalog
extends Resource

@export var levels: Array[EquipmentLevel] = []

func find(category: String, level: int) -> EquipmentLevel:
	for item in levels:
		if item.category == category and item.level == level:
			return item
	return null
