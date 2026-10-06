# Opening cinematic artwork

`cinematic-atlas.png` is an original AI-generated placeholder illustration created for this game's Opening using OpenAI image generation on 2026-10-06. It is not a downloaded photograph, game asset, or third-party copyrighted illustration. No paid external stock pack was introduced. Human visual inspection confirmed no protagonist identity, monster, No.00, forbidden lore or readable story caption in the artwork.

Image: 1672 × 940 PNG, four equal 836 × 470 landscape panels:

| Texture | Atlas rectangle | Content |
| --- | --- | --- |
| room.tres | (0, 0, 836, 470) | Quiet old tatami room, desk, fishing tools, closed olive journal |
| journal.tres | (836, 0, 836, 470) | Same opened journal, ordinary fishing sketch and faded writing |
| mystery.tres | (0, 470, 836, 470) | Same journal's lake depth sketch and incomplete notes |
| decision.tres | (836, 470, 836, 470) | Same journal ready to take aboard grandfather's boat at the lake |

Godot AtlasTexture resources share the image without duplicating four PNGs. `filter_clip` prevents atlas edge bleed. The inherited nearest filter and no mipmaps retain detail; no full-screen shader, blur, video decoder or particles are used. Texture memory is approximately 6 MiB before driver overhead.

The image has no authoritative text. All required Japanese subtitles come from `data/story/opening-cinematic-v1.json`. Existing Noto Sans JP / OFL credit remains. Replace an AtlasTexture with any Texture2D to swap final art without changing sequence, input, save or fishing logic.

Generation direction: coherent restrained pixel-art-inspired dioramas, natural aged wood, warm morning light, blue-green Lake Biwa, same olive-grey journal across four quadrants, subtle mystery only; no people/faces, no monster/body/eyes, no readable names or numbers, no horror colors, no copied gameplay HUD.
