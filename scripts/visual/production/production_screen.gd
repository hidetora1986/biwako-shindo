extends Node
## Full-game presentation adapter. Never mutates progress, AI, RNG, inputs or saves.
var lake: Node2D
var flow: Node2D
var golden: Node
var backdrop: Node2D
var water: Node2D
var active := false
var timer := 0.0
var last_size := Vector2.ZERO
var was_active := false
func _ready() -> void:
	lake = get_parent();flow = lake.get_node("FishingController");golden = lake.get_node("GoldenVisual")
	call_deferred("_build")
func _build() -> void:
	backdrop = Node2D.new();backdrop.name = "ProductionBackdrop";backdrop.set_script(preload("res://scripts/visual/production/production_backdrop.gd"));backdrop.lake=lake;backdrop.flow=flow;lake.add_child(backdrop)
	# Move the raster planes before existing boat/fish, preserving their draw order.
	lake.move_child(backdrop,0)
	water = Node2D.new();water.name="ProductionWater";water.set_script(preload("res://scripts/visual/production/production_water.gd"));water.lake=lake;water.flow=flow;water.boat=lake.get_node("Lake/Boat");lake.add_child(water)
	backdrop.visible=false;water.visible=false
func _process(delta: float) -> void:
	timer -= delta
	if timer>0 or backdrop==null:return
	timer=.05
	active = not golden.active and flow.state != flow.State.HIDDEN and (flow.hidden_route == null or flow.hidden_route.visual.amount <= 0)
	backdrop.visible=active;water.visible=active
	if active:
		for path in ["Background/BackgroundSky","Background/BackgroundMountains","Underwater/WaterBackground","Lake/LakeSurface"]:lake.get_node(path).visible=false
		var boat: Node2D=lake.get_node("Lake/Boat")
		boat.boat_art=GoldenAssets.BOAT;boat.get_node("Sprite").texture=GoldenAssets.BOAT
		for fish: FishController in lake.get_node("Underwater/FishContainer").get_children():fish.sprite.set_golden(GoldenAssets.FISH.has(fish.fight_profile.species_id))
		# Reuse the exact Golden instrument skin/layout without changing its scope flag.
		if not was_active or last_size != lake.view_size:
			golden._skin();golden.active=true;golden.apply_layout();golden.active=false
			last_size = lake.view_size
			golden.time_label.add_theme_color_override("font_color",Color("a3bcb9"))
			golden.hud.get_node("AreaLabel").add_theme_color_override("font_color",Color("dae7d4"))
			var badge:=StyleBoxFlat.new();badge.bg_color=Color(0.05,.13,.16,.75);badge.content_margin_left=5
			golden.hud.get_node("AreaLabel").add_theme_stylebox_override("normal",badge)
		golden.time_label.visible=flow.state not in [flow.State.TITLE,flow.State.ENDING,flow.State.NARRATIVE] and not flow.story.active
		golden.time_label.text="NIGHT" if flow.environment.value>1.5 else ("SUNSET" if flow.environment.value>.65 else "MORNING")
		golden.hud.get_node("SonarPlaceholder").golden_visual=true
		if flow.state==flow.State.READY:golden.hud.set_area_range(lake.depth_origin_m,lake.depth_span_m)

	if not active and was_active and not golden.active:
		for path in ["Background/BackgroundSky","Background/BackgroundMountains","Underwater/WaterBackground","Lake/LakeSurface"]:lake.get_node(path).visible=true
	if golden.active:
		if was_active or golden.time_label.text!="MORNING":
			golden.time_label.text="MORNING"
			golden.time_label.add_theme_color_override("font_color",Color("365451"))
	was_active=active
