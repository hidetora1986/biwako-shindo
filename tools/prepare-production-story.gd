extends SceneTree
## Approved original art, fitted to at most 2x the 640x360 visual budget.
func _initialize() -> void:
	var image:=Image.load_from_file("res://assets/visual/v2/story/source/mysterious-sketch.png")
	var factor:=minf(1280.0/image.get_width(),720.0/image.get_height())
	image.resize(int(image.get_width()*factor),int(image.get_height()*factor),Image.INTERPOLATE_NEAREST)
	assert(image.save_png("res://assets/visual/v2/story/mysterious-sketch.png")==OK)
	print("PRODUCTION_STORY_PACK PASS");quit()
