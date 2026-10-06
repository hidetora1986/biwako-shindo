# Narrative & Ending v1

Base: `release/web-test` / `42281da7004b0143fa35801b8e79e74bb61ef5b2`
Working branch: `feature/narrative-ending-v1`. Public Web deployment is unchanged.

## Presentation

The unnamed protagonist has come to clear their grandfather's unused boat. Four quiet cards introduce one final fishing trip, without anticipating the horror. A fresh save shows the Opening once (20 seconds); SKIP begins ordinary fishing immediately. Established v1 saves retain their progress and skip the added Opening.

The Fish Book contains a separate **記録** tab. Journal entries are short, data-driven in `data/story/narrative-v1.json`, and unlock from existing discoveries and progression. There is no additional persistent lake HUD button, tutorial overlay, or hidden-route checklist. First night turns one small page near the boat; knocks never open the book automatically.

No.15 retains its ordinary catch, automatic sale and reward. The following presentation returns to the South Shore at dawn, shows the grandfather's final ordinary entry and 「……帰ろう。」, then MAIN END and credits. Continue restores the existing postgame.

Cut preserves the original choice/fight conditions. A single old tally and 「もう、来ない。」 lead back to the title; its faint shadow disappears after four seconds. Contact preserves the existing No.00 reveal and count of two. The journal shows two vertical tallies in silence, followed by a brief blackout. No full-body No.00 image or explanation of the tally's author is introduced.

Each ending includes 30 seconds of skippable credits: BIWAKO SHINDO / Hiro Koma / Godot Engine / Noto Sans JP (OFL 1.1). Credits also skip with a tap anywhere. Ending-content SKIP advances to credits; a second tap skips credits. A short input lock prevents one tap from also activating Continue.

## State and save compatibility

`NarrativeScreen` owns presentation; fishing/controller keeps game states and rewards. The new `NARRATIVE` enum is appended, preserving existing numeric states. Story cards pause fishing inputs, while the Book retains the existing modal pause behavior. Prices, fish profiles, spawning, fight formulas, equipment effects and hidden eligibility are unchanged.

The existing atomic v1 save format has additive fields:

- `opening_seen`, `night_page_seen`
- `journal_pages_unlocked` (whitelisted page IDs)
- `main_story_ending_seen`, `cut_story_ending_seen`, `contact_story_ending_seen`

Existing completed ending flags provide migration defaults. New explicit incomplete story flags replay presentation after interruption, without catching or paying again. Ending-content SKIP persists the same completion flags as natural playback. Contact continues to derive No.00 count two from the existing saved contact flag. Load performs no migration write; normal event saves remain event-based.

## Review

The narrative acceptance suite exercises actual No.15/No.00 fights and choices, separate cut/contact runs, interrupted story saves, migration, touch skip, safe UI bounds and 44px SKIP targets. Browser fixtures only prepare isolated local IndexedDB states for presentation QA; they do not alter normal saves or expose debug controls in the game.

Human review remains required for opening interest, motivation clarity, journal pacing, main-ending satisfaction, hidden-ending impact, mystery preservation and physical iPhone/Android usability. Automated PASS does not establish these subjective qualities.
