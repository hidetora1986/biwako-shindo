class_name HiddenRoute
extends Node
## Dedicated encounter; no FishController, ordinary catch/sale or permanent depth mutation.
enum Stage { INACTIVE, DEPTH, CONTACT, FIGHT, STILL, CHOICE, FAILURE, CUT, REEL_UP, REVEAL, TITLE }
var stage: Stage = Stage.INACTIVE
var elapsed: float = 0
var total: float = 0
var depth_display: String = "104m"
var fight := HiddenFishingFight.new()
var flow: Node2D
var visual: HiddenVisual
var panel: Control
var message: Label
var meters: Label
var tension_bar: ProgressBar
var pull_bar: ProgressBar
var tension_fill: StyleBoxFlat
var line_sound: AudioStreamPlayer
var reel: Button
var cut: Button
var lift: Button
var night_button: Button
var depth_label: Label
var lure_button: Button
var pointer_owner: int = -1
var _boat_anchor := Vector2.ZERO
var _night_selected: bool = false
var _cut_title: bool = false
var _saved_visibility: Dictionary = {}

func setup(controller: Node2D) -> void:
	flow = controller
	visual = HiddenVisual.new()
	visual.name = "HiddenVisual"
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow._hud.add_child(visual)
	panel = Control.new()
	panel.name = "HiddenUI"
	panel.theme = preload("res://assets/ui/pixel_theme.tres")
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow._hud.add_child(panel)
	message = Label.new()
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size",22)
	panel.add_child(message)
	depth_label = Label.new()
	depth_label.add_theme_font_size_override("font_size",20)
	panel.add_child(depth_label)
	meters = Label.new()
	meters.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meters.add_theme_font_size_override("font_size",16)
	panel.add_child(meters)
	tension_bar = ProgressBar.new()
	tension_bar.show_percentage = false
	tension_fill = StyleBoxFlat.new()
	tension_fill.bg_color = Color("7fb5b0")
	tension_bar.add_theme_stylebox_override("fill",tension_fill)
	panel.add_child(tension_bar)
	pull_bar = ProgressBar.new()
	pull_bar.show_percentage = false
	pull_bar.max_value = 5
	panel.add_child(pull_bar)
	line_sound = AudioStreamPlayer.new()
	line_sound.volume_db = -26
	add_child(line_sound)
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 11025
	var pcm := PackedByteArray()
	pcm.resize(2205*2)
	for i in range(2205): pcm.encode_s16(i*2,int(sin(i*TAU*170/11025)*1200+sin(i*TAU*211/11025)*400))
	sound.data = pcm
	sound.loop_mode = AudioStreamWAV.LOOP_FORWARD
	sound.loop_end = 2205
	line_sound.stream = sound
	reel = _button("REEL",panel)
	cut = _button("切る",panel)
	lift = _button("巻き上げる",panel)
	cut.pressed.connect(func(): choose(false))
	lift.pressed.connect(func(): choose(true))
	reel.button_down.connect(func(): set_reeling(true))
	reel.button_up.connect(func(): set_reeling(false))
	lure_button = _button("無名ルアー",flow._hud)
	lure_button.name = "AnonymousLure"
	lure_button.add_theme_font_size_override("font_size",13)
	lure_button.pressed.connect(toggle_lure)
	night_button = _button("NIGHT",flow._hud)
	night_button.pressed.connect(toggle_night)
	flow.progress.changed.connect(refresh_lure)
	refresh_lure()
	layout()
	panel.visible = false

func _button(text: String, parent: Node) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size",16)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("152a37")
	style.border_color = Color("87aeb4")
	style.set_border_width_all(1)
	button.add_theme_stylebox_override("normal",style)
	var held := style.duplicate()
	held.bg_color = Color("476779")
	button.add_theme_stylebox_override("pressed",held)
	parent.add_child(button)
	return button

func layout() -> void:
	if flow == null: return
	var size: Vector2 = flow._hud.size
	var safe: Rect2 = flow._hud.safe_rect
	visual.size = size
	panel.size = size
	visual.surface_y = flow._surface_y
	visual.sonar_rect = flow._hud.get_node("SonarPlaceholder").get_global_rect()
	var middle := safe.get_center().x
	depth_label.position = Vector2(safe.position.x+10,safe.position.y+40)
	depth_label.size = Vector2(110,32)
	night_button.size = Vector2(maxf(112,flow._hud.get_node("SonarPlaceholder").position.x - flow._hud.core_rect.position.x - 280),44)
	night_button.position = Vector2(flow._hud.core_rect.position.x+272,safe.position.y+50)
	message.position = Vector2(middle-230,safe.position.y+90)
	message.size = Vector2(460,156)
	meters.position = Vector2(middle-210,safe.end.y-140)
	meters.size = Vector2(420,60)
	tension_bar.position = Vector2(middle-100,safe.end.y-90)
	tension_bar.size = Vector2(200,12)
	pull_bar.position = Vector2(middle-100,safe.end.y-72)
	pull_bar.size = Vector2(200,12)
	reel.size = Vector2(140,64)
	reel.position = Vector2(safe.end.x-144,safe.end.y-68)
	cut.size = Vector2(180,60)
	lift.size = Vector2(180,60)
	lift.position = Vector2(middle-192,safe.end.y-80)
	cut.position = Vector2(middle+12,safe.end.y-80)
	lure_button.size = night_button.size
	lure_button.position = Vector2(flow._hud.core_rect.position.x+272,safe.position.y+100)

func refresh_lure() -> void:
	if lure_button == null: return
	# Browser viewport changes must also reposition the postgame controls.
	if OS.has_feature("web"): layout()
	var postgame_night: bool = flow.progress.main_ending_seen and flow.progress.night_unlocked
	if not flow.progress.anonymous_lure_obtained and not lure_button.visible and not night_button.visible and not postgame_night: return
	var idle: bool = stage == Stage.INACTIVE and flow.state == flow.State.READY and not flow._shop_open and not flow._book_open and not flow._area_open and not flow._save_pending
	lure_button.visible = flow.progress.anonymous_lure_obtained and idle
	lure_button.text = ("無名ルアー ✓" if flow.progress.anonymous_lure_equipped else "無名ルアー") + "\n所持品に入っていた。"
	night_button.visible = postgame_night and idle
	night_button.text = "MORNING" if _night_selected else "NIGHT"
	lure_button.tooltip_text = "所持品に入っていた。"

func toggle_lure() -> bool:
	if flow.state != flow.State.READY or flow._book_open or flow._area_open or flow._save_pending or flow._shop_open or not flow.progress.anonymous_lure_obtained: return false
	flow.progress.anonymous_lure_equipped = not flow.progress.anonymous_lure_equipped
	_night_selected = flow.progress.anonymous_lure_equipped
	flow.progress.changed.emit()
	flow.environment.target = 2 if _night_selected and flow.progress.night_unlocked else 0
	return true

func toggle_night() -> bool:
	if flow.state != flow.State.READY or flow._shop_open or flow._book_open or flow._area_open or flow._save_pending or not flow.progress.night_unlocked: return false
	_night_selected = not _night_selected
	flow.environment.target = 2 if _night_selected else 0
	refresh_lure()
	return true

func can_start() -> bool:
	return stage == Stage.INACTIVE and flow.progress.current_area == LakeAreas.CENTER and flow.progress.hidden_eligible() and not flow.progress.hidden_finished() and flow.progress.anonymous_lure_obtained and flow.progress.anonymous_lure_equipped and flow.environment.value >= 1.95 and flow.selected_band == 6 and flow.state == flow.State.READY and not flow._shop_open and not flow._book_open and not flow._area_open and not flow._save_pending

func begin() -> bool:
	if not can_start(): return false
	flow.state = flow.State.HIDDEN
	flow.lure.finish_reset()
	flow.lure.cast_from(flow._boat.rod_tip_position())
	flow.lure.set_physics_process(false)
	flow.active_fish = null
	flow.line.visible = true
	_boat_anchor = flow._boat.anchor_position
	visual.old_contacts = flow._hud.get_node("SonarPlaceholder").contacts.duplicate(true)
	for fish: FishController in flow._fish_container.get_children():
		fish.visible = false
		fish.set_physics_process(false)
	for node: Node in flow._hud.get_children():
		if node is CanvasItem and node not in [visual,panel]:
			_saved_visibility[node.name] = node.visible
			node.visible = false
	panel.visible = true
	visual.title_shadow = false
	visual.visible = true
	_enter(Stage.DEPTH)
	return true

func _enter(next: Stage) -> void:
	stage = next
	elapsed = 0
	message.text = ""
	depth_label.visible = next in [Stage.DEPTH,Stage.CONTACT,Stage.FIGHT,Stage.STILL,Stage.CHOICE]
	reel.visible = next == Stage.FIGHT
	tension_bar.visible = next == Stage.FIGHT
	pull_bar.visible = next == Stage.FIGHT
	line_sound.stop()
	if next == Stage.REEL_UP and DisplayServer.get_name() != "headless": line_sound.play()
	meters.visible = next == Stage.FIGHT
	cut.visible = next == Stage.CHOICE
	lift.visible = next == Stage.CHOICE
	if next == Stage.CONTACT: message.text = "接触"
	if next == Stage.REVEAL:
		message.text = "No.00\n帰ってきたもの\n深度: 記録不能\nサイズ: ---   売値: ---\n捕獲数: 2\n記録が一致しない。"
	if next == Stage.FIGHT: fight = HiddenFishingFight.new()
	pointer_owner = -1

func step(delta: float) -> void:
	layout()
	if stage == Stage.INACTIVE: return
	elapsed += delta
	total += delta
	visual.motion = total if stage not in [Stage.STILL,Stage.CHOICE] else 0
	visual.warning = stage == Stage.FIGHT and fight.warning
	visual.under_boat = stage == Stage.REEL_UP and elapsed >= 0.5 and elapsed < 1.3
	match stage:
		Stage.DEPTH:
			# Short cast, four measured pauses, then an invalid reading. Physics stays <=120m.
			var readings := ["104m","108m","114m","121m","---"]
			depth_display = readings[mini(4,int(maxf(0,elapsed-0.6)/1.25))]
			visual.amount = minf(1,elapsed/3)
			if elapsed < 0.6:
				var fraction := elapsed/0.6
				flow.lure.position = flow._boat.rod_tip_position().lerp(Vector2(flow._water.get_center().x+45,flow._surface_y),fraction) - Vector2(0,sin(fraction*PI)*28)
			else:
				flow.lure.position = Vector2(flow._water.get_center().x+45,lerpf(flow._surface_y,flow._water.end.y-18,clampf((elapsed-0.6)/4.4,0,1)))
			flow.lure.position.y = minf(flow._water.end.y-4,flow.lure.position.y+maxf(0,elapsed-5)*4)
			flow.lure.visible = true
			flow.lure.depth_m = minf(120,100+elapsed*4)
			if elapsed >= 7: _enter(Stage.CONTACT)
		Stage.CONTACT:
			if elapsed >= 1: _enter(Stage.FIGHT)
		Stage.FIGHT:
			fight.step(delta)
			meters.text = "LINE TENSION  %03d / 100\nBOAT PULL  %.1fm / 5.0m" % [fight.tension,fight.boat_pull_depth]
			tension_bar.value = fight.tension
			tension_fill.bg_color = Color("aa4d53") if fight.tension >= 90 else (Color("ddbd83") if fight.tension >= 70 else Color("7fb5b0"))
			pull_bar.value = fight.boat_pull_depth
			meters.modulate = Color("e5b17a") if fight.tension >= 75 else Color("cadbd9")
			reel.modulate = Color("c6eaf2") if fight.reeling else Color.WHITE
			flow._boat.set_anchor(_boat_anchor+Vector2(sin(total*2)*2 if fight.phase >= 2 else 0,fight.boat_pull_depth*3))
			flow._boat.set_line_pull(fight.tension,true)
			if fight.failure != "": _enter(Stage.FAILURE)
			elif fight.completed:
				flow._boat.set_line_pull(0,false)
				_enter(Stage.STILL)
		Stage.STILL:
			if elapsed >= 2: _enter(Stage.CHOICE)
		Stage.FAILURE:
			visual.fade = minf(1,elapsed)
			if elapsed >= 3: _restore(false)
		Stage.CUT:
			visual.amount = maxf(0,1-elapsed)
			visual.fade = maxf(0,1-elapsed)
			flow.environment.target = 0
			flow.environment.transition_seconds = 1
			flow.environment.step(delta)
			if elapsed >= 3:
				flow.progress.finish_hidden(false)
				_restore(false)
				flow.story.begin("cut")
		Stage.REEL_UP:
			flow.lure.position.y -= delta*50
			visual.fade = clampf((elapsed-1)/1.0,0,1)
			if elapsed >= 3: _enter(Stage.REVEAL)
		Stage.REVEAL:
			visual.fade = 1
			if elapsed >= 3:
				flow.progress.finish_hidden(true)
				_restore(false)
				flow.story.begin("contact")
	depth_label.text = depth_display
	visual.depth_text = depth_display
	visual.queue_redraw()
	if flow.line.get_point_count() == 2:
		flow.line.set_point_position(0,flow._boat.rod_tip_position())
		flow.line.set_point_position(1,flow.lure.position)

func set_reeling(pressed: bool) -> bool:
	if stage != Stage.FIGHT: return false
	fight.reeling = pressed
	return true

func choose(contact: bool) -> bool:
	if stage != Stage.CHOICE: return false
	flow._playtest.record("NO00 FINAL CHOICE", {"choice": "CONTACT" if contact else "CUT"})
	flow.line.visible = contact
	_enter(Stage.REEL_UP if contact else Stage.CUT)
	return true

func _restore(title: bool) -> void:
	flow.lure.finish_reset()
	flow.lure.set_physics_process(true)
	flow.line.visible = false
	flow._boat.set_anchor(_boat_anchor)
	flow._boat.set_line_pull(0,false)
	flow.selected_band = 0
	flow.seek_depth_m = 0
	flow.restore_area()
	for fish: FishController in flow._fish_container.get_children(): fish.set_physics_process(true)
	_night_selected = false
	flow.environment.value = 0
	flow.environment.target = 0
	flow.environment._apply()
	for node: Node in flow._hud.get_children():
		if node is CanvasItem and node not in [visual,panel]: node.visible = _saved_visibility.get(node.name,false)
	_saved_visibility.clear()
	line_sound.stop()
	visual.old_contacts.clear()
	visual.under_boat = false
	visual.amount = 0
	visual.fade = 0
	visual.title_shadow = title and flow.progress.hidden_cut_ending_seen
	visual.queue_redraw()
	panel.visible = false
	_enter(Stage.INACTIVE)
	flow.state = flow.State.READY
	if title:
		flow._set_cinematic(true)
		flow.state = flow.State.TITLE
		flow.ending_screen.show_title()
		visual.visible = true
		flow.ending_screen.get_node("Clear").visible = false
	flow._refresh_ui()

func _input(event: InputEvent) -> void:
	if stage == Stage.INACTIVE:
		if flow._shop_open or flow._book_open or flow._area_open or flow._save_pending: return
		if event is InputEventScreenTouch and event.pressed and lure_button.visible and lure_button.get_global_rect().has_point(event.position):
			toggle_lure(); get_viewport().set_input_as_handled()
		elif event is InputEventScreenTouch and event.pressed and night_button.visible and night_button.get_global_rect().has_point(event.position):
			toggle_night(); get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if stage == Stage.FIGHT:
			if event.pressed and pointer_owner == -1 and reel.get_global_rect().has_point(event.position): pointer_owner = event.index; set_reeling(true)
			elif not event.pressed and pointer_owner == event.index: pointer_owner = -1; set_reeling(false)
		elif event.pressed and stage == Stage.CHOICE:
			if cut.get_global_rect().has_point(event.position): choose(false)
			elif lift.get_global_rect().has_point(event.position): choose(true)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == pointer_owner and not reel.get_global_rect().has_point(event.position):
		pointer_owner = -1; set_reeling(false)
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT: set_reeling(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		pointer_owner = -1
		set_reeling(false)

func debug_setup() -> bool:
	if not OS.is_debug_build() or flow.state != flow.State.READY: return false
	for fish: FishFightProfile in GameProgress.FISH_PROFILES: flow.progress.record_catch(fish,fish.min_size_cm,false)
	flow.progress.boss15_defeated = true
	flow.progress.main_ending_seen = true
	flow.progress.main_story_ending_seen = true
	flow.progress.opening_seen = true
	flow.progress.unknown_a_sold_first = false
	flow.progress.unknown_b_sold_first = false
	flow.progress.returned_unknown_a = true
	flow.progress.returned_unknown_b = true
	flow.progress.hull_knock_count = 3
	flow.progress.zero_depth_contact_seen = true
	flow.progress.night_unlocked = true
	flow.progress.levels = {"rod":5,"reel":5,"line":5,"sonar":5}
	flow.progress.anonymous_lure_obtained = true
	flow.progress.anonymous_lure_equipped = true
	flow.progress.changed.emit()
	flow.environment.value = 2
	flow.environment.target = 2
	flow.environment._apply()
	flow.progress.current_area = LakeAreas.CENTER
	flow.restore_area()
	flow.select_depth_band(6)
	return true

func on_title() -> void:
	if flow.progress.hidden_finished():
		flow.ending_screen.get_node("Clear").visible = false
		visual.visible = true
		visual.title_shadow = flow.progress.hidden_cut_ending_seen
		visual.queue_redraw()

func on_continue() -> void:
	visual.title_shadow = false
	visual.queue_redraw()
	refresh_lure()

func debug_stage(target: Stage) -> bool:
	# Callable acceptance tools only. Never a production menu or condition checklist.
	if not OS.is_debug_build(): return false
	if stage == Stage.INACTIVE:
		if not debug_setup(): return false
		var finished: bool = flow.progress.hidden_cut_ending_seen or flow.progress.hidden_contact_ending_seen
		var cut_seen: bool = flow.progress.hidden_cut_ending_seen
		var contact_seen: bool = flow.progress.hidden_contact_ending_seen
		if finished:
			flow.progress.hidden_cut_ending_seen = false
			flow.progress.hidden_contact_ending_seen = false
		var started := begin()
		flow.progress.hidden_cut_ending_seen = cut_seen
		flow.progress.hidden_contact_ending_seen = contact_seen
		if not started: return false
	_enter(target)
	visual.amount = 1
	depth_display = "---"
	return true

func _exit_tree() -> void:
	if is_instance_valid(line_sound):
		line_sound.stop()
		line_sound.stream = null
