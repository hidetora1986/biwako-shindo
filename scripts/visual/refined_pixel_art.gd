class_name RefinedPixelArt
extends RefCounted
## Original, cached pixel sprites. No external art, game RNG or fish data mutation.
## All fish use the original 40×22 frame envelope; AI geometry stays unchanged.
static var _fish_cache: Dictionary = {}
static var _boat_cache: Texture2D

static func fish_frames(species: String) -> SpriteFrames:
	if _fish_cache.has(species):
		return _fish_cache[species]
	var frames := SpriteFrames.new()
	frames.rename_animation("default", "swim")
	frames.set_animation_speed("swim", 4)
	for phase in range(3):
		frames.add_frame("swim", fish_texture(species, phase))
	_fish_cache[species] = frames
	return frames

static func fish_texture(species: String, phase: int = 1) -> Texture2D:
	var image := Image.create(40, 22, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var body := Color("849a72")
	var back := Color("435c49")
	var belly := Color("d5cf9c")
	var fin := Color("879578")
	var length := 29
	var height := 6
	match species:
		"bluegill":
			length = 23
			height = 8
			body = Color("8d9b69")
			back = Color("486b62")
			belly = Color("d4ad70")
			fin = Color("a2a476")
		"crucian":
			length = 26
			height = 7
			body = Color("b9b79a")
			back = Color("677769")
			belly = Color("e2d4ab")
			fin = Color("a29270")
		"catfish":
			length = 32
			height = 4
			body = Color("94938b")
			back = Color("535f5e")
			belly = Color("cbc6ac")
			fin = Color("78857b")
		"biwamasu":
			length = 31
			height = 4
			body = Color("b0c5c0")
			back = Color("4b8583")
			belly = Color("e5e0c5")
			fin = Color("879e99")
	var tail_phase: int = [-1, 0, 1][phase % 3]
	for x in range(1, 9):
		var spread := (8 - x) / 2 + 1
		for y in range(11 - spread + tail_phase, 12 + spread + tail_phase):
			if species == "biwamasu" and x <= 3 and abs(y - 11 - tail_phase) <= 1:
				continue # Forked salmon tail.
			image.set_pixel(x, clampi(y, 0, 21), fin if (x + y) % 3 else back)
	for x in range(6, 6 + length):
		var u := float(x - 6) / float(length - 1)
		var contour := sqrt(maxf(0, 1.0 - pow((u - 0.51) * 2, 2)))
		var radius := maxi(1, int(round(contour * height)))
		if species == "catfish":
			# Broad flat head, tapered rear, long low body.
			radius = 2 + int(u * 2)
		for y in range(11 - radius, 12 + radius):
			var tone := body
			if y == 11 - radius or y == 11 + radius:
				tone = back if y < 11 else belly.darkened(0.14)
			elif y < 9:
				tone = back.lerp(body, 0.35)
			elif y > 12:
				tone = belly
			elif (x + y * 3) % 9 == 0:
				tone = body.lightened(0.13)
			image.set_pixel(x, y, tone)
	var nose := 5 + length
	var gill := nose - 7
	if species != "catfish":
		for x in range(12, gill + 1):
			var fin_y := maxi(1, 10 - height)
			image.set_pixel(x, fin_y, fin)
			if x % 2 == 0:
				image.set_pixel(x, fin_y - 1, back)
		for x in range(14, 21):
			image.set_pixel(x, mini(21, 12 + height), fin)
	for y in range(10, 14):
		image.set_pixel(gill, y, back)
	image.set_pixel(gill + 2, 12, fin.lightened(0.18))
	image.set_pixel(gill + 3, 13, fin)
	image.set_pixel(nose - 4, 8 if height > 4 else 9, Color("f3e5b9"))
	image.set_pixel(nose - 3, 8 if height > 4 else 9, Color("294849"))
	image.set_pixel(nose, 11, back)
	match species:
		"bluegill":
			for x in [12, 16, 20]:
				for y in range(7, 15):
					image.set_pixel(x, y, back.lerp(body, 0.55))
			_paint(image, Rect2i(gill - 1, 9, 3, 3), "345c5b")
		"bass":
			for x in range(8, nose - 4):
				image.set_pixel(x, 11 + (x % 5 / 3), back)
			_paint(image, Rect2i(nose - 1, 10, 2, 3), "526d57")
		"crucian":
			for x in range(10, gill, 3):
				for y in range(8, 15, 3):
					image.set_pixel(x, y, belly.lightened(0.1))
		"catfish":
			for x in range(12, 29):
				image.set_pixel(x, 16, fin)
			for x in range(nose - 5, 40):
				image.set_pixel(x, 13 + (x - nose + 5) / 4, Color("d3ceb5"))
			_paint(image, Rect2i(35, 10, 4, 1), "d3ceb5")
		"biwamasu":
			for x in range(12, gill, 4):
				image.set_pixel(x, 9, back)
				image.set_pixel(x + 1, 11, back.lightened(0.12))
			_paint(image, Rect2i(12, 6, 3, 2), "849c91")
	return ImageTexture.create_from_image(image)

static func boat_texture() -> Texture2D:
	if _boat_cache != null:
		return _boat_cache
	var image := Image.create(154, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	# 1.4× original hull presence, anchored to the same gameplay rod tip.
	_paint(image, Rect2i(7, 45, 135, 4), "d7e4d4")
	_paint(image, Rect2i(11, 49, 128, 6), "548c89")
	_paint(image, Rect2i(18, 55, 113, 4), "35666a")
	_paint(image, Rect2i(26, 59, 95, 3), "244b57")
	_paint(image, Rect2i(35, 62, 75, 1), "254f5a")
	_paint(image, Rect2i(14, 48, 123, 1), "f5eac5")
	_paint(image, Rect2i(24, 52, 106, 1), "a3bbac")
	for x in range(26, 125, 9):
		_paint(image, Rect2i(x, 53, 5, 1), "6b9690")
	# Raised bow, pale deck, darker side rail and small deck compartments.
	_paint(image, Rect2i(10, 42, 39, 3), "c3d3bf")
	_paint(image, Rect2i(15, 40, 27, 2), "8ca899")
	_paint(image, Rect2i(95, 42, 38, 3), "9fbab0")
	_paint(image, Rect2i(23, 42, 11, 1), "e9e4c5")
	_paint(image, Rect2i(108, 42, 13, 1), "e9e4c5")
	# Seat, compact console, outboard casing, lower shaft and propeller.
	_paint(image, Rect2i(54, 39, 26, 4), "537477")
	_paint(image, Rect2i(66, 42, 3, 3), "355960")
	_paint(image, Rect2i(88, 35, 16, 8), "476e75")
	_paint(image, Rect2i(88, 34, 12, 2), "b1c7b7")
	_paint(image, Rect2i(91, 36, 7, 3), "234e5d")
	_paint(image, Rect2i(138, 33, 12, 18), "30515c")
	_paint(image, Rect2i(139, 32, 10, 3), "6d9391")
	_paint(image, Rect2i(141, 37, 6, 6), "4d7175")
	_paint(image, Rect2i(142, 50, 4, 12), "2d515c")
	_paint(image, Rect2i(138, 60, 10, 2), "6c8e88")
	# Angler: straw cap, face, sage jacket, seated trousers, arm to original rod.
	_paint(image, Rect2i(67, 16, 10, 10), "c0b892")
	_paint(image, Rect2i(72, 18, 5, 6), "e0c8a0")
	_paint(image, Rect2i(65, 26, 14, 14), "7e9b81")
	_paint(image, Rect2i(66, 27, 5, 12), "a5b597")
	_paint(image, Rect2i(65, 39, 19, 4), "355965")
	_paint(image, Rect2i(80, 41, 5, 6), "355965")
	_paint(image, Rect2i(83, 46, 7, 2), "c0bda2")
	_paint(image, Rect2i(61, 30, 8, 3), "d3c3a0")
	_paint(image, Rect2i(63, 15, 17, 3), "b5b49b")
	_paint(image, Rect2i(67, 11, 10, 4), "e4d7af")
	_paint(image, Rect2i(67, 14, 10, 1), "668987")
	_boat_cache = ImageTexture.create_from_image(image)
	return _boat_cache

static func _paint(image: Image, rect: Rect2i, color: String) -> void:
	image.fill_rect(rect, Color(color))
