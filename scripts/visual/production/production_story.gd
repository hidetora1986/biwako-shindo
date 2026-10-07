class_name ProductionStory
extends RefCounted
## Existing scene timing/text/progression untouched; replaces only the presentation surface.
const SKETCH:=preload("res://assets/visual/v2/story/mysterious-sketch.png")
const JOURNAL:=preload("res://assets/opening/journal.tres")
const MOORING:=preload("res://assets/opening/decision.tres")
static func caption(story:NarrativeScreen) -> void:
	if story.mode=="opening" and not story.credits:return
	story.panel.size=Vector2(minf(540,story.safe.size.x),96)
	story.panel.position=Vector2(story.safe.get_center().x-story.panel.size.x/2,story.safe.end.y-100)
	story.heading.position=Vector2(12,6);story.heading.size=Vector2(story.panel.size.x-24,24)
	story.text.position=Vector2(16,30);story.text.size=Vector2(story.panel.size.x-32,62)
	var style:=StyleBoxFlat.new();style.bg_color=Color(0.025,.05,.07,.78)
	story.panel.add_theme_stylebox_override("panel",style)
	story.text.add_theme_color_override("font_color",Color("e0eee1"));story.heading.add_theme_color_override("font_color",Color("c4d3c9"))
	ProductionSkin.button(story.skip_button)
static func paint(story:NarrativeScreen) -> void:
	if not story.active or (story.mode=="opening" and not story.credits):return
	var journal:bool=not story.credits and ((story.mode=="main" and story.section==1) or (story.mode=="cut" and story.section==1))
	var sketch:bool=not story.credits and ((story.mode=="main" and story.section==3) or (story.mode=="contact" and story.section==0))
	if sketch or journal:
		var texture:Texture2D=SKETCH if sketch else JOURNAL
		story.draw_texture_rect(texture,Rect2(Vector2.ZERO,story.size),false)
		story.draw_rect(Rect2(Vector2.ZERO,story.size),Color(0.03,.025,.02,.06))
	elif not story.credits and story.mode=="cut" and story.section>=2:
		story.draw_texture_rect(MOORING,Rect2(Vector2.ZERO,story.size),false)
	# Credits are intentionally quiet over the same dawn lake, not a new ending.
static func book_sketch(book:Control) -> void:
	var photo:=TextureRect.new();photo.texture=JOURNAL;photo.custom_minimum_size=Vector2(0,132);photo.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	photo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;photo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;photo.mouse_filter=Control.MOUSE_FILTER_IGNORE
	book.journal_scroll.get_child(0).add_child(photo);book.journal_scroll.get_child(0).move_child(photo,0)
	var entry:RichTextLabel=book.journal_entries["last"]
	entry.custom_minimum_size.y=216
	var texture:=TextureRect.new();texture.name="LastPageSketch";texture.texture=SKETCH
	texture.position=Vector2(0,35);texture.size=Vector2(420,168)
	texture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;texture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;texture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	entry.add_child(texture)
