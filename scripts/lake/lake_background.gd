extends Node2D
## Static layers redraw only when the viewport or visual profile changes.

@export_enum("Sky", "Mountains", "Underwater") var layer: String = "Sky"

var view_size := Vector2(640.0, 360.0)
var profile: LakeProfile
var _far_ridge := PackedVector2Array()
var _near_ridge := PackedVector2Array()
var _rng := RandomNumberGenerator.new()

func configure(size: Vector2, settings: LakeProfile) -> void:
	view_size = size
	profile = settings
	if layer == "Mountains":
		_far_ridge = _ridge(35.0, 0.5)
		_near_ridge = _ridge(21.0, 2.2)
	queue_redraw()

func _ridge(height: float, phase: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var horizon := floorf(view_size.y * 0.265)
	points.append(Vector2(0, horizon + 6))
	for x in range(0, int(view_size.x) + 9, 8):
		var rolling := sin(x * 0.012 + phase) * 0.42 + sin(x * 0.027 + phase) * 0.18 + 0.65
		points.append(Vector2(x, floorf((horizon - height * rolling) / 2.0) * 2.0))
	points.append(Vector2(view_size.x + 8, horizon + 6))
	return points

func _draw() -> void:
	if profile == null:
		return
	match layer:
		"Sky": _draw_sky()
		"Mountains": _draw_mountains()
		"Underwater": _draw_underwater()

func _draw_sky() -> void:
	var horizon := view_size.y * 0.27
	for y in range(0, int(horizon) + 4, 4):
		var color := profile.sky_top.lerp(profile.sky_bottom, float(y) / horizon)
		draw_rect(Rect2(0, y, view_size.x, 4), color)
	var sun := Vector2(floorf(view_size.x * 0.23), 47)
	draw_rect(Rect2(sun - Vector2(10, 7), Vector2(20, 14)), Color("f0e9bf"))
	draw_rect(Rect2(sun - Vector2(7, 10), Vector2(14, 20)), Color("f0e9bf"))
	draw_rect(Rect2(sun - Vector2(6, 6), Vector2(12, 12)), Color("fbefc9"))
	_draw_cloud(Vector2(view_size.x * 0.07, 35), 1.0)
	_draw_cloud(Vector2(view_size.x * 0.69, 46), 1.3)
	_draw_cloud(Vector2(view_size.x * 0.41, 18), 0.7)
	# Tiny distant birds are part of the static background.
	for x in [view_size.x * 0.35, view_size.x * 0.37]:
		draw_line(Vector2(x, 53), Vector2(x + 3, 55), Color("739a95"))
		draw_line(Vector2(x + 3, 55), Vector2(x + 6, 53), Color("739a95"))

func _draw_cloud(origin: Vector2, scale_factor: float) -> void:
	var steps := [Rect2(0, 5, 52, 5), Rect2(7, 1, 18, 9), Rect2(23, 3, 21, 7)]
	for shape: Rect2 in steps:
		draw_rect(Rect2((origin + shape.position * scale_factor).floor(), (shape.size * scale_factor).floor()), Color("e6ebd8"))
	draw_rect(Rect2((origin + Vector2(5, 10) * scale_factor).floor(), Vector2(43 * scale_factor, 2)), Color("c3d9cd"))

func _draw_mountains() -> void:
	draw_colored_polygon(_far_ridge, profile.mountain_far)
	draw_colored_polygon(_near_ridge, profile.mountain_near)
	for i in range(2, _near_ridge.size() - 2):
		var peak := _near_ridge[i]
		if i % 3 == 0:
			draw_line(peak + Vector2(1, 4), peak + Vector2(12, 13), profile.mountain_near.lightened(0.06), 2)
		if i % 2 == 0:
			draw_rect(Rect2(peak + Vector2(0, -2), Vector2(2, 4)), profile.mountain_near.darkened(0.05))
	var horizon := floorf(view_size.y * 0.265)
	draw_rect(Rect2(0, horizon - 1, view_size.x, 3), Color("789b82"))
	draw_rect(Rect2(0, horizon + 2, view_size.x, 2), Color("a5b99a"))

func color_at_depth(depth_m: float) -> Color:
	var ratio := clampf(depth_m / profile.displayed_depth_m, 0.0, 1.0)
	if ratio < 0.5:
		return profile.water_upper.lerp(profile.water_middle, ratio * 2.0)
	return profile.water_middle.lerp(profile.water_deep, (ratio - 0.5) * 2.0)

func _draw_underwater() -> void:
	var surface := floorf(view_size.y * profile.surface_ratio)
	var height := view_size.y - surface
	for y in range(int(surface), int(view_size.y), 4):
		var depth := float(y - surface) / height * profile.displayed_depth_m
		draw_rect(Rect2(0, y, view_size.x, 4), color_at_depth(depth))
	# Baked shafts of morning light; no shaders or particles.
	for x in [view_size.x * 0.16, view_size.x * 0.43, view_size.x * 0.77]:
		var ray := PackedVector2Array([
			Vector2(x, surface + 4), Vector2(x + 23, surface + 4),
			Vector2(x + 101, view_size.y - 24), Vector2(x + 67, view_size.y - 24)])
		draw_colored_polygon(ray, Color(0.64, 0.83, 0.71, 0.035))
	_rng.seed = 3418
	# A gravel bed and modest vegetation suggest Biwa's shallow littoral zone.
	draw_rect(Rect2(0, view_size.y - 16, view_size.x, 16), Color("173d46"))
	for i in range(int(view_size.x / 7)):
		var x := _rng.randi_range(0, int(view_size.x))
		var y := _rng.randi_range(int(view_size.y) - 18, int(view_size.y) - 2)
		var rock := Color("466362") if i % 3 == 0 else Color("2d5155")
		draw_rect(Rect2(x, y, _rng.randi_range(2, 7), 2), rock)
	for i in range(10):
		var x := float(i) * view_size.x / 9.0 + _rng.randf_range(-12.0, 12.0)
		var height_of_weed := _rng.randi_range(14, 33)
		for blade in range(4):
			var stem_x := x + blade * 3
			var tip := view_size.y - height_of_weed + blade * 3
			draw_line(Vector2(stem_x, view_size.y - 6), Vector2(stem_x - 2, tip), Color("3c7268"), 2)
			draw_line(Vector2(stem_x - 2, tip + 10), Vector2(stem_x - 7, tip + 5), Color("507e6c"), 2)
	# Sparse suspended specks are static draw calls, not particle nodes.
	for i in range(38):
		var p := Vector2(_rng.randi_range(0, int(view_size.x)), _rng.randi_range(int(surface) + 24, int(view_size.y) - 30))
		draw_rect(Rect2(p, Vector2.ONE), Color(0.60, 0.80, 0.72, 0.16))
