class_name BossFishingFight
extends FishingFight
## Same hold/release input, isolated from normal fish. No QTE or extra controls.
enum Action { HEAVY, SURGE, DIVE }
var boss_phase: int = 1
var action: Action = Action.HEAVY
var telegraph_started: bool = false
var depth_offset: float = 0.0
var _action_index: int = 0

func start(fish_profile: FishFightProfile, reel_speed: float = 1.0, rod_capacity_cm: float = 180.0, size_cm: float = 0.0) -> void:
	super.start(fish_profile,reel_speed,rod_capacity_cm,size_cm)
	# The required deep rod supplies a forgiving baseline even with an old reel.
	# Lv4/5 retain their full advantage; no extra equipment purchase is mandatory.
	reel_multiplier = maxf(reel_multiplier,1.3)
	boss_phase = 1
	action = Action.HEAVY
	_action_index = 0
	depth_offset = 0
	telegraph_started = false

func step(delta: float) -> void:
	run_started = false
	telegraph_started = false
	danger_entered = false
	if profile == null or failure != "" or landed:
		return
	elapsed += delta
	var ratio := stamina / profile.max_stamina
	boss_phase = 1 if ratio > 0.7 else (2 if ratio > 0.3 else 3)
	_resistance_timer -= delta
	if _resistance_timer <= 0 and stamina > 0:
		match resistance:
			Resistance.CALM:
				action = Action.HEAVY if boss_phase == 1 else (Action.DIVE if boss_phase == 2 and _action_index % 2 == 1 else Action.SURGE)
				resistance = Resistance.WARNING
				_resistance_timer = profile.run_warning_seconds
				telegraph_started = true
			Resistance.WARNING:
				resistance = Resistance.RUN
				_resistance_timer = 1.5 if action == Action.DIVE else (0.7 if boss_phase == 3 else profile.run_duration)
				run_started = true
				_action_index += 1
			Resistance.RUN:
				resistance = Resistance.CALM
				_resistance_timer = 2.2 if boss_phase == 3 else (3.2 if boss_phase == 2 else profile.run_interval)
	if stamina <= 0:
		resistance = Resistance.CALM
	var running := resistance == Resistance.RUN
	var diving := running and action == Action.DIVE
	depth_offset = move_toward(depth_offset,4.0 if diving else 0.0,delta * (3.0 if diving else 2.5))
	var power := 28.0 if action == Action.HEAVY else (32.0 if diving else profile.run_power)
	if reeling:
		tension += (profile.pull_power + (32.0 if tension < 20 else 0.0) + (power if running else 0.0)) * delta
		fish_distance -= profile.reel_progress_speed * reel_multiplier * (0.3 if running else 1.0) * delta
	else:
		tension -= (36.0 - (9.0 if running else 0.0)) * delta
		if running:
			fish_distance += 0.10 * delta
	if diving:
		fish_distance += 0.14 * delta
	tension = clampf(tension,0,100)
	fish_distance = clampf(fish_distance,0,1.15)
	if reeling:
		var efficiency := 0.1 if tension < 20 else (1.05 if tension >= 70 else 1.0)
		stamina = maxf(0,stamina-profile.stamina_drain * reel_multiplier * efficiency * (0.3 if running else 1.0) * delta)
	break_time = break_time + delta if tension >= 98 else 0.0
	slack_time = slack_time + delta if tension <= 8 else 0.0
	if break_time >= break_grace:
		failure = "LINE BREAK"
	elif slack_time >= slack_grace:
		failure = "ESCAPED"
	elif stamina <= 0 and fish_distance <= 0:
		landed = true
	danger_entered = tension >= 90 and not _was_danger
	_was_danger = tension >= 90

func action_hint() -> String:
	if resistance == Resistance.WARNING:
		return "DIVE SOON" if action == Action.DIVE else "PULL SOON"
	if resistance == Resistance.RUN:
		return "DIVE / RELEASE" if action == Action.DIVE else ("PULL / RELEASE" if action == Action.HEAVY else "SURGE / RELEASE")
	return "RELEASE" if tension >= 70 else "HOLD REEL"
