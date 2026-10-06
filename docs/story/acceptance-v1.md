# Narrative v1 acceptance

Engine: Godot 4.6.3.stable.official.7d41c59c4. Tests use isolated save paths/browser contexts.

Run the new native suite:

```sh
godot --headless --path . --script tests/narrative_acceptance.gd
```

Existing acceptance fixtures explicitly skip the new Opening and ending credits where necessary. Their gameplay, rewards, save durability and encounter assertions remain active; completed legacy save fixtures declare their already-seen presentation flags.

For local Web QA:

```sh
godot --headless --path . --export-release 'Web Playtest' build/web/index.html
python3 -m http.server 8765 --directory build/web
# In another terminal (requires Chromium + Python Playwright):
python3 tests/web/narrative.py
# Existing Web interaction regression (also requires Tesseract):
python3 tests/web/playtest_feedback.py
python3 tests/web/boss_playtest.py
```

Screenshots in `screenshots/` include spoilers. Native layout assertions cover 16:9, 19.5:9, 20:9 and 640x360; Web screenshots use 640x360, 844x390 and 800x360. They test a local exported build, not the public Pages deployment. Physical iPhone Safari / Android remain MANUAL TEST REQUIRED.

## Human review checklist

Rate independently after playing:

- Does the Opening create interest, and is the one-last-trip motivation clear?
- Do short journal pages complement fishing without turning into exposition?
- Does Main END feel complete?
- Do Cut and Contact feel distinct, without explaining No.00?
- Can story/credits/Book controls be read and tapped on the actual device?

Story interest, motivation clarity, ending satisfaction, hidden impact and mystery: **MANUAL TEST REQUIRED**.

Machine verification results are recorded in `verification-results.json` after completion. No deploy or merge is part of this phase.

## Verified result

PASS: Narrative acceptance (50 checks), all 31 prior regression cases, plus cast aim, No.15 isolated playtest, feedback telemetry, and separate-process mid/late save tests. Local Chromium touch tests passed for narrative, existing fishing/travel/save/book/shop, and isolated No.15. Godot Import, Headless and Web export passed with no errors. After the final ending-line visibility fix, narrative/cast/No.15/save tests and the exported Web narrative suite were rerun.

The native No.15 test requires `-- --boss15-playtest`; telemetry requires `-- --rc1-playtest`. Mid/late restart fixtures now identify their already-played Opening/night and resumed lake area, preserving the existing area gates.
