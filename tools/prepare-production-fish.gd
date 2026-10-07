extends SceneTree
## Offline alpha-bound extraction, nearest packing, native geometry. No runtime work.
func _initialize() -> void:
	var source:=Image.load_from_file("res://assets/visual/v2/fish/source/species-sheet.png")
	var species := ["giant_catfish","pale_biwamasu","long_eel","blind_isaza","unknown_a","thread_jaw","split_belly","reverse_scale","unknown_b"]
	var widths := [60,60,88,28,60,72,72,80,96]
	var heights := [26,26,18,18,26,32,32,32,36]
	for row in range(9):
		var w:int=widths[row];var h:int=heights[row]
		var sheet:=Image.create(w,h*3,false,Image.FORMAT_RGBA8);sheet.fill(Color.TRANSPARENT)
		for col in range(3):
			var cell:=source.get_region(Rect2i(col*source.get_width()/3,row*source.get_height()/9,source.get_width()/3,source.get_height()/9))
			for y in range(cell.get_height()):
				for x in range(cell.get_width()):
					if cell.get_pixel(x,y).a<.35:cell.set_pixel(x,y,Color.TRANSPARENT)
			var bounds:=cell.get_used_rect()
			var art:=cell.get_region(bounds)
			var scale_factor:=minf(float(w-8)/art.get_width(),float(h-4)/art.get_height())
			art.resize(maxi(1,int(art.get_width()*scale_factor)),maxi(1,int(art.get_height()*scale_factor)),Image.INTERPOLATE_NEAREST)
			sheet.blit_rect(art,Rect2i(0,0,art.get_width(),art.get_height()),Vector2i(w-5-art.get_width(),col*h+(h-art.get_height())/2))
		# Original contour accents keep unusual anatomy readable after tiny nearest packing.
		if row==6:
			for phase in range(3):
				for x in range(w/3,w-17):
					for y in range(h/2+5,h/2+8):sheet.set_pixel(x,phase*h+y,Color.TRANSPARENT)
		if row==7:
			for phase in range(3):
				for x in range(18,w-18,7):
					for y in [h/2-4,h/2+1]:
						for step in range(3):
							var point:=Vector2i(x+step,phase*h+y+step)
							var c:Color=sheet.get_pixelv(point)
							if c.a>.5:sheet.set_pixelv(point,c.lerp(Color("c1c7bd"),.22))
		var category:String="midgame" if row<5 else "lategame"
		assert(sheet.save_png("res://assets/visual/v2/fish/%s/%s.png" % [category,species[row]])==OK)
	print("PRODUCTION_FISH_PACK PASS");quit()
