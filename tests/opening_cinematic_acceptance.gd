extends "res://tests/phase2_acceptance.gd"
## Grounded script, image/camera sequence, safe subtitles, actual input and Save integration.
const EXPECTED := [
	"祖父が亡くなってから、\nこの部屋はずっと、そのままだった。",
	"船も、道具も、釣果帳も。\nまだ、片付けられずにいる。",
	"処分する前に、\n一度だけ目を通すつもりだった。",
	"ただの釣りの記録――\n最初は、そう思っていた。",
	"けれど、最後の方のページだけ、\n様子が違っていた。",
	"琵琶湖の深場。\n見覚えのない記録。",
	"そして、\n説明のつかない“何か”。",
	"祖父が何を見たのか、\n確かめたいと思った。",
	"船を出そう。\nあの帳面の続きは、自分の手で確かめる。",
	"――琵琶湖深度"]

func _run() -> void:
	root.size = Vector2i(1280,720)
	_new_scene(false);await process_frame;await process_frame
	var story: NarrativeScreen = _flow.story
	var opening: OpeningCinematic = story.opening
	_check(story.active and opening.visible and not story.panel.visible and _flow.state == FLOW.State.NARRATIVE, "Image Opening replaces central text panel")
	_check(opening.backgrounds.size() == 4 and opening.backgrounds.all(func(t):return t is AtlasTexture and t.get_width() > 0 and t.get_height() > 0), "Four real illustrated backgrounds loaded")
	_check(opening.subtitle.get_theme_font("font").variation_opentype.get(TextServerManager.get_primary_interface().name_to_tag("wght")) == 500.0, "Readable Medium caption weight uses the font axis tag")
	_check(opening.current.texture == opening.backgrounds[0], "Grandfather room / closed journal first")
	_check(not _flow.request_cast() and not _flow.request_shop() and not _flow.request_book(), "Opening input modal protects gameplay")
	var original_size: Vector2 = opening.current.size
	_step(1.2)
	_check(opening.current.size.x > original_size.x and opening.current.position.x < 0, "Gentle zoom/pan contained within clipped art frame")
	_check(not opening.transitioning and is_equal_approx(opening.current.modulate.a,1), "Opening fade settles after 0.5 seconds")
	_new_scene(false);await process_frame;await process_frame
	story = _flow.story;opening = story.opening
	var total := 0.0
	for i in range(EXPECTED.size()):
		_check(story.section == i and opening.subtitle.text == EXPECTED[i], "Exact supplied text %d / correct order" % (i+1))
		var scene: int = [0,0,1,1,2,2,2,3,3,3][i]
		_check(opening.scene_index == scene and opening.current.texture == opening.backgrounds[scene], "Scene and script mapping %d" % (i+1))
		if i in [2,4,7]:
			_check(opening.previous.visible and opening.transitioning and opening.previous.texture != opening.current.texture, "Crossfade between distinct images")
		total += float(story.steps[i].seconds)
		_step(float(story.steps[i].seconds)+0.005)
	_check(is_equal_approx(total,23.6) and total >= 18 and total <= 25, "Whole Opening 23.6s including fades/title")
	_check(not story.active and not opening.visible and _flow.state == FLOW.State.READY and _flow.progress.opening_seen and not _flow.line.visible, "Natural completion restores ordinary game / saves flag")
	_check(_flow.request_cast() and _flow.lure.state == LureController.State.CASTING, "Ordinary CAST immediately works after Opening")
	var saved := GameProgress.new()
	_check(_flow.save_manager.load_into(saved) and saved.opening_seen and saved.money == 0 and saved.levels.line == 1, "Save/Load without changing balance/progression")
	_new_scene(false);await process_frame;await process_frame
	story = _flow.story;opening = story.opening
	for ratio in [Vector2i(1280,720),Vector2i(1560,720),Vector2i(1600,720),Vector2i(640,360)]:
		root.size = ratio;await process_frame;await process_frame
		for card in range(EXPECTED.size()):
			opening.show_card(card);await process_frame
			var label_rect := opening.subtitle.get_global_rect()
			var band_rect := opening.subtitle_band.get_global_rect()
			var font := opening.subtitle.get_theme_font("font")
			var font_size := opening.subtitle.get_theme_font_size("font_size")
			var width := 0.0
			for line: String in EXPECTED[card].split("\n"):width = maxf(width,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x)
			_check(band_rect.encloses(label_rect) and _hud.safe_rect.encloses(label_rect) and width <= label_rect.size.x and opening.subtitle.get_line_count() <= 2 and font.get_height(font_size)*opening.subtitle.get_line_count() <= label_rect.size.y, "Safe two-line lower band fits %s card %d" % [ratio,card+1])
		_check(opening.subtitle_band.position.y >= _lake.view_size.y*0.8 and is_equal_approx(opening.subtitle_band.color.a,0.7), "Bottom 20%% / 70%% black band %s" % ratio)
		_check(story.skip_button.size.y*float(ratio.y)/_lake.view_size.y >= 44 and _hud.safe_rect.encloses(story.skip_button.get_global_rect()), "44px safe SKIP %s" % ratio)
	_touch(story.skip_button.get_global_rect().get_center());_step(0.3)
	_check(not story.active and not opening.visible and _flow.progress.opening_seen and _flow.state == FLOW.State.READY, "Actual touch SKIP hides cinematic and persists")
	var path := _test_save_path
	_main.free();_main = load("res://scenes/main.tscn").instantiate()
	_main.get_node("LakeScene/FishingController").save_path = path;root.add_child(_main)
	await process_frame;await process_frame
	_flow = _main.get_node("LakeScene/FishingController")
	_check(not _flow.story.active and _flow.progress.opening_seen and _flow.state == FLOW.State.READY, "Existing Save resumes without Opening")
	print("OPENING_CINEMATIC_ACCEPTANCE ",JSON.stringify({"result":"PASS" if _failures.is_empty() else "FAIL","checks":_checks,"failures":_failures,"duration_s":total,"manual_clarity_emotion_hook_phone":"REQUIRED"}))
	_main.free();DirAccess.remove_absolute(path);await process_frame
	quit(0 if _failures.is_empty() else 1)
