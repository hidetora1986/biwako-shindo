extends "res://tests/boss_acceptance.gd"
## Presentation-only checks plus the real boss hook/fight/landing path. Isolated test save.
func _run() -> void:
	root.size = Vector2i(640,360)
	_new_scene();await process_frame;await process_frame
	var frames := RefinedPixelArt.fish_frames("lake_master")
	_check(frames.get_frame_count("swim") == 3 and is_equal_approx(frames.get_animation_speed("swim"),4),"Original three frames / four fps")
	for phase in range(3):
		var texture := frames.get_frame_texture("swim",phase)
		_check(texture is AtlasTexture and texture.get_size() == Vector2(288,96),"Offline raster / unchanged envelope frame %d" % phase)
		var image := texture.get_image()
		_check(image.get_pixel(0,0).a == 0 and image.get_pixel(287,95).a == 0,"True transparent margins frame %d" % phase)
		_check(image.get_pixel(282,48).a > 0.1,"Mouth aligned with existing line anchor frame %d" % phase)
		_check(BossPixelArt.texture(phase) == BossPixelArt.texture(phase+3),"Shared cached atlas frame %d" % phase)
	var before: Dictionary = _flow.save_manager.snapshot(_flow.progress)
	for i in range(100):RefinedPixelArt.fish_frames("lake_master")
	_check(_flow.save_manager.snapshot(_flow.progress) == before,"Art lookup has no gameplay/save side effects")
	_boss_fixture(5,5)
	_check(_boss_hook(),"Original natural cast / boss bite / HOOK")
	_check(_flow.active_fish._half_width == 144 and _flow.active_fish._half_height == 48,"Original AI/hit geometry retained")
	_check(_boss_land(),"Original fight and landing retained")
	print("BOSS_VISUAL_ACCEPTANCE ",JSON.stringify({"result":"PASS" if _failures.is_empty() else "FAIL","checks":_checks,"failures":_failures,"art":"MANUAL REVIEW REQUIRED"}))
	_main.free();DirAccess.remove_absolute(_test_save_path);await process_frame
	quit(0 if _failures.is_empty() else 1)
