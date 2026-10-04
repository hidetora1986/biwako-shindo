extends Node2D
## Owns fishing states/input. FishingFight handles only fight numbers.

enum State { READY, CASTING, SINKING, WAITING, BITTEN, HOOKED, FIGHTING, LANDING, LANDED, FAILED, RESET }
signal hook_succeeded
signal hook_missed

@export var save_path: String = "user://biwako-shindo/save.json"
@export var random_seed: int = 2463
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
var save_manager: SaveManager
var anomaly := SonarAnomaly.new()

func _ready() -> void:
	_rng.seed = random_seed
	line.add_point(Vector2.ZERO)
	line.add_point(Vector2.ZERO)
	line.visible = false

func setup(boat: Node2D, fishes: Node2D, hud: Control) -> void:
	_boat = boat
	_fish_container = fishes
	_hud = hud
	save_manager = SaveManager.new(save_path)
	save_manager.load_into(progress)
	save_manager.bind_progress(progress)
	_hud.get_node("CastButton").pressed.connect(request_cast)
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
	_progress_changed()
	_refresh_ui()

func configure_water(bounds: Rect2, surface_y: float, depth_m: float) -> void:
	_water = bounds
	_surface_y = surface_y
	lure.configure_water(bounds, surface_y, depth_m)
	if _boat != null:
		lure.set_cast_origin(_boat.rod_tip_position())
	if state == State.FIGHTING:
		_update_fight_pose()
	_update_line()
	_refresh_ui()

func request_cast() -> bool:
	if state != State.READY or _boat == null or _shop_open or _book_open:
		return false
	if not lure.cast_from(_boat.rod_tip_position()):
		return false
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
	if _shop_open or _book_open:
		return
	if event is InputEventScreenTouch and event.pressed and _hud != null and not _hud.get_node("ShopButton").disabled and _hud.get_node("ShopButton").get_global_rect().has_point(event.position):
		if request_shop():
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch and event.pressed and _hud != null and not _hud.get_node("BookButton").disabled and _hud.get_node("BookButton").get_global_rect().has_point(event.position):
		if request_book():
			get_viewport().set_input_as_handled()
		return
	if state == State.FIGHTING:
		_reel_input(event)
		return
	if state == State.READY and event is InputEventScreenTouch and event.pressed and _hud != null:
		if _hud.get_node("CastButton").get_global_rect().has_point(event.position):
			if request_cast():
				get_viewport().set_input_as_handled()
			return
	var pressed: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed)
	if pressed and request_hook():
		get_viewport().set_input_as_handled()

func request_hook() -> bool:
	if state != State.BITTEN or _bite_remaining <= 0.0 or _shop_open or _book_open:
		return false
	state = State.HOOKED
	lure.hook()
	active_fish.hook()
	_hit_remaining = hit_hold_seconds
	_session_caught = false
	active_fish.prepare_catch_size(_rng)
	fight.start(active_fish.fight_profile, progress.current("reel").effect_value, progress.current("rod").effect_value, active_fish.size_cm)
	_fight_origin_fraction = Vector2((active_fish.position.x - _water.position.x) / _water.size.x, (active_fish.position.y - _surface_y) / (_water.end.y - _surface_y))
	_hud.show_bite(false, lure.position)
	_hud.show_result("HIT!")
	hook_succeeded.emit()
	_refresh_ui()
	return true

func _physics_process(delta: float) -> void:
	if _hud == null or _shop_open or _book_open:
		return
	anomaly.step(delta, can_trigger_anomaly())
	if state == State.READY:
		_refresh_ui()
		return
	cast_elapsed += delta
	lure.set_cast_origin(_boat.rod_tip_position())
	_message_remaining = maxf(0.0, _message_remaining - delta)
	if _message_remaining == 0.0 and state not in [State.HOOKED, State.LANDED, State.FAILED, State.RESET]:
		_hud.show_result("")
	match state:
		State.CASTING:
			if lure.state == LureController.State.SINKING:
				state = State.SINKING
		State.SINKING, State.WAITING:
			state = State.WAITING if lure.state == LureController.State.WAITING else State.SINKING
			_retry_delay = maxf(0.0, _retry_delay - delta)
			_detection_timer -= delta
			if active_fish == null and cast_elapsed >= 2.2 and _retry_delay <= 0.0 and _detection_timer <= 0.0:
				_detection_timer = 0.45
				_detect_fish()
			if active_fish != null and cast_elapsed >= 5.0 and active_fish.position.distance_to(lure.position) <= 22.0:
				_begin_bite()
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
		if fish.can_detect_lure() and fish.fight_profile.allows_depth(lure.depth_m) and candidate_distance <= fish.bite_detection_radius and candidate_distance < distance:
			closest = fish
			distance = candidate_distance
	if closest == null:
		return
	# Repeated local detection gradually raises interest to avoid long MVP waits.
	var chance := minf(1.0, closest.bite_probability + maxf(0.0, cast_elapsed - 3.0) * 0.18)
	if _rng.randf() <= chance and closest.approach_lure(lure):
		active_fish = closest
		lure.pause_for_interest()

func _begin_bite() -> void:
	state = State.BITTEN
	lure.begin_bite()
	active_fish.begin_bite()
	_bite_remaining = hook_window_seconds
	# The first ~0.7 s of this generous window also provides the visible nibble.
	_hud.show_bite(true, lure.position)
	if OS.get_name() in ["Android", "iOS"]:
		# Godot safely does nothing on devices without vibration support.
		Input.vibrate_handheld(60)

func _miss() -> void:
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
	if state in [State.LANDED, State.FAILED]:
		progress.complete_normal_session()
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
	var fish_position := origin.lerp(target, clampf(1.0 - fight.fish_distance, 0.0, 1.0))
	if fight.resistance == FishingFight.Resistance.WARNING:
		fish_position.y += sin(fight.elapsed * 38.0) * 2.0
	active_fish.set_fight_pose(fish_position, fight.resistance)
	active_fish.sprite.modulate = Color("fff0bd") if fight.resistance == FishingFight.Resistance.WARNING else Color.WHITE
	lure.follow_fish(fish_position + Vector2(active_fish.swim_direction * 14, 0))
	_boat.set_line_pull(fight.tension, true)

func _fail_fight(message: String) -> void:
	state = State.FAILED
	_stop_reel()
	active_fish.finish_session(false)
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
	last_catch = {"species_id": active_fish.fight_profile.species_id, "name": active_fish.fight_profile.display_name, "size_cm": active_fish.size_cm, "id": active_fish.fight_profile.id, "price": progress.sell_catch(active_fish.fight_profile, active_fish.size_cm, _cast_serial)}
	last_catch["new_discovery"] = progress.last_sale_new_discovery
	active_fish.visible = false
	_hud.show_catch(last_catch, active_fish.sprite.sprite_frames.get_frame_texture("swim", 0))
	_haptic(100, 0.8)

func _haptic(duration_ms: int, amplitude: float) -> void:
	if OS.get_name() in ["Android", "iOS"]:
		Input.vibrate_handheld(duration_ms, amplitude)

func _update_line() -> void:
	line.visible = state not in [State.READY, State.LANDED, State.FAILED, State.RESET]
	line.default_color = Color("dfb875") if state == State.FIGHTING and fight.tension >= 70.0 else Color(0.88, 0.94, 0.81, 0.75)
	if _boat != null and line.get_point_count() == 2:
		line.set_point_position(0, _boat.rod_tip_position())
		line.set_point_position(1, lure.position)

func _refresh_ui() -> void:
	if _hud == null:
		return
	_hud.get_node("CastButton").disabled = state != State.READY or _shop_open or _book_open
	_hud.get_node("ShopButton").disabled = not can_open_shop()
	_hud.get_node("BookButton").disabled = not can_open_book()
	_hud.get_node("NextUpgrade").visible = state in [State.READY, State.CASTING, State.SINKING, State.WAITING, State.BITTEN]
	_hud.get_node("CastButton").visible = state in [State.READY, State.CASTING, State.SINKING, State.WAITING, State.BITTEN]
	_hud.show_fight(fight, state == State.FIGHTING)
	_hud.get_node("Depth").visible = state in [State.READY, State.CASTING, State.SINKING, State.WAITING, State.BITTEN]
	_hud.show_lure_depth(lure.depth_m, state != State.READY and state != State.RESET)
	_hud.show_bite(state == State.BITTEN, lure.position)

func can_open_shop() -> bool:
	return not _shop_open and not _book_open and not anomaly.active and state in [State.READY, State.SINKING, State.WAITING]

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
	lure.max_depth_m = progress.current("line").effect_value
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
	return state == State.READY and not _shop_open and not _book_open

func debug_trigger_anomaly() -> bool:
	# Acceptance callable; no released-game button or player-facing warning.
	return OS.is_debug_build() and anomaly.try_trigger(can_trigger_anomaly(), true)

func _exit_tree() -> void:
	if save_manager != null:
		save_manager.unbind_progress()
