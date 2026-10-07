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
		var initial_band:int=4 if lake.current_area==LakeAreas.CENTER else (3 if target.contains("night") else 1)
		flow.progress.levels={"rod":5,"reel":5,"line":5,"sonar":5}
		lake.populate_depth_band(initial_band,120,0,true);flow.selected_band=initial_band
	if target.contains("night"):flow.environment.value=2;flow.environment.target=2;flow.environment._apply()
	elif target.contains("sunset"):flow.environment.value=1;flow.environment.target=1;flow.environment._apply()
	if target.begins_with("depth_"):
		var depth:=float(target.trim_prefix("depth_"));var band:=0
		for j in range(DepthBands.STARTS.size()):
			if depth >= DepthBands.STARTS[j]:band=j
		lake.populate_depth_band(band,120,0,true)
		flow.selected_band=band
	flow._hud.get_node("AreaLabel").text=LakeAreas.DATA[lake.current_area].name
	lake.layout_for_size(lake.view_size)
	if target=="fish_mid":lake.populate_depth_band(2,120,3,true);flow.selected_band=2
	if target=="fish_late":lake.populate_depth_band(4,120,3,true);flow.selected_band=4
	if target=="boss":
		flow.progress.levels={"rod":5,"reel":5,"line":5,"sonar":5}
		flow.progress.night_unlocked=true
		flow.progress.fish_records["No.14"].discovered=true
		lake.current_area=LakeAreas.CENTER;flow.progress.current_area=LakeAreas.CENTER
		lake.populate_depth_band(6,120,0,true);flow.selected_band=6
		flow.boss_encounter.try_spawn(lake,flow.progress,112)
		flow.boss_encounter.reserve(flow._fish_container)
		flow.active_fish=flow.boss_encounter.boss
		flow.active_fish.hook()
		flow.active_fish.position=Vector2(lake.view_size.x*.68,lake.surface_y+(lake.view_size.y-lake.surface_y)*.46)
		flow.fight=BossFishingFight.new();flow.fight.start(flow.active_fish.fight_profile,1.3,500,400)
		flow.state=flow.State.FIGHTING
		flow.environment.value=2;flow.environment.target=2;flow.environment._apply()
	if target in ["hidden_contact","hidden_fight","hidden_choice","hidden_reel_up","hidden_reveal"]:
		var stage:String=target.trim_prefix("hidden_").to_upper()
		flow.hidden_route.debug_stage(HiddenRoute.Stage[stage])
		flow.hidden_route.step(0)
	if target in ["shop","book","journal","map"]:
		if target=="shop":flow.request_shop()
		elif target=="map":flow.request_area()
		else:
			flow.request_book()
			if target=="journal":flow._hud.get_node("FishBook").show_journal(true)
	if target in ["catch","no10_choice","no14_choice"]:
		var index:int=9 if target=="no10_choice" else (13 if target=="no14_choice" else 1)
		var profile:FishFightProfile=GameProgress.FISH_PROFILES[index]
		flow.state=flow.State.LANDED if target=="catch" else flow.State.CHOOSING
		flow._hud.show_catch({"id":profile.id,"name":profile.display_name,"size_cm":42.6,"price":1430,"new_discovery":true},RefinedPixelArt.fish_texture(profile.species_id))
		if target!="catch":flow._hud.show_unknown_choice(true)
	if target in ["hook","fight","cast"]:
		flow.active_fish=flow._fish_container.get_child(0)
		if target=="hook":flow._begin_bite()
		elif target=="cast":flow.state=flow.State.CASTING
		else:
			flow.fight.start(flow.active_fish.fight_profile)
			flow.state=flow.State.FIGHTING
		flow._refresh_ui()
	if target=="title":flow.state=flow.State.TITLE;flow.ending_screen.show_title();flow._set_cinematic(true)
	if target.begins_with("story_"):
		var words:PackedStringArray=target.trim_prefix("story_").split("_")
		flow.story.begin(words[0]);flow.story.section=int(words[1]);flow.story._render()
		if words[0]=="opening":flow.story.opening.step(1.0)
	if target=="credits":flow.story.begin("main");flow.story._finish_content()
	if target=="hidden_104":flow.hidden_route.debug_stage(HiddenRoute.Stage.DEPTH);flow.hidden_route.elapsed=1.0;flow.hidden_route.step(0)
	if target=="hidden_121":flow.hidden_route.debug_stage(HiddenRoute.Stage.DEPTH);flow.hidden_route.elapsed=4.5;flow.hidden_route.step(0)
	if not target.begins_with("story_") and target not in ["credits","title"]:flow._refresh_ui()
	flow._hud.get_node("AreaLabel").text=LakeAreas.DATA[lake.current_area].name
	flow._hud.set_area_range(lake.depth_origin_m,lake.depth_span_m)
	flow.set_physics_process(false)
	for i in range(20):await get_tree().process_frame
	var backdrop:Node=lake.get_node("ProductionVisual").backdrop
	backdrop.visual_depth=float(lake.depth_band)
	backdrop._refresh_assets();backdrop.queue_redraw()
	for i in range(3):await get_tree().process_frame
	if OS.has_feature("web"):JavaScriptBridge.eval("window.fullVisualReady=true",true)

func _process(_delta:float) -> void:
	# The screenshot fixture freezes flow physics. Keep its displayed boss line/depth
	# synchronized after viewport changes, as ordinary gameplay physics does.
	if flow!=null and flow.state==flow.State.FIGHTING and flow.active_fish!=null and flow.active_fish.fight_profile.is_boss:
		flow.lure.depth_m=112
		flow.lure.position=flow.active_fish.position+Vector2(flow.active_fish.swim_direction*(flow.active_fish._half_width-6),0)
		flow._hud.show_lure_depth(112,true)
		flow._update_line()
