class_name OpeningCinematic
extends Control
## Image-only presentation. NarrativeScreen owns input, completion flag and Save.
@export var backgrounds: Array[Texture2D] = []
const FADE_SECONDS := 0.5
var script_data: Dictionary
var scene_index := -1
var scene_elapsed := 0.0
var scene_seconds := 1.0
var fade_elapsed := 0.0
var transitioning := false
var displayed_text := ""
var frame := Rect2()
var safe := Rect2()
var _font: Font = preload("res://assets/fonts/NotoSansJP.ttf")
@onready var art: Control = $Art
@onready var previous: TextureRect = $Art/Previous
@onready var current: TextureRect = $Art/Current
@onready var shade: ColorRect = $Shade
@onready var subtitle_band: ColorRect = $SubtitleBand
@onready var subtitle: Label = $SubtitleBand/Subtitle

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	script_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/opening-cinematic-v1.json"))
	var caption_font := FontVariation.new()
	caption_font.base_font = _font
	caption_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"):500.0}
	subtitle.add_theme_font_override("font",caption_font)
	subtitle.add_theme_font_size_override("font_size",18)
	subtitle.add_theme_constant_override("line_spacing",0)
	subtitle.add_theme_color_override("font_color",Color("fffdf2"))
	visible = false

func configure(view_size: Vector2, safe_area: Rect2) -> void:
	size = view_size;safe = safe_area
	# Protect the composition on tall-aspect phones; only quiet side mattes expand.
	frame = Rect2(Vector2((size.x-minf(size.x,size.y*16/9))/2,0),Vector2(minf(size.x,size.y*16/9),size.y))
	art.position = frame.position;art.size = frame.size
	shade.size = size
	var band_height := size.y * 0.20
	subtitle_band.position = Vector2(0,size.y-band_height)
	subtitle_band.size = Vector2(size.x,band_height)
	var left := maxf(frame.position.x+16,safe.position.x)
	var right := minf(frame.end.x-16,safe.end.x)
	var bottom := minf(size.y-6,safe.end.y)
	subtitle.position = Vector2(left,0)
	subtitle.size = Vector2(maxf(1,right-left),bottom-subtitle_band.position.y)
	_camera()

func show_card(index: int) -> void:
	var card: Dictionary = script_data.cards[index]
	displayed_text = card.text;subtitle.text = displayed_text
	var next_scene := int(card.scene)
	if next_scene != scene_index:
		previous.texture = current.texture
		previous.position = current.position;previous.size = current.size
		previous.visible = scene_index >= 0
		scene_index = next_scene;scene_elapsed = 0;scene_seconds = 0
		for entry: Dictionary in script_data.cards:
			if int(entry.scene) == scene_index:scene_seconds += float(entry.seconds)
		current.texture = backgrounds[scene_index]
		fade_elapsed = 0;transitioning = true
	visible = true
	_camera();_fade()

func step(delta: float) -> void:
	if not visible:return
	scene_elapsed = minf(scene_seconds,scene_elapsed+delta)
	if transitioning:
		fade_elapsed = minf(FADE_SECONDS,fade_elapsed+delta)
		if fade_elapsed >= FADE_SECONDS:
			transitioning = false;previous.visible = false
	_camera();_fade()

func _camera() -> void:
	if current == null or frame.size.y <= 0:return
	var fraction := clampf(scene_elapsed/maxf(0.01,scene_seconds),0,1)
	var zoom := lerpf(1.035,1.075,fraction)
	current.size = frame.size*zoom
	var drift := Vector2(lerpf(-3,3,fraction),lerpf(2,-2,fraction))
	current.position = ((frame.size-current.size)*0.5+drift).round()

func _fade() -> void:
	var alpha := clampf(fade_elapsed/FADE_SECONDS,0,1)
	current.modulate.a = alpha
	shade.color.a = (1-alpha)*0.65 if scene_index == 0 and transitioning else 0
	# Title stays in the lower band; a short, gentle darkening prepares the lake.
	if displayed_text == "――琵琶湖深度":shade.color.a = 0.28

func finish() -> void:
	visible = false;current.texture = null;previous.texture = null
	previous.visible = false;scene_index = -1;transitioning = false
