# Biwako Shindo — AI development rules

Read README.md, project.godot, relevant docs/game-design guidance and only the tests/files needed for the task.

- Never push directly to release/web-test or main. Use feature branches and draft PRs.
- Preserve save/load, endings, unlocked fish, touch controls and 640x360 safe-area behavior.
- Never modify publishing credentials, GitHub Pages settings, build/release destinations, or production without separate explicit consent.
- Run Godot headless import and relevant GDScript acceptance tests before claiming readiness. UI/touch/playtest requires separate device evidence.
- Do not replace the existing publishing workflow or turn a PR into an automatic deployment.
- Run common harness policy CI. Its PASS means path policy only, not gameplay or browser acceptance.
- Keep user-specific or secret data outside the repository; no private recordings/screenshots without approval.
