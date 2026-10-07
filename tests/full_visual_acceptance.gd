extends SceneTree
## Presentation-only validation; quality is reserved for human review.
var checks := 0
func visit(path:String) -> void:
	var directory:=DirAccess.open(path)
	for name in directory.get_directories():
		if name != "source":visit(path.path_join(name))
	for name in directory.get_files():
		if name.ends_with(".png"):
			var texture:Texture2D=load(path.path_join(name))
			check(texture!=null and texture.get_width()<=1280 and texture.get_height()<=720,"Committed runtime texture "+path.path_join(name))
func check(value: bool, label: String) -> void:
	assert(value,label);checks+=1
func _initialize() -> void:call_deferred("run")
func run() -> void:
	visit("res://assets/visual/v2")
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
	var progress_before:Dictionary=flow.save_manager.snapshot(flow.progress)
	flow.set_physics_process(false)
	for width in [640,780,800]:
		lake.layout_for_size(Vector2(width,360))
		for i in range(10):await process_frame
		var hud:Control=lake.get_node("HUD/Root")
		for name in ["CastButton","HookButton","ReelButton","ShopButton","BookButton","AreaButton"]:
			var node:Control=hud.get_node(name)
			check(node.size.x>=44 and node.size.y>=44,"Touch target "+name)
	check(flow.save_manager.snapshot(flow.progress)==progress_before,"Presentation does not mutate Save data")
	for profile:FishFightProfile in GameProgress.FISH_PROFILES:
		var frames:=RefinedPixelArt.fish_frames(profile.species_id)
		check(frames.get_frame_count("swim")==3,"Three-frame raster "+profile.id)
		for frame in range(3):check(frames.get_frame_texture("swim",frame) is AtlasTexture,"Raster atlas "+profile.id)
	var adapter:Node=lake.get_node("ProductionVisual")
	for area in LakeAreas.IDS:
		lake.current_area=area
		flow.environment.value=2
		for band in range(7):
			lake.depth_band=band;lake.depth_origin_m=DepthBands.STARTS[band];lake.depth_span_m=DepthBands.ENDS[band]-lake.depth_origin_m
			adapter.backdrop.visual_depth=band
			for i in range(10):await process_frame
			check(adapter.active and adapter.backdrop.visible,"Production scope "+area+str(band))
			check(adapter.backdrop.textures.size()==12,"Only active raster blend packs retained")
	lake.current_area=LakeAreas.SOUTH;lake.depth_band=0;lake.depth_origin_m=0;lake.depth_span_m=15;flow.environment.value=0
	for i in range(20):await process_frame
	check(lake.get_node("GoldenVisual").active and lake.get_node("GoldenVisual").time_label.text=="MORNING","Returning from deep/night restores Golden morning label")
	var nodes:int=get_node_count();var writes:int=flow.save_manager.write_count
	for i in range(100):adapter._process(.1);adapter.backdrop._process(.1)
	check(get_node_count()==nodes and flow.save_manager.write_count==writes,"100 render updates: stable nodes / zero Save writes")
	check(ProductionStory.SKETCH != null,"Mysterious sketch asset")
	main.queue_free();await process_frame
	print("FULL_VISUAL_ACCEPTANCE PASS ",checks," checks. MANUAL ART REVIEW REQUIRED")
	quit()
