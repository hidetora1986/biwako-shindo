extends Node
## Presentation-only scope adapter. No simulation data, visibility of fish, input signals or Save writes.
@export var enabled := true
var active := false
var lake: Node2D
var flow: Node2D
var hud: Control
var backdrop: Node2D
var water: Node2D
var time_label: Label
var _original: Dictionary = {}
var _original_boat_texture: Texture2D
var _original_boat_art: Texture2D
var _layout_size := Vector2.ZERO
var _sample_timer := 0.0

func _ready() -> void:
	lake = get_parent();flow = lake.get_node("FishingController");hud = lake.get_node("HUD/Root")
	for name in ["Money","Depth","Title","Subtitle","AreaLabel","ShopButton","BookButton","AreaButton","SaveButton","CastButton","HookButton","ReelButton","DepthBandButton","NextUpgrade","SonarPlaceholder","Money/Label","Depth/Label"]:
		var node: Control = hud.get_node(name)
		_original[name] = {"position":node.position,"size":node.size,"minimum":node.custom_minimum_size,"modulate":node.modulate,"text":node.text if node is Button else ""}
	_original_boat_texture = lake.get_node("Lake/Boat/Sprite").texture
	_original_boat_art = lake.get_node("Lake/Boat").boat_art
	call_deferred("_build")

func _build() -> void:
	backdrop = Node2D.new();backdrop.name = "GoldenBackdrop";backdrop.set_script(preload("res://scripts/visual/golden/golden_backdrop.gd"));lake.add_child(backdrop)
	water = Node2D.new();water.name = "GoldenWater";water.set_script(preload("res://scripts/visual/golden/golden_water.gd"));water.lake = lake;water.boat = lake.get_node("Lake/Boat");lake.add_child(water)
	time_label = Label.new();time_label.name = "GoldenTime";time_label.text = "MORNING";time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE;hud.add_child(time_label)
	backdrop.visible = false;water.visible = false;time_label.visible = false
	sync_scope()

func _process(delta: float) -> void:
	_sample_timer -= delta
	if _sample_timer <= 0:
		_sample_timer = 0.05;sync_scope()

func eligible() -> bool:
	return enabled and flow.environment != null and lake.current_area == LakeAreas.SOUTH and lake.depth_origin_m == 0 and flow.environment.value <= 0.001 and flow.state not in [flow.State.TRAVELLING,flow.State.ENDING,flow.State.TITLE,flow.State.HIDDEN,flow.State.NARRATIVE,flow.State.BOSS_BITE] and (flow.story == null or not flow.story.active)

func sync_scope() -> void:
	if not is_instance_valid(backdrop) or not backdrop.is_inside_tree() or not water.is_inside_tree() or not time_label.is_inside_tree():return
	var next := eligible()
	if next != active:
		active = next
		for path in ["Background/BackgroundSky","Background/BackgroundMountains","Underwater/WaterBackground","Lake/LakeSurface"]:lake.get_node(path).visible = not active
		backdrop.visible = active;water.visible = active;time_label.visible = active
		var boat: Node2D = lake.get_node("Lake/Boat")
		boat.boat_art = GoldenAssets.BOAT if active else _original_boat_art
		boat.get_node("Sprite").texture = GoldenAssets.BOAT if active else _original_boat_texture
		boat.queue_redraw()
		for fish: FishController in lake.get_node("Underwater/FishContainer").get_children():fish.sprite.set_golden(active)
		hud.get_node("SonarPlaceholder").golden_visual = active;hud.get_node("SonarPlaceholder").queue_redraw()
		if active:
			if _style_snapshot.is_empty():capture_styles()
			_skin()
		else:_restore_skin();hud.configure(lake.view_size,lake.surface_y,lake.depth_span_m)
		_layout_size = Vector2.ZERO
	if active and _layout_size != hud.size:apply_layout()

func _skin() -> void:
	for name in ["Money","Depth"]:
		var node: Panel = hud.get_node(name);node.custom_minimum_size = Vector2.ZERO
		var style := StyleBoxFlat.new();style.bg_color = Color(0.05,0.13,0.16,0.72);style.border_color = Color("6a9699");style.border_width_bottom = 1
		node.add_theme_stylebox_override("panel",style)
	for name in ["ShopButton","BookButton","AreaButton","SaveButton","DepthBandButton"]:
		var button: Button = hud.get_node(name)
		for state in ["normal","hover","pressed","disabled"]:
			var style := StyleBoxFlat.new();style.bg_color = Color(0.05,0.13,0.16,0.58 if state != "pressed" else 0.85);style.border_color = Color("709998");style.border_width_bottom = 1
			style.content_margin_left = 3;style.content_margin_right = 3
			button.add_theme_stylebox_override(state,style)
		button.add_theme_font_size_override("font_size",12)
	for name in ["CastButton","HookButton","ReelButton"]:
		var button: Button = hud.get_node(name)
		for state in ["normal","hover","pressed","disabled"]:
			var style := StyleBoxTexture.new()
			style.texture = load("res://assets/visual/golden/south_shore/hud/primary-%s.png" % ("normal" if state == "hover" else state))
			style.texture_margin_left = 16;style.texture_margin_right = 16;style.texture_margin_top = 16;style.texture_margin_bottom = 16
			style.content_margin_top = 2 if state == "pressed" else 0
			button.add_theme_stylebox_override(state,style)
		button.add_theme_color_override("font_color",Color("203d42"));button.add_theme_color_override("font_hover_color",Color("203d42"));button.add_theme_color_override("font_pressed_color",Color("203d42"));button.add_theme_color_override("font_disabled_color",Color("90aaa0"))
		hud.get_node(name).add_theme_font_size_override("font_size",22)
	hud.get_node("Title").modulate.a = 0;hud.get_node("Subtitle").modulate.a = 0
	hud.get_node("BookButton").text = "BOOK"
	var heading: Label = hud.get_node("AreaLabel")
	var font := FontVariation.new();font.base_font = preload("res://assets/fonts/NotoSansJP.ttf")
	font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"):500.0}
	heading.add_theme_font_override("font",font)
	heading.add_theme_color_override("font_color",Color("173943"))
	var badge := StyleBoxFlat.new();badge.bg_color = Color(0.84,0.9,0.79,0.73);badge.content_margin_left = 5
	heading.add_theme_stylebox_override("normal",badge)
	time_label.add_theme_font_size_override("font_size",11);time_label.add_theme_color_override("font_color",Color("365451"))

func _restore_skin() -> void:
	# Restore the exact local overrides that existed before this adapter took ownership.
	for name: String in _original:
		var node: Control = hud.get_node(name);node.custom_minimum_size = _original[name].minimum;node.modulate = _original[name].modulate
		node.size = _original[name].size
		if name in ["Money/Label","Depth/Label"]:node.position = _original[name].position
		if node is Button:
			if name == "BookButton":node.text = _original[name].text
			for state in ["normal","hover","pressed","disabled"]:node.remove_theme_stylebox_override(state)
			for color in ["font_color","font_hover_color","font_pressed_color","font_disabled_color"]:node.remove_theme_color_override(color)
			node.remove_theme_font_size_override("font_size")
		elif node is Panel:node.remove_theme_stylebox_override("panel")
	hud.get_node("AreaLabel").remove_theme_stylebox_override("normal")
	hud.get_node("AreaLabel").remove_theme_font_override("font")
	# Scene-authored styles are reinstated by the stored snapshot below.
	for key: String in _style_snapshot:
		var entry: Dictionary = _style_snapshot[key]
		var node: Control = hud.get_node(entry.node)
		if entry.kind == "style":node.add_theme_stylebox_override(entry.property,entry.value)
		elif entry.kind == "color":node.add_theme_color_override(entry.property,entry.value)
		elif entry.kind == "font_resource":node.add_theme_font_override(entry.property,entry.value)
		else:node.add_theme_font_size_override(entry.property,entry.value)

var _style_snapshot: Dictionary = {}
func capture_styles() -> void:
	for name: String in _original:
		var node: Control = hud.get_node(name)
		for property in ["panel","normal","hover","pressed","disabled"]:
			if node.has_theme_stylebox_override(property):_style_snapshot[name+property] = {"node":name,"kind":"style","property":property,"value":node.get_theme_stylebox(property)}
		for property in ["font_color","font_hover_color","font_pressed_color","font_disabled_color"]:
			if node.has_theme_color_override(property):_style_snapshot[name+property] = {"node":name,"kind":"color","property":property,"value":node.get_theme_color(property)}
		if node.has_theme_font_override("font"):_style_snapshot[name+"font_resource"] = {"node":name,"kind":"font_resource","property":"font","value":node.get_theme_font("font")}
		if node.has_theme_font_size_override("font_size"):_style_snapshot[name+"font"] = {"node":name,"kind":"font","property":"font_size","value":node.get_theme_font_size("font_size")}

func apply_layout() -> void:
	if not active or hud == null:return
	_layout_size = hud.size
	backdrop.configure(lake.view_size,lake.surface_y)
	var safe: Rect2 = hud.core_rect
	var left: float = safe.position.x;var top: float = safe.position.y
	var pixel_scale := maxf(0.1,minf(float(get_window().size.x)/hud.size.x,float(get_window().size.y)/hud.size.y))
	var tap := 44.0/pixel_scale
	hud.get_node("AreaLabel").position = Vector2(left,top-2);hud.get_node("AreaLabel").size = Vector2(190,24)
	time_label.position = Vector2(left+1,top+20);time_label.size = Vector2(180,18)
	var money: Panel = hud.get_node("Money");money.position = Vector2(left+220,top);money.size = Vector2(106,28)
	money.get_node("Label").position = Vector2(7,1);money.get_node("Label").size = Vector2(92,26);money.get_node("Label").add_theme_font_size_override("font_size",18)
	for i in range(3):
		var button: Button = hud.get_node(["ShopButton","BookButton","AreaButton"][i]);button.position = Vector2(left+i*maxf(57,tap+5),top+44);button.size = Vector2(maxf(52,tap),maxf(44,tap));button.custom_minimum_size = Vector2.ZERO
	var sonar: Control = hud.get_node("SonarPlaceholder");sonar.custom_minimum_size = Vector2.ZERO;sonar.size = Vector2(156,104);sonar.position = Vector2(safe.end.x-156,top)
	var depth: Panel = hud.get_node("Depth");depth.position = Vector2(left,lake.surface_y+52);depth.size = Vector2(88,28)
	depth.get_node("Label").position = Vector2(7,0);depth.get_node("Label").size = Vector2(77,28)
	hud.get_node("DepthBandButton").position = Vector2(left,lake.surface_y+86);hud.get_node("DepthBandButton").size = Vector2(maxf(118,tap),maxf(44,tap))
	for name in ["CastButton","HookButton","ReelButton"]:
		var button: Button = hud.get_node(name);button.custom_minimum_size = Vector2.ZERO;button.size = Vector2(maxf(144,tap),maxf(64,tap));button.position = safe.end-button.size
	hud.get_node("NextUpgrade").position = Vector2(left,safe.end.y-hud.get_node("NextUpgrade").size.y)
