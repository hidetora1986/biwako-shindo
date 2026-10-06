extends Node
## Opt-in debug instrumentation. Never changes gameplay, RNG, timers or normal saves.
const TEST_SAVE := "user://rc1-playtest/save.json"
const SESSION_FILE := "user://rc1-playtest/playtest-session.json"
const RATINGS := ["Fishing Feel", "Upgrade Tempo", "Midgame Boredom", "Horror Pacing", "No.15 Feel", "No.00 Feel", "Overall"]
var enabled := false
var manual_pause := false
var focus_lost := false
var background := false
var data: Dictionary = {}
var flow: Node
var last_error: Error = OK
var _last_tick: int = 0
var _last_flush := 0.0
var _previous_state := -1
var _previous_hidden := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	set_process_input(false)
	var args := OS.get_cmdline_user_args()
	if OS.is_debug_build() and "--rc1-playtest" in args:
		start_session("--rc1-fresh" in args)

func start_session(fresh: bool = false) -> bool:
	if not OS.is_debug_build(): return false
	last_error = DirAccess.make_dir_recursive_absolute(TEST_SAVE.get_base_dir())
	if last_error != OK: return false
	if fresh:
		# Fixed QA namespace only: no arbitrary path, normal save is never removed.
		for path: String in [TEST_SAVE, TEST_SAVE + ".tmp", SESSION_FILE, SESSION_FILE + ".tmp"]:
			if FileAccess.file_exists(path):
				last_error = DirAccess.remove_absolute(path)
				if last_error != OK: return false
	data = {}
	if not fresh and FileAccess.file_exists(SESSION_FILE):
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(SESSION_FILE))
		if _valid_session(raw):
			data = raw
	if data.is_empty():
		var ratings := {}
		for name: String in RATINGS: ratings[name] = null
		data = {"session_version": 1, "build": "0.9.0-rc1", "save_path": TEST_SAVE, "started_unix": Time.get_unix_time_from_system(), "active_seconds": 0.0, "events": [], "seen": {}, "ratings": ratings, "failed_fights": 0, "boss15_attempts": 0, "no00_attempts": 0, "human_feel_status": "MANUAL TEST REQUIRED"}
	enabled = true
	if not FileAccess.file_exists(TEST_SAVE):
		var initial_save := SaveManager.new(TEST_SAVE)
		if not initial_save.save_progress(GameProgress.new()):
			last_error = initial_save.last_error
			enabled = false
			return false
	_last_tick = Time.get_ticks_usec()
	set_process(true)
	set_process_input(true)
	if data.events.is_empty(): record("SESSION START")
	else: record("SESSION RESUME", {}, false)
	return true

func _valid_session(raw: Variant) -> bool:
	if not raw is Dictionary or raw.get("session_version") != 1: return false
	for key: String in ["events", "seen", "ratings"]:
		if not raw.get(key) is Array and key == "events": return false
		if not raw.get(key) is Dictionary and key != "events": return false
	for key: String in ["active_seconds", "started_unix", "failed_fights", "boss15_attempts", "no00_attempts"]:
		var value: Variant = raw.get(key)
		if not (value is int or value is float) or not is_finite(float(value)) or value < 0: return false
	for name: String in RATINGS:
		var value: Variant = raw.ratings.get(name)
		if value != null and (not (value is int or value is float) or value < 1 or value > 5 or floorf(float(value)) != value): return false
	return true

func test_save_path(normal_path: String) -> String:
	return TEST_SAVE if enabled and OS.is_debug_build() else normal_path

func bind_flow(controller: Node) -> void:
	if not enabled: return
	flow = controller
	_previous_state = -1
	_previous_hidden = -1
	if not flow.progress.changed.is_connected(sample): flow.progress.changed.connect(sample)
	sample()

func _tick() -> void:
	if not enabled: return
	var now := Time.get_ticks_usec()
	var delta := maxf(0, float(now - _last_tick) / 1000000.0)
	_last_tick = now
	advance_clock(delta, manual_pause or focus_lost or background or get_tree().paused)

func advance_clock(seconds: float, paused: bool) -> void:
	# Long frame gaps may be suspend/debugger stops. Exclude the entire gap, not reading time.
	if enabled and is_finite(seconds) and seconds >= 0 and seconds <= 5 and not paused:
		data.active_seconds += seconds

func _process(_delta: float) -> void:
	_tick()
	sample()
	if float(data.active_seconds) - _last_flush >= 30: flush()

func telemetry() -> Dictionary:
	var result := {"elapsed_seconds": data.get("active_seconds", 0), "wall_clock_seconds": maxf(0, Time.get_unix_time_from_system() - float(data.get("started_unix", Time.get_unix_time_from_system()))), "failed_fights": data.get("failed_fights", 0), "boss15_attempts": data.get("boss15_attempts", 0), "no00_attempts": data.get("no00_attempts", 0), "money": 0, "total_fish_caught": 0, "rod_level": 1, "reel_level": 1, "line_level": 1, "sonar_level": 1, "current_depth": 0.0}
	if is_instance_valid(flow):
		var caught := 0
		for value: Dictionary in flow.progress.fish_records.values(): caught += int(value.caught_count)
		result.merge({"money": flow.progress.money, "total_fish_caught": caught, "rod_level": flow.progress.levels.rod, "reel_level": flow.progress.levels.reel, "line_level": flow.progress.levels.line, "sonar_level": flow.progress.levels.sonar, "current_depth": flow.lure.depth_m, "depth_band": flow.selected_band, "current_area": flow.progress.current_area})
	return result

func record(milestone: String, extra: Dictionary = {}, once: bool = true) -> void:
	if not enabled: return
	_tick()
	if once and data.seen.has(milestone): return
	data.seen[milestone] = true
	var entry := telemetry()
	entry.merge(extra)
	entry["milestone"] = milestone
	data.events.append(entry)
	flush()

func choice(id: String, value: String) -> void:
	if not enabled: return
	sample()
	if id in ["No.10", "No.14"]: record(id.replace("No.", "NO") + " CHOICE", {"choice": value}, false)

func sample() -> void:
	if not enabled or not is_instance_valid(flow): return
	var p: GameProgress = flow.progress
	var catches := 0
	for value: Dictionary in p.fish_records.values(): catches += int(value.caught_count)
	if catches > 0: record("FIRST CATCH")
	for pair: Array in [["line", 2], ["sonar", 2], ["line", 4], ["line", 5]]:
		if p.levels[pair[0]] >= pair[1]: record(str(pair[0]).to_upper() + " LV" + str(pair[1]))
	if p.anomaly_seen: record("FIRST SONAR ANOMALY")
	for id: String in ["No.06", "No.10", "No.11", "No.14"]:
		if p.fish_records[id].discovered: record(id.replace("No.", "NO") + " DISCOVERED")
	if flow.environment.value >= 1.95: record("NIGHT")
	for i in range(1, p.hull_knock_count + 1): record("HULL KNOCK " + str(i))
	if p.boss15_defeated: record("NO15 DEFEATED")
	if p.main_ending_seen: record("MAIN ENDING")
	if p.anonymous_lure_obtained: record("ANONYMOUS LURE")
	if p.hidden_finished(): record("HIDDEN ENDING", {"ending": "CONTACT" if p.hidden_contact_ending_seen else "CUT"})
	if flow.state != _previous_state:
		_previous_state = flow.state
		if flow.state == flow.State.BOSS_BITE:
			data.boss15_attempts += 1
			record("NO15 ENCOUNTER", {}, false)
		if flow.state == flow.State.FAILED:
			data.failed_fights += 1
			record("FIGHT FAILED", {"kind": "FISHING"}, false)
	if is_instance_valid(flow.hidden_route) and flow.hidden_route.stage != _previous_hidden:
		_previous_hidden = flow.hidden_route.stage
		if _previous_hidden == HiddenRoute.Stage.DEPTH:
			data.no00_attempts += 1
			record("NO00 ENCOUNTER", {}, false)
		if _previous_hidden == HiddenRoute.Stage.CONTACT: record("NO00 CONTACT", {}, false)
		if _previous_hidden == HiddenRoute.Stage.FAILURE:
			data.failed_fights += 1
			record("FIGHT FAILED", {"kind": "NO00"}, false)

func set_manual_pause(value: bool) -> void:
	if not enabled or manual_pause == value: return
	_tick()
	manual_pause = value
	record("TIMER PAUSED" if value else "TIMER RESUMED", {}, false)

func rate(name: String, score: int) -> bool:
	if not enabled or name not in RATINGS or score < 1 or score > 5: return false
	data.ratings[name] = score
	return flush()

func _input(event: InputEvent) -> void:
	if not enabled or not OS.is_debug_build(): return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F6: record("BORED", {}, false)
			KEY_F7: record("GOOD MOMENT", {}, false)
			KEY_F8: record("CONFUSED", {}, false)
			KEY_F9: set_manual_pause(not manual_pause)

func _notification(what: int) -> void:
	if not enabled: return
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_RESUMED]:
		_tick()
		match what:
			NOTIFICATION_APPLICATION_FOCUS_OUT: focus_lost = true
			NOTIFICATION_APPLICATION_FOCUS_IN: focus_lost = false
			NOTIFICATION_APPLICATION_PAUSED: background = true
			NOTIFICATION_APPLICATION_RESUMED: background = false
		record("APP PAUSE" if focus_lost or background else "APP RESUME", {}, false)
	if what == NOTIFICATION_WM_CLOSE_REQUEST: flush()

func flush() -> bool:
	if not enabled: return false
	data["wall_clock_seconds"] = telemetry().wall_clock_seconds
	var file := FileAccess.open(SESSION_FILE + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = FileAccess.get_open_error()
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	last_error = file.get_error()
	file.close()
	if last_error == OK: last_error = DirAccess.rename_absolute(SESSION_FILE + ".tmp", SESSION_FILE)
	_last_flush = float(data.active_seconds)
	return last_error == OK

func _exit_tree() -> void:
	if enabled:
		_tick()
		flush()
