class_name HullEvents
extends RefCounted
## Three quiet, saved sequences and one 0m return. No text/camera/music effects.
var _progress: GameProgress
var _boat: Node2D
var _sonar: SonarDisplay
var _audio: AudioStreamPlayer
var active: bool = false
var stage: int = 0
var _delay: float = 3.0
var _elapsed: float = 0.0
var _hit_index: int = 0
var _beats: Array[float] = []
var zero_active: bool = false
var completed_stages: Array[int] = [] # Acceptance observation; bounded to three.
var strike_count: int = 0

func setup(progress: GameProgress, boat: Node2D, sonar: SonarDisplay, owner_node: Node, sound: AudioStream = null) -> void:
	_progress = progress
	_boat = boat
	_sonar = sonar
	_audio = AudioStreamPlayer.new()
	_audio.name = "HullKnockAudio"
	_audio.volume_db = -18
	_audio.stream = sound if sound != null else _placeholder_sound()
	owner_node.add_child(_audio)

static func _placeholder_sound() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var count := int(stream.mix_rate * 0.14)
	var samples := PackedByteArray()
	samples.resize(count * 2)
	for i in range(count):
		var t := float(i) / stream.mix_rate
		var envelope := minf(t / 0.006,1) * exp(-t * 34) * (1.0 - float(i) / count)
		var sample := int(sin(t * TAU * 94) * envelope * 10000)
		samples[i * 2] = sample & 255
		samples[i * 2 + 1] = (sample >> 8) & 255
	stream.data = samples
	return stream

func _eligible_stage(time_value: float) -> int:
	var records := _progress.fish_records
	if _progress.hull_knock_count == 0 and records["No.11"].discovered and time_value >= 0.95:
		return 1
	if _progress.hull_knock_count == 1 and records["No.12"].discovered and _progress.max_depth_reached_m >= 60:
		return 2
	if _progress.hull_knock_count == 2 and records["No.13"].discovered and _progress.max_depth_reached_m >= 70:
		return 3
	return 0

func step(delta: float, can_start: bool, time_value: float) -> void:
	if active:
		_elapsed += delta
		if zero_active:
			_sonar.set_zero_contact(true)
			if _elapsed >= 0.6:
				_sonar.set_zero_contact(false)
				_progress.finish_zero_contact()
				_finish()
			return
		while _hit_index < _beats.size() and _elapsed >= _beats[_hit_index]:
			_strike()
			_hit_index += 1
		if _elapsed >= _beats.back() + 0.2:
			_progress.finish_hull_knock(stage)
			completed_stages.append(stage)
			_finish()
		return
	var candidate := _eligible_stage(time_value)
	var can_zero: bool = _progress.hull_knock_count == 3 and _progress.levels.sonar >= 4 and time_value >= 1.95 and not _progress.zero_depth_contact_seen
	if candidate == 0 and not can_zero:
		_delay = 3.0
		return
	_delay -= delta
	if _delay > 0 or not can_start:
		return
	active = true
	_elapsed = 0
	_hit_index = 0
	stage = candidate
	zero_active = candidate == 0
	if zero_active:
		_sonar.set_zero_contact(true)
	else:
		_beats.assign([0.0] if stage == 1 else ([0.0,0.65] if stage == 2 else [0.0,0.3,0.6]))
		_strike()
		_hit_index = 1

func _strike() -> void:
	strike_count += 1
	_boat.hull_knock()
	# Device-free headless QA advances the same logical beats without audio voices.
	if DisplayServer.get_name() != "headless":
		_audio.play()
	if OS.get_name() in ["Android","iOS"]:
		Input.vibrate_handheld(35,0.22)

func _finish() -> void:
	active = false
	zero_active = false
	stage = 0
	_delay = 3.0

func stop_audio() -> void:
	if is_instance_valid(_audio):
		_audio.stop()
		_audio.stream = null
