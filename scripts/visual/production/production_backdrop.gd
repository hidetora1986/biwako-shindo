extends Node2D
## Cached modular raster planes. Only display values are blended, never lake depth/state.
var lake: Node2D
var flow: Node2D
var textures: Dictionary = {}
var visual_depth := 0.0
var elapsed := 0.0
func _ready() -> void:
	z_index = 0
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for area in ["south_shore","north_shore","north_center"]:
		for time in ["morning","day","sunset","night"]:
			for plane in ["sky","far","middle","shore","surface"]:
				var path := "res://assets/visual/v2/environment/%s/%s/%s.png" % [area,time,plane]
				textures[area+time+plane] = load(path)
	for band in ["shallow","mid","lower_mid","deep","cold","dark","abyss"]:
		textures[band] = load("res://assets/visual/v2/depth/%s/water.png" % band)
func _process(delta: float) -> void:
	if not visible:return
	elapsed += delta
	visual_depth = move_toward(visual_depth,float(lake.depth_band),delta*2.0)
	if elapsed >= 0.05:elapsed = 0;queue_redraw()
func _draw() -> void:
	if lake == null or textures.is_empty():return
	var value: float = flow.environment.value if flow.environment != null else 0.0
	var times := ["morning","day","sunset","night"]
	var phase := clampf(value*1.5,0,3)
	var lo := mini(2,int(phase));var blend := phase-lo
	var above := Rect2(Vector2.ZERO,Vector2(lake.view_size.x,lake.surface_y))
	for plane in ["sky","far","middle","shore","surface"]:
		draw_texture_rect(textures[lake.current_area+times[lo]+plane],above,false)
		if blend>0:draw_texture_rect(textures[lake.current_area+times[lo+1]+plane],above,false,Color(1,1,1,blend))
	var bands := ["shallow","mid","lower_mid","deep","cold","dark","abyss"]
	var index := mini(5,int(visual_depth));var fraction := visual_depth-index
	var below := Rect2(0,lake.surface_y,lake.view_size.x,lake.view_size.y-lake.surface_y)
	var tint := Color.WHITE.lerp(Color("668694"),clampf(value*.18,0,.36))
	draw_texture_rect(textures[bands[index]],below,false,tint)
	if fraction>0:draw_texture_rect(textures[bands[index+1]],below,false,Color(tint.r,tint.g,tint.b,fraction))
