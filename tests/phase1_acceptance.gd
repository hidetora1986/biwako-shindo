extends SceneTree
## Run with: godot --headless --path . --script res://tests/phase1_acceptance.gd

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures.append(label)
		push_error("FAIL: " + label)
	else:
		print("PASS: ", label)

func _run() -> void:
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	main.get_node("LakeScene/FishingController").save_path = "user://tests/phase1-%d.json" % OS.get_process_id()
	root.add_child(main)
	await process_frame
	var lake = main.get_node("LakeScene")
	var fish_container: Node2D = lake.get_node("Underwater/FishContainer")
	var boat = lake.get_node("Lake/Boat")
	var surface = lake.get_node("Lake/LakeSurface")
	var background = lake.get_node("Underwater/WaterBackground")
	var hud = lake.get_node("HUD/Root")
	_check(fish_container.get_child_count() >= 5 and fish_container.get_child_count() <= 8, "Fish Spawn: 5–8 fish")
	_check(boat.get_node("Sprite").texture != null, "Boat: visible texture")
	_check(background.color_at_depth(1).get_luminance() > background.color_at_depth(7.5).get_luminance()
		and background.color_at_depth(7.5).get_luminance() > background.color_at_depth(14).get_luminance(), "Underwater: progressively darker")
	var speeds: Dictionary = {}
	var overlap := false
	var fishes := fish_container.get_children()
	for i in range(fishes.size()):
		var fish: FishController = fishes[i]
		speeds[fish.swim_speed] = true
		var box := Rect2(fish.position - Vector2(20, 11), Vector2(40, 22))
		for j in range(i + 1, fishes.size()):
			var other: FishController = fishes[j]
			if box.intersects(Rect2(other.position - Vector2(20, 11), Vector2(40, 22))):
				overlap = true
	_check(not overlap, "Fish Spawn: separated initial positions")
	var clear_of_hud := true
	for fish: FishController in fishes:
		clear_of_hud = clear_of_hud and not Rect2(fish.position - Vector2(20, 11), Vector2(40, 22)).intersects(hud.get_node("Depth").get_global_rect())
	_check(clear_of_hud, "Fish Spawn: initial fish are clear of the depth HUD")
	_check(speeds.size() >= 3, "Fish Movement: varied base speeds")
	# Verify actual movement and sprite facing away from the edges.
	var movement_ok := true
	var turns_ok := true
	for fish: FishController in fishes:
		fish.position.x = lake.view_size.x * 0.5
		fish.swim_direction = 1
		var start := fish.position.x
		fish._physics_process(0.2)
		movement_ok = movement_ok and fish.position.x > start and not fish.sprite.flip_h
		fish.swim_direction = -1
		start = fish.position.x
		fish._physics_process(0.2)
		movement_ok = movement_ok and fish.position.x < start and fish.sprite.flip_h
		fish.position.x = fish.water_bounds.position.x + 20
		fish._physics_process(0.1)
		turns_ok = turns_ok and fish.swim_direction == 1 and not fish.sprite.flip_h and fish.state == FishController.SwimState.TURN
		fish.position.x = fish.water_bounds.end.x - 20
		fish._physics_process(0.1)
		turns_ok = turns_ok and fish.swim_direction == -1 and fish.sprite.flip_h and fish.state == FishController.SwimState.TURN
	_check(movement_ok, "Fish Movement: both directions and matching sprite facing")
	_check(turns_ok, "Fish Movement: turn at both edges")
	var node_count := get_node_count()
	var contained := true
	var minimum_y: float = boat.position.y
	var maximum_y: float = boat.position.y
	var original_ripple: float = surface.ripple_offset(2)
	for tick in range(2250):
		for fish: FishController in fishes:
			fish._physics_process(1.0 / 30.0)
			var box := Rect2(fish.position - Vector2(20, 11), Vector2(40, 22))
			contained = contained and box.position.x >= 0 and box.end.x <= lake.view_size.x
			contained = contained and box.position.y > lake.surface_y and box.end.y < lake.view_size.y
		if tick < 75:
			boat._physics_process(1.0 / 30.0)
			minimum_y = minf(minimum_y, boat.position.y)
			maximum_y = maxf(maximum_y, boat.position.y)
		surface._process(1.0 / 30.0)
	_check(contained, "Fish Movement: 75 seconds stay underwater and on screen")
	_check(get_node_count() == node_count, "Performance: no nodes created during animation")
	_check(maximum_y - minimum_y > 5.5 and maximum_y - minimum_y <= 6.1, "Boat: 3 px bobbing over 2.5 seconds")
	_check(not is_equal_approx(original_ripple, surface.ripple_offset(2)), "Water Animation: ripples move")
	# Exercise the actual viewport resize path and simulated device insets.
	for spec in [[1280, 720, "16:9"], [1560, 720, "19.5:9"], [1600, 720, "20:9"]]:
		root.size = Vector2i(spec[0], spec[1])
		await process_frame
		await process_frame
		var size: Vector2 = lake.view_size
		_check(absf(size.x / size.y - float(spec[0]) / spec[1]) < 0.01, spec[2] + ": viewport expands correctly")
		var ui_ok := true
		for node_name in ["Money", "SonarPlaceholder", "Depth", "Title", "Subtitle"]:
			var control: Control = hud.get_node(node_name)
			ui_ok = ui_ok and hud.safe_rect.encloses(control.get_global_rect())
		_check(ui_ok, spec[2] + ": HUD inside safe area")
		hud.layout_in_safe_area(size, Rect2(36, 8, size.x - 72, size.y - 24), lake.surface_y, 15.0)
		ui_ok = true
		for node_name in ["Money", "SonarPlaceholder", "Depth"]:
			var control: Control = hud.get_node(node_name)
			ui_ok = ui_ok and hud.safe_rect.encloses(control.get_global_rect()) and control.size.y >= 44
		_check(ui_ok, spec[2] + ": simulated notch and 44 px future touch regions")
		hud.configure(size, lake.surface_y, 15.0)
	# A different image size can be supplied without changing the fish logic.
	var custom_art := SpriteFrames.new()
	custom_art.rename_animation("default", "swim")
	var custom_image := Image.create(48, 30, false, Image.FORMAT_RGBA8)
	custom_image.fill(Color.WHITE)
	custom_art.add_frame("swim", ImageTexture.create_from_image(custom_image))
	var custom_fish: FishController = load("res://scenes/fish/fish.tscn").instantiate()
	custom_fish.fish_art = custom_art
	root.add_child(custom_fish)
	custom_fish.depth_position = 0
	custom_fish.configure_water(lake.water_bounds, 15)
	var new_box := Rect2(custom_fish.position - Vector2(24, 15), Vector2(48, 30))
	_check(custom_fish.sprite.sprite_frames == custom_art and lake.water_bounds.encloses(new_box), "Fish Art: replacement frames and dimensions are respected")
	custom_fish.queue_free()
	var summary := {"phase": 1, "failures": _failures, "fish_count": fishes.size(), "result": "PASS" if _failures.is_empty() else "FAIL"}
	print("PHASE1_ACCEPTANCE ", JSON.stringify(summary))
	main.queue_free()
	await process_frame
	quit(0 if _failures.is_empty() else 1)
