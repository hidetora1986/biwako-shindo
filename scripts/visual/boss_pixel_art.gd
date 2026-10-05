class_name BossPixelArt
extends RefCounted
## Original huge freshwater-fish silhouette. Cached by RefinedPixelArt.
static func texture(phase: int) -> Texture2D:
	var image := Image.create(288,96,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var middle := 48
	for x in range(16,274):
		var u := float(x-16)/258
		var radius := int(7+27*sin(u*PI)+7*exp(-pow((u-0.81)/0.14,2)))
		for y in range(middle-radius,middle+radius):
			var tone := Color("354c59") if y < middle-radius+6 else (Color("8a9a93") if y > middle+12 else Color("647c7d"))
			image.set_pixel(x,y,tone)
	# Heavy tail, small natural eye and old pale markings, no teeth or red.
	for x in range(3,40):
		var radius := maxi(4,int((40-x)*0.72))
		for y in range(middle-radius+phase*2-2,middle+radius+phase*2-2):
			image.set_pixel(x,clampi(y,0,95),Color("48626e"))
	image.fill_rect(Rect2i(246,35,4,3),Color("a7b2a4"))
	image.fill_rect(Rect2i(272,48,8,2),Color("93a49c"))
	for x in [132,167,192]:
		for i in range(14):
			image.fill_rect(Rect2i(x+i/3,41+i,2,2),Color("93a399"))
	image.fill_rect(Rect2i(129,10,22,4),Color("476371"))
	image.fill_rect(Rect2i(190,78,27,6),Color("536e77"))
	return ImageTexture.create_from_image(image)
