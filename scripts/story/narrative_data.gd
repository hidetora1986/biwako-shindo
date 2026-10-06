class_name NarrativeData
extends RefCounted
const PATH := "res://data/story/narrative-v1.json"
const PAGE_IDS := ["early","fish05","fish10","deep","night","knock","fish14","main","sketch","postgame","last"]
static var _content: Dictionary = {}
static func content() -> Dictionary:
	if _content.is_empty(): _content = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return _content

static func pages(progress: GameProgress) -> Array[String]:
	var result: Array[String] = ["early"]
	for id: String in PAGE_IDS:
		if id in progress.journal_pages_unlocked and id not in result and (id != "sketch" or progress.main_ending_seen): result.append(id)
	var conditions := {"fish05":progress.fish_records["No.05"].discovered,"fish10":progress.lv4_unlocked(),"deep":progress.fish_records["No.11"].discovered or progress.fish_records["No.12"].discovered or progress.fish_records["No.13"].discovered,"night":progress.night_page_seen,"knock":progress.hull_knock_count > 0,"fish14":progress.lv5_unlocked(),"main":progress.main_story_ending_seen,"sketch":progress.main_ending_seen,"postgame":progress.main_story_ending_seen,"last":progress.hidden_eligible() or progress.hidden_finished()}
	for id: String in PAGE_IDS:
		if conditions.get(id,false) and id not in result: result.append(id)
	var ordered: Array[String] = []
	for id: String in PAGE_IDS:
		if id in result: ordered.append(id)
	return ordered
