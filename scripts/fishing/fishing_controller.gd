extends Node2D
## Owns fishing states/input. FishingFight handles only fight numbers.

enum State { READY, CASTING, SINKING, WAITING, BITTEN, HOOKED, FIGHTING, LANDING, LANDED, CHOOSING, FAILED, RESET, BOSS_BITE, ENDING, TITLE, HIDDEN, TRAVELLING }
signal hook_succeeded
signal hook_missed

@export var save_path: String = "user://biwako-shindo/save.json"
@export var random_seed: int = 2463
@export var hull_knock_sound: AudioStream
@export_range(1.0, 3.0) var hook_window_seconds: float = 1.5
@export_range(0.1, 0.5) var hit_hold_seconds: float = 0.3

@onready var lure: LureController = $Lure
@onready var line: Line2D = $Line

var state: State = State.READY
var active_fish: FishController
var cast_elapsed: float = 0.0
var _boat: Node2D
var _fish_container: Node2D
var _hud: Control
var _rng := RandomNumberGenerator.new()
var _detection_timer: float = 0.0
var _retry_delay: float = 0.0
var _bite_remaining: float = 0.0
var _hit_remaining: float = 0.0
var _reset_remaining: float = 0.0
var _message_remaining: float = 0.0
var fight := FishingFight.new()
var last_catch: Dictionary = {}
var _reel_owner: int = -1 # -1 none, -2 mouse, >=0 touch index
var _water := Rect2()
var _surface_y: float = 0.0
var _fight_origin_fraction := Vector2.ZERO
var _landing_start := Vector2.ZERO
var _landing_remaining: float = 0.0
var _result_remaining: float = 0.0
var _session_caught: bool = false
var progress := GameProgress.new()
var _cast_serial: int = 0
var _shop_open: bool = false
var _book_open: bool = false
var _area_open := false
var _save_pending := false
var _manual_confirmation := false
var _travel_remaining := 0.0
var _travel_destination := ""
var _playtest: Node
var boss_playtest := false
var save_manager: SaveManager
var anomaly := SonarAnomaly.new()
var environment := LakeEnvironment.new()
var hull_events := HullEvents.new()
var selected_band: int = 0
var seek_depth_m: float = 0.0
var _deep_cast_count: int = 0
var aim_selected := false
var aim_fraction := 0.28
var aim_depth_m := -1.0
var boss_encounter := BossEncounter.new()
var ending_screen: MainEndingScreen
var hidden_route: HiddenRoute
var ending_elapsed: float = 0.0
var _ending_surface_restored: bool = false
var _cinematic_visibility: Dictionary = {}
var _boss_bite_elapsed: float = 0.0
var _boss_bite_start := Vector2.ZERO

func _ready() -> void:
	_rng.seed = random_seed
	line.add_point(Vector2.ZERO)
	line.add_point(Vector2.ZERO)
	line.visible = false

func setup(boat: Node2D, fishes: Node2D, hud: Control) -> void:
	_boat = boat
	_fish_container = fishes
	_hud = hud
	_playtest = get_node("/root/HumanPlaytest")
	save_path = _playtest.test_save_path(save_path)
	boss_playtest = BossWebPlaytest.requested()
	if boss_playtest:
		# Separate namespace, fresh on each explicit test URL load. No normal-save IO.
		save_path = BossWebPlaytest.SAVE_PATH
		progress = BossWebPlaytest.fresh_progress()
	save_manager = SaveManager.new(save_path)
	if boss_playtest:
		save_manager.save_progress(progress)
	else:
		save_manager.load_into(progress)
	save_manager.bind_progress(progress)
	_hud.get_node("CastButton").pressed.connect(_cast_or_retrieve)
	_hud.get_node("HookButton").pressed.connect(request_hook)
	_hud.get_node("AreaButton").pressed.connect(request_area)
	_hud.get_node("SaveButton").pressed.connect(request_save)
	_hud.get_node("AreaMap").setup(self)
	_hud.get_node("AreaMap").closed.connect(_area_closed)
	_hud.get_node("AreaMap").destination_selected.connect(request_travel)
	_hud.get_node("AreaMap").save_requested.connect(request_save.bind(true))
	_hud.get_node("DepthBandButton").pressed.connect(cycle_depth_band)
	_hud.get_node("CatchPanel/SellChoice").pressed.connect(resolve_unknown_catch.bind(true))
	_hud.get_node("CatchPanel/ReturnChoice").pressed.connect(resolve_unknown_catch.bind(false))
	_hud.get_node("ShopButton").pressed.connect(request_shop)
	_hud.get_node("BookButton").pressed.connect(request_book)
	_hud.get_node("FishBook").setup(progress)
	_hud.get_node("FishBook").closed.connect(_book_closed)
	_hud.get_node("SonarPlaceholder").setup(fishes, progress)
	anomaly.setup(progress, _hud.get_node("SonarPlaceholder"))
	progress.changed.connect(_progress_changed)
	progress.depth_unlocked.connect(_hud.get_node("DepthUnlock").show_unlock)
	_hud.get_node("Shop").setup(progress, _hud)
	_hud.get_node("Shop").closed.connect(_shop_closed)
	environment.setup(get_parent(), progress)
	hull_events.setup(progress, _boat, _hud.get_node("SonarPlaceholder"), self, hull_knock_sound)
	ending_screen = preload("res://scenes/ui/main_ending.tscn").instantiate()
	_hud.add_child(ending_screen)
	ending_screen.configure(_hud.size,_hud.safe_rect)
	ending_screen.continued.connect(request_continue)
	hidden_route = HiddenRoute.new()
	add_child(hidden_route)
	hidden_route.setup(self)
	restore_area()
	_progress_changed()
	_refresh_ui()
	if progress.boss15_defeated:
		if progress.main_ending_seen:
			_set_cinematic(true)
			state = State.TITLE
			ending_screen.show_title()
			hidden_route.on_title()
		else:
			_begin_ending() # Interrupted after reward: replay only the ending, never the boss/reward.
	if boss_playtest:
		BossWebPlaytest.configure(self)
	_playtest.bind_flow(self)

func configure_water(bounds: Rect2, surface_y: float, depth_m: float, origin_m: float = 0.0) -> void:
	_water = bounds
	_surface_y = surface_y
	lure.configure_water(bounds, surface_y, depth_m, origin_m)
	if _boat != null:
		lure.set_cast_origin(_boat.rod_tip_position())
	if state == State.FIGHTING:
		_update_fight_pose()
	_update_line()
	_refresh_ui()

func request_cast() -> bool:
	if state != State.READY or _boat == null or _shop_open or _book_open or _area_open or _save_pending:
		return false
	seek_depth_m = 0.0
	if selected_band > 0:
		_deep_cast_count += 1
		# Keep the visible fish in place when the player explicitly aims at them.
		if not aim_selected:
			get_parent().populate_depth_band(selected_band, progress.current("line").effect_value, _deep_cast_count)
		seek_depth_m = DepthBands.seek_depth(selected_band, _deep_cast_count, progress.current("line").effect_value)
	if aim_selected and aim_depth_m >= 0:
		seek_depth_m = aim_depth_m
	if hidden_route != null and hidden_route.can_start():
		return hidden_route.begin()
	boss_encounter.begin_cast()
	if not lure.cast_from(_boat.rod_tip_position(), aim_fraction if aim_selected else 0.28, aim_depth_m if aim_selected else -1.0):
		return false
	clear_aim()
	state = State.CASTING
	_cast_serial += 1
	cast_elapsed = 0.0
	_detection_timer = 0.0
	_retry_delay = 0.0
	_message_remaining = 0.0
	_hud.show_result("")
	_update_line()
	_refresh_ui()
	return true

func _input(event: InputEvent) -> void:
	if _shop_open or _book_open or _area_open or _save_pending or state in [State.ENDING,State.TITLE,State.BOSS_BITE,State.HIDDEN]:
		return
	if event is InputEventScreenTouch and event.pressed and _hud != null and not _hud.get_node("ShopButton").disabled and _hud.get_node("ShopButton").get_global_rect().has_point(event.position):
		if request_shop():
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch and event.pressed and _hud != null and not _hud.get_node("BookButton").disabled and _hud.get_node("BookButton").get_global_rect().has_point(event.position):
		if request_book():
			get_viewport().set_input_as_handled()
		return
	if state == State.CHOOSING:
		if event is InputEventScreenTouch and event.pressed:
			for name in ["SellChoice", "ReturnChoice"]:
				if _hud.get_node("CatchPanel/" + name).get_global_rect().has_point(event.position):
					resolve_unknown_catch(name == "SellChoice")
					get_viewport().set_input_as_handled()
					return
		return
	if state == State.READY and event is InputEventScreenTouch and event.pressed:
		if _hud.get_node("AreaButton").get_global_rect().has_point(event.position):
			request_area()
			get_viewport().set_input_as_handled()
			return
		if _hud.get_node("DepthBandButton").get_global_rect().has_point(event.position):
			cycle_depth_band()
			get_viewport().set_input_as_handled()
			return
	if state == State.FIGHTING:
		_reel_input(event)
		return
	if state == State.READY and event is InputEventScreenTouch and event.pressed and _hud != null:
		if _hud.get_node("CastButton").get_global_rect().has_point(event.position):
			if _cast_or_retrieve():
				get_viewport().set_input_as_handled()
			return
	if can_retrieve() and event is InputEventScreenTouch and event.pressed and _hud.get_node("CastButton").get_global_rect().has_point(event.position):
		request_retrieve()
		get_viewport().set_input_as_handled()
		return
	if state == State.BITTEN and event is InputEventScreenTouch and event.pressed and _hud.get_node("HookButton").get_global_rect().has_point(event.position):
		if request_hook(): get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	var pressed: bool = event is InputEventScreenTouch and event.pressed
	pressed = pressed or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed)
	if pressed and select_cast_point(event.position):
		get_viewport().set_input_as_handled()

func select_cast_point(point: Vector2) -> bool:
	if state != State.READY or _hud == null or _shop_open or _book_open or _area_open or _save_pending or anomaly.active or hull_events.active:
		return false
	if not point.is_finite() or not Rect2(Vector2(_water.position.x, _surface_y - 24), Vector2(_water.size.x, _water.end.y - _surface_y + 24)).has_point(point):
		return false
	# Even passive HUD labels/sonar are not lake targets.
	for child in _hud.get_children():
		if child is HiddenVisual: continue # Full-screen rendering layer, not a UI hit area.
		if child is Control and child.is_visible_in_tree() and child.get_global_rect().has_point(point):
			return false
	aim_fraction = clampf((point.x - _water.position.x) / _water.size.x, 0.03, 0.97)
	aim_depth_m = -1.0
	if point.y > _surface_y + 4:
		var fraction := clampf((point.y - _surface_y) / maxf(1, _water.end.y - 8 - _surface_y), 0, 1)
		aim_depth_m = minf(lure.max_depth_m, lure.depth_origin_m + fraction * lure._visible_depth_m)
	# Small fish remain tappable: snap a nearby tap to the visible fish snapshot.
	if point.y > _surface_y + 4:
		var radius := maxf(14, 22.0 * _hud.size.y / maxf(1, get_window().size.y))
		var nearest: FishController
		for fish: FishController in _fish_container.get_children():
			var distance := point.distance_to(fish.position)
			if fish.visible and distance < radius:
				nearest = fish
				radius = distance
		if nearest != null:
			aim_fraction = clampf((nearest.position.x - _water.position.x) / _water.size.x, 0.03, 0.97)
			aim_depth_m = minf(lure.max_depth_m, nearest.depth_position)
	aim_selected = true
	queue_redraw()
	return true

func clear_aim() -> void:
	aim_selected = false
	aim_depth_m = -1.0
	queue_redraw()

func aim_position() -> Vector2:
	var y := _surface_y
	if aim_depth_m >= 0:
		y += clampf((aim_depth_m - lure.depth_origin_m) / lure._visible_depth_m, 0, 1) * (_water.end.y - 8 - _surface_y)
	return Vector2(_water.position.x + aim_fraction * _water.size.x, y).round()

func _draw() -> void:
	if not aim_selected or state != State.READY or _shop_open or _book_open or _area_open or _save_pending:
		return
	var center := aim_position()
	var tint := Color("fff1be")
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		draw_line(center + direction * 5, center + direction * 11, tint, 2)
	draw_circle(center, 2, tint)
	if aim_depth_m >= 0:
		draw_line(Vector2(center.x - 6, _surface_y), Vector2(center.x + 6, _surface_y), tint, 2)
		var label_position := center + Vector2(14, 4)
		label_position.x = clampf(label_position.x, _hud.safe_rect.position.x, _hud.safe_rect.end.x - 70)
		label_position.y = minf(label_position.y, _hud.safe_rect.end.y - 4)
		draw_string(ThemeDB.fallback_font, label_position, "%.1fm" % aim_depth_m, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, tint)

func request_hook() -> bool:
	if state != State.BITTEN or _bite_remaining <= 0.0 or _shop_open or _book_open or _area_open or _save_pending:
		return false
	state = State.HOOKED
	lure.hook()
	active_fish.hook()
	_hit_remaining = hit_hold_seconds
	_session_caught = false
	active_fish.prepare_catch_size(_rng)
	fight = BossFishingFight.new() if active_fish.fight_profile.is_boss else FishingFight.new()
	fight.start(active_fish.fight_profile, progress.current("reel").effect_value, progress.current("rod").effect_value, active_fish.size_cm)
	_fight_origin_fraction = Vector2((active_fish.position.x - _water.position.x) / _water.size.x, (active_fish.position.y - _surface_y) / (_water.end.y - _surface_y))
	_hud.show_bite(false, lure.position)
	_hud.show_result("HIT!")
	_playtest.record("FIRST_HOOK_BUTTON_SUCCESS")
	_haptic(90, 0.65)
	hook_succeeded.emit()
	_refresh_ui()
	return true

func _physics_process(delta: float) -> void:
	if _hud == null or _shop_open or _book_open or _area_open or _save_pending:
		return
	if state == State.TRAVELLING:
		_step_travel(delta)
		return
	if state == State.HIDDEN:
		hidden_route.step(delta)
		return
	if state == State.ENDING:
		_step_ending(delta)
		return
	if state == State.TITLE:
		return
	environment.step(delta)
	progress.note_depth(lure.depth_m)
	var hull_was_active := hull_events.active
	hull_events.step(delta, state in [State.READY,State.WAITING] and active_fish == null and not anomaly.active, environment.value)
	var anomaly_was_active := anomaly.active
	anomaly.step(delta, can_trigger_anomaly())
	if state == State.READY:
		# Static HUD needs updating only when the modal eligibility changes.
		if anomaly_was_active != anomaly.active or hull_was_active != hull_events.active:
			_refresh_ui()
		return
	cast_elapsed += delta
	lure.set_cast_origin(_boat.rod_tip_position())
	_message_remaining = maxf(0.0, _message_remaining - delta)
	if _message_remaining == 0.0 and state not in [State.HOOKED, State.LANDED, State.CHOOSING, State.FAILED, State.RESET]:
		_hud.show_result("")
	match state:
		State.CASTING:
			if lure.state == LureController.State.SINKING:
				state = State.SINKING
		State.SINKING, State.WAITING:
			state = State.WAITING if lure.state == LureController.State.WAITING else State.SINKING
			if selected_band > 0 and lure.depth_m >= seek_depth_m:
				lure.pause_for_interest()
			_retry_delay = maxf(0.0, _retry_delay - delta)
			_detection_timer -= delta
			if active_fish == null:
				boss_encounter.try_spawn(get_parent(),progress,lure.depth_m)
			if active_fish == null and lure.depth_m >= seek_depth_m and cast_elapsed >= 2.2 and _retry_delay <= 0.0 and _detection_timer <= 0.0:
				_detection_timer = 0.45
				_detect_fish()
			if active_fish != null and cast_elapsed >= 5.0 and active_fish.bite_reached(lure.position):
				_begin_bite()
		State.BOSS_BITE:
			_boss_bite_elapsed += delta
			# Slow, visible line draw before the familiar generous tap window.
			lure.position = _boss_bite_start + Vector2(0,minf(3,_boss_bite_elapsed*2.0))
			_boat.set_line_pull(minf(35,_boss_bite_elapsed*24),true)
			if _boss_bite_elapsed >= 1.5:
				state = State.BITTEN
				_bite_remaining = 1.8
		State.BITTEN:
			_bite_remaining = maxf(0.0, _bite_remaining - delta)
			if _bite_remaining <= 0.0:
				_miss()
		State.HOOKED:
			_hit_remaining -= delta
			if _hit_remaining <= 0.0:
				state = State.FIGHTING
				_hud.show_result("")
		State.FIGHTING:
			fight.step(delta)
			if fight is BossFishingFight and fight.telegraph_started:
				_haptic(35,0.2)
			active_fish.stamina = fight.stamina
			_update_fight_pose()
			if fight.run_started:
				_haptic(55, 0.5)
			if fight.danger_entered:
				_haptic(35, 0.4)
			if fight.failure != "":
				_fail_fight(fight.failure)
			elif fight.landed:
				_begin_landing()
		State.LANDING:
			_landing_remaining = maxf(0.0, _landing_remaining - delta)
			active_fish.position = _landing_start.lerp(Vector2(_boat.position.x - 25, _surface_y - 6), 1.0 - clampf((_landing_remaining - 0.2) / 0.45, 0.0, 1.0))
			lure.follow_fish(active_fish.position + Vector2(14, 0), true)
			if _landing_remaining <= 0.2 and lure.splash_remaining <= 0.0:
				lure.landing_splash(Vector2(active_fish.position.x, _surface_y))
			if _landing_remaining <= 0.0:
				_show_catch()
		State.LANDED, State.FAILED:
			_result_remaining -= delta
			if _result_remaining <= 0.0:
				if state == State.LANDED and last_catch.get("id") == "No.15" and not progress.main_ending_seen:
					_begin_ending()
				elif state == State.LANDED and last_catch.get("id") in ["No.10","No.14"]:
					state = State.CHOOSING
					_hud.show_unknown_choice(true)
				else:
					_begin_reset()
		State.RESET:
			_reset_remaining -= delta
			if _reset_remaining <= 0.0:
				lure.finish_reset()
				state = State.READY
				_hud.show_result("")
	_update_line()
	_refresh_ui()

func _detect_fish() -> void:
	# Reserve at most one nearby fish; no teleporting or global attraction.
	var closest: FishController
	var distance := INF
	for fish: FishController in _fish_container.get_children():
		var candidate_distance := fish.position.distance_to(lure.position)
		if fish.visible and (not fish.fight_profile.is_boss or progress.can_encounter_boss()) and fish.can_detect_lure() and fish.fight_profile.allows_depth(lure.depth_m) and candidate_distance <= fish.bite_detection_radius and candidate_distance < distance:
			closest = fish
			distance = candidate_distance
	if closest == null:
		return
	# Repeated local detection gradually raises interest to avoid long MVP waits.
	var chance := minf(1.0, closest.bite_probability + maxf(0.0, cast_elapsed - 3.0) * 0.18)
	if _rng.randf() <= chance and closest.approach_lure(lure):
		active_fish = closest
		if closest.fight_profile.is_boss:
			boss_encounter.reserve(_fish_container)
		lure.pause_for_interest()

func _begin_bite() -> void:
	state = State.BOSS_BITE if active_fish.fight_profile.is_boss else State.BITTEN
	_boss_bite_elapsed = 0
	_boss_bite_start = lure.position
	lure.begin_bite()
	active_fish.begin_bite()
	_bite_remaining = hook_window_seconds
	# The first ~0.7 s of this generous window also provides the visible nibble.
	_hud.show_bite(true, lure.position)
	if OS.get_name() in ["Android", "iOS"]:
		# Godot safely does nothing on devices without vibration support.
		Input.vibrate_handheld(60)

func _miss() -> void:
	if active_fish.fight_profile.is_boss:
		_fail_fight("MISS")
		return
	active_fish.release_lure(true)
	active_fish = null
	lure.resume_sinking()
	state = State.WAITING if lure.state == LureController.State.WAITING else State.SINKING
	_retry_delay = 2.0
	_message_remaining = 0.9
	_hud.show_bite(false, lure.position)
	_hud.show_result("MISS")
	hook_missed.emit()

func _begin_reset() -> void:
	if state in [State.LANDED, State.CHOOSING, State.FAILED]:
		progress.complete_normal_session()
		if _session_caught:
			progress.note_postgame_catch()
	state = State.RESET
	lure.begin_reset()
	_stop_reel()
	if active_fish != null:
		active_fish.finish_session(_session_caught)
	active_fish = null
	_reset_remaining = 0.2
	_hud.hide_catch()
	_boat.set_line_pull(0.0, false)

func _reel_input(event: InputEvent) -> void:
	var button_rect: Rect2 = _hud.get_node("ReelButton").get_global_rect()
	var handled := false
	if event is InputEventScreenTouch:
		if event.pressed and _reel_owner == -1 and button_rect.has_point(event.position):
			_reel_owner = event.index
			set_reeling(true)
			handled = true
		elif not event.pressed and _reel_owner == event.index:
			_stop_reel()
			handled = true
	elif event is InputEventScreenDrag and event.index == _reel_owner:
		if not button_rect.has_point(event.position):
			_stop_reel()
			handled = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _reel_owner == -1 and button_rect.has_point(event.position):
			_reel_owner = -2
			set_reeling(true)
			handled = true
		elif not event.pressed and _reel_owner == -2:
			_stop_reel()
			handled = true
	elif event is InputEventMouseMotion and _reel_owner == -2 and not button_rect.has_point(event.position):
		_stop_reel()
		handled = true
	if handled:
		get_viewport().set_input_as_handled()

func set_reeling(pressed: bool) -> bool:
	if state != State.FIGHTING:
		return false
	fight.reeling = pressed
	_refresh_ui()
	return true

func _stop_reel() -> void:
	_reel_owner = -1
	fight.reeling = false
	if _hud != null:
		_refresh_ui()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_stop_reel()

func _update_fight_pose() -> void:
	var origin := Vector2(_water.position.x + _fight_origin_fraction.x * _water.size.x, _surface_y + _fight_origin_fraction.y * (_water.end.y - _surface_y))
	var target := Vector2(_boat.position.x - 24, _surface_y + 22)
	var mouth_offset: float = active_fish._half_width * active_fish.sprite.scale.x - 6 if fight is BossFishingFight else 14.0
	if fight is BossFishingFight:
		target.x = _boat.position.x - mouth_offset - 10
	var fish_position := origin.lerp(target, clampf(1.0 - fight.fish_distance, 0.0, 1.0))
	if active_fish.fight_profile.pull_pulse_power > 0:
		fish_position.y += sin(fight.elapsed * TAU * 2.4) * 1.2
	if fight.resistance == FishingFight.Resistance.WARNING:
		fish_position.y += sin(fight.elapsed * 38.0) * 2.0
	if fight is BossFishingFight:
		fish_position.y = minf(_water.end.y,fish_position.y+fight.depth_offset/20.0*_water.size.y)
	active_fish.set_fight_pose(fish_position, fight.resistance)
	active_fish.sprite.modulate = Color("fff0bd") if fight.resistance == FishingFight.Resistance.WARNING else Color.WHITE
	lure.follow_fish(fish_position + Vector2(active_fish.swim_direction * mouth_offset, 0))
	_boat.set_line_pull(fight.tension, true)

func _fail_fight(message: String) -> void:
	state = State.FAILED
	_stop_reel()
	active_fish.finish_session(false)
	if active_fish.fight_profile.is_boss:
		boss_encounter.release(_fish_container)
	active_fish = null
	lure.begin_reset()
	_result_remaining = 1.3
	_hud.show_result(message)
	_boat.set_line_pull(0.0, false)
	_haptic(130 if message == "LINE BREAK" else 60, 1.0 if message == "LINE BREAK" else 0.5)

func _begin_landing() -> void:
	state = State.LANDING
	_stop_reel()
	active_fish.state = FishController.SwimState.LANDING
	_landing_start = active_fish.position
	_landing_remaining = 0.65
	_boat.set_line_pull(0.0, false)

func _show_catch() -> void:
	if state != State.LANDING or _session_caught or active_fish == null:
		return
	state = State.LANDED
	_session_caught = true
	_result_remaining = 1.5
	var profile: FishFightProfile = active_fish.fight_profile
	if profile.is_boss:
		_result_remaining = 2.2
	var unknown := profile.id in ["No.10","No.14"]
	last_catch = {"species_id": profile.species_id, "name": profile.display_name, "size_cm": active_fish.size_cm, "id": profile.id, "price": profile.sale_price(active_fish.size_cm) if unknown else progress.sell_catch(profile, active_fish.size_cm, _cast_serial)}
	last_catch["new_discovery"] = not progress.fish_records[profile.id].discovered if unknown else progress.last_sale_new_discovery
	if profile.id == "No.14":
		_hud.get_node("SonarPlaceholder").retain_catch_contact(active_fish)
	active_fish.visible = false
	_hud.show_catch(last_catch, active_fish.sprite.sprite_frames.get_frame_texture("swim", 0))
	_haptic(100, 0.8)

func _haptic(duration_ms: int, amplitude: float) -> void:
	if OS.get_name() in ["Android", "iOS"]:
		Input.vibrate_handheld(duration_ms, amplitude)

func _update_line() -> void:
	line.visible = state not in [State.TRAVELLING, State.READY, State.LANDED, State.CHOOSING, State.FAILED, State.RESET, State.ENDING, State.TITLE]
	line.default_color = Color("dfb875") if state == State.FIGHTING and fight.tension >= 70.0 else Color(0.88, 0.94, 0.81, 0.75)
	if _boat != null and line.get_point_count() == 2:
		line.set_point_position(0, _boat.rod_tip_position())
		line.set_point_position(1, lure.position)

func _refresh_ui() -> void:
	queue_redraw()
	if _hud == null:
		return
	if hidden_route != null:
		hidden_route.refresh_lure()
	if state in [State.ENDING,State.TITLE,State.HIDDEN]:
		return
	_hud.get_node("AreaButton").visible = state not in [State.LANDED, State.CHOOSING]
	# Manual save lives in the paused AREA map; keep the lake HUD clear.
	_hud.get_node("SaveButton").visible = false
	_hud.get_node("AreaButton").disabled = not can_open_area()
	_hud.get_node("SaveButton").disabled = true
	_hud.get_node("HookButton").visible = state == State.BITTEN
	_hud.get_node("HookButton").disabled = state != State.BITTEN or _area_open or _save_pending
	_hud.get_node("CastButton").disabled = (state != State.READY and not can_retrieve()) or _shop_open or _book_open or _area_open or _save_pending
	_hud.get_node("CastButton").text = "回収" if state in [State.SINKING, State.WAITING] else "CAST"
	_hud.get_node("ShopButton").visible = state not in [State.LANDED, State.CHOOSING]
	_hud.get_node("BookButton").visible = state not in [State.LANDED, State.CHOOSING]
	_hud.get_node("ShopButton").disabled = not can_open_shop()
	_hud.get_node("BookButton").disabled = not can_open_book()
	_hud.get_node("NextUpgrade").visible = state in [State.READY, State.CASTING, State.SINKING, State.WAITING, State.BITTEN]
	_hud.get_node("CastButton").visible = state in [State.READY, State.CASTING, State.SINKING, State.WAITING]
	var band_button: Button = _hud.get_node("DepthBandButton")
	band_button.visible = state in [State.READY, State.CASTING, State.SINKING, State.WAITING, State.BITTEN]
	band_button.disabled = state != State.READY or _shop_open or _book_open or _area_open or _save_pending or anomaly.active or hull_events.active
	band_button.text = "ABYSS 100–120m" if selected_band == 6 else "DEPTH %d–%dm" % [DepthBands.STARTS[selected_band], minf(DepthBands.ENDS[selected_band], progress.current("line").effect_value)]
	_hud.show_fight(fight, state == State.FIGHTING)
	_hud.get_node("Depth").visible = state in [State.READY, State.CASTING, State.SINKING, State.WAITING, State.BITTEN, State.BOSS_BITE] or (state == State.FIGHTING and fight is BossFishingFight)
	_hud.show_lure_depth(lure.depth_m, state != State.READY and state != State.RESET)
	_hud.show_bite(state == State.BITTEN, lure.position)

func can_open_shop() -> bool:
	return not _shop_open and not _book_open and not _area_open and not _save_pending and not anomaly.active and not hull_events.active and state in [State.READY, State.SINKING, State.WAITING]

func request_shop() -> bool:
	if not can_open_shop():
		return false
	_shop_open = true
	_stop_reel()
	_hud.get_node("Shop").open_shop()
	_refresh_ui()
	return true

func _shop_closed() -> void:
	_shop_open = false
	_refresh_ui()

func _progress_changed() -> void:
	lure.max_depth_m = minf(LakeAreas.DATA[progress.current_area].max_depth, progress.current("line").effect_value)
	environment.update_target(progress)
	if hidden_route != null and hidden_route._night_selected and progress.night_unlocked:
		environment.target = 2
	if _hud != null:
		_hud.show_progress(progress)

func can_open_book() -> bool:
	return can_open_shop()

func request_book() -> bool:
	if not can_open_book():
		return false
	_book_open = true
	_stop_reel()
	_hud.get_node("FishBook").open_book()
	_refresh_ui()
	return true

func _book_closed() -> void:
	_book_open = false
	_refresh_ui()

func can_trigger_anomaly() -> bool:
	# Between fishing sessions only; cannot overlap HIT/fight/catch or a modal.
	return state == State.READY and not _shop_open and not _book_open and not _area_open and not _save_pending and not hull_events.active

func debug_trigger_anomaly() -> bool:
	# Acceptance callable; no released-game button or player-facing warning.
	return OS.is_debug_build() and anomaly.try_trigger(can_trigger_anomaly(), true)

func _exit_tree() -> void:
	hull_events.stop_audio()
	if save_manager != null:
		save_manager.unbind_progress()

func select_depth_band(band: int) -> bool:
	if state != State.READY or _shop_open or _book_open or _area_open or _save_pending or anomaly.active or hull_events.active or not LakeAreas.band_available(progress.current_area, band, progress.current("line").effect_value):
		return false
	clear_aim()
	selected_band = band
	seek_depth_m = 0.0
	_deep_cast_count = 0
	get_parent().populate_depth_band(band, progress.current("line").effect_value)
	_hud.get_node("SonarPlaceholder").refresh_contacts()
	_refresh_ui()
	return true

func cycle_depth_band() -> bool:
	for offset in range(1, DepthBands.STARTS.size() + 1):
		var band := (selected_band + offset) % DepthBands.STARTS.size()
		if LakeAreas.band_available(progress.current_area, band, progress.current("line").effect_value):
			return select_depth_band(band)
	return false

func resolve_unknown_catch(sell: bool) -> bool:
	if state != State.CHOOSING or active_fish == null or last_catch.get("id") not in ["No.10","No.14"]:
		return false
	if sell:
		progress.sell_catch(active_fish.fight_profile, active_fish.size_cm, _cast_serial)
	else:
		if not progress.return_catch(active_fish.fight_profile, active_fish.size_cm, _cast_serial):
			return false
	last_catch["returned"] = not sell
	_playtest.choice(last_catch.get("id", ""), "SELL" if sell else "RETURN")
	_begin_reset()
	return true

func _set_cinematic(enabled: bool) -> void:
	if enabled:
		for node: Node in _hud.get_children():
			if node is CanvasItem and node != ending_screen:
				_cinematic_visibility[node.name] = node.visible
				node.visible = false
	else:
		for node: Node in _hud.get_children():
			if node is CanvasItem and node != ending_screen:
				node.visible = _cinematic_visibility.get(node.name,true)
		_cinematic_visibility.clear()
	_hud.get_node("SonarPlaceholder").set_process(not enabled)

func _begin_ending() -> void:
	state = State.ENDING
	_stop_reel()
	lure.begin_reset()
	line.visible = false
	_hud.hide_catch()
	active_fish = null
	ending_elapsed = 0
	_ending_surface_restored = false
	_set_cinematic(true)
	ending_screen.show_dawn(0)

func _step_ending(delta: float) -> void:
	ending_elapsed += delta
	if ending_elapsed >= 0.6 and not _ending_surface_restored:
		_ending_surface_restored = true
		selected_band = 0
		_deep_cast_count = 0
		seek_depth_m = 0
		get_parent().populate_depth_band(0,progress.current("line").effect_value,0,true)
		environment.transition_seconds = 3
		environment.target = 0
	if _ending_surface_restored:
		environment.step(delta)
	ending_screen.show_dawn(ending_elapsed)
	if ending_elapsed >= 8:
		progress.finish_main_ending()
		state = State.TITLE
		ending_screen.show_title()

func request_continue() -> bool:
	if state != State.TITLE or not progress.main_ending_seen:
		return false
	_playtest.record("POST GAME CONTINUE")
	ending_screen.visible = false
	_set_cinematic(false)
	state = State.READY
	lure.finish_reset()
	selected_band = 0
	_deep_cast_count = 0
	seek_depth_m = 0
	restore_area()
	environment.transition_seconds = 6
	_boat.set_line_pull(0,false)
	hidden_route.on_continue()
	_refresh_ui()
	return true

func can_open_area() -> bool:
	return state == State.READY and not _shop_open and not _book_open and not _area_open and not _save_pending and not anomaly.active and not hull_events.active

func request_area() -> bool:
	if not can_open_area(): return false
	_area_open = true
	_hud.get_node("AreaMap").open_map()
	_refresh_ui()
	return true

func _area_closed() -> void:
	_area_open = false
	_refresh_ui()

func can_save(from_map: bool = false) -> bool:
	return state == State.READY and not _shop_open and not _book_open and (not _area_open or from_map) and not _save_pending and not anomaly.active and not hull_events.active

func request_save(from_map: bool = false) -> bool:
	if not can_save(from_map): return false
	var success := _save_with_feedback()
	if success and not OS.has_feature("web"): _playtest.record("FIRST_MANUAL_SAVE")
	elif success: _manual_confirmation = true
	return success

func _save_with_feedback() -> bool:
	if not save_manager.save_progress(progress):
		_hud.save_feedback("SAVE FAILED", 2)
		return false
	if OS.has_feature("web"):
		# FileAccess writes are synchronous; IndexedDB durability is asynchronous.
		# Report SAVED only after this exact snapshot can be read from the browser DB.
		_save_pending = true
		_hud.save_feedback("SAVING…", 10)
		_confirm_web_save(FileAccess.get_file_as_string(save_manager.save_path))
	else:
		_hud.save_feedback("SAVED")
	return true

func _confirm_web_save(expected: String) -> void:
	var suffix := "/" + save_manager.save_path.trim_prefix("user://")
	var script := "window.biwakoSaveConfirmed=false;window.biwakoSaveCheck=async function(){try{const d=await new Promise((ok,bad)=>{const r=indexedDB.open('/userfs');r.onsuccess=()=>ok(r.result);r.onerror=()=>bad(r.error);});if(!d.objectStoreNames.contains('FILE_DATA')){d.close();return;}const tx=d.transaction('FILE_DATA');const store=tx.objectStore('FILE_DATA');const keys=await new Promise(ok=>{const r=store.getAllKeys();r.onsuccess=()=>ok(r.result);});const key=keys.find(k=>String(k).endsWith(%s));if(key){const tx2=d.transaction('FILE_DATA');const v=await new Promise(ok=>{const r=tx2.objectStore('FILE_DATA').get(key);r.onsuccess=()=>ok(r.result);});window.biwakoSaveConfirmed=v&&new TextDecoder().decode(v.contents)===%s;}d.close();}catch(e){window.biwakoSaveConfirmed=false;}};" % [JSON.stringify(suffix), JSON.stringify(expected)]
	JavaScriptBridge.eval(script, true)
	var confirmed := false
	for attempt in range(32):
		JavaScriptBridge.eval("window.biwakoSaveCheck()", true)
		await get_tree().create_timer(0.25, true).timeout
		if JavaScriptBridge.eval("window.biwakoSaveConfirmed === true", true):
			confirmed = true
			break
	_save_pending = false
	if confirmed and _manual_confirmation: _playtest.record("FIRST_MANUAL_SAVE")
	_manual_confirmation = false
	_hud.save_feedback("SAVED" if confirmed else "SAVE FAILED", 0.7 if confirmed else 2)
	_refresh_ui()

func request_travel(destination: String) -> bool:
	if not can_open_area() or destination == progress.current_area or not LakeAreas.unlocked(destination, progress): return false
	state = State.TRAVELLING
	_travel_destination = destination
	_travel_remaining = 1.4
	_hud.show_result("移動中")
	_update_line()
	_refresh_ui()
	return true

func _step_travel(delta: float) -> void:
	_travel_remaining = maxf(0, _travel_remaining - delta)
	var fraction := 1.0 - _travel_remaining / 1.4
	_boat.set_anchor(Vector2(floorf(get_parent().view_size.x * 0.52 + sin(fraction * PI) * 80), _surface_y - 3))
	if _travel_remaining > 0: return
	progress.current_area = _travel_destination
	_travel_destination = ""
	restore_area()
	state = State.READY
	_hud.show_result("")
	_save_with_feedback() # Arrival is an explicit additional autosave, including current_area.
	_playtest.record("FIRST_AREA_MOVE")
	if progress.current_area == LakeAreas.NORTH: _playtest.record("NORTH_SHORE_ENTERED")
	if progress.current_area == LakeAreas.CENTER: _playtest.record("NORTH_CENTER_ENTERED")
	_refresh_ui()

func restore_area() -> void:
	clear_aim()
	var area := progress.current_area
	if not LakeAreas.unlocked(area, progress):
		area = LakeAreas.SOUTH
		progress.current_area = area
	get_parent().set_area(area)
	selected_band = LakeAreas.safe_band(area, selected_band, progress.current("line").effect_value)
	seek_depth_m = 0
	_deep_cast_count = 0
	_progress_changed()
	get_parent().populate_depth_band(selected_band, progress.current("line").effect_value)
	_hud.get_node("SonarPlaceholder").lingering_contact.clear()
	_hud.get_node("SonarPlaceholder").lingering_remaining = 0
	_hud.get_node("SonarPlaceholder").refresh_contacts()
	_hud.get_node("AreaLabel").text = LakeAreas.DATA[area].name
	_refresh_ui()

func can_retrieve() -> bool:
	return state in [State.SINKING, State.WAITING] and active_fish == null and not _shop_open and not _book_open and not _area_open and not _save_pending

func request_retrieve() -> bool:
	if not can_retrieve(): return false
	_begin_reset()
	_refresh_ui()
	return true

func _cast_or_retrieve() -> bool:
	return request_cast() if state == State.READY else request_retrieve()
