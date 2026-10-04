extends Node2D
## Owns Phase 2 flow and input; lake drawing stays independent.

enum State { READY, CASTING, SINKING, WAITING, BITTEN, HOOKED, RESET }
signal hook_succeeded
signal hook_missed

@export var random_seed: int = 2463
@export_range(1.0, 3.0) var hook_window_seconds: float = 1.5
@export_range(0.5, 2.0) var hit_hold_seconds: float = 1.0

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

func _ready() -> void:
	_rng.seed = random_seed
	line.add_point(Vector2.ZERO)
	line.add_point(Vector2.ZERO)
	line.visible = false

func setup(boat: Node2D, fishes: Node2D, hud: Control) -> void:
	_boat = boat
	_fish_container = fishes
	_hud = hud
	_hud.get_node("CastButton").pressed.connect(request_cast)
	_refresh_ui()

func configure_water(bounds: Rect2, surface_y: float, depth_m: float) -> void:
	lure.configure_water(bounds, surface_y, depth_m)
	if _boat != null:
		lure.set_cast_origin(_boat.rod_tip_position())
	_update_line()
	_refresh_ui()

func request_cast() -> bool:
	if state != State.READY or _boat == null:
		return false
	if not lure.cast_from(_boat.rod_tip_position()):
		return false
	state = State.CASTING
	cast_elapsed = 0.0
	_detection_timer = 0.0
	_retry_delay = 0.0
	_message_remaining = 0.0
	_hud.show_result("")
	_update_line()
	_refresh_ui()
	return true

func _input(event: InputEvent) -> void:
	if state == State.READY and event is InputEventScreenTouch and event.pressed and _hud != null:
		if _hud.get_node("CastButton").get_global_rect().has_point(event.position):
			if request_cast():
				get_viewport().set_input_as_handled()
			return
	var pressed: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed)
	if pressed and request_hook():
		get_viewport().set_input_as_handled()

func request_hook() -> bool:
	if state != State.BITTEN or _bite_remaining <= 0.0:
		return false
	state = State.HOOKED
	lure.hook()
	active_fish.hook()
	_hit_remaining = hit_hold_seconds
	_hud.show_bite(false, lure.position)
	_hud.show_result("HIT!")
	hook_succeeded.emit()
	_refresh_ui()
	return true

func _physics_process(delta: float) -> void:
	if _hud == null:
		return
	if state == State.READY:
		return
	cast_elapsed += delta
	lure.set_cast_origin(_boat.rod_tip_position())
	_message_remaining = maxf(0.0, _message_remaining - delta)
	if _message_remaining == 0.0 and state not in [State.HOOKED, State.RESET]:
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
		if fish.can_detect_lure() and candidate_distance <= fish.bite_detection_radius and candidate_distance < distance:
			closest = fish
			distance = candidate_distance
	if closest == null:
		return
	# Repeated local detection gradually raises interest to avoid long MVP waits.
	var chance := minf(1.0, closest.bite_probability + maxf(0.0, cast_elapsed - 3.0) * 0.18)
	if _rng.randf() <= chance and closest.approach_lure(lure):
		active_fish = closest

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
	# Phase 2 test reset only. Phase 3 replaces this path with FishingFight.
	state = State.RESET
	lure.begin_reset()
	active_fish.release_lure(false)
	active_fish = null
	_reset_remaining = 0.2

func _update_line() -> void:
	line.visible = state not in [State.READY, State.RESET]
	if _boat != null and line.get_point_count() == 2:
		line.set_point_position(0, _boat.rod_tip_position())
		line.set_point_position(1, lure.position)

func _refresh_ui() -> void:
	if _hud == null:
		return
	_hud.get_node("CastButton").disabled = state != State.READY
	_hud.show_lure_depth(lure.depth_m, state != State.READY and state != State.RESET)
	_hud.show_bite(state == State.BITTEN, lure.position)
