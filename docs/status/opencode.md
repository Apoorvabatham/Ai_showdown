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

## O2b: Donald props

State: **review** — `scripts/supers/scenes/tariff_stamp.gd` and the victory scene now load
these instead of Claude's stand-ins; the scenes and their timings are unchanged.

- `assets/props/supers/donald/shipping_container.tscn`: 1.2 × 0.5 × 0.5 m cartoon
  container, corrugated long sides, raised IMPORTS panels (front -Z), two door leaves with
  hinges and locking bars at the +X end, corner castings.
- `assets/props/supers/donald/tariff_stamp.tscn`: 2.3 m giant rubber stamp (red rubber
  base, wooden block/plate, handle and knob), origin at the middle of the rubber base's
  underside; the underside reads TARIFF mirrored.
- `assets/props/supers/donald/office_desk.tscn`: 2.4 × 1.2 m, 0.78 m tall dark-wood
  executive desk with two drawer pedestals, brass pulls, modesty panel and plinth.
- `assets/props/supers/donald/us_flag.tscn`: 4.3 m pole with gold finial and a `Cloth`
  child hinged at the pole (the victory scene swings it); 13 stripes and a star canton.
- `donald/tariff_mark.tscn` (not on the board, but the tariff scene loads it): the flat red
  TARIFF mark left on the desk, replacing the last stand-in in that scene.
- `tools/build_super_props.gd` builds the set (user args now filter folders, e.g.
  `-- donald`); `tools/render_super_props.gd` (new) renders
  `docs/review/opencode/props_donald.jpg` (fitted cells, front-left view).
- Note: the TARIFF mark reads correctly from the scene's `Cam_Desk` (+Z); the review sheet
  looks from the prop contract's front (-Z), so the text appears mirrored there.
- `godot --headless --path . -s res://tests/sim_test.gd`: `0 failure(s)`.

## O2c: Jensen leather jacket

State: **review** — the tornado scene already loads `jensen/leather_jacket` when it exists,
so no scene change was needed.

- `assets/props/supers/jensen/leather_jacket.tscn`: open black leather jacket, ~1.9 m
  across with the sleeves out; back, side and flared front panels, open zip edges with
  pulls, collar and lapels, rounded shoulders, bent sleeves with cuffs, dark lining,
  waistband and a small red maker's tag. Origin at the middle of the chest like the scene's
  stand-in (the scene places it on Jensen's chest), front = -Z.
- `tools/build_super_props.gd` now builds Jensen's folder too (`-- jensen`).
- `tools/render_super_props.gd`: wide props are now framed from a lower front-left angle,
  and a centered prop (this jacket) is grounded at its own bounds; regenerated the Donald
  sheet with the same tool. New `docs/review/opencode/props_jensen.jpg`.
- `godot --headless --path . -s res://tests/sim_test.gd`: `0 failure(s)`.


