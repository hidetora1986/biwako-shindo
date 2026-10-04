extends Control
## Keep essential HUD inside a centered 16:9 frame and the device safe area.

const BASE_MARGIN := 16.0
var safe_rect := Rect2()
var core_rect := Rect2()

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
	size = view_size
	safe_rect = device_safe.grow(-BASE_MARGIN)
	var width := minf(640.0, safe_rect.size.x)
	core_rect = Rect2(safe_rect.position + Vector2((safe_rect.size.x - width) * 0.5, 0), Vector2(width, safe_rect.size.y))
	$Money.position = core_rect.position
	$SonarPlaceholder.position = Vector2(core_rect.end.x - $SonarPlaceholder.size.x, core_rect.position.y)
	$Title.position = Vector2(core_rect.get_center().x - 120, core_rect.position.y)
	$Subtitle.position = Vector2(core_rect.get_center().x - 120, core_rect.position.y + 20)
	$Depth.position = Vector2(core_rect.get_center().x - $Depth.size.x * 0.5, clampf(surface_y + 9, safe_rect.position.y, safe_rect.end.y - $Depth.size.y))
	$Depth/Label.text = "0–%dm" % int(depth_m)
