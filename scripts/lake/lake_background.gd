extends Node2D
## Static visual layers. Cached geometry is rebuilt only by viewport/profile changes.
@export_enum("Sky", "Mountains", "Underwater", "FarMountains", "MiddleMountains", "NearShore") var layer: String = "Sky"
var view_size := Vector2(640, 360)
var profile: LakeProfile
var shore_factor: float = 1.0
var time_of_day: float = 0.0
var depth_origin_m: float = 0.0
var depth_span_m: float = 15.0
var _ridge_points := PackedVector2Array()
var _rng := RandomNumberGenerator.new()

func configure(size: Vector2, settings: LakeProfile) -> void:
	view_size = size
	profile = settings
	match layer:
		"FarMountains": _ridge_points = _ridge(37, 0.5)
		"MiddleMountains": _ridge_points = _ridge(25, 2.2)
		"NearShore": _ridge_points = _ridge(12, 3.4)
	for child in get_children():
		if child.has_method("configure"):
			child.configure(size, settings)
	queue_redraw()

func _ridge(height: float, phase: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var horizon := floorf(view_size.y * 0.265)
	points.append(Vector2(0, horizon + 6))
	for x in range(0, int(view_size.x) + 5, 4):
		var rolling := sin(x * 0.012 + phase) * 0.42 + sin(x * 0.027 + phase) * 0.18 + 0.65
		points.append(Vector2(x, floorf((horizon - height * rolling * shore_factor) / 2) * 2))
	points.append(Vector2(view_size.x + 4, horizon + 6))
	return points

func _draw() -> void:
	if profile == null:
		return
	match layer:
		"Sky": _draw_sky()
		"FarMountains", "MiddleMountains", "NearShore": _draw_mountain_layer()
		"Underwater": _draw_underwater()

func _draw_sky() -> void:
	var horizon := view_size.y * 0.27
	for y in range(0, int(horizon) + 2, 2):
		draw_rect(Rect2(0, y, view_size.x, 2), profile.sky_top.lerp(profile.sky_bottom, float(y) / horizon))
	var sun := Vector2(floorf(view_size.x * 0.62), 37)
	# Soft stepped haze, without blur, lights or post-processing.
	for i in range(3, 0, -1):
		draw_rect(Rect2(sun - Vector2(10 + i * 3, 8 + i * 2), Vector2(20 + i * 6, 16 + i * 4)), Color(0.97, 0.96, 0.80, 0.055))
	draw_rect(Rect2(sun - Vector2(8, 6), Vector2(16, 12)), Color("fff1c9").lerp(Color("c6d5d9"),clampf(time_of_day - 1,0,1)))
	draw_rect(Rect2(sun - Vector2(6, 8), Vector2(12, 16)), Color("fff1c9").lerp(Color("c6d5d9"),clampf(time_of_day - 1,0,1)))
	_draw_cloud(Vector2(view_size.x * 0.04, 24), 1.2, 0)
	_draw_cloud(Vector2(view_size.x * 0.40, 45), 0.8, 1)
	_draw_cloud(Vector2(view_size.x * 0.76, 21), 1.6, 2)
	_draw_cloud(Vector2(view_size.x * 0.25, 59), 0.55, 1)
	for x in [view_size.x * 0.47, view_size.x * 0.49]:
		draw_line(Vector2(floorf(x), 55), Vector2(floorf(x) + 3, 57), Color("779da6"))
		draw_line(Vector2(floorf(x) + 3, 57), Vector2(floorf(x) + 6, 55), Color("779da6"))

func _draw_cloud(origin: Vector2, factor: float, variant: int) -> void:
	var shapes := [Rect2(0, 7, 62, 4), Rect2(9, 4, 40, 5), Rect2(16, 0, 20, 7)]
	if variant == 1:
		shapes = [Rect2(0, 6, 74, 3), Rect2(16, 3, 41, 4)]
	elif variant == 2:
		shapes = [Rect2(0, 7, 61, 4), Rect2(4, 4, 18, 5), Rect2(25, 1, 27, 8)]
	for shape: Rect2 in shapes:
		draw_rect(Rect2((origin + shape.position * factor).floor(), (shape.size * factor).floor()), Color("edf3e5").lerp(Color("60758b"),time_of_day * 0.5))
	draw_rect(Rect2((origin + Vector2(4, 10) * factor).floor(), Vector2(floorf(54 * factor), 2)), Color("c8e0dd").lerp(Color("455b74"),time_of_day * 0.5))

func _draw_mountain_layer() -> void:
	var color := profile.mountain_far
	if layer == "MiddleMountains":
		color = profile.mountain_middle
	elif layer == "NearShore":
		color = profile.mountain_near
	if layer == "NearShore" and shore_factor < 0.2: return
	draw_colored_polygon(_ridge_points, color)
	for i in range(2, _ridge_points.size() - 2):
		var p := _ridge_points[i]
		if layer == "MiddleMountains" and i % 5 == 0:
			draw_line(p + Vector2(0, 5), p + Vector2(12, 13), color.lightened(0.045), 2)
		elif layer == "NearShore" and i % 3 == 0:
			draw_rect(Rect2(p - Vector2(0, 3), Vector2(2, 5)), color.darkened(0.08))
			draw_rect(Rect2(p + Vector2(2, -1), Vector2(4, 3)), color.lightened(0.04))
	if layer == "NearShore":
		var horizon := floorf(view_size.y * 0.265)
		draw_rect(Rect2(0, horizon - 1, view_size.x, 2), Color("8ca999"))
		draw_rect(Rect2(0, horizon + 1, view_size.x, 2), Color("bfd0bb"))

func set_depth_band(origin: float, span: float) -> void:
	depth_origin_m = origin
	depth_span_m = span
	queue_redraw()

func color_at_depth(depth_m: float) -> Color:
	if depth_m > 100:
		return Color("101e30").lerp(Color("0c1926"),clampf((depth_m-100)/20,0,1))
	if depth_m > 50:
		return Color("23364b").lerp(Color("101e30"),clampf((depth_m-50)/50,0,1))
	if depth_m > 15:
		return profile.water_deep.lerp(Color("23364b"), clampf((depth_m - 15) / 35, 0, 1))
	var ratio := clampf(depth_m / profile.displayed_depth_m, 0, 1)
	if ratio < 0.5:
		return profile.water_upper.lerp(profile.water_middle, ratio * 2)
	return profile.water_middle.lerp(profile.water_deep, (ratio - 0.5) * 2)

func _draw_underwater() -> void:
	var surface := floorf(view_size.y * profile.surface_ratio)
	var height := view_size.y - surface
	for y in range(int(surface), int(view_size.y), 2):
		var depth := depth_origin_m + float(y - surface) / height * depth_span_m
		draw_rect(Rect2(0, y, view_size.x, 2), color_at_depth(depth))
	# Narrow, broken light bands attenuate downwards. Static, no god-ray shader.
	for x in [view_size.x * 0.10, view_size.x * 0.38, view_size.x * 0.72, view_size.x * 0.93]:
		for band in range(6):
			var y := surface + 6 + band * 26
			var ray := PackedVector2Array([Vector2(floorf(x + band * 7), y), Vector2(floorf(x + 15 + band * 7), y), Vector2(floorf(x + 23 + band * 7), y + 26), Vector2(floorf(x + 6 + band * 7), y + 26)])
			draw_colored_polygon(ray, Color(0.72, 0.92, 0.84, (0.045 - band * 0.0055) * maxf(0,1.0 - depth_origin_m / 65.0)))
	if depth_origin_m >= 50:
		# Bounded static specks; no particle nodes, flashes or large noisy layers.
		_rng.seed = 847
		for i in range(24):
			var point := Vector2(_rng.randf_range(0,view_size.x),_rng.randf_range(surface+12,view_size.y-12)).floor()
			draw_rect(Rect2(point,Vector2.ONE),Color(0.42,0.56,0.65,0.14))
		if depth_origin_m >= 65:
			for x in range(0,int(view_size.x),38):
				var y := floorf(view_size.y - 9 + sin(x * 0.016)*4)
				draw_rect(Rect2(x,y,27,2),Color("263646").lerp(Color("1a293a"),clampf((depth_origin_m-65)/35,0,1)))
	if depth_origin_m >= 30:
		if depth_origin_m >= 100:
			# Sparse mud/bedrock and one ambiguous old outline; no explanatory text.
			for x in range(0,int(view_size.x),12):
				var bed_y := floorf(view_size.y-18+sin(x*0.016)*4)
				draw_rect(Rect2(x,bed_y,12,view_size.y-bed_y),Color("1a2931"))
				draw_rect(Rect2(x,bed_y,10,2),Color("2f4047"))
			_draw_rock(Vector2(floorf(view_size.x*0.14),view_size.y-20),1.1)
			var outline := Vector2(floorf(view_size.x*0.79),view_size.y-36)
			for rect in [Rect2(0,0,32,3),Rect2(0,0,3,20),Rect2(29,0,3,20),Rect2(2,17,28,2)]:
				draw_rect(Rect2(outline+rect.position,rect.size),Color("293c45"))
		# Open deeper water; avoid suggesting the lake floor is only 50m down.
		return
	_rng.seed = 3418
	# Keep the central fishing lane uncluttered. A normal gravel / silt lake bed.
	for x in range(0, int(view_size.x), 8):
		var bed_y := view_size.y - 15 + floorf(sin(x * 0.017) * 3)
		draw_rect(Rect2(x, bed_y, 8, view_size.y - bed_y), Color("224652"))
		draw_rect(Rect2(x, bed_y, 8, 2), Color("3b5d60"))
	for i in range(int(view_size.x / 6)):
		var x := _rng.randi_range(0, int(view_size.x))
		var y := _rng.randi_range(int(view_size.y) - 12, int(view_size.y) - 2)
		draw_rect(Rect2(x, y, _rng.randi_range(2, 6), 1), Color("668072") if i % 4 == 0 else Color("33565b"))
	for fraction in [0.06, 0.25, 0.72, 0.94]:
		_draw_rock(Vector2(floorf(view_size.x * fraction), view_size.y - 15), 1.0 if fraction < 0.5 else 1.4)
	for fraction in [0.03, 0.10, 0.30, 0.76, 0.92, 0.98]:
		_draw_weeds(floorf(view_size.x * fraction), view_size.y - 6)
	# One small, ordinary submerged branch on the lower right.
	var log_origin := Vector2(floorf(view_size.x * 0.83), view_size.y - 18)
	draw_line(log_origin, log_origin + Vector2(34, -7), Color("4a6662"), 4)
	draw_line(log_origin + Vector2(13, -3), log_origin + Vector2(21, -13), Color("688172"), 2)
	draw_line(log_origin + Vector2(3, -1), log_origin + Vector2(28, -6), Color("728676"))
	for i in range(32):
		var p := Vector2(_rng.randi_range(0, int(view_size.x)), _rng.randi_range(int(surface) + 24, int(view_size.y) - 30))
		draw_rect(Rect2(p, Vector2.ONE), Color(0.66, 0.83, 0.76, 0.16))

func _draw_rock(origin: Vector2, factor: float) -> void:
	for rect in [Rect2(-13, -6, 29, 8), Rect2(-9, -11, 19, 7)]:
		draw_rect(Rect2(origin + (rect.position * factor).floor(), (rect.size * factor).floor()), Color("395c60"))
	draw_rect(Rect2(origin + Vector2(-8, -10) * factor, Vector2(13, 2) * factor), Color("6a8074"))
	draw_rect(Rect2(origin + Vector2(1, -8) * factor, Vector2(6, 2) * factor), Color("4a6e6b"))

func _draw_weeds(x: float, floor_y: float) -> void:
	for blade in range(5):
		var h := 13 + blade * 4 + int(x) % 9
		var base := Vector2(x + blade * 3, floor_y)
		var tip := base + Vector2(-4 + blade, -h)
		draw_line(base, tip, Color("47776d"), 2)
		draw_line(base + Vector2(-1, -h / 2), base + Vector2(-7, -h / 2 - 5), Color("71977a"))
