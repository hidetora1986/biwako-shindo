extends Control
## Data-backed entries; undiscovered names/stats/descriptions stay hidden.
signal closed
var progress: GameProgress
var entries: Dictionary = {}
var hidden_entry: Button
var journal_entries: Dictionary = {}
var journal_scroll: ScrollContainer
var fish_tab: Button
var journal_tab: Button
var journal_mode := false
var _owns_pause: bool = false

func _ready() -> void:
	$Panel/Close.pressed.connect(close_book)
	fish_tab = Button.new();fish_tab.text = "魚図鑑";fish_tab.focus_mode = Control.FOCUS_NONE
	journal_tab = Button.new();journal_tab.text = "記録";journal_tab.focus_mode = Control.FOCUS_NONE
	for button: Button in [fish_tab,journal_tab]:
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		button.add_theme_font_size_override("font_size",16)
		$Panel.add_child(button)
	fish_tab.pressed.connect(show_journal.bind(false))
	journal_tab.pressed.connect(show_journal.bind(true))
	journal_scroll = ScrollContainer.new();journal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	$Panel.add_child(journal_scroll)
	var rows := VBoxContainer.new();rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",12);journal_scroll.add_child(rows)
	for id: String in NarrativeData.PAGE_IDS:
		var page := RichTextLabel.new()
		page.bbcode_enabled = true;page.fit_content = true;page.scroll_active = false
		page.custom_minimum_size.y = 96;page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.add_theme_font_override("normal_font",preload("res://assets/fonts/NotoSansJP.ttf"))
		page.add_theme_font_size_override("normal_font_size",18)
		rows.add_child(page);journal_entries[id] = page
	journal_scroll.visible = false
	for fish: FishFightProfile in GameProgress.FISH_PROFILES:
		var label := Label.new()
		label.name = fish.species_id.capitalize()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.custom_minimum_size.y = 78
		label.add_theme_font_size_override("font_size", 14)
		$Panel/Scroll/Rows.add_child(label)
		entries[fish.id] = label

	hidden_entry = Button.new()
	hidden_entry.name = "No00"
	hidden_entry.add_theme_font_override("font",preload("res://assets/ui/pixel_theme.tres").default_font)
	hidden_entry.custom_minimum_size.y = 78
	hidden_entry.add_theme_font_size_override("font_size",14)
	hidden_entry.pressed.connect(func(): progress.mark_hidden_entry(); _show_no00())
	$Panel/Scroll/Rows.add_child(hidden_entry)

func _show_no00() -> void:
	hidden_entry.modulate = Color.WHITE
	hidden_entry.text = "No.00\n帰ってきたもの\n深度: 記録不能   サイズ: ---   売値: ---\n捕獲数: 2\n記録が一致しない。" if progress.no00_contacted else "No.00\nこの項目は存在しない。"

func setup(state: GameProgress) -> void:
	progress = state
	progress.changed.connect(_refresh)
	_refresh()

func configure(core_rect: Rect2, view_size: Vector2) -> void:
	size = view_size
	$Shade.size = view_size
	$Panel.size = Vector2(minf(560, core_rect.size.x), minf(328, core_rect.size.y))
	$Panel.position = core_rect.get_center() - $Panel.size * 0.5
	var scale := maxf(0.1, float(get_window().size.y) / view_size.y)
	$Panel/Close.size = Vector2(maxf(50, 44 / scale), maxf(44, 44 / scale))
	$Panel/Close.position = Vector2($Panel.size.x - $Panel/Close.size.x - 14, 10)
	fish_tab.size = Vector2(100,maxf(44,44/scale));journal_tab.size = Vector2(100,maxf(44,44/scale))
	fish_tab.position = Vector2(182,10);journal_tab.position = Vector2(290,10)
	$Panel/Title.size.x = 168
	$Panel/Title.add_theme_font_size_override("font_size",20)
	var top := maxf(76, $Panel/Close.size.y + 24)
	$Panel/Scroll.position = Vector2(14, top)
	$Panel/Scroll.size = $Panel.size - Vector2(28, top + 14)
	journal_scroll.position = $Panel/Scroll.position
	journal_scroll.size = $Panel/Scroll.size
	for label: Label in entries.values():
		label.add_theme_font_size_override("font_size", maxi(14, int(ceil(11.0 / scale))))

func open_book() -> void:
	if visible or progress == null:
		return
	visible = true
	_owns_pause = true
	get_tree().paused = true
	show_journal(false)
	_refresh()

func show_journal(enabled: bool) -> void:
	journal_mode = enabled
	$Panel/Scroll.visible = not enabled;journal_scroll.visible = enabled
	$Panel/Title.text = "祖父の釣果帳" if enabled else "FISH BOOK"
	fish_tab.disabled = not enabled;journal_tab.disabled = enabled
	_refresh()

func close_book() -> void:
	if not visible:
		return
	visible = false
	if _owns_pause:
		get_tree().paused = false
	_owns_pause = false
	closed.emit()

func _exit_tree() -> void:
	if _owns_pause:
		get_tree().paused = false

func _input(event: InputEvent) -> void:
	if visible and event is InputEventScreenTouch and event.pressed and $Panel/Close.get_global_rect().has_point(event.position):
		close_book()
		get_viewport().set_input_as_handled()
	elif visible and event is InputEventScreenTouch and event.pressed and (fish_tab.get_global_rect().has_point(event.position) or journal_tab.get_global_rect().has_point(event.position)):
		show_journal(journal_tab.get_global_rect().has_point(event.position))
		get_viewport().set_input_as_handled()
	elif visible and not journal_mode and event is InputEventScreenTouch and event.pressed and hidden_entry.visible and hidden_entry.get_global_rect().has_point(event.position) and $Panel/Scroll.get_global_rect().has_point(event.position):
		progress.mark_hidden_entry()
		_show_no00()
		get_viewport().set_input_as_handled()

func _refresh() -> void:
	if progress == null:
		return
	var found := 0
	for fish: FishFightProfile in GameProgress.FISH_PROFILES:
		var record: Dictionary = progress.fish_records[fish.id]
		if record.discovered:
			found += 1
			entries[fish.id].text = "%s  %s\n捕獲数 %d  |  BEST SIZE %.1f cm\n%s" % [fish.id, fish.display_name, record.caught_count, record.best_size_cm, fish.description]
		else:
			entries[fish.id].text = "%s  ???\n未発見" % fish.id
	hidden_entry.visible = progress.hidden_eligible() or progress.no00_contacted
	hidden_entry.modulate = Color(0.7,0.78,0.8,0.25)
	hidden_entry.text = "No.00"
	if progress.no00_contacted or progress.hidden_entry_seen:
		_show_no00()
	var pages := NarrativeData.pages(progress)
	for id: String in NarrativeData.PAGE_IDS:
		var entry: RichTextLabel = journal_entries[id]
		entry.visible = id in pages
		entry.text = "\n".join(NarrativeData.content().journal[id])
		if id == "last":
			entry.text = "日付なし\n\n[color=#84938b]│[/color]" + ("  [color=#dae4d3]│[/color]" if progress.hidden_contact_ending_seen else "")
		if id == "deep":entry.modulate = Color(0.82,0.86,0.82,0.9)
	$Panel/Wallet.text = "記録　%dページ" % pages.size() if journal_mode else "%d / %d 種 発見" % [found, GameProgress.FISH_PROFILES.size()]
