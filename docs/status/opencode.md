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

## O2d: Zuckerbot props

State: **review** — both consumers (`metaverse_trap.gd`, `victory/zuckerbot.gd`) already
load these through `prop()` / `Fx.wear`.

- `assets/props/supers/zuckerbot/vr_goggles.tscn`: chunky VR headset with a dark shell, a
  glowing lens band behind a dark frame, rubber face pads with a nose notch, side arms,
  top strap and head band. Origin between the eyes, +Z front — this follows the consumer
  convention documented in `zuckerbot_fx.gd` rather than contract §3.1's -Z, because the
  goggles are worn on the head bone.
- `assets/props/supers/zuckerbot/metaverse_kit.tscn`: low-poly floating island (pastel
  grass slab, two faceted rock layers, pink rock tip, a pond and grass tufts), a cartoon
  tree with four pastel canopies, three glowing crystals on little rock bases, and a small
  cloud. Named groups `Island`, `Tree`, `Crystals`, `Cloud`; origin at the rock tip.
- `tools/build_super_props.gd` builds Zuckerbot's folder (`-- zuckerbot`);
  `tools/render_super_props.gd` views `vr_goggles` from its +Z front and frames wide props
  from a lower angle. New `docs/review/opencode/props_zuckerbot.jpg`.
- `godot --headless --path . -s res://tests/sim_test.gd`: `0 failure(s)`.

## O2e: Sundar browser window

State: **review** — `not_found.gd` already loads it; every child it looks up is present with
the expected type (`Url` Label3D, `Progress`, `PageLoading`, `PageError`, `PageTint`,
`Inside` Marker3D).

- `assets/props/supers/sundar/browser_window.tscn`: giant 4 x 3 m browser window: title bar
  with app icon and window buttons, toolbar with back/forward/reload buttons, address bar
  and typed URL, loading progress track/bar, page backing with bevel, scrollbar, a skeleton
  loading page with spinner and "Loading...", and the hidden 404 page. The page faces +Z,
  like the scene's stand-in (the cameras and the trapped fighter are on that side); root
  origin is the floor under the window's centre.
- `tools/build_super_props.gd` builds Sundar's folder (`-- sundar`);
  `tools/render_super_props.gd` views it from the page side. New
  `docs/review/opencode/props_sundar.jpg`.
- `godot --headless --path . -s res://tests/sim_test.gd`: `0 failure(s)`.

## O2f: Xi paper dragon

State: **review** — `projectile_looks.gd` builds its code look only when the prop is
missing, so the scene picks this up; the `segment` / `rest_y` meta match what its
`animate()` expects.

- `assets/props/supers/xi/paper_dragon.tscn`: ~2.6 m festival dragon, front -Z, root origin
  at the head's centre (a projectile, like the code look, not a floor prop). `Head`
  (metadata `segment` 0, `rest_y` 0): red skull/snout/jaw, glowing gold eyes with pupils and
  gold rims, brows, antler horns with branches, whiskers with beads, fangs, gold nose
  bridge, jaw trim, mane and crest, plus a warm omni light. `Segment1`..`Segment7`
  (metadata `segment` 1..7, `rest_y` -0.02 i): tapered red hoops, gold rings, top fins, red
  under-fringes and a gold tail fan.
- `tools/build_super_props.gd`: `-- xi` builds the set. Also fixed `_sphere()`: it never set
  `SphereMesh.height`, so every sphere was a 1 m tall ellipsoid. Rebuilt and re-rendered
  Donald, Jensen and Zuckerbot (flag finial, shoulder pads, tree canopy/cloud now round);
  refreshed those sheets.
- `docs/review/opencode/props_xi.jpg` (new); regenerated `props_donald.jpg`,
  `props_jensen.jpg`, `props_zuckerbot.jpg`.
- `godot --headless --path . -s res://tests/sim_test.gd`: `0 failure(s)`.

## O7: Sundar search bar, Jensen GPU card

State: **review** — `projectile_looks.gd` keeps its code looks for now; Claude swaps these
in when a prop exists. The child names match what the animation looks for (`Fan1`, `Fan2`;
`Query` is there if the swap wants to set the text).

- `assets/props/supers/sundar/search_bar.tscn`: ~1.8 x 0.44 m search bar: a glowing blue
  outline behind a white pill, magnifier, `Query` Label3D ("how to win a fight") and a
  blue light. Origin at the pill's centre and face +Z, like the code look (the projectile
  turns that side to the camera).
- `assets/props/supers/jensen/gpu_card.tscn`: ~0.95 x 0.36 m card: dark shroud, silver
  backplate, green accent strip and fan hubs, two `Fan1` / `Fan2` fans (7 blades, rings,
  hubs), gold PCIe fingers, a two-slot bracket and a power socket, green light. Origin at
  the card's centre; the fans face +Z like the code look (the consumer tumbles it anyway).
- `tools/build_super_props.gd`: `-- sundar` / `-- jensen` build them;
  `tools/render_super_props.gd` views both from +Z on the refreshed
  `props_sundar.jpg` and `props_jensen.jpg`.
- `godot --headless --path . -s res://tests/sim_test.gd`: `0 failure(s)`.

## O3: stage NPCs

State: **review** — every id `data/stage_life/*.json` references now has a look
(`data/npcs/<id>.tres`), so `StageActor` no longer falls back to the capsule stand-in.

- 44 new NPCs across the four stages, in `tools/build_npcs.gd`: the Senate (chair,
  senator_1..4, stenographer, press_1..3, aide_1..3, citizen_1..3), the mensa (cook,
  cashier, student_1..10, grad_student), the foundry (technician_1..4, lead_architect,
  quality_inspector, cleanroom_guard, cleanroom_aide) and the server farm (sysadmin_1..2,
  noc_lead, cloud_architect, devops_tech, site_reliability, intern, field_engineer).
  They share the generated table with the three helpers; optional fields (hair, skin,
  eyes, shape, posture, accessories) are filled by `_expand()` and per-id seeded random
  face/shape/posture, so they stay reproducible.
- Female NPCs use `Superhero_Female_FullBody.gltf` and the two female skins; 15 of the 44
  are female. Body shapes (stocky, tall and slim, broad), posture presets (upright,
  slouch, lean-forward) and scales vary the silhouettes; sizes sit between 0.92 and 1.09.
- `tools/build_outfits.gd`: outfit specs for all 44 (suits and blazers for the Senate and
  offices, zhongshan for the cook and lead architect, cardigans, sweaters, hoodies, tees
  and leather jackets for the crowds and the server farm) plus a new `_coverall_spec()`:
  cleanroom coverall with standing collar, front zip and pull, ankle cuffs, pale booties
  and the hood bunched on the back. `_suit_spec`'s `alt_tie` now accepts `null` (open
  collar variants).
- `tools/render_npcs.gd`: still renders the four-panel helper sheet; a stage name now
  renders that stage's people as a full-body grid with the id under each person, ids read
  from `data/stage_life/<stage>.json`.
- `docs/review/opencode/npcs_senate.jpg`, `npcs_mensa.jpg`, `npcs_foundry.jpg`,
  `npcs_server_farm.jpg` (new). Rebuilt `npcs_helpers.jpg`.
- Notes: glasses and thick glasses are the only accessory pieces the model supports, so
  the NPCs vary by hair and face rather than by hats or badges; the outfits are fitted to
  the body, which reads tighter on the female base (fine at stage distance).
- `godot --headless --path . -s res://tests/sim_test.gd`: `0 failure(s)`.
