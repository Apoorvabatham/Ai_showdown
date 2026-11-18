# OpenCode status

OpenCode updates this file (branch `opencode/work`). One section per task: id, state
(`in progress` / `review` / `done`), what changed, screenshots in `docs/review/opencode/`,
and any requests for other agents.

## O5: Xi's OpenCode helpers (helper_qwen, helper_alibaba, helper_kimi)

State: **review** — `open_source_squad.gd` now loads the real NPCs instead of the kit
stand-ins. Clips, poses and the scene flow are unchanged.

- `tools/build_npcs.gd` (new): builds `data/npcs/<id>.tres` as look-only CharacterData on
  the male base body and the shared outfit/face pipeline. Three made-up young engineers,
  all distinct: Qwen (tall and slim, slicked side part, glasses, indigo tee), Alibaba
  (short and stocky, buzzed, orange tee) and Kimi (tallest, curly mop, black tee).
- `tools/build_outfits.gd`: finds kits, fighters and now NPCs (`data/npcs/`), and has
  `_npc_specs()` (tee, jeans, sneakers); generated `assets/characters/outfits/helper_*`.
- `tools/build_prints.py`: a plain `wordmark()` design and the chest prints Qwen, Alibaba
  and Kimi (no logos, just the word over an accent bar), written to
  `assets/characters/prints/T_helper_*_tee.png`.
- `tools/render_npcs.gd` (new): review sheet; screenshot
  `docs/review/opencode/npcs_helpers.jpg` (front, side, chest print, head per helper).
- `godot --headless --path . -s res://tests/sim_test.gd`: `0 failure(s)` — including
  "Xi's Open-Source Squad runs in (Qwen, Alibaba, Kimi)" with the new data.

Requests: none. Rebuild order for this task: `python tools/build_prints.py` →
`godot --headless --path . --import` → `tools/build_npcs.gd` →
`tools/build_outfits.gd -- helper_qwen helper_alibaba helper_kimi`.
