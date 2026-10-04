class_name SonarAnomaly
extends RefCounted
## The sole Phase 5 anomaly lives only inside the sonar display.
const DURATION := 0.6
var active: bool = false
var elapsed: float = 0.0
var _progress: GameProgress
var _sonar: SonarDisplay

func setup(progress: GameProgress, sonar: SonarDisplay) -> void:
	_progress = progress
	_sonar = sonar

func try_trigger(allowed: bool, debug: bool = false) -> bool:
	if active or not allowed or _progress.anomaly_seen or _progress.levels.sonar < 2:
		return false
	if not debug and _progress.sonar_sessions < 3:
		return false
	active = true
	elapsed = 0.0
	_sonar.set_anomaly(true, 0.0)
	return true

func step(delta: float, allowed: bool) -> void:
	if not active:
		try_trigger(allowed)
		return
	elapsed = minf(DURATION, elapsed + delta)
	_sonar.set_anomaly(true, elapsed / DURATION)
	if elapsed >= DURATION:
		active = false
		_sonar.set_anomaly(false, 0.0)
		_progress.finish_anomaly()
