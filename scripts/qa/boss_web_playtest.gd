class_name BossWebPlaytest
extends RefCounted
## Opt-in Web playtest fixture. Never reads, resets or writes the normal save.
const SAVE_PATH := "user://web-boss-playtest/no15/save.json"

static func requested() -> bool:
	if OS.has_feature("web") and OS.has_feature("web_playtest"):
		return JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('boss_test')", true) == "15"
	return OS.is_debug_build() and "--boss15-playtest" in OS.get_cmdline_user_args()

static func fresh_progress() -> GameProgress:
	var result := GameProgress.new()
	for fish: FishFightProfile in GameProgress.FISH_PROFILES:
		if fish.id != "No.15":
			result.record_catch(fish, fish.min_size_cm, false)
	result.levels = {"rod":5,"reel":5,"line":5,"sonar":5}
	result.current_area = LakeAreas.CENTER
	result.night_unlocked = true
	result.anomaly_seen = true
	result.hull_knock_count = 3
	result.zero_depth_contact_seen = true
	result.returned_unknown_a = true
	result.returned_unknown_b = true
	return result

static func configure(flow: Node2D) -> void:
	flow.environment.value = 2
	flow.environment.target = 2
	flow.environment._apply()
	flow.select_depth_band(6)
	flow._hud.get_node("Subtitle").text = "No.15 BOSS PLAYTEST"
