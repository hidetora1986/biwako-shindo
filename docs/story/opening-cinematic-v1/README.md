# Opening Cinematic Refresh v1

Base: `release/web-test` / `74999ba3b80041d798d6eb5c4e43eb3de886228e`.
Feature: `feature/opening-cinematic-v1`. This phase does **not** deploy or modify release/web-test, release/rc1 or main.

Four dedicated illustrated backgrounds replace the lake-backed central text Opening. They depict the grandfather's quiet room, the ordinary opened fishing log, unusual depth notes, and setting out with the same journal. No monster identity, protagonist age/gender, Grandpa's fate beyond the supplied script, or hidden boss information is introduced.

## Sequence

| Scene | Supplied text cards | Duration |
| --- | --- | --- |
| Room | 1–2 | 4.8 seconds |
| Open journal | 3–4 | 4.8 seconds |
| Depth notes | 5–7 | 7.2 seconds |
| Decision / boat | 8–9 | 4.8 seconds |
| Title (lake image) | ――琵琶湖深度 | 2.0 seconds |

Total **23.6 seconds**. Each ordinary card lasts 2.4 seconds. The 0.5-second scene crossfades overlap card time. A weak 3.5–7.5% zoom and six-pixel pan give motion without strong camera swings. The title remains in the lower subtitle band. Sound is intentionally quiet/silent; no new BGM or scare sound is added.

The lower **20%** band is black at 70% opacity. Japanese captions use the existing font, 18 logical pixels (Medium 500), at most two explicit lines and zero additional line spacing. Captions fit inside the device safe rectangle; a centered 16:9 art frame expands only the side mattes on wide phones. The journal and other important subjects remain visible above/through the composition, rather than being replaced by gameplay sprites or HUD.

## Responsibility and compatibility

`OpeningCinematic` / `scenes/story/opening_cinematic.tscn` owns image framing, motion, fade and subtitles. `NarrativeScreen` continues to own the sequence clock, SKIP, modal input and completion/Save flag. No new save fields/version are added. Fresh New Game plays once; natural completion and touch SKIP save `opening_seen`, restore the original lake HUD and allow CAST. Existing Continue skips Opening. Interrupted uncompleted Opening can replay safely.

Journal, Main/Cut/Contact story text, credits, fishing formulas, economy, data profiles, equipment and save migration remain unchanged. The old unused four-card opening text was removed from narrative-v1.json; journal and credits data match the base exactly.

## Verify

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/opening_cinematic_acceptance.gd
godot --headless --path . --script tests/narrative_acceptance.gd
godot --headless --path . --export-release 'Web Playtest' build/web/index.html
python3 -m http.server 8765 --directory build/web
# In another terminal, with Chromium / Python Playwright installed:
python3 tests/web/opening_cinematic.py
```

New native tests check each exact provided caption and mapping, real image resources, camera/fade progression, total duration, safe lower-third geometry and text metrics for every card at four viewport sizes, actual touch skip, natural transition, CAST, persisted flag and no replay after reload. Web captures the four chapters and title at 640×360, 844×390 and 800×360, natural completion/save and separate-context touch skip. Existing narrative tests retain all ending, migration and reward assertions with the updated Opening duration.

Machine results are in verification-results.json. Screenshots are local test exports and contain Opening/story spoilers, not a public deployment.

## Human acceptance

Opening clarity, emotional impact, mystery hook and readability on a physical smartphone are **MANUAL TEST REQUIRED**. Automated layout PASS does not establish those qualities. Physical iPhone Safari / Android have not been tested in this environment.

## Machine result

PASS: 84 Opening checks, 31 prior regression cases, 50 narrative/ending checks and the additional cast/No.15/telemetry/mid-late save cases. Local Chromium touch suites passed for Opening, ordinary fishing/travel/save/shop/book, all three ending presentations and isolated No.15. Final Medium-weight Opening passed native text metrics and Web completion/save checks again. Observed Web completion check: 24.63 seconds, including capture/read overhead; sequence time is 23.6 seconds. Godot errors: zero.
