# Smartphone Web Play Test

Repository: hidetora1986/biwako-shindo. Branch: `release/web-test`.
Exact base: `8654c5112a3b524ed4ec1d01e3cbcad8eaf9f5d7`.
`release/rc1` currently contains later Human telemetry (`a296c41…`), which is intentionally not included in this requested base. All protected branches remain unchanged.

## Deployment status

**PAGES SETUP REQUIRED**. Repository metadata reports `has_pages=false`. Pages GET and create with `build_type=workflow` both returned **403 Resource not accessible by integration**. Expected URL `https://hidetora1986.github.io/biwako-shindo/` currently returns **404**, and is **not a playable/deployed URL**. No alternate hosting or repository visibility change is performed.

On your smartphone, open https://github.com/hidetora1986/biwako-shindo then:

1. **Settings → Pages → Build and deployment → Source → GitHub Actions**.
2. Open **Actions → Smartphone Web Play Test**, select the run for `release/web-test`, then **Re-run all jobs** after enabling Pages.
3. If manual **Run workflow** is available, select branch **release/web-test** before starting it. GitHub's `workflow_dispatch` discovery requires a workflow on the default branch; this change deliberately does not modify `main` or the repository default branch. The branch push trigger and rerun of an existing run are the available route until that GitHub limitation is resolved.
4. If `github-pages` environment deployment rules restrict branches, allow **release/web-test** in **Settings → Environments → github-pages**.
5. Once Deploy succeeds, use the URL shown by the `deployment` step/environment. Confirm a successful page response and the actual game startup before sharing it as the Play URL.

This repository is private. If GitHub shows that Pages is unavailable under the current plan, the repository owner must resolve plan eligibility; this task does not make the source public. No signing secrets, personal tokens or source transfer to an external build service are needed.

## Build

Godot **4.6.3 stable official**, Compatibility renderer, `variant/thread_support=false`, no GDExtension, no PWA/service worker or SharedArrayBuffer/COOP/COEP requirement. Output `build/web/index.html` plus `.js`, `.wasm`, `.pck` and audio worklet files. Build output is gitignored; source preset is tracked.

`.github/workflows/web-playtest.yml` handles push to `release/web-test` and defines `workflow_dispatch`. It checks out source, downloads the official version-matched binary/templates, verifies SHA512, imports, exports **release**, configures Pages, uploads the Pages artifact and deploys with `contents:read`, `pages:write`, `id-token:write` into `github-pages`. Its branch guard prevents deploying `main` or another feature branch.

Local equivalent:

```sh
export XDG_DATA_HOME=/tmp/biwako-web-data
bash tools/install-godot-web.sh /tmp/biwako-web-tools
mkdir -p build/web
/tmp/biwako-web-tools/godot --headless --editor --path . --import --quit
/tmp/biwako-web-tools/godot --headless --path . --export-release "Web Playtest" build/web/index.html
python -m http.server 8765 --directory build/web
```

For local browser automation, install Playwright (Python), Chromium and Tesseract, serve on port 8765, then run `python tests/web/browser_playtest.py`. Browser profiles are disposable; fixtures affect only that local browser IndexedDB. Tests are excluded from the public PCK.

## Compatibility-only changes

- Web HTML shell: touch-to-start, loader, portrait guidance, fit canvas inside CSS safe-area insets, disable unwanted page scroll/pinch. No CAST/REEL or game state code added to JavaScript.
- Add ETC2/ASTC texture import support required by the mobile Web export option; Compatibility and Nearest remain intact.
- Web-only postgame control relayout when the browser viewport changes; keeps NIGHT/lure buttons inside the new canvas. No state transitions or unlock logic changed.
- Bundle licensed Japanese glyph fallback because Web SystemFont renders missing glyphs. Existing five resources preserve native font names and geometry. [Source/license](../../assets/fonts/README.md).
- No gameplay calculations, fish/equipment data, prices, spawn rates, fight timing, saving API/schema, events or endings changed. The single Web UI relayout call above is the only script difference. No Human telemetry on this base, debug menus, give-money or force-boss UI in the release page.

## Save and limitations

Existing `user://biwako-shindo/save.json` remains version 1 and is persisted through Godot's Web IndexedDB filesystem. Same-origin reload can restore money, gear, fish records and flags. Native-device save files do not automatically transfer to a browser. Different browsers/profiles/hosts have independent saves.

Use a normal Safari/Chrome window. Private mode, storage denial, quota, clearing site data or OS/browser eviction can lose progress. IndexedDB persistence is asynchronous: avoid immediately force-closing the tab after a catch/purchase; leave it open for several seconds. No new gameplay save format or fallback storage implementation is introduced.

WebGL2 and WebAssembly are required. Audio begins through a user gesture, and Godot handles AudioContext unlocking on canvas input; physical speakers and Safari autoplay behavior still require device testing. Landscape is recommended without requiring Fullscreen or Orientation Lock (Safari can restrict these). Initial download includes a roughly 36MB Wasm and the bundled font; cold-start speed and phone heat/FPS are not measured here.

## Evidence scope

Godot import/export and all 28 RC1 executions pass with no Godot/Script errors or warnings. Browser verification uses real Chromium WebGL2 under software rendering, mobile viewport/touch emulation and no cross-origin isolation. Actual touch CAST, HOOK, REEL, catch and IndexedDB save creation are tested. A storage fixture separately checks restored high-level equipment, 15 discovered fish and ending state; it is not a claim of human full-game browser completion.

16:9, 19.5:9 and 20:9 canvas fitting, portrait prompt and page scroll are checked. Desktop Native tests cover advanced Sell/Return and final-choice input; these advanced encounters have not been played on a physical phone browser. Safari/WebKit launch was blocked by missing host libraries. **Physical Safari, physical Chrome, haptics, audio feel and phone performance: NOT TESTED.** No actual Pages deployment is claimed before setup.

RC1 still has its existing B01 pacing blocker. Preparing Web play does not resolve it or change the balance to inflate play time.
