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
	$SonarPlaceholder.position = Vector2(core_rect.end.x - $SonarPlaceholder.size.x, core_rect.position.y)
	$Title.position = Vector2(core_rect.get_center().x - 120, core_rect.position.y)
	$Subtitle.position = Vector2(core_rect.get_center().x - 120, core_rect.position.y + 20)
	$Depth.position = Vector2(core_rect.get_center().x - $Depth.size.x * 0.5, clampf(surface_y + 9, safe_rect.position.y, safe_rect.end.y - $Depth.size.y))
	# Preserve a physical 44px target even in a small 320px-wide PC preview.
	var window_size := Vector2(get_window().size)
	var pixel_scale := maxf(0.1, minf(window_size.x / view_size.x, window_size.y / view_size.y))
	$CastButton.size = Vector2(maxf(136.0, 44.0 / pixel_scale), maxf(48.0, 44.0 / pixel_scale))
	$CastButton.add_theme_font_size_override("font_size", maxi(20, int(ceil(12.0 / pixel_scale))))
	$CastButton.position = Vector2(core_rect.get_center().x - $CastButton.size.x * 0.5, core_rect.end.y - $CastButton.size.y)
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
	$Result.text = message
	$Result.visible = not message.is_empty()
