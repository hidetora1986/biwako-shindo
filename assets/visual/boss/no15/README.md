# No.15 湖底の主 — visual v2

Original high-density pixel sprite sheet generated with OpenAI image generation for this project. No external game art or downloaded copyrighted assets. Source: `source/lake-master-source.png`, 1536×1024 RGBA, true transparency, three stacked frames. Original generator output remains unchanged.

`tools/prepare-boss-sprites.gd` performs offline alpha-bound measurement and nearest-neighbor format conversion, aligning the mouth to the existing game anchor. Output: `lake-master-swim.png`, three 288×96 atlas frames stacked vertically. No runtime image generation. Three AtlasTexture resources share the same PNG. Animation remains three frames at four fps; fish-controller size and collision geometry are unchanged.

Design: massive blunt head, deep scaled body, heavy fins/tail, muted slate teal/olive/old ivory, small natural dark eye and pale healed abrasions. No glowing red eyes, teeth, tentacles or human features. No.00 and other fish art are unchanged.

Reproduce: `godot --headless --path . --script tools/prepare-boss-sprites.gd`, then project import. Godot 4.6.3. Source PNG and resulting PNGs are checked in.

The high-resolution source directory has `.gdignore` so it is retained for offline art preparation but excluded from game imports/exports.
