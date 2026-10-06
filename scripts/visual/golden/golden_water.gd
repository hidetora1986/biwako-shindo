extends Node2D
## Twelve suspended motes, raster wave segments and rod/wake presentation at 20 Hz.
const WATERLINE := preload("res://assets/visual/golden/south_shore/water/waterline.png")
const GLITTER := preload("res://assets/visual/golden/south_shore/water/glitter.png")
const MOTE := preload("res://assets/visual/golden/south_shore/water/mote.png")
var lake: Node2D
var boat: Node2D
var time := 0.0
var timer := 0.0
var points: Array[Vector2] = []
func _ready() -> void:
	z_index = 4
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for i in range(12):points.append(Vector2(float((i*197+61)%631)/640.0,float((i*137+47)%211)/215.0))
func _process(delta: float) -> void:
	if not visible:return
	time += delta;timer += delta
	if timer >= 0.05:timer = fmod(timer,0.05);queue_redraw()
func _draw() -> void:
	if lake == null:return
	var y: float = lake.surface_y
	for i in range(int(ceil(lake.view_size.x/128.0))):
		draw_texture(WATERLINE,Vector2(i*128+floorf(sin(time*0.9+i)*2),y-2+floorf(sin(time+i*1.7)*1.5)))
	for i in range(3):draw_texture(GLITTER,Vector2(lake.view_size.x*0.36+i*53+floorf(sin(time+i)*2),y-30+i*6),Color(1,1,1,0.4))
	for i in range(points.size()):
		var point := Vector2(points[i].x*lake.view_size.x+sin(time*0.15+i)*3,y+12+fmod(points[i].y*(lake.view_size.y-y-24)+time*0.3,lake.view_size.y-y-24))
		draw_texture(MOTE,point.floor())
	if boat != null:
		var base: Vector2 = boat.position
		for i in range(3):
			draw_texture_rect_region(GoldenAssets.BOAT,Rect2(base+Vector2(-59+i*6,2+i*3),Vector2(114-i*12,1)),Rect2(15,52+i*2,114-i*12,1),Color(0.72,0.84,0.82,0.23-i*0.045))
			draw_line(base+Vector2(-76+i*8,3+i*3),base+Vector2(74-i*8,3+i*3),Color(0.77,0.88,0.8,0.21-i*0.045),1)
		# Read the original rod tip; its gameplay attachment is never moved.
		var hand := base+Vector2(-25,-30)
		var tip: Vector2 = boat.rod_tip_position()
		draw_line(hand,hand.lerp(tip,0.5)+Vector2(0,boat._tension*0.02),Color("344e51"),1)
		draw_line(hand.lerp(tip,0.5)+Vector2(0,boat._tension*0.02),tip,Color("647c73"),1)
