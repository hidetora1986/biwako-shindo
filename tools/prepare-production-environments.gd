extends SceneTree
## Offline crop/band packing/colour grading. All PNGs committed; never run in gameplay.
func _initialize() -> void:
	var source:=Image.load_from_file("res://assets/visual/v2/environment/source/north-sheet.png")
	var north_source:=source
	for area in ["south_shore","north_shore","north_center"]:
		source=Image.load_from_file("res://assets/visual/golden/south_shore/south-shore-morning.png") if area=="south_shore" else north_source
		var top:int=475 if area=="north_center" else 0
		var cut:int=357 if area=="south_shore" else (232 if area=="north_shore" else 176)
		var height:int=941 if area=="south_shore" else (469 if area=="north_shore" else source.get_height()-top)
		var above:=source.get_region(Rect2i(0,top,source.get_width(),cut));above.resize(1280,272,Image.INTERPOLATE_NEAREST);above.convert(Image.FORMAT_RGBA8)
		var under:=source.get_region(Rect2i(0,top+cut,source.get_width(),height-cut));under.resize(1280,448,Image.INTERPOLATE_NEAREST);under.convert(Image.FORMAT_RGBA8)
		for time in ["morning","day","sunset","night"]:
			var graded:=above.duplicate()
			for y in range(graded.get_height()):
				for x in range(graded.get_width()):
					var c:Color=graded.get_pixel(x,y)
					if time=="day":c=Color(c.r*.95,c.g*1.03,c.b*1.08,1)
					elif time=="sunset":c=Color(c.r*.91+.07,c.g*.72+.04,c.b*.67+.04,1)
					elif time=="night":c=Color(c.r*.11+.015,c.g*.20+.03,c.b*.31+.045,1)
					graded.set_pixel(x,y,c)
			var bands := [0,73,117,167,201,272] if area=="south_shore" else ([0,48,92,142,208,272] if area=="north_shore" else [0,122,161,208,208,272])
			var names := ["sky","far","middle","shore","surface"]
			for i in range(5):
				var layer:=Image.create(1280,272,false,Image.FORMAT_RGBA8);layer.fill(Color.TRANSPARENT)
				layer.blit_rect(graded,Rect2i(0,bands[i],1280,bands[i+1]-bands[i]),Vector2i(0,bands[i]))
				if time=="night" and i==0:
					# Small moon and fixed star pattern, not a gameplay weather/time system.
					layer.fill_rect(Rect2i(850,27,14,14),Color("d5dec6"))
					for n in range(48):layer.set_pixel(posmod(n*197,1274)+3,posmod(n*37,42)+3,Color("62838f"))
				assert(layer.save_png("res://assets/visual/v2/environment/%s/%s/%s.png" % [area,time,names[i]])==OK)
		if area=="north_shore":
			for i in range(7):
				var band=["shallow","mid","lower_mid","deep","cold","dark","abyss"][i]
				var water:=under.duplicate()
				# Deep water excludes the shallow reed beds / caustic surface pattern.
				# Reuse the original central mud, gravel and submerged wood at a closer scale.
				if i>=3:
					water=under.get_region(Rect2i(384,80+i*8,512,300-i*8))
					water.resize(1280,448,Image.INTERPOLATE_NEAREST)
				var tone:Color=[Color("ffffff"),Color("a3c9d0"),Color("6f9da9"),Color("456a86"),Color("294b66"),Color("16334e"),Color("102c40")][i]
				for y in range(448):
					for x in range(1280):
						var c:Color=water.get_pixel(x,y);var depth_fog:float=i*.095
						c=(c*tone).lerp(Color("0d2536"),depth_fog)
						water.set_pixel(x,y,c)
				assert(water.save_png("res://assets/visual/v2/depth/%s/water.png" % band)==OK)
	print("PRODUCTION_ENVIRONMENT_PACK PASS");quit()
