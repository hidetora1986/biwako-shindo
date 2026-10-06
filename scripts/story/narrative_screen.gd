class_name NarrativeScreen
extends Control
## Short, skippable presentation only. No fishing/economy/RNG changes.
var flow: Node2D
var mode := ""
var section := 0
var elapsed := 0.0
var input_lock := 0.0
var active := false
var credits := false
var flip_remaining := 0.0
var shadow_remaining := 0.0
var steps: Array[Dictionary] = []
var panel: Panel
var text: Label
var heading: Label
var skip_button: Button
var old_mark: Line2D
var new_mark: Line2D
var safe := Rect2()
var mysterious_sketch: MysteriousSketch
var _font: Font = preload("res://assets/fonts/NotoSansJP.ttf")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 120
	theme = preload("res://assets/ui/pixel_theme.tres")
	mysterious_sketch = preload("res://scenes/story/mysterious_sketch.tscn").instantiate()
	add_child(mysterious_sketch)
	panel = Panel.new(); add_child(panel)
	heading = Label.new();panel.add_child(heading)
	heading.add_theme_font_override("font",_font)
	heading.add_theme_font_size_override("font_size",16)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text = Label.new();panel.add_child(text)
	text.add_theme_font_override("font",_font)
	text.add_theme_font_size_override("font_size",22)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skip_button = Button.new();add_child(skip_button)
	skip_button.text = "SKIP";skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	skip_button.pressed.connect(skip)
	old_mark = Line2D.new();old_mark.width = 3;old_mark.default_color = Color("84938b");add_child(old_mark)
	new_mark = Line2D.new();new_mark.width = 3;new_mark.default_color = Color("314845");add_child(new_mark)
	old_mark.visible = false;new_mark.visible = false
	panel.visible = false;skip_button.visible = false

func setup(controller: Node2D) -> void:
	flow = controller
	configure(flow._hud.size,flow._hud.safe_rect)

func configure(view_size: Vector2, safe_area: Rect2) -> void:
	size = view_size;safe = safe_area
	mysterious_sketch.configure(view_size,safe_area)
	panel.size = Vector2(minf(540,safe.size.x),150)
	panel.position = Vector2(safe.get_center().x-panel.size.x/2,safe.get_center().y-35)
	heading.position = Vector2(12,10);heading.size = Vector2(panel.size.x-24,24)
	text.position = Vector2(16,38);text.size = panel.size-Vector2(32,48)
	var scale := maxf(0.1,float(get_window().size.y)/view_size.y)
	skip_button.size = Vector2(maxf(96,44/scale),maxf(44,44/scale))
	skip_button.position = Vector2(safe.end.x-skip_button.size.x,safe.position.y)
	_update_marks()
	queue_redraw()

func begin(kind: String) -> void:
	flip_remaining = 0
	mode = kind;active = true;credits = false;section = 0;elapsed = 0
	steps = []
	if kind == "opening":
		for line: String in NarrativeData.content().opening: steps.append({"text":line,"seconds":5.0,"heading":""})
	elif kind == "main":
		for page: Dictionary in JSON.parse_string(FileAccess.get_file_as_string(MysteriousSketch.CARDS_PATH)).cards:steps.append(page)
	elif kind == "cut":
		steps = [{"text":"","seconds":2.0,"heading":""},{"text":"","seconds":4.0,"heading":"祖父の釣果帳"},{"text":"もう、来ない。","seconds":3.0,"heading":""},{"text":"","seconds":1.0,"heading":""}]
	else:
		steps = [{"text":"","seconds":5.0,"heading":"祖父の釣果帳"},{"text":"","seconds":1.0,"heading":""}]
	flow._stop_reel()
	flow.line.visible = false # A resumed ending must not draw the fresh lure at (0, 0).
	flow._set_cinematic(true)
	flow.ending_screen.visible = false
	if kind != "main":flow.state = flow.State.NARRATIVE
	if kind in ["cut","contact"]: _shore()
	visible = true;skip_button.visible = true
	_render()

func _shore() -> void:
	flow.progress.current_area = LakeAreas.SOUTH
	flow.selected_band = 0;flow.restore_area()
	flow.environment.value = 0;flow.environment.target = 0;flow.environment._apply()

func _render() -> void:
	var page: Dictionary = steps[section]
	if mode == "main" and not credits:
		mysterious_sketch.show_card(page)
	else:
		mysterious_sketch.finish()
	var paper: bool = page.heading == "祖父の釣果帳"
	var style := StyleBoxFlat.new()
	style.bg_color = Color("bec5ab") if paper else Color(0.06,0.15,0.19,0.94)
	style.set_border_width_all(2)
	style.border_color = Color("6e7c6d") if paper else Color("8ab8b4")
	panel.add_theme_stylebox_override("panel",style)
	text.add_theme_color_override("font_color",Color("314845") if paper else Color("e0eee1"))
	heading.add_theme_color_override("font_color",Color("51605b") if paper else Color("c4d3c9"))
	heading.text = page.heading;text.text = page.text
	panel.visible = (not page.text.is_empty() or not page.heading.is_empty()) and not (mode == "main" and not credits)
	_update_marks()
	queue_redraw()

func _update_marks() -> void:
	if old_mark == null:return
	old_mark.visible = active and not credits and ((mode == "cut" and section == 1) or (mode == "contact" and section == 0))
	new_mark.visible = old_mark.visible and mode == "contact"
	var center := panel.position + Vector2(panel.size.x*0.5,95)
	old_mark.points = PackedVector2Array([center+Vector2(-10,-20),center+Vector2(-12,16)])
	new_mark.points = PackedVector2Array([center+Vector2(12,-22),center+Vector2(12,18)])

func step(delta: float) -> void:
	input_lock = maxf(0,input_lock-delta)
	if shadow_remaining > 0:
		shadow_remaining = maxf(0,shadow_remaining-delta)
		if shadow_remaining == 0:flow.hidden_route.visual.title_shadow = false;flow.hidden_route.visual.queue_redraw()
	if not active: return
	mysterious_sketch.step(delta)
	elapsed += delta
	while active and elapsed >= float(steps[section].seconds):
		elapsed -= float(steps[section].seconds)
		section += 1
		if section == steps.size():
			if credits: _finish()
			else: _finish_content()
		else: _render()

func skip() -> void:
	if not active: return
	input_lock = 0.25
	if credits: _finish()
	else: _finish_content()

func _finish_content() -> void:
	mysterious_sketch.finish()
	var progress: GameProgress = flow.progress
	if mode == "opening":
		progress.opening_seen = true;progress.changed.emit()
		active = false;panel.visible = false;skip_button.visible = false
		flow._set_cinematic(false);flow.state = flow.State.READY;flow._refresh_ui()
		return
	if mode == "main":
		flow.restore_ending_surface()
		flow.environment.value = 0;flow.environment.target = 0;flow.environment._apply()
		progress.main_ending_seen = true;progress.main_story_ending_seen = true
	elif mode == "cut":progress.cut_story_ending_seen = true
	else:progress.contact_story_ending_seen = true
	progress.changed.emit()
	flow.environment.target = 0
	credits = true;section = 0;elapsed = 0;steps = []
	for page: Array in NarrativeData.content().credits:steps.append({"text":"\n".join(page),"seconds":8.0,"heading":""})
	steps.append({"text":"Noto Sans JP\nSIL Open Font License 1.1","seconds":6.0,"heading":"FONT"})
	_render()

func _finish() -> void:
	active = false;panel.visible = false;skip_button.visible = false
	mysterious_sketch.finish()
	_update_marks();queue_redraw()
	flow.state = flow.State.TITLE;flow.ending_screen.show_title()
	flow.ending_screen.get_node("Clear").visible = mode == "main"
	if mode == "cut":
		flow.hidden_route.visual.visible = true;flow.hidden_route.visual.title_shadow = true
		shadow_remaining = 4.0;flow.hidden_route.visual.queue_redraw()

func sync_progress(delta: float) -> void:
	if flow.environment.value >= 1.95 and not flow.progress.night_page_seen and flow.state == flow.State.READY and not flow._shop_open and not flow._book_open and not flow._area_open and not flow.anomaly.active and not flow.hull_events.active:
		flow.progress.night_page_seen = true;flow.progress.changed.emit();flip_remaining = 1.0
	if flip_remaining > 0:
		flip_remaining = maxf(0,flip_remaining-delta)
		queue_redraw()

func _draw() -> void:
	if active and mode == "contact":draw_rect(Rect2(Vector2.ZERO,size),Color(0.015,0.025,0.04,0.98))
	if flip_remaining > 0 and not active:
		var boat: Vector2 = flow._boat.position
		var width := 100 * absf(cos((1-flip_remaining)*PI))
		draw_rect(Rect2(boat+Vector2(-50,-55),Vector2(maxf(2,width),38)),Color("cbd1b5"))
		if width > 85:draw_string(_font,boat+Vector2(-47,-31),"北湖中央",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("374e50"))
	if active and mode in ["main","cut"] and not credits:
		var dock: Vector2 = flow._boat.position + Vector2(-100,7)
		draw_rect(Rect2(dock,Vector2(84,6)),Color("766956"))
		for x in [4,68]:draw_rect(Rect2(dock+Vector2(x,6),Vector2(5,22)),Color("4d5955"))

func _input(event: InputEvent) -> void:
	if input_lock > 0:
		if event is InputEventScreenTouch or event is InputEventMouseButton:get_viewport().set_input_as_handled()
		return
	if not active:return
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		if credits or skip_button.get_global_rect().has_point(event.position):skip()
		get_viewport().set_input_as_handled()
