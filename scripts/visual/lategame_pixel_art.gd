class_name LategamePixelArt
extends RefCounted
## Original cached sprites: unusual anatomy, no blood, teeth, faces or red eyes.
static func texture(species: String, phase: int) -> Texture2D:
	var width := 96 if species == "unknown_b" else (80 if species == "reverse_scale" else 72)
	var height := 36 if species == "unknown_b" else 32
	var image := Image.create(width,height,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var center := height / 2
	var body := Color("819694")
	var back := Color("476574")
	var belly := Color("b3c0af")
	if species == "unknown_b":
		body = Color("6b858b")
		back = Color("405b70")
		belly = Color("9fafaa")
	for x in range(3,width-5):
		var u := float(x-3)/(width-8)
		var radius := maxi(1,int(sin(u * PI)*10))
		if species == "unknown_b":
			radius = maxi(2,int(2 + 13 * exp(-pow((u-0.77)/0.22,2))))
		for y in range(center-radius,center+radius+1):
			var tone := back if y < center-radius+2 else (belly if y > center+3 else body)
			if species == "split_belly" and x > 19 and x < width-15 and y >= center+6 and y <= center+8:
				continue # A narrow ambiguous structural gap, never an open wound.
			image.set_pixel(x,y,tone)
		if x < 10:
			var tail := (10-x)/2 + 1
			for y in range(center-tail+phase-1,center+tail+phase):
				image.set_pixel(x,clampi(y,0,height-1),back)
	image.fill_rect(Rect2i(width-11,center-3,2,1),Color("9daea9"))
	match species:
		"thread_jaw":
			for i in range(3):
				for step in range(10+i*2):
					image.set_pixel(width-12+step/3-i,clampi(center+5+step,0,height-1),belly.darkened(0.2))
		"split_belly":
			for x in range(18,width-15):
				image.set_pixel(x,center+9,back)
		"reverse_scale":
			for x in range(16,width-16,7):
				for y in range(center-5,center+5,5):
					for step in range(3):
						image.set_pixel(x+step,y+step,belly.darkened(0.16))
		"unknown_b":
			image.fill_rect(Rect2i(43,center-11,5,3),back)
			image.fill_rect(Rect2i(62,center+13,8,2),body)
			image.fill_rect(Rect2i(75,center+5,14,2),belly)
	return ImageTexture.create_from_image(image)
