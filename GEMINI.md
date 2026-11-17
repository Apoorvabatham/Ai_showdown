# Notes for Gemini

Read [AGENTS.md](AGENTS.md) first: it lists the docs to read and the shared rules.

Your area (see the Gemini tasks in [docs/TASKS.md](docs/TASKS.md) §4):
- **Stages**: the realism pass (`scripts/stages/stage_retheme.gd`, `scenes/stages/`), CC0
  props in `assets/stage_props/`, stage sounds in `assets/audio/stage/`, crowd content in
  `data/stage_life/`.
- **Writing**: story scripts in `data/story/`, docs prose.

Work on one stage (or one fighter's story) at a time, take screenshots for the owner
(`tools/render_screenshots.gd`, `tools/render_stage_thumbs.gd`, needs a display or xvfb),
and keep the tests at `0 failure(s)`.
