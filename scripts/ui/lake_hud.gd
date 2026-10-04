extends Control
## Keep essential HUD inside a centered 16:9 frame and the device safe area.

const BASE_MARGIN := 16.0
var safe_rect := Rect2()
var core_rect := Rect2()
var _area_depth_m: float = 15.0

func configure(view_size: Vector2, surface_y: float, depth_m: float) -> void:
	var device_safe := Rect2(Vector2.ZERO, view_size)
	if OS.get_name() in ["Android", "iOS"]:
		var area := DisplayServer.get_display_safe_area()
		var window_size := Vector2(DisplayServer.window_get_size())
		if area.has_area() and window_size.x > 0 and window_size.y > 0:
			var origin := Vector2(DisplayServer.window_get_position())
			var ratio := view_size / window_size
			device_safe = Rect2((Vector2(area.position) - origin) * ratio, Vector2(area.size) * ratio)
			device_safe = device_safe.intersection(Rect2(Vector2.ZERO, view_size))
	layout_in_safe_area(view_size, device_safe, surface_y, depth_m)

func layout_in_safe_area(view_size: Vector2, device_safe: Rect2, surface_y: float, depth_m: float) -> void:
	_area_depth_m = depth_m
	size = view_size
	safe_rect = device_safe.grow(-BASE_MARGIN)
	var width := minf(640.0, safe_rect.size.x)
	core_rect = Rect2(safe_rect.position + Vector2((safe_rect.size.x - width) * 0.5, 0), Vector2(width, safe_rect.size.y))
	$Money.position = core_rect.position
	$ShopButton.size = Vector2(112, maxf(44, 44.0 * view_size.y / maxf(get_window().size.y, 1)))
	$ShopButton.position = core_rect.position + Vector2(0, 50)
	$BookButton.size = Vector2(136, $ShopButton.size.y)
	$BookButton.position = $ShopButton.position + Vector2($ShopButton.size.x + 8, 0)
	$BookButton.add_theme_font_size_override("font_size", maxi(14, int(ceil(11.0 * view_size.y / maxf(get_window().size.y, 1)))))
	$FishBook.configure(core_rect, view_size)
	$NextUpgrade.position = Vector2(core_rect.position.x, core_rect.end.y - $NextUpgrade.size.y)
	$DepthUnlock.position = core_rect.get_center() - $DepthUnlock.size * 0.5
	$Shop.configure(core_rect, view_size)
	$SonarPlaceholder.position = Vector2(core_rect.end.x - $SonarPlaceholder.size.x, core_rect.position.y)
	var title_left: float = $Money.position.x + $Money.size.x + 10
	var title_right: float = $SonarPlaceholder.position.x - 10
	var title_width: float = minf(240, title_right - title_left)
	$Title.size.x = title_width
	$Subtitle.size.x = title_width
	$Title.position = Vector2((title_left + title_right - title_width) * 0.5, core_rect.position.y)
	$Subtitle.position = $Title.position + Vector2(0, 20)
	$Depth.position = Vector2(core_rect.get_center().x - $Depth.size.x * 0.5, clampf(surface_y + 9, safe_rect.position.y, safe_rect.end.y - $Depth.size.y))
	# Preserve a physical 44px target even in a small 320px-wide PC preview.
	var window_size := Vector2(get_window().size)
	var pixel_scale := maxf(0.1, minf(window_size.x / view_size.x, window_size.y / view_size.y))
	$CastButton.size = Vector2(maxf(136.0, 44.0 / pixel_scale), maxf(48.0, 44.0 / pixel_scale))
	$CastButton.add_theme_font_size_override("font_size", maxi(20, int(ceil(12.0 / pixel_scale))))
	$CastButton.position = Vector2(core_rect.get_center().x - $CastButton.size.x * 0.5, core_rect.end.y - $CastButton.size.y)
	$ReelButton.size = Vector2(maxf(152.0, 44.0 / pixel_scale), maxf(72.0, 44.0 / pixel_scale))
	$ReelButton.position = core_rect.end - $ReelButton.size
	$FightHUD.size = Vector2(minf(320.0, core_rect.size.x - $ReelButton.size.x - 16.0), 72)
	$FightHUD.position = Vector2(core_rect.position.x, core_rect.end.y - $FightHUD.size.y)
	$CatchPanel.position = core_rect.get_center() - $CatchPanel.size * 0.5
	$Result.size.x = minf(320.0, core_rect.size.x)
	$Result.add_theme_font_size_override("font_size", 28 if $Result.text == "LINE BREAK" else 36)
	$Result.position = Vector2(core_rect.get_center().x - $Result.size.x * 0.5, clampf(surface_y + 60, safe_rect.position.y, safe_rect.end.y - $Result.size.y))
	$Depth/Label.text = "0–%dm" % int(depth_m)

func show_lure_depth(depth_m: float, active: bool) -> void:
	if active:
		$Depth/Label.text = "%.1fm" % depth_m
	else:
		$Depth/Label.text = "0–%dm" % int(_area_depth_m)

func show_bite(active: bool, lure_position: Vector2) -> void:
	$Bite.visible = active
	$Bite.position = lure_position + Vector2(-14, -42)
	$Bite.position.x = clampf($Bite.position.x, safe_rect.position.x, safe_rect.end.x - $Bite.size.x)
	$Bite.position.y = clampf($Bite.position.y, safe_rect.position.y, safe_rect.end.y - $Bite.size.y)

func show_result(message: String) -> void:
	$Result.add_theme_font_size_override("font_size", 28 if message == "LINE BREAK" else 36)
	$Result.text = message
	$Result.visible = not message.is_empty()

func show_fight(fight: FishingFight, active: bool) -> void:
	$ReelButton.visible = active
	$ReelButton.disabled = not active
	$ReelButton.set_pressed_no_signal(active and fight.reeling)
	$FightHUD.visible = active
	if active:
		$FightHUD.display(fight)

func show_catch(result: Dictionary, fish_texture: Texture2D) -> void:
	$CatchPanel.visible = true
	$CatchPanel/New.visible = result.get("new_discovery", false)
	$CatchPanel/Name.text = result["name"]
	$CatchPanel/Size.text = "%.1f cm" % result["size_cm"]
	$CatchPanel/Fish.texture = fish_texture
	$CatchPanel/Price.text = "+ ¥%s" % _format_money(result.get("price", 0))

func hide_catch() -> void:
	$CatchPanel.visible = false
	$CatchPanel/Fish.texture = null

func _format_money(value: int) -> String:
	var digits := str(value)
	var formatted := ""
	for i in range(digits.length()):
		if i > 0 and (digits.length() - i) % 3 == 0:
			formatted += ","
		formatted += digits[i]
	return formatted

func show_progress(progress: GameProgress) -> void:
	$Money/Label.text = "¥" + _format_money(progress.money)
	var item := progress.cheapest_next()
	$NextUpgrade.text = "ALL EQUIPMENT MAX" if item == null else "NEXT  %s Lv%d\n%s" % [item.category.to_upper(), item.level, "購入できます" if progress.money >= item.price else "あと ¥" + _format_money(item.price - progress.money)]
