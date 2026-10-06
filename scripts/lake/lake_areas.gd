class_name LakeAreas
extends RefCounted
## Small data table: area gates augment, never replace, existing depth/boss gates.
const SOUTH := "south_shore"
const NORTH := "north_shore"
const CENTER := "north_center"
const IDS := [SOUTH, NORTH, CENTER]
const DATA := {
	SOUTH: {"name": "南湖沿岸", "min_depth": 0.0, "max_depth": 30.0, "first_fish": 1, "last_fish": 7, "gate": "初期解放", "shore": 1.0},
	NORTH: {"name": "北湖沿岸", "min_depth": 15.0, "max_depth": 85.0, "first_fish": 6, "last_fish": 13, "gate": "LINE Lv3", "shore": 0.55},
	CENTER: {"name": "北湖中央", "min_depth": 50.0, "max_depth": 120.0, "first_fish": 11, "last_fish": 15, "gate": "No.10 発見 / LINE Lv4", "shore": 0.12},
}

static func unlocked(id: String, progress: GameProgress) -> bool:
	match id:
		SOUTH: return true
		NORTH: return progress.levels.line >= 3
		CENTER: return progress.levels.line >= 4 and progress.lv4_unlocked()
	return false

static func band_available(id: String, band: int, line_depth: float) -> bool:
	if not DATA.has(id) or not DepthBands.available(band, line_depth): return false
	var area: Dictionary = DATA[id]
	return DepthBands.STARTS[band] >= area.min_depth and DepthBands.STARTS[band] < area.max_depth

static func allows_fish(id: String, fish: FishFightProfile) -> bool:
	if not DATA.has(id): return false
	var number := int(fish.id.trim_prefix("No."))
	return number >= DATA[id].first_fish and number <= DATA[id].last_fish

static func pool(id: String, band: int, line_depth: float) -> Array[FishFightProfile]:
	return DepthBands.pool(band, minf(line_depth, DATA[id].max_depth)).filter(func(fish: FishFightProfile) -> bool: return allows_fish(id, fish))

static func safe_band(id: String, band: int, line_depth: float) -> int:
	if band_available(id, band, line_depth): return band
	for candidate in range(DepthBands.STARTS.size()):
		if band_available(id, candidate, line_depth): return candidate
	return 0
