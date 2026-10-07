extends Node
## QA-only fixture in a copied debug project; no production entry point or Save.
var flow: Node2D
var lake: Node2D
func _ready() -> void:
	assert(OS.is_debug_build())
	var main := preload("res://scenes/main.tscn").instantiate()
	flow=main.get_node("LakeScene/FishingController");lake=main.get_node("LakeScene")
	flow.save_path="user://tests/full-visual-%d.json" % Time.get_ticks_usec()
	add_child(main)
	for i in range(10):await get_tree().process_frame
	if flow.story.active:flow.story.skip()
	for i in range(3):await get_tree().process_frame
	var target := "south_morning"
	if OS.has_feature("web"):
		var query: Variant=JavaScriptBridge.eval("new URLSearchParams(location.search).get('view')",true)
		if query is String:target=query
	if target.begins_with("north"):
		lake.current_area=LakeAreas.CENTER if target.contains("center") else LakeAreas.NORTH
		flow.progress.current_area=lake.current_area
	if target.contains("night"):flow.environment.value=2;flow.environment.target=2;flow.environment._apply()
	elif target.contains("sunset"):flow.environment.value=1;flow.environment.target=1;flow.environment._apply()
	if target.begins_with("depth_"):
		var depth:=float(target.trim_prefix("depth_"));var band:=0
		for j in range(DepthBands.STARTS.size()):
			if depth >= DepthBands.STARTS[j]:band=j
		lake.populate_depth_band(band,120,0,true)
	flow._hud.get_node("AreaLabel").text=LakeAreas.DATA[lake.current_area].name
	lake.layout_for_size(lake.view_size)
	if target=="fish_mid":lake.populate_depth_band(2,120,3,true)
	if target=="fish_late":lake.populate_depth_band(4,120,3,true)
	if target=="boss":
		flow.progress.levels={"rod":5,"reel":5,"line":5,"sonar":5}
		flow.progress.night_unlocked=true
		flow.progress.fish_records["No.14"].discovered=true
		lake.current_area=LakeAreas.CENTER;flow.progress.current_area=LakeAreas.CENTER
		lake.populate_depth_band(6,120,0,true)
		flow.boss_encounter.try_spawn(lake,flow.progress,112)
		flow.boss_encounter.reserve(flow._fish_container)
		flow.environment.value=2;flow.environment.target=2;flow.environment._apply()
	if target.begins_with("hidden_"):
		var stage:String=target.trim_prefix("hidden_").to_upper()
		flow.hidden_route.debug_stage(HiddenRoute.Stage[stage])
		flow.hidden_route.step(0)
	if target in ["shop","book","journal","map"]:
		if target=="shop":flow.request_shop()
		elif target=="map":flow.request_area()
		else:
			flow.request_book()
			if target=="journal":flow._hud.get_node("FishBook").show_journal(true)
	flow.set_physics_process(false)
	for i in range(20):await get_tree().process_frame
	if OS.has_feature("web"):JavaScriptBridge.eval("window.fullVisualReady=true",true)
