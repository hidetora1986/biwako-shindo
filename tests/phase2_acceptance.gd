extends SceneTree
## Deterministic integration tests, including actual viewport touch/mouse input.

const FLOW := preload("res://scripts/fishing/fishing_controller.gd")
var _failures: Array[String] = []
var _checks: int = 0
var _main: Node2D
var _lake: Node2D
var _flow: Node2D
var _hud: Control
var _fishes: Array[Node]
var _boat: Node2D
var _cast_times: Array[float] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", label)
	else:
		_failures.append(label)
		push_error("FAIL: " + label)

func _disable_physics(node: Node) -> void:
	node.set_physics_process(false)
	for child in node.get_children():
		_disable_physics(child)

func _step(seconds: float) -> void:
	for tick in range(int(ceil(seconds * 60.0))):
		for fish: FishController in _fishes:
			fish._physics_process(1.0 / 60.0)
		_boat._physics_process(1.0 / 60.0)
		_flow.lure._physics_process(1.0 / 60.0)
		_flow._physics_process(1.0 / 60.0)

func _until_bite(limit: float = 15.0) -> bool:
	for tick in range(int(limit * 60.0)):
		if _flow.state == FLOW.State.BITTEN:
			return true
		_step(1.0 / 60.0)
	return false

func _mouse(position: Vector2, pressed: bool = true) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	root.push_input(event, true)

func _touch(position: Vector2, index: int = 0, pressed: bool = true) -> void:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.index = index
	event.pressed = pressed
	root.push_input(event, true)

func _new_scene() -> void:
	if is_instance_valid(_main):
		_main.free()
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	_lake = _main.get_node("LakeScene")
	_flow = _lake.get_node("FishingController")
	_hud = _lake.get_node("HUD/Root")
	_fishes = _lake.get_node("Underwater/FishContainer").get_children()
	_boat = _lake.get_node("Lake/Boat")
	_disable_physics(_main)

func _run() -> void:
	_new_scene()
	await process_frame
	await process_frame
	_check(_flow.state == FLOW.State.READY and _flow.lure.state == LureController.State.READY and not _flow.lure.visible and not _flow.line.visible, "READY: idle lure and line are hidden")
	_check(not _hud.get_node("CastButton").disabled and _hud.get_node("CastButton").size.y >= 44, "CAST: usable 44px+ target")
	var node_count := get_node_count()
	var landings: Array[Vector2] = []
	_flow.lure.landed.connect(func(): landings.append(_flow.lure.position))
	_mouse(_hud.get_node("CastButton").get_global_rect().get_center())
	_mouse(_hud.get_node("CastButton").get_global_rect().get_center(), false)
	_check(_flow.state == FLOW.State.CASTING and _flow.lure.state == LureController.State.CASTING, "CAST: real mouse press starts flight")
	var doubled := false
	for tap in range(20):
		doubled = _flow.request_cast() or doubled
		_touch(_hud.get_node("CastButton").get_global_rect().get_center(), tap)
	_check(not doubled and _hud.get_node("CastButton").disabled and get_node_count() == node_count, "CAST: rapid clicks/touches reuse exactly one lure")
	var origin: Vector2 = _flow.lure.position
	_step(0.25)
	_check(_flow.lure.position.x < origin.x and _flow.lure.position.y < origin.y and _flow.lure.state == LureController.State.CASTING, "Lure Flight: visible arc from the rod")
	_check(_flow.line.visible and _flow.line.get_point_position(0).is_equal_approx(_boat.rod_tip_position()), "Fishing Line: attached to the boat")
	_step(0.32)
	_check(_flow.lure.state == LureController.State.SINKING and landings.size() == 1 and is_equal_approx(landings[0].y, _lake.surface_y) and _flow.lure.splash_remaining > 0.0, "Lure Splash: 0.55s landing with splash")
	_step(1.0)
	_check(_flow.lure.depth_m > 2.0 and _flow.lure.position.y > _lake.surface_y, "Lure Sinking: depth increases underwater")
	_check(_hud.get_node("Depth/Label").text == "%.1fm" % _flow.lure.depth_m or absf(float(_hud.get_node("Depth/Label").text.trim_suffix("m")) - _flow.lure.depth_m) < 0.1, "Depth Display: metres follow sinking")
	_check(not _flow.request_hook(), "Hook: early tap does not hook")
	_check(_flow.line.get_point_position(1).is_equal_approx(_flow.lure.position), "Fishing Line: endpoint follows the sinking lure")
	_step(1.5)
	var approaching := 0
	for fish: FishController in _fishes:
		if fish.state == FishController.SwimState.APPROACH_LURE:
			approaching += 1
	_check(approaching == 1 and _flow.active_fish != null, "Fish Detection: exactly one nearby fish approaches")
	if _flow.active_fish != null:
		var selected: FishController = _flow.active_fish
		var previous_distance := selected.position.distance_to(_flow.lure.position)
		_step(0.3)
		_check(selected.position.distance_to(_flow.lure.position) < previous_distance, "Fish Approach: distance decreases")
		_check(not selected.approach_lure(_flow.lure), "Fish: reserved fish cannot take a second bite")
	_check(_until_bite(), "Bite: natural detection reaches the bite window")
	_check(_hud.get_node("Bite").visible and _flow.lure.state == LureController.State.BITTEN and _flow.active_fish.state == FishController.SwimState.BITE, "Bite: exclamation and matching states")
	_step(1.35)
	_touch(Vector2(600, 180))
	_check(_flow.state == FLOW.State.HOOKED and _flow.active_fish.state == FishController.SwimState.HOOKED and _hud.get_node("Result").text == "HIT!", "Hook Success: wide-area touch near the 1.5s deadline")
	var frozen: Vector2 = _flow.active_fish.position
	var frozen_lure: Vector2 = _flow.lure.position
	_touch(Vector2(20, 180), 1)
	_mouse(Vector2(320, 200))
	_check(not _flow.request_hook() and not _flow.request_cast(), "Hook: duplicate touch/mouse and post-HIT input ignored")
	_step(0.95)
	_check(_flow.state == FLOW.State.HOOKED and _flow.active_fish.position.is_equal_approx(frozen) and _flow.lure.position.is_equal_approx(frozen_lure), "HIT: fish and lure hold for about 1 second")
	_step(0.08)
	_check(_flow.state == FLOW.State.RESET and not _flow.request_cast() and not _flow.request_hook(), "RESET: input locked during temporary reset")
	_step(0.22)
	_check(_flow.state == FLOW.State.READY and _flow.lure.state == LureController.State.READY and not _flow.line.visible and not _hud.get_node("CastButton").disabled, "Temporary Reset: CAST re-enabled")
	_touch(_hud.get_node("CastButton").get_global_rect().get_center())
	_check(_flow.state == FLOW.State.CASTING, "CAST: real screen touch starts a second cast")
	_check(_until_bite(), "Bite: second cast can bite")
	var missed_fish: FishController = _flow.active_fish
	_step(1.51)
	_check(_flow.state != FLOW.State.BITTEN and _flow.state != FLOW.State.HOOKED and _hud.get_node("Result").text == "MISS" and not _flow.request_hook(), "Hook Miss: expired window cannot hook")
	_check(missed_fish.state == FishController.SwimState.SWIM and not missed_fish.can_detect_lure(), "MISS: fish swims away with cooldown")
	_step(1.0)
	_check(not _hud.get_node("Result").visible and _flow.active_fish == null, "MISS: feedback clears and retry waits")
	_check(_until_bite(12.0) and _flow.active_fish != missed_fish, "MISS: another fish bites without recasting")
	_mouse(Vector2(50, 220))
	_check(_flow.state == FLOW.State.HOOKED, "Hook Success: PC left click also hooks")
	_step(1.25)
	_check(get_node_count() == node_count and _fishes.size() == 7, "Reuse: two casts and retry add no nodes or fish")
	# Isolate the lure to verify maximum depth and future depth scales.
	var isolated: LureController = load("res://scenes/fishing/lure.tscn").instantiate()
	root.add_child(isolated)
	isolated.set_physics_process(false)
	isolated.configure_water(_lake.water_bounds, _lake.surface_y, 15.0)
	isolated.cast_from(Vector2(300, 95))
	isolated._physics_process(0.55)
	isolated._physics_process(6.53)
	_check(isolated.state == LureController.State.WAITING and is_equal_approx(isolated.depth_m, 15.0) and isolated.position.y < _lake.water_bounds.end.y, "Depth: 15m cap reached in 6.53 seconds after landing")
	isolated.max_depth_m = 120
	isolated.configure_water(_lake.water_bounds, _lake.surface_y, 120)
	isolated._physics_process(0.1)
	_check(is_equal_approx(isolated.depth_m, 15) and isolated.position.y < _lake.surface_y + _lake.water_bounds.size.y * 0.2, "Depth: 120m display rescales pixels while preserving metres")
	isolated.free()
	# Configurable radius and cooldown gate interest; swimming alone never attracts.
	_new_scene()
	_flow.request_cast()
	for fish: FishController in _fishes:
		fish.bite_detection_radius = 1.0
	_step(8.0)
	_check(_flow.active_fish == null and _flow.lure.state == LureController.State.WAITING, "Fish Detection: outside radius fish keep swimming")
	# Verify real layouts/input at both target aspect ratios plus 20:9 and notches.
	for spec in [[1280, 720, "16:9"], [1560, 720, "19.5:9"], [1600, 720, "20:9"], [320, 180, "320px 16:9"]]:
		_new_scene()
		root.size = Vector2i(spec[0], spec[1])
		await process_frame
		await process_frame
		var safe := Rect2(36, 8, _lake.view_size.x - 72, _lake.view_size.y - 24)
		_hud.layout_in_safe_area(_lake.view_size, safe, _lake.surface_y, 15.0)
		var ui_ok := true
		for node_name in ["Money", "SonarPlaceholder", "Depth", "Title", "Subtitle", "CastButton", "Result"]:
			ui_ok = ui_ok and _hud.safe_rect.encloses(_hud.get_node(node_name).get_global_rect())
		_check(ui_ok and _hud.get_node("CastButton").size.y >= 44, spec[2] + ": controls and results inside simulated safe area")
		var physical_height: float = _hud.get_node("CastButton").size.y * float(spec[1]) / _lake.view_size.y
		_check(physical_height >= 44.0, spec[2] + ": CAST retains a physical 44px target")
		_touch(_hud.get_node("CastButton").get_global_rect().get_center())
		_check(_until_bite(), spec[2] + ": touch cast, flight, approach and bite work")
		_check(_hud.safe_rect.encloses(_hud.get_node("Bite").get_global_rect()), spec[2] + ": exclamation inside safe area")
		_touch(Vector2(_lake.view_size.x - 10, 180))
		_check(_flow.state == FLOW.State.HOOKED, spec[2] + ": broad-area touch hooks")
	# Resize while sinking, and again during the hook window, without changing metres.
	root.size = Vector2i(1280, 720)
	_new_scene()
	await process_frame
	_flow.request_cast()
	_step(2.0)
	var preserved_depth: float = _flow.lure.depth_m
	root.size = Vector2i(1560, 720)
	await process_frame
	await process_frame
	_check(is_equal_approx(_flow.lure.depth_m, preserved_depth) and _flow.line.get_point_position(1).is_equal_approx(_flow.lure.position), "Resize: sinking preserves metres and line attachment")
	_check(_until_bite(), "Resize: the same cast still bites")
	preserved_depth = _flow.lure.depth_m
	root.size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	_check(_flow.state == FLOW.State.BITTEN and is_equal_approx(_flow.lure.depth_m, preserved_depth) and _hud.safe_rect.encloses(_hud.get_node("Bite").get_global_rect()), "Resize: active bite and indicator remain usable")
	_touch(Vector2(300, 100))
	_check(_flow.state == FLOW.State.HOOKED, "Resize: resized cast can hook")
	# Several fresh seeds/delayed starts and repeated casts expose long waits and leaks.
	root.size = Vector2i(1280, 720)
	for seed_value in range(12):
		_new_scene()
		_flow._rng.seed = seed_value * 31 + 7
		_step(float(seed_value) * 1.7)
		for cast_index in range(3):
			_flow.request_cast()
			if _until_bite(25):
				_cast_times.append(_flow.cast_elapsed + 0.25)
				_step(0.25)
				_flow.request_hook()
				_step(1.25)
			else:
				_cast_times.append(30.0)
	var total := 0.0
	var longest := 0.0
	for seconds in _cast_times:
		total += seconds
		longest = maxf(longest, seconds)
	var average := total / _cast_times.size()
	_check(longest < 15.0 and average >= 5.0 and average <= 12.0, "Tempo: 36 casts, average 5–12s and no long wait")
	print("PHASE2_ACCEPTANCE ", JSON.stringify({"result": "PASS" if _failures.is_empty() else "FAIL", "checks": _checks, "failures": _failures, "casts": _cast_times.size(), "average_cast_to_hit_s": average, "longest_cast_to_hit_s": longest}))
	_main.queue_free()
	await process_frame
	quit(0 if _failures.is_empty() else 1)
