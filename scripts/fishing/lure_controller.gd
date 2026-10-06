class_name LureController
extends Node2D
## Depth is measured in metres; only this scene converts it to lake pixels.

enum State { READY, CASTING, SINKING, WAITING, BITTEN, HOOKED, FIGHTING, LANDING, RESET }
signal landed

@export var lure_art: Texture2D
@export_range(0.4, 0.7) var cast_duration: float = 0.55
@export_range(0.1, 20.0) var sink_speed_m: float = 2.3
@export_range(0.0, 5.0) var deep_sink_acceleration: float = 1.8
@export_range(1.0, 150.0, 0.1, "or_greater") var max_depth_m: float = 15.0

var state: State = State.READY
var depth_origin_m: float = 0.0
var depth_m: float = 0.0
var target_depth_m: float = -1.0 # Negative keeps the ordinary automatic descent.
var splash_remaining: float = 0.0
var _surface_y: float = 136.0
var _water := Rect2(10, 140, 620, 198)
var _visible_depth_m: float = 15.0
var _cast_start := Vector2.ZERO
var _cast_elapsed: float = 0.0
var _x_fraction: float = 0.28
var _wobble_time: float = 0.0
var _splash_x: float = 0.0

func _ready() -> void:
	visible = false

func configure_water(bounds: Rect2, surface_y: float, visible_depth_m: float, origin_m: float = 0.0) -> void:
	_water = bounds
	_surface_y = surface_y
	depth_origin_m = origin_m
	_visible_depth_m = maxf(visible_depth_m, 0.1)
	_splash_x = _target_x()
	if state not in [State.READY, State.RESET, State.CASTING, State.FIGHTING, State.LANDING]:
		_update_underwater_position()

func cast_from(origin: Vector2, target_fraction: float = 0.28, stop_depth_m: float = -1.0) -> bool:
	if state != State.READY:
		return false
	_cast_start = origin
	_x_fraction = clampf(target_fraction, 0.03, 0.97)
	target_depth_m = stop_depth_m
	_cast_elapsed = 0.0
	depth_m = 0.0
	splash_remaining = 0.0
	_wobble_time = 0.0
	position = origin
	state = State.CASTING
	visible = true
	queue_redraw()
	return true

func set_cast_origin(origin: Vector2) -> void:
	# Keep the arc and line attached to the bobbing boat, including on resize.
	_cast_start = origin

func _physics_process(delta: float) -> void:
	if state in [State.READY, State.RESET]:
		return
	splash_remaining = maxf(0.0, splash_remaining - delta)
	match state:
		State.CASTING:
			_cast_elapsed = minf(_cast_elapsed + delta, cast_duration)
			var t := _cast_elapsed / cast_duration
			var target := Vector2(_target_x(), _surface_y)
			position = _cast_start.lerp(target, t) - Vector2(0, sin(t * PI) * 32.0)
			if t >= 1.0:
				state = State.SINKING
				splash_remaining = 0.45
				_splash_x = position.x
				landed.emit()
		State.SINKING:
			depth_m = minf(depth_m + (sink_speed_m + maxf(0, depth_m - 15.0) * deep_sink_acceleration) * delta, _sink_limit())
			_update_underwater_position()
			if depth_m >= _sink_limit():
				state = State.WAITING
		State.BITTEN:
			_wobble_time += delta
			_update_underwater_position()
			if _wobble_time <= 0.7:
				position += Vector2(sin(_wobble_time * 24.0) * 2.0, sin(_wobble_time * 18.0) * 1.2)
	queue_redraw()

func _sink_limit() -> float:
	var limit := minf(max_depth_m, depth_origin_m + _visible_depth_m)
	return minf(limit, maxf(depth_origin_m, target_depth_m)) if target_depth_m >= 0 else limit

func _target_x() -> float:
	return _water.position.x + _water.size.x * _x_fraction

func _update_underwater_position() -> void:
	position = Vector2(_target_x(), _surface_y + clampf((depth_m - depth_origin_m) / _visible_depth_m, 0.0, 1.0) * (_water.end.y - 8.0 - _surface_y))

func pause_for_interest() -> void:
	# Hold the lure while a reserved fish approaches within its depth habitat.
	if state == State.SINKING:
		state = State.WAITING

func begin_bite() -> void:
	state = State.BITTEN
	_wobble_time = 0.0

func hook() -> void:
	state = State.HOOKED

func resume_sinking() -> void:
	state = State.WAITING if depth_m >= _sink_limit() else State.SINKING
	_update_underwater_position()

func begin_reset() -> void:
	state = State.RESET
	visible = false
	splash_remaining = 0.0

func finish_reset() -> void:
	state = State.READY
	depth_m = 0.0
	target_depth_m = -1.0

func _draw() -> void:
	if lure_art != null:
		draw_texture(lure_art, -lure_art.get_size() * 0.5)
	else:
		# Original pixel spoon; swap lure_art without changing the flow.
		draw_rect(Rect2(-3, -5, 6, 9), Color("dfb367"))
		draw_rect(Rect2(-2, -4, 2, 6), Color("fff1be"))
		draw_rect(Rect2(2, -2, 2, 5), Color("b37045"))
		draw_line(Vector2(0, 4), Vector2(0, 7), Color("d7e7d7"), 1.0)
		draw_line(Vector2(0, 7), Vector2(3, 7), Color("d7e7d7"), 1.0)
	if splash_remaining > 0.0:
		var t := 1.0 - splash_remaining / 0.45
		var center := Vector2(_splash_x, _surface_y) - position
		var tint := Color(0.85, 0.96, 0.89, 1.0 - t)
		var radius := 3.0 + t * 13.0
		draw_line(center - Vector2(radius, 0), center + Vector2(radius, 0), tint, 1.0)
		for direction in [-1, 1]:
			draw_rect(Rect2(center + Vector2(direction * radius * 0.65, -sin(t * PI) * 9.0), Vector2(2, 2)), tint)

func follow_fish(value: Vector2, landing: bool = false) -> void:
	state = State.LANDING if landing else State.FIGHTING
	position = value
	depth_m = depth_origin_m + clampf((position.y - _surface_y) / maxf(_water.end.y - 8.0 - _surface_y, 1.0) * _visible_depth_m, 0.0, _visible_depth_m)

func landing_splash(value: Vector2) -> void:
	position = value
	_splash_x = value.x
	splash_remaining = 0.45
	state = State.LANDING
