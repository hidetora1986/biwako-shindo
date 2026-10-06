extends "res://tests/narrative_acceptance.gd"
## Presentation, genuine modal input and legacy save compatibility.
func _run() -> void:
	root.size = Vector2i(1280,720)
	_new_scene();await process_frame;await process_frame
	var story: NarrativeScreen = _flow.story
	var book: Control = _hud.get_node("FishBook")
	_check(MysteriousSketch.TEXTURE.get_width() > 1200, "Dedicated landscape journal asset exists")
	_check(not "sketch" in NarrativeData.pages(_flow.progress) and not book.sketch_image.visible, "New Game cannot see special page")
	# A forged cached page must not bypass its existing ending gate.
	_flow.progress.journal_pages_unlocked.append("sketch")
	_check(not "sketch" in NarrativeData.pages(_flow.progress), "Cached page cannot unlock before main ending")
	_flow.progress.journal_pages_unlocked.erase("sketch")
	_boss_fixture()
	_check(_boss_hook() and _boss_land(), "Real boss reward launches main ending")
	_step(2.6)
	var presentation: MysteriousSketch = story.mysterious_sketch
	_check(story.active and presentation.stage == "lake" and not _flow.request_cast(), "Main intro / input blocked")
	_step(3.1)
	_check(presentation.stage == "record" and not presentation.image.visible and presentation.subtitle.text.contains("これで全部や"), "Ordinary last record before special page")
	_step(3.0)
	_check(presentation.subtitle.text == "……帰ろう。", "Closure remains before curiosity")
	_step(2.1)
	_check(presentation.stage == "turn" and not presentation.image.visible, "Quiet extra page turn")
	_step(0.5)
	_check(presentation.stage == "sketch" and presentation.subtitle.text == "……？" and presentation.image.visible, "Sketch reveal / no explanatory dialogue")
	_check(presentation.stage_elapsed < 1 and presentation.image.size.is_equal_approx(presentation.frame.size), "First second holds complete spread")
	_step(4.2)
	_check(presentation.image.size.x > presentation.frame.size.x and presentation.image.size.x <= presentation.frame.size.x*1.066, "Small slow camera approach, no moving sketch")
	for ratio: Vector2i in [Vector2i(1280,720),Vector2i(1560,720),Vector2i(1600,720),Vector2i(640,360)]:
		root.size = ratio;await process_frame;await process_frame
		_check(_hud.safe_rect.encloses(presentation.subtitle.get_global_rect()), "Bottom subtitle safe at %s" % ratio)
		_check(presentation.band.position.y >= presentation.size.y*0.79 and not story.panel.visible, "No central prose at %s" % ratio)
		var font: Font = presentation.subtitle.get_theme_font("font")
		for card: Dictionary in story.steps:
			_check(str(card.text).split("\n").size() <= 2, "One/two lines at %s: %s" % [ratio,card.stage])
			for line: String in str(card.text).split("\n"):
				_check(font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x <= presentation.subtitle.size.x, "Subtitle fits width at %s" % ratio)
		_check(font.get_height(18)*2 <= presentation.subtitle.size.y, "Two lines fit height at %s" % ratio)
		_check(_hud.safe_rect.encloses(story.skip_button.get_global_rect()), "Skip touch target safe at %s" % ratio)
	for tick in range(900):
		if presentation.stage == "fade":break
		_step(1.0/60.0)
	_step(0.3)
	_check(presentation.image.visible and presentation.shade.color.a > 0 and presentation.shade.color.a < 1, "Quiet darkening before returning to lake")
	_step(0.4)
	_check(presentation.stage == "lake" and not presentation.image.visible, "Lake returns before MAIN END")
	_step(60)
	_check(_flow.state == FLOW.State.TITLE and _flow.progress.main_story_ending_seen and not presentation.visible, "Natural main ending and credits / cleanup")
	_check(_flow.request_continue() and "sketch" in NarrativeData.pages(_flow.progress), "Continue unlocks special journal page")
	_check(_flow.request_book(), "Postgame book opens")
	book.show_journal(true)
	_check(book.sketch_image.visible and book.sketch_button.visible and book.journal_entries.sketch.visible, "Postgame thumbnail / inspect affordance")
	await process_frame;await process_frame
	book.journal_scroll.scroll_vertical = int(book.sketch_button.position.y)-80
	await process_frame;await process_frame
	_touch(book.sketch_button.get_global_rect().get_center());await process_frame
	_check(book.sketch_review.visible and paused and not _flow.request_cast() and not _flow.request_shop(), "Review retains modal lock")
	for ratio: Vector2i in [Vector2i(1280,720),Vector2i(1560,720),Vector2i(1600,720),Vector2i(640,360)]:
		root.size = ratio;await process_frame;await process_frame
		_check(_hud.safe_rect.encloses(book.sketch_close.get_global_rect()) and book.sketch_close.size.y*float(ratio.y)/_lake.view_size.y >= 44, "Review close safe / 44px at %s" % ratio)
		_check(_hud.safe_rect.encloses(book.sketch_review.subtitle.get_global_rect()), "Review subtitle safe at %s" % ratio)
	_touch(book.sketch_close.get_global_rect().get_center())
	_check(not book.sketch_review.visible and book.visible and paused, "Touch close returns to book")
	book.close_book();_step(0.1)
	_check(not paused and not _flow._book_open and _flow.state == FLOW.State.READY, "Close resumes fishing without reward")
	var loaded := GameProgress.new()
	var legacy: Dictionary = _flow.save_manager.snapshot(_flow.progress)
	legacy.erase("journal_pages_unlocked")
	var file := FileAccess.open(_test_save_path,FileAccess.WRITE);file.store_string(JSON.stringify(legacy));file.close()
	_check(_flow.save_manager.load_into(loaded) and "sketch" in NarrativeData.pages(loaded), "Existing completed save reconstructs page without new flag")
	_check(_flow.save_manager.snapshot(loaded).money == legacy.money and loaded.levels.line == legacy.line_level, "Migration leaves balance/equipment unchanged")
	_check(not "main_ending_sketch_seen" in legacy and loaded.no00_record().caught_count == 0, "No extra save schema / no phantom hidden catch")
	book.open_book();book.show_journal(true);book.open_sketch();book.close_book()
	_check(not book.sketch_review.visible and not paused, "Closing parent also cleans review")
	print("MAIN_ENDING_SKETCH_ACCEPTANCE ",JSON.stringify({"result":"PASS" if _failures.is_empty() else "FAIL","checks":_checks,"failures":_failures,"curiosity_completion_foreshadowing":"MANUAL TEST REQUIRED"}))
	_main.free();DirAccess.remove_absolute(_test_save_path);await process_frame
	quit(0 if _failures.is_empty() else 1)
