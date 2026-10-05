class_name HiddenVisual
extends Control
## Only unbounded surface fragments. No body, closed silhouette, face or catch sprite.
var old_contacts: Array[Dictionary] = []
var amount: float = 0
var motion: float = 0
var sonar_rect := Rect2()
var surface_y: float = 0
var depth_text: String = ""
var warning: bool = false
var title_shadow: bool = false
var under_boat: bool = false
var fade: float = 0

func _draw() -> void:
	if title_shadow:
		draw_rect(Rect2(-40,surface_y+22,size.x+80,12),Color(0.03,0.07,0.09,0.10))
	if amount > 0:
		draw_rect(Rect2(0,surface_y,size.x,size.y-surface_y),Color(0.01,0.02,0.035,amount*0.92))
		# Open horizontal arcs continue beyond both screen edges, never a full outline.
		for i in range(4):
			var y := surface_y + 65 + i*27 + sin(motion*0.45+i)*7
			draw_line(Vector2(-80,y),Vector2(size.x+80,y+18),Color(0.035,0.045,0.065,amount*(0.35-i*0.05)),5)
		draw_rect(sonar_rect,Color("101723"))
		var font := ThemeDB.fallback_font
		draw_string(font,sonar_rect.position+Vector2(10,20),"SONAR  " + depth_text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("c2a2a3"))
		for contact: Dictionary in old_contacts:
			var point := sonar_rect.position + Vector2(20+contact.x_fraction*(sonar_rect.size.x-40),32+contact.depth_m/120*(sonar_rect.size.y-50))
			draw_rect(Rect2(point,Vector2(contact.dot_width,2)),Color(0.7,0.85,0.7,1-amount))
		for i in range(8):
			var offset := 0.0 if warning else sin(motion*1.4+i*2.3)*8
			var r := Rect2(sonar_rect.position+Vector2(5,30+i*9+offset),Vector2(sonar_rect.size.x-10-i%3*13,5+i%2*3))
			draw_rect(r,Color(0.38+i%3*0.03,0.09,0.13,amount*0.7))
	if under_boat:
		draw_rect(Rect2(-40,surface_y+3,size.x+80,13),Color(0.005,0.01,0.015,0.85))
	if fade > 0: draw_rect(Rect2(Vector2.ZERO,size),Color(0.015,0.025,0.04,fade))
