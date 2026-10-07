# Full Visual Production v1 — acceptance

Repository: `hidetora1986/biwako-shindo`
Branch: `feature/full-visual-production-v1`
Base: `0a3cf79bfaa8d1fdd288e66a39e5ee8f0bf88732`
Engine: Godot 4.6.3

[Screen gallery](full/index.md) · [Art Bible](art-bible.md) · [Asset manifest](asset-manifest.md)

## Scope and preservation

Full presentation pack: approved South Morning Golden screen, modular North environments/time grades, continuously blended depth raster planes, original three-frame fish, approved No.15/No.00 assets, fishing instruments, marine catalog, specimen notebook, navigation chart and cinematic journal/sketch overlays. The existing opening atlas remains the visual source for the grandfather room and ordinary journal scenes.

The feature branch attaches a presentation node to the lake scene. Fishing/economy/Save controllers, fish/equipment data, `project.godot` and export settings have no diff from the base. Story text, timing, flags, unlocks, fish AI, hitboxes and balance are preserved. Day is an intermediate visual grade in the existing morning→sunset blend, not a new time system. Existing opening-first/title/continue behavior is retained.

Static art is committed PNG/Sprite; light water motion, line, sonar contacts, wake and a bounded number of motes remain code-drawn. The original raster references are prepared offline into bands/atlases and excluded from runtime export. No full opaque illustration replaces the whole gameplay scene.

## Functional visual coverage

PASS below means assets load and the existing state/layout renders correctly. It does **not** mean human approval of beauty or commercial quality.

| Group | Coverage | Result |
| --- | --- | --- |
| Environment | South Shore, North Shore, North Center | PASS |
| Time | Morning, Day intermediate, Sunset, Night | PASS |
| Depth | 0–15, 15–30, 30–50, 50–65, 65–85, 85–100, 100–120, Hidden | PASS |
| Fish | No.01–05, No.06–10, No.11–14; three swim frames | PASS |
| Boss | No.15 atlas, mouth endpoint and existing fight | PASS |
| Hidden | No.00 unbounded terrain-like partial form; no head/eyes/mouth/full body | PASS |
| HUD | CAST/HOOK/REEL, tension/stamina/distance, secondary actions | PASS |
| Sonar | Existing real contacts/Lv/depth/anomaly; Golden instrument skin | PASS |
| Shop | Four categories, original tier-tinted icons, prices/effects, purchase | PASS |
| Fish Book | Paper specimen notebook, discovered art / undiscovered ink silhouettes | PASS |
| Journal | Older paper, existing records, photo and ambiguous sketch | PASS |
| Area / Save | Navigation chart, original travel/mooring/manual save controls | PASS |
| Catch | Original size/price/NEW; specimen card and Sell/Return | PASS |
| Title | Existing title/continue with BIWAKO SHINDO subtitle | PASS |
| Opening | Original room/journal imagery, existing captions on safe bottom strip | PASS |
| Main Ending | Dawn/return/journal and final mysterious sketch | PASS |
| Mysterious Sketch | Lake outline, irregular rings/curve/depth notes; approved original asset | PASS |
| Cut / Contact / Credits | Existing routes, two marks/count=2, quiet lake background | PASS |

## Regression and layout

| Check | Result |
| --- | --- |
| Fishing / HOOK / REEL / Fight / Catch | PASS |
| Economy / Shop / Fish Book / Area / Save / Load | PASS |
| Opening / Story / Main Ending / both Hidden Endings | PASS |
| No.15 / No.00 / restart / choices | PASS |
| Existing phase1–5 / MVP / visual / midgame / lategame / boss / hidden | PASS |
| 100 fishing cycles / RC1 corrupt Save and postgame recovery | PASS |
| 16:9 / 19.5:9 / 20:9 / 640×360 | PASS |
| Touch targets ≥44 pixels / centered safe layout | PASS |
| Godot import / headless / Web export | PASS |
| Actual local Web touch loop, modals, manual Save and reload | PASS |
| Critical errors | 0 |

Native checks cover 31 existing scenarios plus eight extra visual/narrative/aim/boss checks. `tests/full_visual_acceptance.gd` performs 288 checks: raster loading/path/resolution, area/time/depth packs, three-frame species mapping, touch targets, returning to Golden Morning, bounded cache/node count and no Save writes from rendering.

The Web screenshot matrix uses `tests/fixtures/full_visual_scene.gd` only in a **copied local debug project** built by `tools/build-full-visual-qa.py`. It never modifies the production entry point or ordinary Save. Captures show actual Web renderer output, not composites. 33 required states plus Contact result and major aspect variants are archived in the gallery. Public Pages is not deployed by this task.

## Checkpoints

A: Environment layers/time/depth. The initial procedural North draft was replaced with original high-density raster source bands before proceeding.

B: Boat/fish. The Golden boat and five normal species remain the reference; mid/late sheets retain native controller geometry, No.15 uses the approved atlas.

C: HUD/Sonar/modals. Four equipment rows fit without losing a category; fish records and grandfather journal use paper contrast.

D: Story. Existing room/book imagery and approved mysterious sketch were inspected; obsolete dock drawing is suppressed over the journal photo.

E: Hidden. The partial giant surface, tiny boat, night reflection, depth ERR and boat-pull HUD were inspected. No additional event or creature explanation was added.

## Performance and limits

Runtime keeps 12 currently blended environment/depth textures rather than preloading all areas/times. These planes occupy approximately 17.7 MiB decoded RGBA in total; 5–12 raster plane draws per background frame depending on blend. This is a static bound, not a device GPU-memory measurement. Raster redraw is limited to 20 Hz, existing water/fish animation remains independent, and visual code performs no runtime generation or per-frame file IO. 100 renderer updates retain stable node counts and zero Save writes; existing 100-fishing-cycle stress remains PASS.

Local Chromium uses software ANGLE/SwiftShader. Median frame scheduling, cold load and Web payload measurements are recorded in the adjacent QA evidence; they are **not physical-phone FPS or mobile network results**. The full world pack increases the PCK from about 11.7 MB to 19.7 MB (approximately +69%). Measured local cold start was 3.54 s for the base versus 3.08 s for this build; median requestAnimationFrame spacing was 16.7 ms and p95 was 50 ms for both. Local drawing showed no severe regression, but the increased download cost remains a known tradeoff. Physical iPhone/Android loading, GPU memory and sustained performance need manual testing. No blur, bloom, dynamic lighting or heavy shader was introduced.

## Manual art gate

| Review | Status |
| --- | --- |
| South Shore beauty / North Shore / North Center | MANUAL REVIEW REQUIRED |
| Night / Deep water | MANUAL REVIEW REQUIRED |
| Boat / Fish / No.15 / No.00 | MANUAL REVIEW REQUIRED |
| HUD / Sonar / Shop / Fish Book | MANUAL REVIEW REQUIRED |
| Opening / Main Ending / Hidden Endings | MANUAL REVIEW REQUIRED |
| Overall visual quality / Commercial game feel | MANUAL REVIEW REQUIRED |

No other branches are merged or changed. Review the gallery on a phone before approving this direction or requesting a Web deployment.
