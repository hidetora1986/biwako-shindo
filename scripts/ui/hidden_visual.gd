class_name HiddenVisual
extends Control
## Only unbounded surface fragments. No body, closed silhouette, face or catch sprite.
const SURFACE_FRAGMENT: Texture2D = preload("res://assets/visual/hidden/no00/unbounded-surface.png")

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
		# No.00-only world illustration. Existing amount/motion still own transitions.
		var drift := sin(motion*0.45)*3
		draw_texture_rect_region(SURFACE_FRAGMENT,Rect2(0,0,size.x,surface_y),Rect2(0,0,640,136),Color(1,1,1,amount))
		draw_texture_rect_region(SURFACE_FRAGMENT,Rect2(-3,surface_y+drift,size.x+6,size.y-surface_y+6),Rect2(0,136,640,224),Color(1,1,1,amount))
		_draw_boat(amount)
		_draw_instruments(amount)
		draw_rect(sonar_rect,Color("101723"))
		draw_rect(sonar_rect,Color(0.3,0.42,0.48,amount*0.75),false,1)
		for i in range(4):
			var y := sonar_rect.position.y+32+i*20
			draw_line(Vector2(sonar_rect.position.x+8,y),Vector2(sonar_rect.end.x-8,y),Color(0.12,0.2,0.27,amount*0.7),1)
		var font := ThemeDB.fallback_font
		draw_string(font,sonar_rect.position+Vector2(10,20),"SONAR  " + depth_text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("c2a2a3"))
		for contact: Dictionary in old_contacts:
			var point := sonar_rect.position + Vector2(20+contact.x_fraction*(sonar_rect.size.x-40),32+contact.depth_m/120*(sonar_rect.size.y-50))
			draw_rect(Rect2(point,Vector2(contact.dot_width,2)),Color(0.7,0.85,0.7,1-amount))
		# Same hidden response/warning inputs; arc fragments replace flat red bars.
		var offset := 0.0 if warning else sin(motion*1.4)*3
		for i in range(48):
			var u := float(i)/47
			var point := sonar_rect.position+Vector2(8+u*(sonar_rect.size.x-16),sonar_rect.size.y-12-sin(u*PI)*(sonar_rect.size.y-45)+offset)
			var tint := Color(0.38+i%3*0.03,0.09,0.13,amount*0.7)
			draw_rect(Rect2(point,Vector2(2+i%3,1+i%2)),tint)
			if i%2 == 0:draw_rect(Rect2(point+Vector2(1,9+i%7),Vector2(2,1)),Color(tint,amount*0.3))
	if under_boat:
		draw_rect(Rect2(-40,surface_y+3,size.x+80,13),Color(0.005,0.01,0.015,0.85))
	if fade > 0: draw_rect(Rect2(Vector2.ZERO,size),Color(0.015,0.025,0.04,fade))

var _flow: Node2D
var _boat: Node2D
var _depth_modulate := Color.WHITE
var _depth_owned := false
var _contact_owned := false
var _message_had_color := false
var _message_color := Color.WHITE
var _message_font_size := 24

func _ready() -> void:
	var lake: Node2D = get_parent().get_parent().get_parent()
	_flow = lake.get_node("FishingController")
	_boat = lake.get_node("Lake/Boat")

func _process(_delta: float) -> void:
	# Paint the existing depth reading in a compact instrument; do not change its value/visibility.
	if not is_instance_valid(_flow) or _flow.hidden_route == null:return
	var label: Label = _flow.hidden_route.depth_label
	if not is_instance_valid(label):return
	if amount > 0 and not _depth_owned:
		_depth_modulate = label.modulate;_depth_owned = true;label.modulate.a = 0
	elif amount <= 0 and _depth_owned:
		label.modulate = _depth_modulate;_depth_owned = false
	var message: Label = _flow.hidden_route.message
	if amount > 0 and _flow.hidden_route.stage == HiddenRoute.Stage.CONTACT:
		if not _contact_owned:
			_message_had_color = message.has_theme_color_override("font_color")
			_message_color = message.get_theme_color("font_color")
			_message_font_size = message.get_theme_font_size("font_size")
			_contact_owned = true
		message.position.y = surface_y+62
		message.add_theme_color_override("font_color",Color("bb6262"))
		message.add_theme_font_size_override("font_size",18)
	elif _contact_owned:
		if _message_had_color:message.add_theme_color_override("font_color",_message_color)
		else:message.remove_theme_color_override("font_color")
		message.add_theme_font_size_override("font_size",_message_font_size)
		_contact_owned = false

func _draw_boat(alpha: float) -> void:
	if not is_instance_valid(_boat):return
	var point: Vector2 = _boat.position
	draw_texture_rect(GoldenAssets.BOAT,Rect2(point+Vector2(-77,-61)*0.8,Vector2(154,64)*0.8),false,Color(0.65,0.72,0.77,alpha))
	var grip := point+Vector2(-25,-30)*0.8
	var tip: Vector2 = _boat.rod_tip_position()
	draw_line(grip,(grip+tip)*0.5+Vector2(0,3),Color(0.5,0.6,0.6,alpha),1)
	draw_line((grip+tip)*0.5+Vector2(0,3),tip,Color(0.75,0.66,0.42,alpha),1)
	var lamp := point+Vector2(16,-31)*0.8
	draw_rect(Rect2(lamp-Vector2(3,2),Vector2(9,12)),Color(0.9,0.55,0.19,alpha*0.2))
	draw_rect(Rect2(lamp,Vector2(3,7)),Color(1,0.8,0.4,alpha))
	for i in range(4):draw_line(point+Vector2(11-i,5+i*4),point+Vector2(24+i,5+i*4),Color(0.9,0.63,0.26,alpha*(0.6-i*0.1)),1)
	if is_instance_valid(_flow) and _flow.line.visible and _flow.line.get_point_count() == 2:
		draw_polyline(_flow.line.points,Color(0.65,0.73,0.67,alpha*0.7),1)

func _draw_instruments(alpha: float) -> void:
	var font := ThemeDB.fallback_font
	var safe: Rect2 = _flow._hud.safe_rect
	var ink := Color(0.58,0.76,0.82,alpha)
	draw_rect(Rect2(safe.position,Vector2(92,40)),Color(0.01,0.04,0.06,alpha*0.8))
	draw_rect(Rect2(safe.position,Vector2(92,40)),Color(0.35,0.53,0.6,alpha*0.6),false,1)
	draw_string(font,safe.position+Vector2(10,28),"¥%d" % _flow.progress.money,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color(0.91,0.84,0.61,alpha))
	var title := "BIWAKO SHINDO"
	draw_string(font,Vector2((size.x-font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x)*0.5,safe.position.y+16),title,HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
	var sub := "LAKE BIWA / NIGHT"
	draw_string(font,Vector2((size.x-font.get_string_size(sub,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x)*0.5,safe.position.y+31),sub,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color(ink,alpha*0.8))
	var origin := Vector2(safe.position.x,surface_y+10)
	draw_rect(Rect2(origin,Vector2(68,120)),Color(0.01,0.04,0.06,alpha*0.75))
	draw_line(origin,origin+Vector2(0,120),Color(ink,alpha*0.75),1)
	var readings := ["104m","108m","114m","121m","---"]
	var reached := readings.find(depth_text)
	for i in range(5):
		var tint := Color(ink,alpha*(1.0 if i == reached else 0.45))
		if i == 4:tint = Color(0.65,0.2,0.25,alpha*(1.0 if reached == 4 else 0.35))
		draw_string(font,origin+Vector2(8,19+i*23),readings[i],HORIZONTAL_ALIGNMENT_LEFT,-1,14,tint)
		if i < 4:draw_line(origin+Vector2(5,24+i*23),origin+Vector2(61,24+i*23),Color(ink,alpha*0.18),1)
