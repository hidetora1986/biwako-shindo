extends "res://tests/phase2_acceptance.gd"
## Real scene/input tests and repeatable timing checks for five temporary profiles.

var _fight_times: Dictionary = {}

func _start_fight(species: String = "bass") -> bool:
	if not _flow.request_cast() or not _until_bite():
		return false
	_flow.active_fish.fight_profile = load("res://data/fish/%s-fight.tres" % species)
	if not _flow.request_hook():
		return false
	_step(0.32)
	return _flow.state == FLOW.State.FIGHTING

func _run() -> void:
	root.size = Vector2i(1280, 720)
	_new_scene()
	await process_frame
	await process_frame
	_check(not _hud.get_node("ReelButton").visible and not _hud.get_node("FightHUD").visible and not _flow.set_reeling(true), "Idle: fight UI hidden and REEL ignored")
	_check(_start_fight(), "FIGHTING: CAST -> HIT starts a fight, no Phase 2 reset")
	var fish: FishController = _flow.active_fish
	var node_count := get_node_count()
	var reel_center: Vector2 = _hud.get_node("ReelButton").get_global_rect().get_center()
	_check(_hud.get_node("ReelButton").visible and _hud.get_node("FightHUD").visible and not _flow.request_cast() and not _flow.request_hook(), "Fight: REEL/UI shown, CAST and re-hook blocked")
	_touch(reel_center, 3)
	var tension_before: float = _flow.fight.tension
	var stamina_before: float = fish.stamina
	var distance_before: float = _flow.fight.fish_distance
	_step(0.5)
	_check(_flow.fight.reeling and _hud.get_node("ReelButton").button_pressed, "Long Press: finger owns REEL and button stays pressed")
	_check(_flow.fight.tension > tension_before, "Tension Increase: hold raises tension")
	_check(fish.stamina < stamina_before and _flow.fight.stamina == fish.stamina, "SAFE Zone: holding drains owned fish stamina")
	_check(_flow.fight.fish_distance < distance_before, "REEL: fish gets closer")
	_touch(reel_center, 7)
	_touch(Vector2(1, 1), 7, false)
	_mouse(reel_center, false)
	_check(_flow.fight.reeling and _flow._reel_owner == 3, "Multitouch: other fingers/emulated mouse cannot release the owner")
	_touch(Vector2(1, 1), 3, false)
	tension_before = _flow.fight.tension
	_step(0.3)
	_check(not _flow.fight.reeling and not _hud.get_node("ReelButton").button_pressed, "Release: lift anywhere stops REEL")
	_check(_flow.fight.tension < tension_before, "Tension Recovery: released line recovers")
	stamina_before = fish.stamina
	_step(0.2)
	_check(is_equal_approx(stamina_before, fish.stamina), "Stamina: no drain without REEL")
	_mouse(reel_center)
	_step(0.2)
	_check(_flow.fight.reeling, "PC: mouse left hold reels")
	_mouse(Vector2(1, 1), false)
	_check(not _flow.fight.reeling, "PC: release outside button stops REEL")
	_touch(reel_center, 4)
	var drag := InputEventScreenDrag.new()
	drag.index = 4
	drag.position = Vector2(1, 1)
	root.push_input(drag, true)
	_check(not _flow.fight.reeling, "Touch: dragging off REEL cancels hold")
	_touch(reel_center, 5)
	_flow._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(not _flow.fight.reeling and _flow._reel_owner == -1, "Focus Loss: never leaves a stuck REEL")
	var rod_idle: Vector2 = _boat.position + Vector2(-40, -40)
	_flow.fight.tension = 80
	_step(1.0 / 60.0)
	_check(_boat.rod_tip_position().y > rod_idle.y and _flow.line.default_color.r > 0.8, "Visual Pull: bent rod and warmer HIGH line")
	# Continuous slack is generous; brief release avoids breaking at 100.
	_new_scene()
	_check(_start_fight(), "Failure fixture starts through normal fishing")
	_flow.fight.tension = 98
	reel_center = _hud.get_node("ReelButton").get_global_rect().get_center()
	_touch(reel_center, 0)
	_step(0.55)
	_check(_flow.state == FLOW.State.FIGHTING and _flow.fight.tension == 100, "Line Break: reaching 100 is not an instant failure")
	_touch(reel_center, 0, false)
	_step(0.1)
	_check(_flow.state == FLOW.State.FIGHTING and _flow.fight.break_time == 0.0, "Line Break: prompt release rescues the line")
	_flow.fight.tension = 98
	_touch(reel_center, 0)
	_step(0.8)
	_check(_flow.state == FLOW.State.FAILED and _hud.get_node("Result").text == "LINE BREAK", "Line Break: sustained risk fails with visible feedback")
	_check(not _flow.set_reeling(true) and not _flow.request_cast() and not _flow.request_hook() and _flow.active_fish == null and not _flow.line.visible, "Failed: REEL/CAST/hook blocked, fish escapes")
	_touch(reel_center, 0, false)
	_step(1.6)
	_check(_flow.state == FLOW.State.READY and not _hud.get_node("FightHUD").visible, "Failure Reset: about 1.5s to CAST-ready")
	_check(_start_fight(), "Escape fixture starts through normal fishing")
	_step(5.0)
	_check(_flow.state == FLOW.State.FIGHTING, "LOW: several seconds of release are forgiven")
	_step(1.2)
	_check(_flow.state == FLOW.State.FAILED and _hud.get_node("Result").text == "ESCAPED", "Escape: long continuous slack loses the fish")
	_step(1.6)
	_check(_flow.state == FLOW.State.READY, "Escape Reset: CAST restored")
	# RUN has a warning before the extra pull and the retreat/recovery tradeoff.
	_new_scene()
	_check(_start_fight(), "RUN fixture starts")
	_flow.set_reeling(true)
	_step(1.92)
	_check(_flow.fight.resistance == FishingFight.Resistance.WARNING and _hud.get_node("FightHUD").resistance == FishingFight.Resistance.WARNING, "RUN Warning: 0.5s visible warning before the run")
	_step(0.52)
	_check(_flow.fight.resistance == FishingFight.Resistance.RUN and _flow.active_fish.state == FishController.SwimState.RUN, "Fish Run: enters resistance state")
	distance_before = _flow.fight.fish_distance
	tension_before = _flow.fight.tension
	var before_x: float = _flow.active_fish.position.x
	_flow.set_reeling(false)
	_step(0.2)
	_check(_flow.fight.fish_distance > distance_before and _flow.active_fish.position.x < before_x and _flow.active_fish.sprite.flip_h, "RUN: release gives back distance and fish visibly runs away")
	_check(_flow.fight.tension < tension_before, "RUN: release still recovers line tension")
	# Physical scale, notch-safe layouts and resize while a finger is held.
	for spec in [[1280, 720, "16:9"], [1560, 720, "19.5:9"], [1600, 720, "20:9"], [320, 180, "320px"]]:
		root.size = Vector2i(spec[0], spec[1])
		_new_scene()
		await process_frame
		await process_frame
		_check(_start_fight(), spec[2] + ": fight starts")
		_hud.layout_in_safe_area(_lake.view_size, Rect2(36, 8, _lake.view_size.x - 72, _lake.view_size.y - 24), _lake.surface_y, 15)
		var ui_ok := true
		for node_name in ["ReelButton", "FightHUD", "CatchPanel", "Result"]:
			ui_ok = ui_ok and _hud.safe_rect.encloses(_hud.get_node(node_name).get_global_rect())
		var button: Button = _hud.get_node("ReelButton")
		var physical_height: float = button.size.y * float(spec[1]) / _lake.view_size.y
		_check(ui_ok and physical_height >= 44.0 and not button.get_global_rect().intersects(_hud.get_node("FightHUD").get_global_rect()), spec[2] + ": readable fight/catch UI, nonoverlapping 44px+ REEL")
		_touch(button.get_global_rect().get_center(), 8)
		_step(0.25)
		_check(_flow.fight.reeling, spec[2] + ": touch hold works")
		var preserved: float = _flow.fight.stamina
		root.size = Vector2i(1560 if spec[0] == 1280 else 1280, 720)
		await process_frame
		await process_frame
		_check(_flow.state == FLOW.State.FIGHTING and is_equal_approx(preserved, _flow.fight.stamina) and _flow.line.get_point_position(1).is_equal_approx(_flow.lure.position), spec[2] + ": resize preserves fight and line")
		_touch(Vector2(1, 1), 8, false)
		_check(not _flow.fight.reeling, spec[2] + ": finger releases after resize")
	# Five uninterrupted sessions with each temporary fish profile, real catch/reset.
	root.size = Vector2i(1280, 720)
	_new_scene()
	await process_frame
	node_count = get_node_count()
	var repeated_ok := true
	for species in ["bluegill", "crucian", "bass", "biwamasu", "catfish"]:
		repeated_ok = repeated_ok and _start_fight(species)
		var owned_fish: FishController = _flow.active_fish
		var profile: FishFightProfile = owned_fish.fight_profile
		var size: float = owned_fish.size_cm
		var holding := true
		for tick in range(1200):
			if _flow.state != FLOW.State.FIGHTING:
				break
			if _flow.fight.resistance == FishingFight.Resistance.RUN or _flow.fight.tension >= 76:
				holding = false
			elif _flow.fight.resistance != FishingFight.Resistance.RUN and _flow.fight.tension <= 45:
				holding = true
			_flow.set_reeling(holding)
			_step(1.0 / 60.0)
		_fight_times[species] = _flow.fight.elapsed
		_check(_flow.state == FLOW.State.LANDING and _flow.fight.stamina == 0 and _flow.fight.fish_distance <= 0.08 and not _flow.set_reeling(true), species + ": stamina and distance jointly trigger landing, REEL locked")
		var landing_y: float = owned_fish.position.y
		_step(0.25)
		_check(owned_fish.position.y < landing_y, species + ": fish lifts toward the surface")
		_step(0.25)
		_check(_flow.state == FLOW.State.LANDING and _flow.lure.splash_remaining > 0 and not _hud.get_node("CatchPanel").visible, species + ": landing splash is visible before the result")
		_step(0.2)
		_check(_flow.state == FLOW.State.LANDED and _hud.get_node("CatchPanel").visible and _hud.get_node("CatchPanel/Banner").text == "CATCH!" and _hud.get_node("CatchPanel/Fish").texture != null, species + ": CATCH shows the actual fish")
		_check(_flow.last_catch["name"] == profile.display_name and is_equal_approx(_flow.last_catch["size_cm"], size) and size >= profile.size_min_cm and size <= profile.size_max_cm and _hud.get_node("CatchPanel/Size").text == "%.1f cm" % size, species + ": catch name and retained size are correct")
		_check(not _flow.request_cast() and not _flow.request_hook() and not _flow.set_reeling(true), species + ": result rejects all fishing inputs")
		_step(1.22)
		_check(_flow.state == FLOW.State.LANDED, species + ": catch card stays for about 1.5s")
		_step(0.28)
		_check(_flow.state == FLOW.State.RESET and not _flow.request_cast(), species + ": resetting locks CAST")
		_step(0.23)
		repeated_ok = repeated_ok and _flow.state == FLOW.State.READY and owned_fish.visible and owned_fish.state in [FishController.SwimState.SWIM, FishController.SwimState.TURN]
	_check(repeated_ok and get_node_count() == node_count and _fishes.size() == 7, "Repeated Loop: five CAST/HIT/FIGHT/CATCH/CAST sessions, stable nodes and fish")
	_check(_flow.progress.money > 0 and _hud.get_node("Money/Label").text == "¥" + _hud._format_money(_flow.progress.money) and not _hud.get_node("ReelButton").visible, "Phase 4: auto-sale wallet is retained and fight HUD hides after reset")
	var ranges := {"bluegill": Vector2(2, 4), "crucian": Vector2(3, 5), "bass": Vector2(4, 7), "biwamasu": Vector2(5, 8), "catfish": Vector2(6, 10)}
	for species: String in ranges:
		_check(_fight_times[species] >= ranges[species].x and _fight_times[species] <= ranges[species].y, species + ": short target fight time")
	# Boundary behavior and the performance/safety contract of the pure model.
	var model := FishingFight.new()
	model.start(load("res://data/fish/bass-fight.tres"))
	for value in [[0, "LOW"], [20, "SAFE"], [70, "HIGH"], [90, "BREAK RISK"]]:
		model.tension = value[0]
		_check(model.tension_zone() == value[1], "Tension: " + value[1] + " boundary")
	model.tension = 50
	model.reeling = false
	var stamina: float = model.stamina
	model.step(0.2)
	_check(model.stamina == stamina, "Model: release never drains stamina")
	model.tension = 25
	model.reeling = true
	model.step(0.2)
	_check(model.stamina < stamina, "Model: SAFE REEL efficiently drains stamina")
	model.start(load("res://data/fish/bass-fight.tres"))
	model.stamina = 0
	model.fish_distance = 0.5
	model.step(0.05)
	_check(not model.landed, "Landing: zero stamina alone is insufficient")
	model.stamina = 10
	model.fish_distance = 0.02
	model.step(0.05)
	_check(not model.landed, "Landing: proximity alone is insufficient")
	model.stamina = 0
	model.step(0.05)
	_check(model.landed, "Landing: both conditions are required")
	model.start(load("res://data/fish/bass-fight.tres"))
	model.tension = 0
	model.reeling = true
	model.step(0.2)
	var low_drain: float = model.profile.max_stamina - model.stamina
	model.start(load("res://data/fish/bass-fight.tres"))
	model.tension = 30
	model.reeling = true
	model.step(0.2)
	_check(model.profile.max_stamina - model.stamina > low_drain * 5, "SAFE Zone: stamina drain greatly exceeds LOW")
	# Defined reaction delays assess forgiving tuning, not a claim about human success.
	var guided_catches := 0
	var guided_sessions := 0
	var longest_guided := 0.0
	for species: String in ranges:
		for reaction_delay in [0.3, 0.6, 1.0, 1.4]:
			model.start(load("res://data/fish/%s-fight.tres" % species))
			var guided_hold := true
			var reaction_timer := 0.0
			for tick in range(1200):
				if model.landed or model.failure != "":
					break
				if guided_hold and (model.resistance == FishingFight.Resistance.RUN or model.tension >= 78):
					reaction_timer += 1.0 / 60.0
					if reaction_timer >= reaction_delay:
						guided_hold = false
				elif not guided_hold and model.resistance != FishingFight.Resistance.RUN and model.tension <= 45:
					guided_hold = true
					reaction_timer = 0.0
				model.reeling = guided_hold
				model.step(1.0 / 60.0)
			guided_sessions += 1
			if model.landed:
				guided_catches += 1
			longest_guided = maxf(longest_guided, model.elapsed)
	_check(float(guided_catches) / guided_sessions >= 0.8 and longest_guided < 15.0, "Easy Tuning: delayed release policies usually catch without long fights")
	print("PHASE3_ACCEPTANCE ", JSON.stringify({"result": "PASS" if _failures.is_empty() else "FAIL", "checks": _checks, "failures": _failures, "consecutive_catches": 5, "fight_seconds": _fight_times, "guided_catches": guided_catches, "guided_sessions": guided_sessions, "longest_guided_s": longest_guided}))
	_main.queue_free()
	await process_frame
	quit(0 if _failures.is_empty() else 1)
