class_name FishingFight
extends RefCounted
## Small deterministic fight model. Controller owns transitions and fish pose.

enum Resistance { CALM, WARNING, RUN }
var profile: FishFightProfile
var tension: float = 30.0
var stamina: float = 0.0
var fish_distance: float = 1.0
var reeling: bool = false
var resistance: Resistance = Resistance.CALM
var elapsed: float = 0.0
var break_time: float = 0.0
var slack_time: float = 0.0
var failure: String = ""
var landed: bool = false
var run_started: bool = false
var danger_entered: bool = false
var break_grace: float = 0.65
var slack_grace: float = 5.5
var _resistance_timer: float = 0.0
var _was_danger: bool = false

var reel_multiplier: float = 1.0
var rod_load: float = 1.0

func start(fish_profile: FishFightProfile, reel_speed: float = 1.0, rod_capacity_cm: float = 180.0, size_cm: float = 0.0) -> void:
	profile = fish_profile
	reel_multiplier = reel_speed
	# Oversized normal fish stay catchable: rod capacity is gentle extra pull.
	rod_load = 1.0 + clampf((size_cm / maxf(rod_capacity_cm, 1.0) - 1.0) * 0.15, 0.0, 0.12)
	tension = 30.0
	stamina = profile.max_stamina
	fish_distance = 1.0
	reeling = false
	resistance = Resistance.CALM
	elapsed = 0.0
	break_time = 0.0
	slack_time = 0.0
	failure = ""
	landed = false
	_was_danger = false
	_resistance_timer = profile.run_interval

func step(delta: float) -> void:
	run_started = false
	danger_entered = false
	if profile == null or failure != "" or landed:
		return
	elapsed += delta
	_resistance_timer -= delta
	if _resistance_timer <= 0.0 and stamina > 0.0:
		match resistance:
			Resistance.CALM:
				resistance = Resistance.WARNING
				_resistance_timer = 0.5
			Resistance.WARNING:
				resistance = Resistance.RUN
				_resistance_timer = profile.run_duration
				run_started = true
			Resistance.RUN:
				resistance = Resistance.CALM
				_resistance_timer = profile.run_interval
	if stamina <= 0.0:
		resistance = Resistance.CALM
	var running := resistance == Resistance.RUN
	if reeling:
		tension += (profile.pull_power * rod_load + (32.0 if tension < 20.0 else 0.0) + (profile.run_power if running else 0.0)) * delta
		fish_distance -= profile.reel_progress_speed * reel_multiplier * (0.35 if running else 1.0) * delta
	else:
		tension -= (42.0 - (profile.pull_power * 0.65 if running else 0.0)) * delta
		if running:
			fish_distance += 0.12 * delta
	tension = clampf(tension, 0.0, 100.0)
	fish_distance = clampf(fish_distance, 0.0, 1.15)
	if reeling:
		var efficiency := 0.12 if tension < 20.0 else (1.1 if tension >= 70.0 else 1.0)
		stamina = maxf(0.0, stamina - profile.stamina_drain * reel_multiplier * efficiency * (0.4 if running else 1.0) * delta)
	break_time = break_time + delta if tension >= 98.0 else 0.0
	slack_time = slack_time + delta if tension <= 8.0 else 0.0
	if break_time >= break_grace:
		failure = "LINE BREAK"
	elif slack_time >= slack_grace:
		failure = "ESCAPED"
	elif stamina <= 0.0 and fish_distance <= 0.08:
		landed = true
	danger_entered = tension >= 90.0 and not _was_danger
	_was_danger = tension >= 90.0

func tension_zone() -> String:
	if tension < 20.0:
		return "LOW"
	if tension < 70.0:
		return "SAFE"
	if tension < 90.0:
		return "HIGH"
	return "BREAK RISK"
