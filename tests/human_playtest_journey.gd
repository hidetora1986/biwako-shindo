extends "res://tests/full_game_acceptance.gd"
# Observer enabled on the real full journey; no changes to game steps.
func _run() -> void:
    var logger: Node = root.get_node("HumanPlaytest")
    _check(logger.enabled, "Journey instrumentation explicitly opted in")
    logger.data["measurement_kind"] = "AUTOMATED INSTRUMENTATION CHECK"
    await super._run()
    for name: String in ["SESSION START","FIRST CATCH","LINE LV2","SONAR LV2","FIRST SONAR ANOMALY","NO06 DISCOVERED","NO10 DISCOVERED","NO10 CHOICE","LINE LV4","NO11 DISCOVERED","NIGHT","HULL KNOCK 1","HULL KNOCK 2","HULL KNOCK 3","NO14 DISCOVERED","NO14 CHOICE","LINE LV5","NO15 ENCOUNTER","NO15 DEFEATED","MAIN ENDING","POST GAME CONTINUE","ANONYMOUS LURE","NO00 CONTACT","NO00 FINAL CHOICE","HIDDEN ENDING"]:
        _check(logger.data.seen.has(name), "Actual journey milestone: " + name)
    _check(logger.data.boss15_attempts == 1 and logger.data.no00_attempts == 1 and logger.data.failed_fights == 0, "Actual encounter counters")
    _check(logger.data.ratings.values().all(func(v): return v == null), "No automatic human rating")
    logger.flush()
    print("HUMAN_PLAYTEST_JOURNEY ", JSON.stringify({"result":"PASS" if _failures.is_empty() else "FAIL","checks":_checks,"failures":_failures,"human_playtime":"NOT MEASURED"}))
    quit(0 if _failures.is_empty() else 1)

func _step(seconds: float) -> void:
    super._step(seconds)
    root.get_node("HumanPlaytest").sample()
