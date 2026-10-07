class_name MainEndingScreen
extends Control
## Short dawn/title overlay; flow owns Save and transitions. No hidden-route UI.
signal continued

func _ready() -> void:
	var english:=Label.new();english.text="BIWAKO SHINDO";english.position=Vector2(0,52);english.size=Vector2(500,22);english.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;english.add_theme_font_size_override("font_size",14);$Title.add_child(english)
	ProductionSkin.button($Continue,true)
	$Continue.pressed.connect(func():continued.emit())

func configure(view_size: Vector2, safe: Rect2) -> void:
	size = view_size
	$Fade.size = view_size
	$Title.size = Vector2(minf(500,safe.size.x),60)
	$Title.position = Vector2(safe.get_center().x-$Title.size.x/2,safe.get_center().y-76)
	$Clear.size = Vector2(safe.size.x,28)
	$Clear.position = Vector2(safe.position.x,safe.get_center().y-9)
	var physical_scale := maxf(0.1,minf(float(get_window().size.x)/view_size.x,float(get_window().size.y)/view_size.y))
	$Continue.size = Vector2(minf(240,safe.size.x),maxf(56,44.0/physical_scale))
	$Continue.add_theme_font_size_override("font_size",maxi(20,int(ceil(12.0/physical_scale))))
	$Continue.position = Vector2(safe.get_center().x-$Continue.size.x/2,safe.get_center().y+35)

func show_dawn(elapsed: float) -> void:
	visible = true
	$Title.visible = false
	$Clear.visible = false
	$Continue.visible = false
	var opacity := elapsed/0.6 if elapsed < 0.6 else maxf(0,1.0-(elapsed-0.6)/0.6)
	$Fade.color = Color(0.06,0.12,0.18,opacity * 0.85)

func show_title() -> void:
	visible = true
	$Fade.color = Color(0.04,0.10,0.15,0.34)
	$Title.visible = true
	$Clear.visible = true
	$Continue.visible = true

func _input(event: InputEvent) -> void:
	if visible and $Continue.visible and event is InputEventScreenTouch and event.pressed:
		if $Continue.get_global_rect().has_point(event.position):
			continued.emit()
			get_viewport().set_input_as_handled()
