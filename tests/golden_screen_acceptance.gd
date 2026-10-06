extends "res://tests/phase2_acceptance.gd"
## Structural/presentation checks only. Beauty and commercial quality require human review.
func _run() -> void:
 root.size = Vector2i(1280,720)
 _new_scene(false);await process_frame;await process_frame
 var golden: Node = _lake.get_node("GoldenVisual")
 _check(not golden.active and not _lake.get_node("GoldenBackdrop").visible, "Opening keeps original presentation")
 _flow.story.skip();_step(0.3);golden.sync_scope();await process_frame
 _check(golden.active and _lake.current_area == LakeAreas.SOUTH and _lake.surface_y == 136, "South Morning / unchanged 38 percent cutaway")
 _check(golden.backdrop.layers.size() == 7 and golden.backdrop.has_node("FarMountains") and golden.backdrop.has_node("MiddleMountains") and golden.backdrop.has_node("NearShore"), "Raster sky / three ridge bands / surface / water / bed")
 var snapshot: Dictionary = _flow.save_manager.snapshot(_flow.progress)
 var physics: Array = []
 for fish: FishController in _fishes:physics.append([fish.position,fish.depth_position,fish.swim_speed,fish.bite_probability,fish.bite_detection_radius,fish._half_width,fish._half_height,fish.size_cm,fish.stamina])
 golden.enabled = false;golden.sync_scope()
 _check(not golden.active and _boat.get_node("Sprite").texture == RefinedPixelArt.boat_texture(), "Legacy boat restored outside target")
 var old_scale: float = _fishes[0].sprite.scale.x
 _fishes[0].sprite._process(0);old_scale = _fishes[0].sprite.scale.x
 var legacy_nodes := get_node_count()
 golden.enabled = true;golden.sync_scope()
 for fish: FishController in _fishes:fish.sprite._process(0)
 _check(get_node_count() == legacy_nodes, "Scope toggle never creates scene nodes")
 _check(_flow.save_manager.snapshot(_flow.progress) == snapshot, "Visual toggle leaves complete save snapshot unchanged")
 for i in range(_fishes.size()):
  var fish: FishController = _fishes[i]
  _check(physics[i] == [fish.position,fish.depth_position,fish.swim_speed,fish.bite_probability,fish.bite_detection_radius,fish._half_width,fish._half_height,fish.size_cm,fish.stamina], "Fish AI / hit geometry / catch data unchanged %d" % i)
  _check(fish.sprite.sprite_frames == GoldenAssets.FISH[fish.fight_profile.species_id] and fish.sprite.sprite_frames.get_frame_count("swim") == 3 and fish.sprite.sprite_frames.get_frame_texture("swim",0).get_size() == Vector2(40,22), "Three cached raster frames / original frame envelope %d" % i)
 _check(_fishes[0].sprite.scale.x >= old_scale*1.25 and _fishes[0].sprite.scale.x <= old_scale*1.5, "Fish enlargement is visual only")
 _check(_boat.get_node("Sprite").texture == GoldenAssets.BOAT and _boat.rod_tip_position() == _boat.position+Vector2(-40,-40), "Boat / angler art with unchanged rod attachment")
 var sonar: SonarDisplay = _hud.get_node("SonarPlaceholder")
 var original_contacts: Array = sonar.contacts.duplicate(true)
 sonar.refresh_contacts()
 _check(sonar.golden_visual and sonar.contacts == original_contacts and sonar.max_depth() == 15, "Sonar skin leaves detection and contact data unchanged")
 for spec: Vector2i in [Vector2i(1280,720),Vector2i(1560,720),Vector2i(1600,720),Vector2i(640,360)]:
  root.size = spec;await process_frame;await process_frame
  _hud.layout_in_safe_area(_lake.view_size,Rect2(36,8,_lake.view_size.x-72,_lake.view_size.y-24),_lake.surface_y,15)
  for name in ["ShopButton","BookButton","AreaButton","CastButton","HookButton","ReelButton","DepthBandButton"]:
   var control: Control = _hud.get_node(name)
   var scale: float = float(spec.y)/_lake.view_size.y
   _check(_hud.safe_rect.encloses(control.get_global_rect()) and control.size.x*scale >= 44 and control.size.y*scale >= 44, "%s %s safe / physical 44px" % [spec,name])
  for name in ["Money","Depth","NextUpgrade","SonarPlaceholder"]:_check(_hud.safe_rect.encloses(_hud.get_node(name).get_global_rect()), "%s %s readable information inside notch margin" % [spec,name])
  _check(_hud.get_node("Title").modulate.a == 0 and _hud.get_node("CastButton").position == _hud.get_node("ReelButton").position and _hud.get_node("HookButton").position == _hud.get_node("ReelButton").position, "Fixed primary footprint / title removed %s" % spec)
 _check(_flow.request_shop(), "SHOP existing input")
 _check(paused and not _flow.request_cast(), "SHOP modal blocks fishing")
 _hud.get_node("Shop").close_shop()
 _check(_flow.request_book(), "BOOK existing input")
 _hud.get_node("FishBook").close_book()
 _check(_flow.request_area(), "AREA existing input")
 _check(_flow.request_save(true), "SAVE remains in paused AREA map")
 _hud.get_node("AreaMap").close_map();_step(0.4)
 _check(not paused and _flow.state == FLOW.State.READY, "Modal return resumes normal loop")
 _check(_flow.request_cast() and not _flow.request_cast(), "CAST unchanged / no double lure")
 _check(_until_bite(), "Ordinary lure approach / BITE")
 golden.sync_scope()
 _check(not _hud.get_node("CastButton").visible and _hud.get_node("HookButton").visible and not _hud.get_node("ReelButton").visible, "HOOK is the only primary action during bite")
 _touch(_hud.get_node("HookButton").get_global_rect().get_center());_step(0.4)
 _check(_flow.state == FLOW.State.FIGHTING and _hud.get_node("ReelButton").visible and not _hud.get_node("HookButton").visible, "Touch hook -> sole REEL")
 _check(_finish_fight(), "Fight / landing / sale / reset unchanged")
 var writes: int = _flow.save_manager.write_count
 var nodes: int = get_node_count()
 for i in range(100):
  golden.enabled = false;golden.sync_scope();golden.enabled = true;golden.sync_scope()
  for fish: FishController in _fishes:fish.sprite._process(0.1)
  golden.water._process(0.1)
 _check(get_node_count() == nodes and _flow.save_manager.write_count == writes, "100 scope toggles: no node leak / no per-frame save IO")
 _flow.environment.value = 1;_flow.environment._apply();golden.sync_scope()
 _check(not golden.active and _lake.get_node("Background/BackgroundSky").visible and not sonar.golden_visual and _hud.get_node("BookButton").text == "FISH BOOK", "Evening fully restores existing art / sonar / button labels")
 _check(_hud.get_node("Money/Label").position == Vector2(12,7), "Legacy label geometry restored")
 _flow.environment.value = 0;_flow.environment._apply();_lake.current_area = LakeAreas.NORTH;golden.sync_scope()
 _check(not golden.active, "North Shore excluded")
 _lake.current_area = LakeAreas.SOUTH;_lake.depth_origin_m = 15;golden.sync_scope()
 _check(not golden.active, "Deeper band excluded")
 _lake.depth_origin_m = 0;_flow.story.begin("contact");golden.sync_scope()
 _check(not golden.active and _flow.story.active and _flow.story.mode == "contact", "Ending excluded / Contact story untouched")
 print("GOLDEN_SCREEN_ACCEPTANCE ",JSON.stringify({"result":"PASS" if _failures.is_empty() else "FAIL","checks":_checks,"failures":_failures,"art_quality":"MANUAL REVIEW REQUIRED"}))
 await create_timer(0.35).timeout
 _main.free();DirAccess.remove_absolute(_test_save_path);await process_frame
 quit(0 if _failures.is_empty() else 1)
