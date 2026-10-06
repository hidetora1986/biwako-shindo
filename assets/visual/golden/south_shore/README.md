# Golden Screen 01 assets

Scope: south_shore, morning, 0–15m. Other environments use the original renderer.

`south-shore-morning.png` is an original OpenAI image-generation illustration, created for this project. No external game art was downloaded. The source illustration is preserved at 1672×941. Seven AtlasTexture resources split its vertical bands to fit the existing waterline. Its three atmospheric mountain planes are illustrated within a coherent raster; these are not separately alpha-extracted parallax mountains. Sprite nodes/resources permit later replacement.

`tools/generate-golden-sprites.py` generates original Pillow raster assets offline: boat, five three-frame fish sheets, primary controls, sonar bezel and sparse water accents. Generated PNGs are committed; no asset generation occurs in gameplay. Boat texture envelope remains 154×64; fish frames remain 40×22. Visual fish scale changes without modifying controllers, collision geometry or size data. Nearest filtering is retained.

Directories: sky, mountains, shore, water, lakebed, boat, fish, hud. Each texture/resource can be replaced independently. The dynamic rod uses the original boat rod-tip position. No paid assets or unknown-license downloads were introduced.
