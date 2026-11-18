# OpenCode status

OpenCode updates this file (branch `opencode/work`). One section per task: id, state
(`in progress` / `review` / `done`), what changed, screenshots in `docs/review/opencode/`,
and any requests for other agents.

## O6: Fighting-style animations (contract §3.6)

State: **review** — all six fighters delivered (tesla, Donald, Sundar, Jensen, Zuckerbot,
Xi; the last three by Claude after Cline stopped). Clips are **not** wired into the moves
(Gemini does that).

- `tools/build_style_animations.gd` (new): builds `assets/animations/style_anims.res`, an
  `AnimationLibrary` meant to be added under the name `style` (move clips then read
  `style/<fighter>_<move>`). The pose/IK toolkit is copied from
  `tools/build_fight_animations.gd`; that file was not edited. Run headless to rebuild:
  `godot --headless --path . -s res://tools/build_style_animations.gd`.
- Every one-shot clip starts and ends on the `fight/guard` pose (0.08 s blend), so it drops
  in and out of the guard loop. Idle and walk clips loop; movement clips are in place.
- Review strips: `godot --rendering-driver opengl3 --path . -s
  res://tools/build_style_animations.gd -- render [<fighter>]` renders four poses per clip
  into `docs/review/opencode/style_<fighter>.jpg` and prints the lengths.

### tesla man (fast, jumpy)

`docs/review/opencode/style_tesla.jpg` — row per clip, sampled at start / wind-up / impact /
end.

| clip | length (s) | animation_impact (s) | notes |
|---|---|---|---|
| `tesla_idle` | 0.80 | — (loop) | bouncing guard, two light bounces, up on the balls of the feet |
| `tesla_jab` | 0.28 | 0.08 | lead-hand snap, shoulder rolls in behind the chin |
| `tesla_cross` | 0.34 | 0.14 | rear straight, hip drive, rear heel pivots |
| `tesla_flying_knee` | 0.56 | 0.18 | leaping rear knee at chest height, toes down, both hands pull toward the knee |
| `tesla_spin_back_kick` | 0.56 | 0.22 | turns his back, rear heel spears straight back, spin completes |
| `tesla_dash` | 0.42 | — (movement) | low forward burst, lead knee up, rear leg drives behind |

### donald (slow, heavy)

`docs/review/opencode/style_donald.jpg`.

| clip | length (s) | animation_impact (s) | notes |
|---|---|---|---|
| `donald_idle` | 2.40 | — (loop) | wide stance, feet turned out, hands hanging low, slow breath and weight rock |
| `donald_haymaker` | 1.00 | 0.58 | torso coils away, rear fist swings wide through the centreline, follows past |
| `donald_overhead` | 1.08 | 0.60 | both fists rise above the head, then he bends over and drives both locked fists down in front (Claude, Nov 18) |
| `donald_shove` | 0.86 | 0.32 | step in, palms drawn to the chest, both arms drive out at chest height |
| `donald_walk` | 2.00 | — (loop) | Walk_Carry legs in place; head and chest upright over the hips, slight forward lean, heavy side-to-side sway, arms low in front |

### sundar (upright and precise)

`docs/review/opencode/style_sundar.jpg`.

| clip | length (s) | animation_impact (s) | notes |
|---|---|---|---|
| `sundar_idle` | 2.00 | — (loop) | upright technical guard, small weight shifts, head level |
| `sundar_jab` | 0.36 | 0.10 | precise lead jab, chin stays behind the shoulder |
| `sundar_cross` | 0.44 | 0.14 | rear straight with a clean hip drive |
| `sundar_cast` | 0.72 | 0.26 | lead hand traces a curve, then a palm flick forward |
| `sundar_sweep` | 0.72 | 0.26 | drops onto the rear leg, lead leg shoots out straight and low toward the opponent, foot skimming the floor (Claude, Nov 18) |
| `sundar_walk` | 1.57 | — (loop) | alert walk in guard, hands tucked at the chin |


### jensen (showman) — Claude, Nov 18

`docs/review/opencode/style_jensen.jpg`.

| clip | length (s) | animation_impact (s) | notes |
|---|---|---|---|
| `jensen_idle` | 2.40 | — (loop) | loose guard, a jacket-collar shoulder shrug every other beat |
| `jensen_hook` | 0.50 | 0.20 | lead hook, elbow up, hips turning through |
| `jensen_uppercut` | 0.56 | 0.22 | dips on bent knees, rear fist drives straight up |
| `jensen_backfist` | 0.62 | 0.28 | spins on the lead foot, rear backfist at head height |
| `jensen_walk` | Walk length | — (loop) | presenter walk, lead hand out to the crowd |

### zuckerbot (stiff, robotic) — Claude, Nov 18

`docs/review/opencode/style_zuckerbot.jpg`. Keys snap (no easing) between poses.

| clip | length (s) | animation_impact (s) | notes |
|---|---|---|---|
| `zuckerbot_idle` | 2.00 | — (loop) | square guard, head turns in mechanical steps |
| `zuckerbot_punch` | 0.40 | 0.12 | rigid straight punch, no hip turn, snaps back |
| `zuckerbot_front_kick` | 0.52 | 0.20 | stiff push kick at waist height, sole first |
| `zuckerbot_dash` | 0.40 | — (movement) | upright glide, arms locked at the sides |
| `zuckerbot_hurt` | 0.50 | — | glitchy three-step recoil, then reboots to guard |

### xi (composed, rooted) — Claude, Nov 18

`docs/review/opencode/style_xi.jpg`.

| clip | length (s) | animation_impact (s) | notes |
|---|---|---|---|
| `xi_idle` | 3.00 | — (loop) | low wide stance, slow breathing |
| `xi_palm_push` | 0.56 | 0.20 | sinks, lead palm pushes straight out |
| `xi_sweep` | 0.72 | 0.28 | drops on the rear leg, lead leg shoots out low |
| `xi_fan_strike` | 0.62 | 0.24 | both hands sweep out together like a fan |
| `xi_walk` | Walk length / 0.75 | — (loop) | slow composed walk, hands behind the back |

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

## O4: AGI phase looks

State: **review** — the three palettes ship with `algorithm`; C10 only has to call the
hook on a phase change.

- `tools/build_outfits.gd`: `_bodysuit_spec()` takes optional `variants` (extra suit/glow
  palettes). `algorithm` now carries two: phase 2 "agent" (near-black green suit, acid
  green glow) and phase 3 "superintelligence" (dark maroon suit, hot red glow). The
  generator writes them to the new `CharacterData.variant_outfit_colors`.
- `scripts/character_data.gd`: new additive `variant_outfit_colors: Array[PackedColorArray]`
  (same per-slot layout as `outfit_colors`).
- `scripts/fighter/fighter_model.gd`: new `set_look_variant(index)`: -1 = the normal look
  (or the mirror-match look on an alt build), 0.. = a variant palette. It repaints the
  outfit's surface materials in place (albedo and the glow slot's emission), cosmetic
  only, no rebuild and no simulation state. C10 can call it from the phase transition;
  the existing glitch overlay and red stage lights stay C10's.
- `tools/render_phase_looks.gd` (new): renders the three looks full length with an
  upper-body close-up each; `docs/review/opencode/agi_phases.jpg` (new).
- `godot --headless --path . -s res://tests/sim_test.gd`: `0 failure(s)`.
