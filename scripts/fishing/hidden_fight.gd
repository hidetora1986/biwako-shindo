class_name HiddenFishingFight
extends RefCounted
## Survival, never stamina/distance/capture. Deterministic 50s with telegraphed pulls.
var elapsed: float = 0
var tension: float = 35
var boat_pull_depth: float = 0
var phase: int = 1
var reeling: bool = false
var warning: bool = false
var pulling: bool = false
var completed: bool = false
var failure: String = ""
var _break_time: float = 0
const DURATION := 50.0
const CRITICAL_DEPTH := 5.0

func step(delta: float) -> void:
	if completed or failure != "": return
	elapsed += delta
	phase = 1 if elapsed < 20 else (2 if elapsed < 35 else 3)
	var cycle := fmod(elapsed, 5.0 if phase == 1 else 4.0)
	warning = cycle >= 2.0 and cycle < 2.8
	pulling = cycle >= 2.8 and cycle < (3.5 if phase == 1 else 3.8)
	var force: float = [0.0,0.18,0.25,0.33][phase] + (0.34 if pulling else 0.0)
	# Holding restores the boat; releasing buys tension relief at a visible depth cost.
	boat_pull_depth = clampf(boat_pull_depth + (force - (0.6 if reeling else 0.0))*delta,0,CRITICAL_DEPTH)
	tension = clampf(tension + ((18.0 + (24.0 if pulling else 0.0)) if reeling else -38.0)*delta,0,100)
	_break_time = _break_time + delta if tension >= 98 else 0.0
	if _break_time >= 1.0: failure = "LINE BREAK"
	elif boat_pull_depth >= CRITICAL_DEPTH: failure = "PULL DEPTH"
	elif elapsed >= DURATION:
		completed = true
		tension = 0
		reeling = false
