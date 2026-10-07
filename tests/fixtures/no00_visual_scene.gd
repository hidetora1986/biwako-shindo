extends Node
## Local screenshot fixture only. Not referenced by the production main scene; release exports exclude tests.
var flow: Node2D
var route: HiddenRoute
var ready_for_capture := false
func _ready() -> void:
	assert(OS.is_debug_build())
	var main := preload("res://scenes/main.tscn").instantiate()
	flow = main.get_node("LakeScene/FishingController")
	flow.save_path = "user://tests/no00-visual-browser-%d.json" % Time.get_ticks_usec()
	add_child(main)
	for i in range(5):await get_tree().process_frame
	if flow.story.active:flow.story.skip()
	for i in range(3):await get_tree().process_frame
	route = flow.hidden_route
	var target := "FIGHT"
	if OS.has_feature("web"):
		var query: Variant = JavaScriptBridge.eval("new URLSearchParams(location.search).get('qa_stage')",true)
		if query is String:target = query
	assert(target in ["CONTACT","FIGHT","CHOICE","REEL_UP"])
	assert(route.debug_stage(HiddenRoute.Stage[target]))
	flow.set_physics_process(false)
	for fish: Node in flow._fish_container.get_children():fish.set_physics_process(false)
	route.step(0)
	ready_for_capture = true
	if OS.has_feature("web"):JavaScriptBridge.eval("window.no00VisualReady=true",true)
func _process(delta: float) -> void:
	if ready_for_capture:
		# Real existing model / touch input; only the initial progress is a fixture.
		route.step(delta)
		if OS.has_feature("web") and route.stage == HiddenRoute.Stage.FIGHT:
			JavaScriptBridge.eval("window.no00Reeling=%s" % str(route.fight.reeling).to_lower(),true)
