extends "res://tests/phase2_acceptance.gd"
## Presentation invariants in addition to the unchanged Phase 1–6 regressions.
func _run() -> void:
	root.size = Vector2i(1280, 720)
	_new_scene()
	await process_frame
	await process_frame
	var ids: Dictionary = {}
	var shapes: Dictionary = {}
	for fish: FishController in _fishes:
		ids[fish.fight_profile.species_id] = true
		var frames := fish.sprite.sprite_frames
		_check(frames.get_frame_count("swim") == 3 and frames.get_frame_texture("swim", 0).get_size() == Vector2(40, 22), "Fish art: three nearest pixel frames / unchanged AI envelope")
		_check(frames == RefinedPixelArt.fish_frames(fish.fight_profile.species_id), "Fish art: species-specific shared cache")
		var before: Array = [fish.state, fish.position, fish.depth_position, fish.size_cm, fish.stamina, fish.swim_direction]
		fish.sprite._process(1.0)
		_check(before == [fish.state, fish.position, fish.depth_position, fish.size_cm, fish.stamina, fish.swim_direction], "Fish visual: no state / position / gameplay size mutation")
		_check(fish.sprite.scale.x >= 0.7 and fish.sprite.scale.x <= 1 and fish.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Fish visual: size variation inside original bounds / nearest filtering")
	for profile: FishFightProfile in GameProgress.FISH_PROFILES.slice(0, 5):
		var frame := RefinedPixelArt.fish_frames(profile.species_id).get_frame_texture("swim", 1)
		shapes[frame.get_image().get_data().hex_encode().sha256_text()] = true
	_check(ids.size() == 5 and shapes.size() == 5, "Five original shallow fish species: distinct sprites preserved")
	var fish: FishController = _fishes[1]
	var original_size := fish.size_cm
	fish.size_cm = fish.fight_profile.min_size_cm
	fish.sprite._process(0)
	var small_scale := fish.sprite.scale.x
	fish.size_cm = fish.fight_profile.max_size_cm
	fish.sprite._process(0)
	_check(fish.sprite.scale.x > small_scale, "Fish size: presentation scale reflects catch size")
	fish.size_cm = original_size
	fish.sprite._process(0)
	_check(_boat.get_node("Sprite").texture.get_width() == 154 and _boat.get_node("Sprite").texture.get_height() == 64, "Boat: 1.4× hull presence with unchanged node anchor")
	var position: Vector2 = _boat.position
	_check(_boat.rod_tip_position().is_equal_approx(position + Vector2(-40, -40)), "Boat: original resting rod attachment unchanged")
	_boat.set_line_pull(100, true)
	_check(_boat.rod_tip_position().is_equal_approx(position + Vector2(-37.5, -33.5)), "Boat: original tension-to-rod attachment unchanged")
	_boat.set_line_pull(0, false)
	_check(_lake.get_node("Background/BackgroundMountains").get_child_count() == 3, "Mountains: separate far / middle / shore layers")
	var profile: LakeProfile = _lake.profile
	_check(profile.mountain_far.get_luminance() > profile.mountain_middle.get_luminance() and profile.mountain_middle.get_luminance() > profile.mountain_near.get_luminance(), "Mountains: distance reduces contrast / increases lightness")
	var underwater: Node2D = _lake.get_node("Underwater/WaterBackground")
	_check(underwater.color_at_depth(0).get_luminance() > underwater.color_at_depth(7.5).get_luminance() and underwater.color_at_depth(7.5).get_luminance() > underwater.color_at_depth(15).get_luminance(), "Underwater: progressively darker with existing depth model")
	var book: Control = _hud.get_node("FishBook")
	_check(book.entries.size() == GameProgress.FISH_PROFILES.size() and book.entries["No.02"].get_parent() is HBoxContainer, "Fish book: data-backed visual cards preserve original labels and records")
	var book_visual: Node = _hud.get_node("PixelVisual")
	_check(book_visual._icons["No.02"].texture == book_visual._unknown, "Fish book: undiscovered uses anonymous silhouette")
	_flow.progress.record_catch(GameProgress.FISH_PROFILES[1], 42.6)
	_check(book_visual._icons["No.02"].texture != book_visual._unknown and book.entries["No.02"].text.contains("BEST SIZE 42.6"), "Fish book: discovery swaps icon, original count/BEST remain readable")
	var theme: Theme = _hud.theme
	_check(theme != null and _hud.get_node("Shop").theme == theme and book.theme == theme, "Pixel UI: shared theme for HUD and both modals")
	var nodes: int = get_node_count()
	var writes: int = _flow.save_manager.write_count
	for tick in range(600):
		for item: FishController in _fishes:
			item.sprite._process(1.0 / 60)
		_lake.get_node("Lake/LakeSurface")._process(1.0 / 60)
	_check(nodes == get_node_count() and writes == _flow.save_manager.write_count, "Visual animation: no new nodes or Save IO")
	for dimension in [Vector2i(640, 360), Vector2i(1560, 720), Vector2i(1600, 720)]:
		root.size = dimension
		await process_frame
		await process_frame
		for node_name in ["CastButton", "ReelButton", "ShopButton", "BookButton", "SonarPlaceholder"]:
			var control: Control = _hud.get_node(node_name)
			_check(_hud.safe_rect.encloses(control.get_global_rect()), "%s: %s inside safe area" % [dimension, node_name])
		_check(_flow.request_book(), "%s: original book open input" % dimension)
		await process_frame
		_check(_hud.safe_rect.encloses(book.get_node("Panel").get_global_rect()), "%s: visual book cards fit modal" % dimension)
		book.close_book()
		_check(not paused, "%s: original book close resumes" % dimension)
	print("VISUAL_ACCEPTANCE ", JSON.stringify({"result": "PASS" if _failures.is_empty() else "FAIL", "checks": _checks, "failures": _failures, "fish_species": 5, "mountain_layers": 3}))
	_main.free()
	DirAccess.remove_absolute(_test_save_path)
	quit(0 if _failures.is_empty() else 1)
