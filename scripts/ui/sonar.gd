class_name SonarDisplay
extends Control
## Samples the real fish every 0.15s; estimated details rotate below the depth plot.
@export var text_font: Font
var contacts: Array[Dictionary] = []
var anomaly_active: bool = false
var anomaly_progress: float = 0.0
var _fishes: Node2D
var _progress: GameProgress
var _sample_remaining: float = 0.0
var _focus_remaining: float = 2.0
var _focus_index: int = 0

func _ready() -> void:
	clip_contents = true
	resized.connect(queue_redraw)

func setup(fishes: Node2D, progress: GameProgress) -> void:
	_fishes = fishes
	_progress = progress
	progress.changed.connect(refresh_contacts)
	refresh_contacts()

func _process(delta: float) -> void:
	if _progress == null:
		return
	_sample_remaining -= delta
	_focus_remaining -= delta
	if _focus_remaining <= 0.0:
		_focus_remaining = 2.0
		_focus_index += 1
	if _sample_remaining <= 0.0:
		_sample_remaining = 0.15
		refresh_contacts()

func max_depth() -> float:
	return 15.0 if _progress == null else _progress.current("sonar").effect_value

func refresh_contacts() -> void:
	contacts.clear()
	if not is_instance_valid(_fishes) or _progress == null:
		return
	for fish: FishController in _fishes.get_children():
		if not fish.visible or fish.state == FishController.SwimState.LANDING or fish.depth_position < 0 or fish.depth_position > max_depth():
			continue
		var estimate := fish.size_cm if fish.size_cm > 0 else (fish.fight_profile.min_size_cm + fish.fight_profile.max_size_cm) * 0.5
		var size_text := "SMALL" if estimate < 25 else ("MEDIUM" if estimate < 50 else "LARGE")
		var known: bool = _progress.fish_records[fish.fight_profile.id].discovered
		contacts.append({"instance_id": fish.get_instance_id(), "depth_m": fish.depth_position, "x_fraction": clampf((fish.position.x - fish.water_bounds.position.x) / maxf(fish.water_bounds.size.x, 1), 0, 1), "size_text": size_text if _progress.levels.sonar >= 2 else "", "name_text": ("???" if fish.fight_profile.id == "No.10" else fish.fight_profile.display_name) if _progress.levels.sonar >= 3 and (known or fish.fight_profile.id == "No.10") else "", "dot_width": 8 if fish.fight_profile.id == "No.10" else 5})
	queue_redraw()

func depth_y(depth_m: float) -> float:
	var bottom := size.y - (42 if _progress != null and _progress.levels.sonar >= 2 else 12)
	return lerpf(34, bottom, clampf(depth_m / max_depth(), 0, 1))

func set_anomaly(enabled: bool, value: float) -> void:
	anomaly_active = enabled
	anomaly_progress = value
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("132e40"))
	draw_rect(Rect2(Vector2.ZERO, size), Color("81b1b5"), false, 1)
	# Small pixel brackets and a thin header divider evoke a compact fish finder.
	for x in [2.0, size.x - 7.0]:
		draw_rect(Rect2(x, 2, 5, 1), Color("b3d8d1"))
		draw_rect(Rect2(x, size.y - 3, 5, 1), Color("b3d8d1"))
	draw_line(Vector2(8, 25), Vector2(size.x - 8, 25), Color("385c6b"))
	var font: Font = text_font if text_font != null else ThemeDB.fallback_font
	var level: int = 1 if _progress == null else _progress.levels.sonar
	draw_string(font, Vector2(9, 20), "SONAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("d5e2c9"))
	draw_string(font, Vector2(size.x - 91, 20), "Lv%d / %dm" % [level, max_depth()], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("a1bcaa"))
	for fraction in [0.0, 0.5, 1.0]:
		var y := depth_y(max_depth() * fraction)
		draw_line(Vector2(9, y), Vector2(size.x - 10, y), Color("2c4c60"))
		draw_string(font, Vector2(9, y - 2), "%d" % (max_depth() * fraction), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("a1bcaa"))
	var focused := _focus_index % maxi(1, contacts.size())
	for index in range(contacts.size()):
		var contact: Dictionary = contacts[index]
		var point := Vector2(28 + contact.x_fraction * (size.x - 44), depth_y(contact.depth_m)).floor()
		draw_rect(Rect2(point - Vector2(2, 1), Vector2(contact.dot_width, 2)), Color("d5e6b9"))
		if index == focused and level >= 2:
			draw_rect(Rect2(point - Vector2(4, 3), Vector2(9, 6)), Color("6fc5c4"), false, 1)
	if not contacts.is_empty() and level >= 2:
		draw_string(font, Vector2(10, size.y - 22), contacts[focused].size_text + " · %.1fm" % contacts[focused].depth_m, HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 14, Color("d5e2c9"))
		if level >= 3:
			draw_string(font, Vector2(10, size.y - 6), contacts[focused].name_text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 14, Color("d5e6b9"))
	if anomaly_active:
		# 8x a normal five-pixel return. No lake sprite, text, sound or camera effects.
		var x := lerpf(-40, size.x + 40, anomaly_progress)
		var y := depth_y(max_depth()) - 3
		draw_rect(Rect2(floorf(x) - 20, y - 3, 40, 6), Color("a4bfa7"))
		draw_rect(Rect2(floorf(x) - 24, y - 1, 5, 2), Color("a4bfa7"))
