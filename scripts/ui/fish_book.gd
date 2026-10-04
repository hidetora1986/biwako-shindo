extends Control
## Five data-backed entries; undiscovered names/stats/descriptions stay hidden.
signal closed
var progress: GameProgress
var entries: Dictionary = {}
var _owns_pause: bool = false

func _ready() -> void:
	$Panel/Close.pressed.connect(close_book)
	for fish: FishFightProfile in GameProgress.FISH_PROFILES:
		var label := Label.new()
		label.name = fish.species_id.capitalize()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.custom_minimum_size.y = 78
		label.add_theme_font_size_override("font_size", 14)
		$Panel/Scroll/Rows.add_child(label)
		entries[fish.id] = label

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
	var top := maxf(76, $Panel/Close.size.y + 24)
	$Panel/Scroll.position = Vector2(14, top)
	$Panel/Scroll.size = $Panel.size - Vector2(28, top + 14)
	for label: Label in entries.values():
		label.add_theme_font_size_override("font_size", maxi(14, int(ceil(11.0 / scale))))

func open_book() -> void:
	if visible or progress == null:
		return
	visible = true
	_owns_pause = true
	get_tree().paused = true
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
	$Panel/Wallet.text = "%d / %d 種 発見" % [found, GameProgress.FISH_PROFILES.size()]
