extends "res://scripts/visual/golden/golden_water.gd"
## Existing lightweight ripples/rod/reflection plus a night-only lamp, no model changes.
var flow: Node2D
func _draw() -> void:
	super._draw()
	if flow == null or flow.environment.value < 1.25:return
	var a:=clampf((flow.environment.value-1.25)/.75,0,1)
	var lamp:Vector2=boat.position+Vector2(30,-20)
	draw_rect(Rect2(lamp-Vector2(3,5),Vector2(6,8)),Color(.86,.73,.42,a))
	draw_rect(Rect2(lamp-Vector2(1,4),Vector2(2,6)),Color(.98,.9,.65,a))
	for i in range(6):
		var x:float=lamp.x+sin(time+i)*2
		draw_line(Vector2(x-4+i*.4,lake.surface_y+5+i*3),Vector2(x+4-i*.4,lake.surface_y+5+i*3),Color(.9,.78,.45,a*(.3-i*.035)),1)
