class_name PlaceholderArt
extends RefCounted
## Original placeholders, built once and shared. Replace Boat's texture or
## Fish's SpriteFrames when production art is available.

static var _fish_cache: Dictionary = {}
static var _boat_cache: Texture2D

static func fish_frames(kind: String) -> SpriteFrames:
	if _fish_cache.has(kind):
		return _fish_cache[kind]
	var frames := SpriteFrames.new()
	frames.rename_animation("default", "swim")
	frames.set_animation_speed("swim", 4.0)
	for tail_phase in range(3):
		frames.add_frame("swim", _fish_texture(kind, tail_phase))
	_fish_cache[kind] = frames
	return frames

static func _fish_texture(kind: String, tail_phase: int) -> Texture2D:
	var image := Image.create(40, 22, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var is_small := kind == "minnow"
	var is_round := kind == "bluegill"
	var body := Color("a3bbb0")
	var back := Color("496b60")
	var belly := Color("d8d7ac")
	var fin := Color("668579")
	if is_round:
		body = Color("8caf8e")
		back = Color("4e7166")
		belly = Color("d8bb78")
		fin = Color("809875")
	elif is_small:
		body = Color("b8d2c7")
		back = Color("6e9b99")
		belly = Color("e1e4c4")
		fin = Color("9bbbb0")
	var length := 21 if is_small else (25 if is_round else 32)
	var radius_y := 3 if is_small else (7 if is_round else 5)
	var left := 5
	var center_y := 11
	var center_x := left + length / 2
	for x in range(left, left + length):
		var normalized := float(x - center_x) / (float(length) * 0.5)
		var half_height := int(round(sqrt(maxf(0.0, 1.0 - normalized * normalized)) * radius_y))
		for y in range(center_y - half_height, center_y + half_height + 1):
			var color := body
			if y < center_y - 2:
				color = back
			elif y > center_y + 2:
				color = belly
			elif (x + y * 3) % 7 == 0:
				color = body.lightened(0.12)
			image.set_pixel(x, y, color)
	# Source frames face right; the controller flips the entire sprite.
	var tail_shift: int = [-1, 0, 1][tail_phase]
	for x in range(1, 7):
		var spread := (7 - x) / 2 + 1
		for y in range(center_y - spread + tail_shift, center_y + spread + tail_shift + 1):
			image.set_pixel(x, y, fin if (x + y) % 3 else back)
	for x in range(12, mini(left + length - 6, 26)):
		image.set_pixel(x, center_y - radius_y - 1, fin)
		if x % 2 == 0:
			image.set_pixel(x, center_y - radius_y - 2, back)
	var eye_x := left + length - 5
	image.set_pixel(eye_x, center_y - 2, Color("e8e9c9"))
	image.set_pixel(eye_x + 1, center_y - 2, Color("17383e"))
	image.set_pixel(eye_x + 1, center_y - 1, Color("17383e"))
	for y in range(center_y, center_y + mini(radius_y, 4)):
		image.set_pixel(eye_x - 3, y, back)
	if not is_small:
		for x in range(left + 7, left + length - 6):
			image.set_pixel(x, center_y + 1, back.lightened(0.08))
	return ImageTexture.create_from_image(image)

static func boat_texture() -> Texture2D:
	if _boat_cache != null:
		return _boat_cache
	var image := Image.create(110, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	# Fishing skiff, stern motor, seated silhouette and static rod. No lure.
	_paint(image, Rect2i(12, 34, 88, 3), "e0d6b0")
	_paint(image, Rect2i(16, 37, 80, 5), "637e73")
	_paint(image, Rect2i(22, 42, 67, 3), "355751")
	_paint(image, Rect2i(28, 45, 56, 2), "254747")
	_paint(image, Rect2i(19, 36, 73, 1), "f1e2b8")
	_paint(image, Rect2i(32, 32, 19, 2), "9a9276")
	_paint(image, Rect2i(60, 31, 17, 3), "9a9276")
	_paint(image, Rect2i(96, 27, 8, 11), "344b4b")
	_paint(image, Rect2i(97, 26, 6, 2), "80938b")
	_paint(image, Rect2i(99, 37, 3, 7), "273e42")
	_paint(image, Rect2i(49, 19, 10, 12), "cc925e")
	_paint(image, Rect2i(51, 20, 4, 10), "e8b877")
	_paint(image, Rect2i(47, 29, 19, 4), "334b4c")
	_paint(image, Rect2i(61, 29, 5, 6), "334b4c")
	_paint(image, Rect2i(50, 12, 8, 7), "c7b78c")
	_paint(image, Rect2i(46, 11, 15, 3), "324e4d")
	_paint(image, Rect2i(50, 8, 8, 3), "46645b")
	_paint(image, Rect2i(42, 22, 9, 3), "c7b78c")
	for x in range(15, 45):
		var y := 5 + int(float(x - 15) * 0.57)
		image.set_pixel(x, y, Color("344e4e"))
	_paint(image, Rect2i(25, 36, 6, 2), "a8aa91")
	_paint(image, Rect2i(76, 35, 9, 2), "a8aa91")
	_boat_cache = ImageTexture.create_from_image(image)
	return _boat_cache

static func _paint(image: Image, rect: Rect2i, hex_color: String) -> void:
	image.fill_rect(rect, Color(hex_color))
