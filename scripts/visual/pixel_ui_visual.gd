extends Node
## Presentation-only adapter. Existing labels, signals, inputs and modal state stay intact.
const PIXEL_THEME := preload("res://assets/ui/pixel_theme.tres")
var _icons: Dictionary = {}
var _unknown: Texture2D

func _ready() -> void:
	call_deferred("_decorate")

func _decorate() -> void:
	var hud: Control = get_parent()
	hud.theme = PIXEL_THEME
	for modal_name in ["Shop", "FishBook"]:
		var modal: Control = hud.get_node(modal_name)
		modal.theme = PIXEL_THEME
		modal.get_node("Panel").add_theme_stylebox_override("panel", PIXEL_THEME.get_stylebox("panel", "Panel"))
		modal.get_node("Panel/Title").add_theme_color_override("font_color", Color("d7e6d9"))
		modal.get_node("Panel/Wallet").add_theme_color_override("font_color", Color("9ec2c0"))
	var book: Control = hud.get_node("FishBook")
	var image := RefinedPixelArt.fish_texture("bass").get_image()
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0:
				image.set_pixel(x, y, Color("527989"))
	_unknown = ImageTexture.create_from_image(image)
	for fish: FishFightProfile in GameProgress.FISH_PROFILES:
		var label: Label = book.entries[fish.id]
		var index := label.get_index()
		var rows: VBoxContainer = label.get_parent()
		var card := PanelContainer.new()
		card.name = fish.species_id.capitalize() + "Card"
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rows.add_child(card)
		rows.move_child(card, index)
		var content := HBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_theme_constant_override("separation", 12)
		card.add_child(content)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(70, 44)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(icon)
		label.reparent(content)
		_icons[fish.id] = icon
	book.progress.changed.connect(_refresh_icons)
	_refresh_icons()
	# Shop rows retain their geometry and purchase buttons; give each a card surface.
	var shop: Control = hud.get_node("Shop")
	for category: String in shop._labels:
		var label: Label = shop._labels[category]
		label.add_theme_stylebox_override("normal", PIXEL_THEME.get_stylebox("panel", "PanelContainer"))

	ProductionSkin.decorate(hud)

func _refresh_icons() -> void:
	var book: Control = get_parent().get_node("FishBook")
	for fish: FishFightProfile in GameProgress.FISH_PROFILES:
		_icons[fish.id].texture = RefinedPixelArt.fish_frames(fish.species_id).get_frame_texture("swim", 1) if book.progress.fish_records[fish.id].discovered else _unknown
