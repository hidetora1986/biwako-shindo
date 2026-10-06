class_name MysteriousSketch
extends Control
## Presentation only: an unfinished record, without a canonical interpretation.
const TEXTURE := preload("res://assets/story/main_ending_mysterious_sketch.png")
const CARDS_PATH := "res://data/story/main-ending-sketch-v1.json"
var stage := ""
var stage_elapsed := 0.0
var fade_elapsed := 0.0
var frame := Rect2()
var safe := Rect2()
@onready var art: Control = $Art
@onready var image: TextureRect = $Art/Image
@onready var shade: ColorRect = $Shade
@onready var band: ColorRect = $SubtitleBand
@onready var subtitle: Label = $SubtitleBand/Subtitle

func _ready() -> void:
	var font := FontVariation.new()
	font.base_font = preload("res://assets/fonts/NotoSansJP.ttf")
	font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"):500.0}
	subtitle.add_theme_font_override("font",font)
	subtitle.add_theme_font_size_override("font_size",18)
	subtitle.add_theme_constant_override("line_spacing",0)
	subtitle.add_theme_color_override("font_color",Color("fffdf2"))
	image.texture = TEXTURE
	visible = false

func configure(view_size: Vector2, safe_area: Rect2) -> void:
	size = view_size;safe = safe_area
	frame = Rect2(Vector2((size.x-minf(size.x,size.y*16/9))/2,0),Vector2(minf(size.x,size.y*16/9),size.y))
	art.position = frame.position;art.size = frame.size
	shade.size = size
	band.position = Vector2(0,size.y*0.8);band.size = Vector2(size.x,size.y*0.2)
	var left := maxf(frame.position.x+16,safe.position.x)
	var right := minf(frame.end.x-16,safe.end.x)
	subtitle.position = Vector2(left,0)
	subtitle.size = Vector2(maxf(1,right-left),minf(size.y-6,safe.end.y)-band.position.y)
	_camera();queue_redraw()

func show_card(page: Dictionary) -> void:
	var next: String = page.stage
	if next != stage:
		stage = next;stage_elapsed = 0;fade_elapsed = 0
	subtitle.text = page.text
	visible = true
	image.visible = stage in ["sketch","fade"]
	band.visible = not subtitle.text.is_empty()
	_camera();queue_redraw()

func step(delta: float) -> void:
	if not visible:return
	stage_elapsed += delta;fade_elapsed = minf(0.5,fade_elapsed+delta)
	_camera();queue_redraw()

func _camera() -> void:
	if image == null:return
	# Hold the complete spread for one second, then slowly approach the contours.
	var amount := 1.0 if stage == "fade" else clampf((stage_elapsed-1)/3,0,1)
	var zoom := lerpf(1.0,1.065,amount)
	image.size = frame.size*zoom
	image.position = ((frame.size-image.size)*0.5-Vector2(8,0)*amount).round()
	image.modulate.a = 1.0 if stage == "fade" else clampf(fade_elapsed/0.5,0,1)
	shade.color.a = minf(1,stage_elapsed/0.6) if stage == "fade" else (1-clampf(fade_elapsed/0.5,0,1)) if stage == "lake" else 0

func finish() -> void:
	visible = false;stage = "";image.visible = false

func _draw() -> void:
	if not visible:return
	if stage in ["sketch","fade"]:
		# Wide screens retain the spread's composition, with quiet side mattes.
		draw_rect(Rect2(Vector2.ZERO,size),Color("283231"))
	elif stage in ["record","turn"]:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.12,0.17,0.17,0.86))
		var center := frame.get_center()-Vector2(0,size.y*0.08)
		var spread := Rect2(center-Vector2(frame.size.x*0.4,size.y*0.3),Vector2(frame.size.x*0.8,size.y*0.6))
		draw_rect(spread,Color("c7b993"))
		draw_rect(spread.grow(-5),Color("ddd1ac"))
		draw_line(Vector2(center.x,spread.position.y+5),Vector2(center.x,spread.end.y-5),Color("968970"),3)
		for row in range(6):
			var y := spread.position.y+24+row*22
			draw_line(Vector2(spread.position.x+18,y),Vector2(center.x-20-row%3*17,y+1),Color(0.35,0.37,0.32,0.22),1)
		if stage == "turn":
			var width := spread.size.x*0.5*absf(cos(clampf(stage_elapsed/0.6,0,1)*PI))
			draw_rect(Rect2(Vector2(center.x-width,spread.position.y),Vector2(maxf(2,width),spread.size.y)),Color("e5d9b4"))
