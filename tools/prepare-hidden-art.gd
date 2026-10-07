extends SceneTree
## Offline nearest-neighbor format conversion only; high-resolution source excluded from export.
func _initialize() -> void:
	var image := Image.load_from_file("res://assets/visual/hidden/no00/source/unbounded-source.png")
	assert(image != null)
	image.convert(Image.FORMAT_RGBA8)
	# Match the existing 136/360 gameplay waterline without moving game objects.
	var world := Image.create(640,360,false,Image.FORMAT_RGBA8)
	var sky := image.get_region(Rect2i(0,0,image.get_width(),273))
	var water := image.get_region(Rect2i(0,273,image.get_width(),image.get_height()-273))
	sky.resize(640,136,Image.INTERPOLATE_NEAREST)
	water.resize(640,224,Image.INTERPOLATE_NEAREST)
	world.blit_rect(sky,Rect2i(Vector2i.ZERO,sky.get_size()),Vector2i.ZERO)
	world.blit_rect(water,Rect2i(Vector2i.ZERO,water.get_size()),Vector2i(0,136))
	image = world
	assert(image.get_pixel(320,230).a == 1.0 and image.get_pixel(160,20).b > 0.01)
	assert(image.save_png("res://assets/visual/hidden/no00/unbounded-surface.png") == OK)
	print("Prepared No.00 640x360 surface fragment; no creature silhouette")
	quit()
