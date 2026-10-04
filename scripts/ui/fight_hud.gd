extends Control
## Lightweight bars; visible only during a fight. No game decisions here.

var tension: float = 30.0
var stamina_fraction: float = 1.0
var resistance: int = 0
var zone: String = "SAFE"
var holding: bool = false

func display(fight: FishingFight) -> void:
	tension = fight.tension
	stamina_fraction = fight.stamina / maxf(fight.profile.max_stamina, 1.0)
	resistance = fight.resistance
	zone = fight.tension_zone()
	holding = fight.reeling
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_style_box(_panel(), Rect2(Vector2.ZERO, size))
	var tone := Color("b9d4c8").lerp(Color("e7cf7c"), clampf((tension - 45.0) / 40.0, 0.0, 1.0))
	if tension >= 90:
		tone = Color("e7cf7c").lerp(Color("e17e69"), clampf((tension - 85.0) / 15.0, 0.0, 1.0))
	elif tension >= 70 or resistance == FishingFight.Resistance.WARNING:
		tone = Color("e7cf7c")
	var hint := "HOLD REEL"
	if resistance == FishingFight.Resistance.WARNING:
		hint = "RUN SOON"
	elif resistance == FishingFight.Resistance.RUN:
		hint = "RUN / RELEASE"
	elif tension >= 70:
		hint = "RELEASE"
	draw_string(font, Vector2(10, 17), "LINE TENSION", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("cee1d3"))
	draw_string(font, Vector2(size.x - 135, 17), "%s %d" % [zone, int(tension)], HORIZONTAL_ALIGNMENT_RIGHT, 125, 12, tone)
	var bar := Rect2(10, 24, size.x - 20, 9)
	draw_rect(bar, Color("142f39"))
	draw_rect(Rect2(bar.position + Vector2(bar.size.x * 0.2, 0), Vector2(bar.size.x * 0.5, bar.size.y)), Color("385c50"))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * tension / 100.0, bar.size.y)), tone)
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
		_style.bg_color = Color(0.04, 0.15, 0.19, 0.94)
		_style.border_width_left = 1
		_style.border_width_top = 1
		_style.border_width_right = 1
		_style.border_width_bottom = 1
		_style.border_color = Color("527d73")
	return _style
