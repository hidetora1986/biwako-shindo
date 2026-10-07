extends "res://tests/hidden_boss_acceptance.gd"
## No.00 remains unbounded imagery, no body node, unchanged model/endings/Save. Isolated saves.
func _run() -> void:
	root.size = Vector2i(640,360)
	_new_scene();await process_frame;await process_frame
	_hidden_fixture()
	_check(HiddenVisual.SURFACE_FRAGMENT.get_size() == Vector2(640,360),"Small offline raster / nearest rendering")
	var image := HiddenVisual.SURFACE_FRAGMENT.get_image()
	_check(image.get_pixel(320,230).a == 1 and image.get_pixel(160,20).b > 0.01 and image.get_pixel(320,230) != image.get_pixel(160,20),"Opaque nonempty night / underwater raster")
	_check(hidden.visual.get_child_count() == 0,"No creature sprite or body node")
	_check(_contact(),"Original hidden contact sequence")
	var before: Dictionary = _flow.save_manager.snapshot(_flow.progress)
	var nodes := get_node_count()
	for i in range(100):hidden.visual.queue_redraw()
	await process_frame
	_check(get_node_count() == nodes and _flow.save_manager.snapshot(_flow.progress) == before,"Redraw adds no nodes / Save changes")
	_check(_survive() and hidden.choose(true),"Original 50 second fight / contact choice")
	_step(6.2)
	_check(_flow.progress.no00_record().caught_count == 2 and _flow.story.mode == "contact","Contact count two / story retained")
	_check(GameProgress.FISH_PROFILES.size() == 15 and not _flow.progress.fish_records.has("00"),"No full fish / catalog entry added")
	print("HIDDEN_VISUAL_ACCEPTANCE ",JSON.stringify({"result":"PASS" if _failures.is_empty() else "FAIL","checks":_checks,"failures":_failures,"art":"MANUAL REVIEW REQUIRED"}))
	_main.free();DirAccess.remove_absolute(_test_save_path);await process_frame
	quit(0 if _failures.is_empty() else 1)
