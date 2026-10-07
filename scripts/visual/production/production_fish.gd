class_name ProductionFish
extends RefCounted
## Original committed sheets, native geometry, fixed three-phase atlas cache.
const SHEETS := {
"giant_catfish":preload("res://assets/visual/v2/fish/midgame/giant_catfish.png"),
"pale_biwamasu":preload("res://assets/visual/v2/fish/midgame/pale_biwamasu.png"),
"long_eel":preload("res://assets/visual/v2/fish/midgame/long_eel.png"),
"blind_isaza":preload("res://assets/visual/v2/fish/midgame/blind_isaza.png"),
"unknown_a":preload("res://assets/visual/v2/fish/midgame/unknown_a.png"),
"thread_jaw":preload("res://assets/visual/v2/fish/lategame/thread_jaw.png"),
"split_belly":preload("res://assets/visual/v2/fish/lategame/split_belly.png"),
"reverse_scale":preload("res://assets/visual/v2/fish/lategame/reverse_scale.png"),
"unknown_b":preload("res://assets/visual/v2/fish/lategame/unknown_b.png")}
static var _cache: Dictionary={}
static func texture(species: String, phase: int) -> Texture2D:
	var key:=species+str(phase%3)
	if not _cache.has(key):
		var atlas:=AtlasTexture.new();var sheet:Texture2D=SHEETS[species]
		atlas.atlas=sheet;atlas.region=Rect2(0,(phase%3)*sheet.get_height()/3,sheet.get_width(),sheet.get_height()/3);atlas.filter_clip=true
		_cache[key]=atlas
	return _cache[key]
