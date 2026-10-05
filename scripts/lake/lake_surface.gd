extends Node2D
## A small set of cached ripple segments, animated at 20 Hz.

var time_of_day: float = 0.0
var view_size := Vector2(640, 360)
var profile: LakeProfile
var animation_time: float = 0.0
var _refresh_timer: float = 0.0
var _ripples: Array[Rect2] = []

func configure(size: Vector2, settings: LakeProfile) -> void:
	view_size = size
	profile = settings
	_ripples.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2201
	var top := floorf(size.y * 0.265) + 4
	var bottom := floorf(size.y * settings.surface_ratio)
	for i in range(int(size.x / 7)):
		_ripples.append(Rect2(rng.randf_range(-12, size.x), rng.randf_range(top + 3, bottom - 3), rng.randi_range(3, 18), 1))
	queue_redraw()

func _process(delta: float) -> void:
	animation_time += delta
	_refresh_timer += delta
	if _refresh_timer >= 0.05:
		_refresh_timer = fmod(_refresh_timer, 0.05)
		queue_redraw()

func ripple_offset(index: int) -> float:
	return sin(animation_time * 1.1 + index * 2.7) * 3.0

func _draw() -> void:
	if profile == null:
		return
	var top := floorf(view_size.y * 0.265) + 4
	var surface := floorf(view_size.y * profile.surface_ratio)
	var height := surface - top
	for y in range(int(top), int(surface), 2):
		var color := profile.surface_color.lerp(Color("528e9c").lerp(Color("27485e"),time_of_day * 0.5), float(y - top) / height * 0.5)
		draw_rect(Rect2(0, y, view_size.x, 2), color)
	# Mountain reflections in the distant water.
	for x in range(0, int(view_size.x), 26):
		draw_rect(Rect2(x, top + 1, 16, 2), Color(0.24, 0.47, 0.42, 0.18))
	for i in range(_ripples.size()):
		var r := _ripples[i]
		r.position.x = floorf(r.position.x + ripple_offset(i))
		r.position.y = floorf(r.position.y)
		draw_rect(r, (Color("c3e4d9") if i % 3 == 0 else Color("92c7c5")).lerp(Color("65849a"),time_of_day * 0.5))
	# Stepped reflection of the bright sky, broken by the same quiet ripples.
	for strip in range(9):
		var reflected_x := floorf(view_size.x * 0.62 + ripple_offset(strip) - 10 - strip * 2)
		draw_rect(Rect2(reflected_x, top + 5 + strip * 3, 20 + strip * 4, 1), Color(0.90, 0.94, 0.79, 0.25 - strip * 0.018))
	# Broken highlights at the cutaway's surface keep the waterline legible.
	draw_rect(Rect2(0, surface, view_size.x, 2), Color("acd6be").lerp(Color("628695"),time_of_day * 0.5))
	draw_rect(Rect2(0, surface + 2, view_size.x, 2), Color("549f9a").lerp(Color("345b72"),time_of_day * 0.5))
	for x in range(0, int(view_size.x), 25):
		draw_rect(Rect2(x + floorf(ripple_offset(x)), surface, 13, 1), Color("d1dfbf").lerp(Color("7797aa"),time_of_day * 0.5))
