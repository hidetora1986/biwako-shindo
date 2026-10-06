extends Control
## One paused map. Arriving/closing releases only the pause this modal owns.
signal closed
signal destination_selected(id: String)
signal save_requested
var flow: Node
var buttons: Dictionary = {}
var _owns_pause := false
var _opening_generation := 0
var _armed := false
var panel: Panel
var close_button: Button
var save_button: Button
var heading: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.08, 0.13, 0.86)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	panel = Panel.new()
	add_child(panel)
	heading = Label.new()
	heading.text = "LAKE MAP / 係留地点"
	heading.add_theme_font_size_override("font_size", 18)
	panel.add_child(heading)
	close_button = _button("×")
	close_button.pressed.connect(close_map)
	for id: String in LakeAreas.IDS:
		var button := _button("")
		button.pressed.connect(_select.bind(id))
		buttons[id] = button
	save_button = _button("SAVE POINT / SAVE")
	save_button.pressed.connect(func(): save_requested.emit())

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button.add_theme_font_size_override("font_size", 15)
	panel.add_child(button)
	return button

func setup(controller: Node) -> void:
	flow = controller

func configure(core: Rect2, view_size: Vector2) -> void:
	size = view_size
	panel.size = Vector2(minf(560, core.size.x), minf(328, core.size.y))
	panel.position = core.get_center() - panel.size * 0.5
	heading.position = Vector2(14, 14)
	close_button.size = Vector2(50, 44)
	close_button.position = Vector2(panel.size.x - 64, 6)
	var top := 58.0
	var row_height := maxf(48, (panel.size.y - 116) / 3)
	for i in range(LakeAreas.IDS.size()):
		var button: Button = buttons[LakeAreas.IDS[i]]
		button.position = Vector2(14, top + i * (row_height + 4))
		button.size = Vector2(panel.size.x - 28, row_height)
	save_button.size = Vector2(236, 44)
	save_button.position = Vector2(14, panel.size.y - 48)

func open_map() -> void:
	_opening_generation += 1
	var generation := _opening_generation
	_armed = false
	save_button.disabled = true
	visible = true
	_owns_pause = true
	get_tree().paused = true
	for id: String in LakeAreas.IDS:
		var current: bool = id == flow.progress.current_area
		var accessible := LakeAreas.unlocked(id, flow.progress)
		var entry: Dictionary = LakeAreas.DATA[id]
		buttons[id].text = "%s  %s  %d–%dm\nSAVE POINT / %s" % ["現在地" if current else ("移動する" if accessible else "LOCKED"), entry.name, entry.min_depth, entry.max_depth, "係留地点" if accessible else entry.gate]
		buttons[id].disabled = true
	# The opening tap may also produce an emulated mouse press at a destination.
	# Arm rows only after that gesture; stale timers cannot arm a reopened map.
	await get_tree().create_timer(0.25, true).timeout
	if not visible or generation != _opening_generation: return
	_armed = true
	save_button.disabled = false
	for id: String in LakeAreas.IDS:
		buttons[id].disabled = id == flow.progress.current_area or not LakeAreas.unlocked(id, flow.progress)

func close_map() -> void:
	if not visible: return
	_opening_generation += 1
	_armed = false
	visible = false
	if _owns_pause: get_tree().paused = false
	_owns_pause = false
	closed.emit()

func _select(id: String) -> void:
	if not visible or not _armed or buttons[id].disabled: return
	close_map()
	destination_selected.emit(id)

func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventScreenTouch and event.pressed): return
	if not _armed:
		get_viewport().set_input_as_handled()
		return
	if close_button.get_global_rect().has_point(event.position): close_map()
	elif save_button.get_global_rect().has_point(event.position): save_requested.emit()
	else:
		for id: String in buttons:
			if buttons[id].get_global_rect().has_point(event.position):
				_select(id)
				break
	get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if _owns_pause: get_tree().paused = false
