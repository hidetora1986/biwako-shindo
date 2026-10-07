class_name ProductionSkin
extends RefCounted
## Raster instruments, marine catalog and specimen notebook; no UI actions/data ownership.
static var _styles:Dictionary={}
static func panel(kind:String) -> StyleBoxTexture:
	if not _styles.has(kind):
		var style:=StyleBoxTexture.new();style.texture=load("res://assets/visual/v2/hud/%s.png" % kind)
		style.texture_margin_left=16;style.texture_margin_right=16;style.texture_margin_top=16;style.texture_margin_bottom=16
		style.content_margin_left=8;style.content_margin_right=8;style.content_margin_top=3;style.content_margin_bottom=3
		_styles[kind]=style
	return _styles[kind]
static func button(node:Button,primary:bool=false) -> void:
	for state in ["normal","hover","pressed","disabled"]:
		if primary:
			var style:=StyleBoxTexture.new();style.texture=load("res://assets/visual/golden/south_shore/hud/primary-%s.png" % ("normal" if state=="hover" else state))
			style.texture_margin_left=16;style.texture_margin_right=16;style.texture_margin_top=16;style.texture_margin_bottom=16
			node.add_theme_stylebox_override(state,style)
		else:node.add_theme_stylebox_override(state,panel("catalog"))
	var color:=Color("203d42") if primary else Color("d4e3d4")
	for name in ["font_color","font_hover_color","font_pressed_color"]:node.add_theme_color_override(name,color)
	node.add_theme_color_override("font_disabled_color",Color("788d91"))
static func decorate(hud:Control) -> void:
	var shop:Control=hud.get_node("Shop")
	shop.get_node("Panel").add_theme_stylebox_override("panel",panel("catalog"))
	for category:String in shop._labels:
		var row:HBoxContainer=shop._labels[category].get_parent()
		var icon:=TextureRect.new();icon.texture=load("res://assets/visual/v2/hud/icons/%s.png" % category)
		icon.custom_minimum_size=Vector2(28,24);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
		row.add_child(icon);row.move_child(icon,0)
		shop._labels[category].add_theme_stylebox_override("normal",panel("catalog"))
		button(shop._buttons[category])
	button(shop.get_node("Panel/Close"))
	var book:Control=hud.get_node("FishBook")
	book.get_node("Panel").add_theme_stylebox_override("panel",panel("paper"))
	for name in ["Title","Wallet"]:book.get_node("Panel/"+name).add_theme_color_override("font_color",Color("344844"))
	for id:String in book.entries:
		var label:Label=book.entries[id];label.add_theme_color_override("font_color",Color("304944"))
		label.get_parent().get_parent().add_theme_stylebox_override("panel",panel("paper"))
	for id:String in book.journal_entries:
		book.journal_entries[id].add_theme_color_override("default_color",Color("3e4940"))
	for node:Button in [book.fish_tab,book.journal_tab,book.get_node("Panel/Close"),book.hidden_entry]:button(node)
	var map:Control=hud.get_node("AreaMap")
	map.panel.add_theme_stylebox_override("panel",panel("chart"))
	var chart:=TextureRect.new();chart.name="NavigationChart";chart.texture=preload("res://assets/visual/v2/area_map/chart.png");chart.mouse_filter=Control.MOUSE_FILTER_IGNORE
	chart.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;chart.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map.panel.add_child(chart);map.panel.move_child(chart,0)
	layout_map(map)
	for node:Button in map.buttons.values():button(node)
	button(map.save_button);button(map.close_button)
	hud.get_node("CatchPanel").add_theme_stylebox_override("panel",panel("instrument"))
	for name in ["SellChoice","ReturnChoice"]:button(hud.get_node("CatchPanel/"+name),true)
	var route:HiddenRoute=hud.get_parent().get_parent().get_node("FishingController").hidden_route
	for node:Button in [route.reel,route.cut,route.lift]:button(node,true)
static func layout_map(map:Control) -> void:
	var chart:Control=map.panel.get_node_or_null("NavigationChart")
	if chart==null:return
	chart.position=Vector2(14,58);chart.size=Vector2(156,map.panel.size.y-110)
	for node:Button in map.buttons.values():node.position.x=180;node.size.x=map.panel.size.x-194
