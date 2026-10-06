# Main Ending Sketch Tease v1

Base: `74999ba3b80041d798d6eb5c4e43eb3de886228e`; branch: `feature/main-ending-sketch-v1`.

The ending retains the boss reward, dawn, shore, final ordinary entry and “……帰ろう。” before turning one additional page. A dedicated aged journal spread appears, holds for one second, then approaches the incomplete contours by only 6.5%. Four short captions remain in the lower 20% black translucent band. A quiet 0.6-second darkening returns to the lake before MAIN END. Main presentation lasts 24.1 seconds, followed by the existing credits. There is no added sound, creature animation, flash or new horror event.

The unfinished sketch supports several readings; no authoritative answer is supplied. Small depth fragments and a north-basin mark can be revisited after completion. Human interpretation, satisfaction and curiosity remain **MANUAL TEST REQUIRED**, as do physical iPhone/Android readability and feel.

## Journal and save

The new page is gated by existing `main_ending_seen`. Completed legacy saves reconstruct it on load; no save version or new flag is needed. A cached page alone cannot expose it before completion. In Fish Book → 記録, scroll to the special page and tap **絵を見る**; × returns to the journal, which remains paused, and the usual × returns to fishing. Close controls and the review button retain at least 44px touch targets. The existing hidden final tally page remains independent.

The fishing controller, encounter requirements, fish records, choices, economy, equipment, save-manager code and Cut/Contact steps are unchanged. Contact's count of two and its two marks remain intact. Old Opening is retained at the explicitly requested base; the separate cinematic Opening already deployed on `release/web-test` is not included in this historical base branch. No protected branch or published site is updated by this task.

## Reproduce

Use Godot 4.6.3:

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script tests/main_ending_sketch_acceptance.gd
godot --headless --path . --script tests/narrative_acceptance.gd
godot --headless --path . --export-release "Web Playtest" build/web/index.html
```

Serve `build/web` on localhost:8765, then run `python tests/web/main_ending_sketch.py` with Python Playwright and Chromium installed. Web fixtures affect only isolated browser IndexedDB; no production save is cleared, and no test fixture is exposed in game UI. Test artifacts go to `/tmp/sketch-web-final`.

See `verification-results.json` and `screenshots/` for the actual checks and captures. The native presentation test validates real boss completion, page order, subtle camera motion, fade, subtitle size/safe bounds at four viewports, touch review/close, natural credits, Continue and completed-save reconstruction. Existing narrative tests cover interrupted Main/Cut/Contact reloads and immutable hidden count. Full regression also covers all phases, full-game routes, 100 fish stress and restart cases.
