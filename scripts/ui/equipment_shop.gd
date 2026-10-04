extends Control
## One paused modal, four reusable rows; purchases immediately equip RAM state.
signal closed
var progress: GameProgress
var _hud: Control
var _buttons: Dictionary = {}
var _labels: Dictionary = {}
var _expected_levels: Dictionary = {}
var _cooldown: float = 0.0
var _owns_pause: bool = false
var _notice_visible: bool = false

func _ready() -> void:
	$Panel/Close.pressed.connect(close_shop)
	for category in GameProgress.CATEGORIES:
		var row := HBoxContainer.new()
		row.name = category.capitalize()
		row.add_theme_constant_override("separation", 6)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 14)
		row.add_child(label)
		var button := Button.new()
		button.custom_minimum_size = Vector2(112, 52)
		button.focus_mode = Control.FOCUS_NONE
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(_buy.bind(category))
		row.add_child(button)
		$Panel/Scroll/Rows.add_child(row)
		_buttons[category] = button
		_labels[category] = label

func setup(state: GameProgress, hud: Control) -> void:
	progress = state
	_hud = hud
	progress.changed.connect(_refresh)
	_refresh()

func configure(core_rect: Rect2, view_size: Vector2) -> void:
	size = view_size
	$Shade.size = view_size
	$Panel.size = Vector2(minf(560, core_rect.size.x), minf(328, core_rect.size.y))
	$Panel.position = core_rect.get_center() - $Panel.size * 0.5
	$Panel/Close.position = Vector2($Panel.size.x - 64, 10)
	$Panel/Wallet.size.x = $Panel.size.x - 28
	$Panel/Scroll.position = Vector2(14, 76)
	$Panel/Scroll.size = $Panel.size - Vector2(28, 90)
	var physical_scale := maxf(0.1, float(get_window().size.y) / view_size.y)
	$Panel/Close.size = Vector2(maxf(50, 44.0 / physical_scale), maxf(44, 44.0 / physical_scale))
	$Panel/Close.position.x = $Panel.size.x - $Panel/Close.size.x - 14
	var scroll_top := maxf(76, $Panel/Close.size.y + 24)
	$Panel/Scroll.position.y = scroll_top
	$Panel/Scroll.size.y = $Panel.size.y - scroll_top - 14
	$Panel/Wallet.add_theme_font_size_override("font_size", maxi(15, int(ceil(11.0 / physical_scale))))
	for category: String in _buttons:
		var button: Button = _buttons[category]
		button.custom_minimum_size.y = maxf(52, 44.0 / physical_scale)
		button.add_theme_font_size_override("font_size", maxi(15, int(ceil(12.0 / physical_scale))))
		_labels[category].add_theme_font_size_override("font_size", maxi(14, int(ceil(11.0 / physical_scale))))

func open_shop() -> void:
	if visible or progress == null:
		return
	visible = true
	_owns_pause = true
	get_tree().paused = true
	_refresh()

func close_shop() -> void:
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

func _process(delta: float) -> void:
	if visible:
		var was_cooling := _cooldown > 0.0
		_cooldown = maxf(0, _cooldown - delta)
		var notice_visible: bool = _hud.get_node("DepthUnlock").visible
		if (was_cooling and _cooldown == 0.0) or notice_visible != _notice_visible:
			_notice_visible = notice_visible
			_refresh()

func _input(event: InputEvent) -> void:
	# Explicit touch input also works when mouse emulation is disabled.
	if not visible or not (event is InputEventScreenTouch and event.pressed):
		return
	if $Panel/Close.get_global_rect().has_point(event.position):
		close_shop()
		get_viewport().set_input_as_handled()
		return
	if $Panel/Scroll.get_global_rect().has_point(event.position):
		for category: String in _buttons:
			if _buttons[category].get_global_rect().has_point(event.position):
				_buy(category)
				get_viewport().set_input_as_handled()
				return

func _buy(category: String) -> bool:
	if not visible or _cooldown > 0.0 or _hud.get_node("DepthUnlock").visible:
		return false
	var level: int = _expected_levels.get(category, -1)
	# Update first: synchronous changed signals rebuild the row after purchase.
	_cooldown = 0.25
	var purchased := progress.purchase(category, level)
	if not purchased:
		_cooldown = 0.0
	_refresh()
	return purchased

func _refresh() -> void:
	if progress == null:
		return
	$Panel/Wallet.text = "所持金  ¥" + _hud._format_money(progress.money)
	for category: String in _buttons:
		var item := progress.next_level(category)
		var current := progress.current(category)
		var button: Button = _buttons[category]
		if item == null:
			_labels[category].text = "%s  Lv.%d  MAX\n%s  %s" % [category.to_upper(), current.level, current.effect_label, current.effect_text()]
			button.text = "MAX"
			button.disabled = true
			_expected_levels[category] = -1
		else:
			_labels[category].text = "%s  Lv.%d → Lv.%d\n%s  %s → %s%s" % [category.to_upper(), current.level, item.level, item.effect_label, current.effect_text(), item.effect_text(), "\n" + item.capability if category == "sonar" else ""]
			button.text = "¥%s\n%s" % [_hud._format_money(item.price), "購入" if progress.money >= item.price else "所持金不足"]
			button.disabled = not progress.can_purchase(category, item.level) or _cooldown > 0.0 or _hud.get_node("DepthUnlock").visible
			_expected_levels[category] = item.level
