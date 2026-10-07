extends SceneTree
## Offline format preparation only: true-alpha source, nearest sampling, unchanged 288×96 frames.
func _initialize() -> void:
	var source := Image.load_from_file("res://assets/visual/boss/no15/source/lake-master-source.png")
	assert(source != null and source.get_format() == Image.FORMAT_RGBA8)
	var sheet := Image.create(288,288,false,Image.FORMAT_RGBA8)
	sheet.fill(Color.TRANSPARENT)
	for phase in range(3):
		var y0 := phase * source.get_height() / 3
		var y1 := (phase+1) * source.get_height() / 3
		var min_x := source.get_width();var min_y := y1;var max_x := 0;var max_y := y0
		for y in range(y0,y1):
			for x in range(source.get_width()):
				if source.get_pixel(x,y).a > 0.5:
					min_x = mini(min_x,x);min_y = mini(min_y,y);max_x = maxi(max_x,x);max_y = maxi(max_y,y)
		var tip_sum := 0.0;var tip_count := 0
		for x in range(max_x-3,max_x+1):
			for y in range(min_y,max_y+1):
				if source.get_pixel(x,y).a > 0.5:tip_sum += y;tip_count += 1
		var bounds := Rect2i(min_x,min_y,max_x-min_x+1,max_y-min_y+1)
		var fish := source.get_region(bounds)
		var factor := 282.0/bounds.size.x
		fish.resize(282,roundi(bounds.size.y*factor),Image.INTERPOLATE_NEAREST)
		var offset_y := roundi(48-(tip_sum/tip_count-min_y)*factor)
		assert(offset_y >= 0 and offset_y+fish.get_height() <= 96)
		sheet.blit_rect(fish,Rect2i(Vector2i.ZERO,fish.get_size()),Vector2i(3,phase*96+offset_y))
	assert(sheet.save_png("res://assets/visual/boss/no15/lake-master-swim.png") == OK)
	print("Prepared three 288x96 true-alpha frames; mouth aligned at x282 y48")
	quit()
