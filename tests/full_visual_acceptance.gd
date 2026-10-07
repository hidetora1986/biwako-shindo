extends SceneTree
## Presentation-only validation; quality is reserved for human review.
var checks := 0
func check(value: bool, label: String) -> void:
	assert(value,label);checks+=1
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for area in ["south_shore","north_shore","north_center"]:
		for time in ["morning","day","sunset","night"]:
			for plane in ["sky","far","middle","shore","surface"]:
				var texture: Texture2D=load("res://assets/visual/v2/environment/%s/%s/%s.png" % [area,time,plane])
				check(texture!=null and texture.get_width() in [640,1280],"Environment plane "+area+time+plane)
	for band in ["shallow","mid","lower_mid","deep","cold","dark","abyss"]:
		var texture: Texture2D=load("res://assets/visual/v2/depth/%s/water.png" % band)
		check(texture!=null and texture.get_height() in [224,448],"Depth "+band)
	var main: Node2D=load("res://scenes/main.tscn").instantiate()
	var flow:Node2D=main.get_node("LakeScene/FishingController")
	flow.save_path="user://tests/full-visual-acceptance.json"
	DirAccess.remove_absolute(flow.save_path)
	root.add_child(main)
	for i in range(20):await process_frame
	if flow.story.active:flow.story.skip()
	var lake: Node2D=main.get_node("LakeScene")
	var progress_before:String=JSON.stringify([flow.progress.money,flow.progress.levels,flow.progress.fish_records])
	for width in [640,780,800]:
		lake.layout_for_size(Vector2(width,360))
		for i in range(10):await process_frame
		var hud:Control=lake.get_node("HUD/Root")
		for name in ["CastButton","HookButton","ReelButton","ShopButton","BookButton","AreaButton"]:
			var node:Control=hud.get_node(name)
			check(node.size.x>=44 and node.size.y>=44,"Touch target "+name)
	check(JSON.stringify([flow.progress.money,flow.progress.levels,flow.progress.fish_records])==progress_before,"Presentation does not mutate Save data")
	main.queue_free();await process_frame
	print("FULL_VISUAL_ACCEPTANCE PASS ",checks," checks. MANUAL ART REVIEW REQUIRED")
	quit()
