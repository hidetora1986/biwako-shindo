extends Control
## Lightweight bars; visible only during a fight. No game decisions here.

var tension: float = 30.0
var stamina_fraction: float = 1.0
var resistance: int = 0
var zone: String = "SAFE"
var holding: bool = false
var boss_hint: String = ""

func display(fight: FishingFight) -> void:
	tension = fight.tension
	stamina_fraction = fight.stamina / maxf(fight.profile.max_stamina, 1.0)
	resistance = fight.resistance
	zone = fight.tension_zone()
	holding = fight.reeling
	boss_hint = fight.action_hint() if fight is BossFishingFight else ""
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_style_box(ProductionSkin.panel("instrument"), Rect2(Vector2.ZERO, size))
	var tone := Color("a2dacb").lerp(Color("e7cf7c"), clampf((tension - 45.0) / 40.0, 0.0, 1.0))
	if tension >= 90:
		tone = Color("e7cf7c").lerp(Color("f4e3a3"), clampf((tension - 85.0) / 15.0, 0.0, 1.0))
	elif tension >= 70 or resistance == FishingFight.Resistance.WARNING:
		tone = Color("e7cf7c")
	var hint := "HOLD REEL"
	if resistance == FishingFight.Resistance.WARNING:
		hint = "RUN SOON"
	elif resistance == FishingFight.Resistance.RUN:
		hint = "RUN / RELEASE"
	elif tension >= 70:
		hint = "RELEASE"
	if not boss_hint.is_empty():
		hint = boss_hint
	draw_string(font, Vector2(10, 17), "LINE TENSION", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("cee1d3"))
	draw_string(font, Vector2(size.x - 135, 17), "%s %d" % [zone, int(tension)], HORIZONTAL_ALIGNMENT_RIGHT, 125, 12, tone)
	var bar := Rect2(10, 24, size.x - 20, 9)
	draw_rect(bar, Color("142f39"))
	draw_rect(Rect2(bar.position + Vector2(bar.size.x * 0.2, 0), Vector2(bar.size.x * 0.5, bar.size.y)), Color("385c50"))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * tension / 100.0, bar.size.y)), tone)
	# Crosshatch the risk end, reserving strong red for later horror art.
	if tension >= 90:
		for x in range(int(bar.position.x + bar.size.x * 0.9), int(bar.end.x), 4):
			draw_rect(Rect2(x, bar.position.y + 2, 2, 5), Color("887958"))
	for boundary in [0.2, 0.7, 0.9]:
		draw_line(bar.position + Vector2(bar.size.x * boundary, 0), bar.position + Vector2(bar.size.x * boundary, 9), Color("173639"))
	draw_string(font, Vector2(10, 49), "FISH STAMINA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("cee1d3"))
	draw_string(font, Vector2(size.x - 135, 49), hint, HORIZONTAL_ALIGNMENT_RIGHT, 125, 12, tone)
	draw_rect(Rect2(10, 55, size.x - 20, 6), Color("142f39"))
	draw_rect(Rect2(10, 55, (size.x - 20) * stamina_fraction, 6), Color("9cb9ab"))

var _style: StyleBoxFlat
func _panel() -> StyleBoxFlat:
	if _style == null:
		_style = StyleBoxFlat.new()
		_style.bg_color = Color(0.045, 0.13, 0.20, 0.94)
		_style.border_width_left = 1
		_style.border_width_top = 1
		_style.border_width_right = 1
		_style.border_width_bottom = 1
		_style.border_color = Color("6b9fa6")
	return _style
