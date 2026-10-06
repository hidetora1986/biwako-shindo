class_name GoldenSonar
extends RefCounted
const FRAME := preload("res://assets/visual/golden/south_shore/hud/sonar-frame.png")
static func paint(s: SonarDisplay) -> void:
	s.draw_texture_rect(FRAME,Rect2(Vector2.ZERO,s.size),false)
	var font: Font = s.text_font if s.text_font != null else ThemeDB.fallback_font
	var level: int = 1 if s._progress == null else s._progress.levels.sonar
	s.draw_string(font,Vector2(9,19),"SONAR",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("c8e4d8"))
	s.draw_string(font,Vector2(s.size.x-82,19),"Lv%d  %dm" % [level,s.max_depth()],HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("93b8b5"))
	for fraction in [0.0,0.5,1.0]:
		var y: float = s.depth_y(s.max_depth()*fraction)
		s.draw_line(Vector2(24,y),Vector2(s.size.x-9,y),Color("254552"),1)
		s.draw_string(font,Vector2(7,y+3),"%d" % (s.max_depth()*fraction),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("779c9b"))
	var focused: int = s._focus_index % maxi(1,s.contacts.size())
	for index in range(s.contacts.size()):
		var c: Dictionary = s.contacts[index]
		var point := Vector2(28+c.x_fraction*(s.size.x-44),s.depth_y(c.depth_m)).floor()
		var half: float = floorf(c.dot_width/2.0)
		s.draw_line(point+Vector2(-half,1),point+Vector2(0,-1),Color("e3d994"),1)
		s.draw_line(point+Vector2(0,-1),point+Vector2(half,1),Color("c8e4d8"),1)
		if index == focused and level >= 2:s.draw_rect(Rect2(point-Vector2(maxf(9,c.dot_width+4)/2,3),Vector2(maxf(9,c.dot_width+4),6)),Color("6fc5c4"),false,1)
	if not s.contacts.is_empty() and level >= 2:
		s.draw_string(font,Vector2(9,s.size.y-22),s.contacts[focused].size_text+" · %.1fm" % s.contacts[focused].depth_m,HORIZONTAL_ALIGNMENT_LEFT,s.size.x-18,12,Color("c8e4d8"))
		if level >= 3:s.draw_string(font,Vector2(9,s.size.y-6),s.contacts[focused].name_text,HORIZONTAL_ALIGNMENT_LEFT,s.size.x-18,12,Color("c8e4d8"))
	if s.zero_contact_active:s.draw_rect(Rect2(Vector2(floorf(s.size.x*0.52)-8,s.depth_y(0)-1),Vector2(16,3)),Color("b0cdc2"))
	if s.anomaly_active:
		var x: float = lerpf(-40,s.size.x+40,s.anomaly_progress)
		var y: float = s.depth_y(s.max_depth())-3
		s.draw_rect(Rect2(floorf(x)-20,y-3,40,6),Color("a4bfa7"))
		s.draw_rect(Rect2(floorf(x)-24,y-1,5,2),Color("a4bfa7"))
