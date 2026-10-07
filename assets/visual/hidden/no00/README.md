# No.00 visual — reference direction

`source/unbounded-source.png` is a raster prepared with OpenAI image editing from the user-provided visual reference. The reference defines the night lake / huge unbounded curved mass / restrained burgundy direction. All UI, boat, person, rod/line and small fish were removed from the raster so the game draws its own instruments and moving boat. No external game assets were downloaded. Source is retained unchanged under `.gdignore` and excluded from export.

`tools/prepare-hidden-art.gd` performs offline RGBA conversion and nearest-neighbor band fitting into 640×360. The source waterline (273px) is fitted to the existing 136/360 gameplay waterline: sky/lake 136px, underwater 224px. No game object coordinates or depth values change. Generated PNG: `unbounded-surface.png`.

No.00 has no body Sprite, closed outline, head/face/eyes, fish profile or catch art. The raster depicts only an enormous surface fragment that continues off-screen. It is shown only by the existing HiddenVisual amount/fade controls. Title shadow, Cut/Contact timing and reveal remain controlled by existing logic. Boat uses the existing original GoldenAssets texture; lantern and sonar contacts use lightweight drawing. No shaders, lights or new event nodes.
