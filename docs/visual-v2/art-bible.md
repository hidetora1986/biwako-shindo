# BIWAKO SHINDO — Full Visual Production v1

Authority: Golden Screen 01, base `0a3cf79bfaa8d1fdd288e66a39e5ee8f0bf88732`. Production branch only; no gameplay/balance/Save schema changes. Visual quality is always MANUAL REVIEW REQUIRED.

## Pixel scale and composition

640×360, nearest sampling; crisp clustered detail, readable partial outlines. Waterline retains 136/360. Lake/environment uses replaceable raster layers, independent water/boat/fish/FX. No raw full-screen AI illustration as a complete gameplay scene. Generated references are prepared into layer assets with authored palettes, depth treatment and animated foreground elements. South morning preserves Golden Screen assets and layout.

## Environment / time

South: inhabited, inviting, shore details. North shore: wider water, cooler, taller irregular ridges and distant shore. Center: sparse distant ridges, no nearby houses, broad negative space. Morning cyan/cream/gold; day clean cyan; sunset peach/ochre and darker ridges; night navy/moon/lantern. Day is a visual intermediate of existing morning→sunset transitions, not a new gameplay clock or Save state.

## Depth

0–15 clear cyan, grass/gravel/driftwood. 15–30 cool green, fewer plants. 30–50 blue-green, weak light and scattered bed. 50–65 dark blue, silt silhouettes. 65–85 cold navy, almost no rays. 85–100 near-black blue, No.14 most readable. 100–120 muddy rock/old structural fragments, never total black. Read existing depth/time continuously; crossfade art layers, do not change unlock/spawn/depth physics.

## Boat / fish

Golden hull/console/seat/outboard/angler/rod. Preserve rod endpoint and actor movement. Lamp only night; broken reflection/wake. Fish silhouette and 3-frame tail animation; native frame envelopes and AI/collision remain unchanged. Normal olive/silver; pale/elongated midgame; restricted non-gory unusual late silhouettes. No.15 thick head/body, old scars, huge tail; reuse approved original atlas. No.00 has no full body, head/eye/mouth/catch sprite. Unbounded surface beneath tiny boat; navy #061521/#081B28/#0D2632, burgundy limited to contacts/fragments/ERR.

## HUD / typography

Max two treatments: clean Noto Sans JP HUD, raster handwriting in journals. Primary CAST/HOOK/REEL same right-thumb footprint. Secondary AREA/SHOP/BOOK; SAVE inside map/mooring, short edge notice. Information compact. Minimum 44 physical pixels for operations; retain centered safe frame on wide phones. No large permanent gameplay title.

## Instruments / modals

Sonar navy bezel, faint grid/depth scale, real contacts read existing sampler. Contact width follows existing fish data; hidden invalid response remains separate. Fight tension instrument and subtle stamina/distance; hidden boat pull only. Shop marine catalog/cards/icons, clear level/effect/price. Fish Book specimen notebook with illustrated discoveries and unknown ink silhouettes. Grandfather journal older yellowed paper, water stains, sketch/photo fragments. Area navigation chart with live existing destinations/gates. Catch specimen card; Sell/Return same treatment.

## Story / horror

Opening original room/journal photography-like pixel scene layers, captions on bottom strip. Main dawn→journal→ambiguous northern map/rings/curve/sketch, no No.00 full form. Cut quiet mooring/journal closure; Contact dark/no body/count=2, old sketch with two marks. Credits calm lake. Preserve story words, section timings, skip/continue, flags and capture count. Horror escalates only through existing events; no new event or explanation.

## Performance / provenance / gates

Static assets PNG/Sprite; dynamics bounded cheap geometry. Runtime no image generation/file IO. Background target ≤1280×720, HUD/fish small shared atlases. No blur/bloom/volumetrics/heavy shaders/lights/particles. Original generated/code-built/project-licensed assets only; high-resolution sources excluded from export. Record decoded memory, pack size, browser load and stress; physical phone feel remains manual.

Checkpoints: A Environment, B Boat/Fish, C HUD/Sonar, D Story, E Hidden. Inspect actual rendered screenshots and run layout/load/regression tests at each. Final aesthetic approval is manual, never automated PASS.
