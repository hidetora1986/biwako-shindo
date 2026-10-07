# Production visual assets

Original raster planes and sprite sheets. The runtime retains only two active environment/time/depth packs, and reads committed PNGs. South Morning remains the original Golden pack; other times/areas use prepared modular planes. Story assets reuse the approved opening atlas and mysterious journal sketch.

Offline rebuild order (Pillow + Godot 4.6.3):

1. `python tools/generate-production-art.py`
2. `godot --headless --path . --script tools/prepare-production-environments.gd`
3. `godot --headless --path . --script tools/prepare-production-fish.gd`
4. `godot --headless --path . --script tools/prepare-production-story.gd`
5. `python tools/generate-production-icons.py` (final semantic icon set).
6. Editor import, acceptance and local Web captures.

The first stage authors icons/nine-slices and initial placeholder planes; the preparation stages replace those with the final packed original source art. Source image references are versioned for reproducibility but excluded from runtime exports. No game RNG, balance, collision envelope or Save schema is involved.
