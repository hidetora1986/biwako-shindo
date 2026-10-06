extends Node2D
## Raster presentation pack. Original lake layers stay available outside the golden view.
const LAYERS := [preload("res://assets/visual/golden/south_shore/sky/Sky.tres"),preload("res://assets/visual/golden/south_shore/mountains/FarMountains.tres"),preload("res://assets/visual/golden/south_shore/mountains/MiddleMountains.tres"),preload("res://assets/visual/golden/south_shore/shore/NearShore.tres"),preload("res://assets/visual/golden/south_shore/water/Surface.tres"),preload("res://assets/visual/golden/south_shore/water/Underwater.tres"),preload("res://assets/visual/golden/south_shore/lakebed/LakeBed.tres")]
const NAMES := ["Sky","FarMountains","MiddleMountains","NearShore","Surface","Underwater","LakeBed"]
var layers: Array[Sprite2D] = []
func _ready() -> void:
	for i in range(LAYERS.size()):
		var sprite := Sprite2D.new();sprite.name = NAMES[i]
		sprite.texture = LAYERS[i];sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite);layers.append(sprite)
func configure(view_size: Vector2, surface: float) -> void:
	# Above/below are independently fitted to the existing depth cutaway boundary.
	for i in range(layers.size()):
		var region: Rect2 = LAYERS[i].region
		var above := region.position.y < 357
		var sy := surface/357.0 if above else (view_size.y-surface)/584.0
		layers[i].position = Vector2(0,region.position.y*sy if above else surface+(region.position.y-357)*sy)
		layers[i].scale = Vector2(view_size.x/1672.0,sy)
