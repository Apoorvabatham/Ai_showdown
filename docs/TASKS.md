# Task board

Three agents work on this repo in parallel. The design is in [ROADMAP.md](ROADMAP.md); setup
and traps are in [HANDOFF.md](HANDOFF.md). **Read both before your first task.**

| Agent | Strength | Owns |
|---|---|---|
| **Claude** (Claude Code) | Fast; orchestrator | Core code and logic: fight engine, moves, supers' gameplay and choreography, AI, frameworks, modes, tests, this board. Visuals only as **simple stand-ins** |
| **OpenCode** (DeepSeek) | Character design | **Everything about how people and objects look**: fighter looks (likeness pass), NPCs, super props, fight animations' poses |
| **Gemini** | Steady, thorough | **Everything about how places look**: stages, super-scene sets, victory-scene sets, lighting and post-processing; assets, sounds, story, docs |

**Rule of thumb (owner, Nov 2026):** making things *look real* (characters, maps, sets, props,
lighting, materials, animation poses) is OpenCode's or Gemini's job. Claude builds the logic
and a simple stand-in, then hands the look over through a contract (§3).

The owner (the human) approves fighter looks, movesets and anything visual, and decides
what is next.

## 1. Workflow (everyone)

### Branches
| Branch | Who works there |
|---|---|
| `main` | **Main branch** (integration). Claude works here and merges the others in. |
| `opencode/work` | OpenCode (DeepSeek) only |
| `gemini/work` | Gemini, then Kilo Code |
| `cline/work` | Cline (Nemotron 3.5 Super VL): super props |

1. Work **only on your own branch**: `git fetch origin && git checkout <your branch>`.
   Never push to another agent's branch or to the main branch.
2. Stay up to date: at the start of every task run
   `git fetch origin && git merge origin/main` (the main branch).
3. Edit **only files you own** (§2). If you need a change in someone else's file, write it
   in your status file (step 5) under "Requests".
4. Commit small, with the task id: `[O2] Rocket prop`, `[G3] Mensa lighting`. Push your branch.
5. **Report status in your own file**, not in this board: `docs/status/opencode.md` or
   `docs/status/gemini.md` (task id, state, what changed, screenshots, requests). Claude reads
   it, updates this board and merges your branch into the main branch.
6. Before pushing: `godot --headless --path . -s res://tests/sim_test.gd` must end with
   `0 failure(s)`.
7. Conflict in a generated file (`data/characters/*.tres`, `data/moves/**`)? Take either
   side, then **re-run the generators** (HANDOFF §5) and commit the result.
8. Done = tests pass, renders or screenshots for visual work in `docs/review/` (your own
   subfolder: `docs/review/opencode/`, `docs/review/gemini/`), state `review` in your status
   file. The owner approves; Claude merges.

## 2. File ownership

| Path | Owner |
|---|---|
| `scripts/fighter/**`, `scripts/fight_manager.gd`, `scripts/ai/**`, `scripts/fx/**`, `scripts/camera/**` | Claude |
| `scripts/supers/**`, `scripts/stage_life/**`, `scripts/story/**`, `scripts/autoload/**`, `scripts/ui/**` | Claude |
| `tests/**`, `tools/build_movesets.gd`, `tools/showdown_movesets.gd`, `tools/build_fight_animations.gd`, `assets/animations/**` | Claude |
| `tools/build_showdown_roster.gd`: the `moves`, `damage`, `stats` keys | Claude |
| `tools/build_showdown_roster.gd`: every look key (skin, hair, face, shape, posture, scale, accessories, prints, colours) | OpenCode |
| `tools/build_outfits.gd`, `tools/build_custom_hair.gd`, `tools/face_sculpt.gd`, `tools/build_aged_skins.*`, `tools/build_prints.py`, `tools/render_*.gd` | OpenCode |
| `assets/characters/**`, `assets/ui/portraits/**`, `assets/ui/cutins/**` | OpenCode |
| `tools/build_npcs.gd`, `data/npcs/**` | OpenCode |
| `tools/build_super_props.gd`, `assets/props/**`, `docs/status/cline.md`, `docs/review/cline/**` | Cline |
| `scripts/stages/**` (incl. `stage_retheme.gd`), `scenes/stages/**` | Gemini |
| `scenes/supers/sets/**` (super- and victory-scene sets, contract §3.5; Claude creates each stand-in first) | Gemini |
| `tools/build_style_animations.gd`, `assets/animations/style_anims.res` (contract §3.6) | OpenCode |
| `assets/stage_props/**`, `assets/audio/stage/**`, `data/stage_life/**`, `data/story/**` | Gemini |
| `assets/CREDITS.md`, `LICENSE-ASSETS.md` | anyone adding assets (append only) |
| `README.md`, `docs/**` (except this board, ROADMAP and status files) | Gemini for prose; anyone may fix facts |
| `docs/status/opencode.md`, `docs/review/opencode/**` | OpenCode |
| `docs/status/gemini.md`, `docs/review/gemini/**` | Gemini |
| `docs/status/opus.md`, `docs/review/opus/**` | Opus 4.6 (on `gemini/work`) |
| `docs/TASKS.md`, `docs/ROADMAP.md` | Claude |
| `data/characters/**`, `data/moves/**` | generated: never hand-edit |

## 3. Contracts between agents

### 3.1 Super props (OpenCode → Claude)
- Path: `assets/props/supers/<fighter_id>/<prop>.tscn`, built by `tools/build_super_props.gd`
  (procedural meshes like `tools/build_custom_hair.gd`, or CC0 models with credits).
- Root `Node3D`, **no scripts**, metres, origin at the bottom centre, front faces **-Z**.
- Parts that animate are separate child `MeshInstance3D`s with the names given below.
- Under 30k triangles per prop; textures at most 1024 px, VRAM-compressed (HANDOFF §8).
- Glow parts: emissive `StandardMaterial3D` (Claude adds bloom and animation).

Super-scene sets (rooms, launch pad, space, Mars, metaverse) are built by Claude in code;
props are the objects in them. Scale for **giant** props is real-world: Claude scales them.

### 3.2 NPC models (OpenCode → Claude)
- `data/npcs/<npc_id>.tres` as `CharacterData` (look fields only, no moves), built by
  `tools/build_npcs.gd` with the same body/outfit/face pipeline as the fighters.
- **Made-up generic people, never real persons.** Mix ages, builds, men and women
  (the female base bodies are used by the aelia/rhea/valka/mira kits).
- Claude's `StageActor` and super-scene puppets load them through `FighterModel` and play
  UAL clips on them.
- T-shirt prints go through `tools/build_prints.py` like the fighters' tees.

### 3.3 Stage-life data (Gemini → Claude's loader)
`data/stage_life/<stage>.json` (stage = `server_farm`, `mensa`, `senate`, `foundry`):
```json
{
  "actors": [
    {"npc": "student_1", "pos": [3.0, 0.0, -4.2], "yaw": 180, "pose": "sit",
     "reacts": ["cheer", "gasp"], "role": "crowd"}
  ],
  "shouts": {
    "big_hit": ["Oof!", "Did you see that?"],
    "super": ["NO WAY!"],
    "ko": ["It's over!"],
    "round_start": ["Fight! Fight! Fight!"]
  },
  "events": {"ko": ["food_fight"], "super": ["camera_flashes"]}
}
```
Shout lines are **shown as speech bubbles and spoken**. Voice file for line *n* (0-based) of a
shout key: `assets/audio/stage/<stage>/voice/<key>_<n>.ogg` (e.g. `senate/voice/ko_0.ogg`).
A line without a voice file still shows its bubble.

Poses: `stand`, `sit`, `lean`, `work`. Reactions: `cheer`, `gasp`, `clap`, `point`,
`stand_up`, `bang_table`, `gavel`, `photo`. Shout and event keys: `big_hit`, `super`, `ko`,
`round_start`, `throw`, `wall_hit`. Events: `camera_flashes` (uses actors with role `press`),
`gavel` (actor with role `chair` shouts "Order!"; sound `assets/audio/stage/<stage>/gavel.ogg`
if present), `food_fight`, `sparks`, `spark_shower`, `steam_burst`, `alarm`. An event entry is a
name or `{"event": "sparks", "pos": [x, y, z]}` (sparks and alarm look best with a `pos`).
At most 20 actors and 2 bubbles at once. A working example: `tests/fixtures/stage_life_example.json`.

Animation clip names drop the `_Loop` suffix of the UAL files: `ual1/Idle`,
`ual1/Sitting_Idle`, `ual1/Walk`, `ual1/Dance`, `ual2/Idle_Rail`...
Coordinates: stage space, fight area is about x ∈ [-6, 6], z ∈ [-2, 2]; keep actors outside
it and out of the camera's way.

### 3.5 Super- and victory-scene sets (Claude stand-in → Gemini makes it real)
- One scene file per set: `scenes/supers/sets/<set>.tscn` (e.g. `launch_pad`, `space`,
  `mars`, `oval_office_desk`, `metaverse`, `browser`), root `Node3D`, no scripts.
- It holds the **place**: floor, walls, sky / `WorldEnvironment`, lights, static dressing.
- It must keep the **Marker3D anchors** Claude's stand-in has (names like `Attacker`,
  `Opponent`, `Prop_Rocket`, `Cam_1`, `Cam_2`...): Claude's scene script puts the fighters,
  props and cameras on them. Move them if needed; don't rename or delete them.
- The set sits far from the stage (Claude places it); keep it within about 30 × 30 m.
- Claude adds the task to §4 when a stand-in exists ("G8: dress `<set>`").

### 3.6 Fight animations (OpenCode → Claude)
- New per-fighter punches, kicks, movement, power-move and super poses go in their own
  library: `tools/build_style_animations.gd` builds `assets/animations/style_anims.res`
  (library name `style`, clips `style/<fighter_id>_<move>`), with the same pose/IK toolkit as
  `tools/build_fight_animations.gd` (copy what you need; don't edit that file).
- For each clip, write in `docs/status/opencode.md`: its length and the time (s) the strike
  lands (`animation_impact`). Claude wires clips into the moves and tunes the frame data.
- Claude asks for clips per fighter in §4 (task O6).

### 3.4 Story script (Gemini → Claude's story mode)
`data/story/<fighter_id>.json`:
```json
{
  "intro": ["Line shown over the fighter's cut-in.", "Second line."],
  "fights": [
    {"opponent": "yann", "stage": "mensa",
     "before": [{"who": "ram", "line": "..."}, {"who": "yann", "line": "..."}],
     "after_win": [{"who": "ram", "line": "..."}]}
  ],
  "rival": "tesla",
  "ending": ["Ending panel 1.", "Ending panel 2.", "Ending panel 3."]
}
```
6 fights: 4 regular, the rival (5th), then AGI (6th, stage `senate`). Lines ≤ 90 characters.
Tone: fun parody of public personas and ideas, never humiliating, sexual or ethnic.

## 4. Tasks

Status: `todo`, `in progress (<agent>)`, `review`, `done`, `blocked`.

### Claude (core)

| ID | Task | Depends | Status |
|---|---|---|---|
| C0 | Collaboration docs (this board, ROADMAP, AGENTS.md), "fun project" wording | — | done |
| C1 | Per-fighter moveset system: `tools/showdown_movesets.gd` overrides (remove/tweak/add/stats/trials); per-fighter CPU personality and showcase via `CharacterData.lookup()` with kit fallback | — | done |
| C2 | New engine features: multi-shot / burst / sky projectiles, barriers, reflect, teleport, meter drain, `super_fx` id (MoveData fields; all in saved state; tests in `engine_feature_tests()`) | C1 | done |
| C2b | New fight animations for the new moves (toolkit in `build_fight_animations.gd`, unused UAL clips) | C1 | todo |
| C3 | Sundar moveset (ROADMAP §1.2): Trapper CPU style, showcase, 6 trials | C2 | review |
| C4 | Donald moveset: Trade War containers (236P, power move), Build the Wall (214P barrier), armoured Executive Order and Trade War Tackle, You're Fired grab, Tycoon CPU style, 6 trials; balance ~51% | C2 | review |
| C5 | Xi moveset: Fortress (no armour, wall-carry Belt and Road Rush, low Social Credit Hammer shockwave, 214K Censorship reflect, 63214P Paper Dragon Dance power move, CPU style, showcase); balance ~47%. Still to do: Zuckerbot and tesla normals/styles | C2 | review |
| C6 | AGI boss kit | C2 | todo |
| C7 | Super- and victory-scene frameworks (`scripts/supers/`: SuperScene, VictoryScene, ScenePuppet, SuperScenePlayer, VictoryScenePlayer, SuperStandins; `MoveData.cinematic` + `cinematic_ticks`; `FightManager.match_won`). First scenes: tesla man's Rocket Launch super and Mars victory; stand-in sets `launch_pad`, `space`, `mars` (`tools/build_super_sets.gd`) | — | done |
| C8 | Per fighter: power move + super scene + victory scene (ROADMAP §2). Done: power moves tesla, Jensen, Sundar, Donald, Xi; super scenes tesla (Rocket Launch), Xi (Open-Source Squad); victory tesla (Mars). WIP branches (§7): Donald, Zuckerbot, Sundar + Jensen | C7 | in progress (handed off) |
| C9 | Stage-life framework (`scripts/stage_life/`: StageCrowd, StageActor, ShoutBubble, StageEvents; loads `data/stage_life/<stage>.json`, cosmetic and rollback-safe; test fixture `tests/fixtures/stage_life_example.json`) | — | done |
| C10 | AGI phases + mimicry + phase transitions | C6 | todo |
| C11 | Story mode screens and flow | G1 (one fighter is enough to start) | todo |
| C12 | 1v1 Quick Match: player vs a random CPU, random stage, one round (`GameState.Mode.QUICK`) | — | done |

### OpenCode (character design) — branch `opencode/work`

Start with O2a, then O5, then O3. All can start now (no dependency on Claude's code).

| ID | Task | Depends | Status |
|---|---|---|---|
| O1 | Likeness pass: whatever the owner asks next for fighter looks (HANDOFF §2–§5) | — | ongoing |
| O2a | **tesla man** props (contract §3.1): `tesla/steel_pickup` (angular stainless-steel pickup truck, **our own design, no logo or badge**, ~5.6 m long, wheels as children `Wheel_FL`, `Wheel_FR`, `Wheel_RL`, `Wheel_RR`, child `Headlights` emissive strip), `tesla/rocket` (tall rocket ~8 m, white/steel, child `Flame` at the nozzle, child Marker3D `ChainPoint` where a fighter is chained), `tesla/mini_rocket` (~0.6 m power-move shot, child `Flame`), `tesla/mars_flag` (pole ~2.5 m + white cloth child `Cloth` with blank space for the text "CAPTURED") | — | todo |
| O2b | **Donald** props: `donald/shipping_container` (cartoon container ~1.2 × 0.5 × 0.5 m, corrugated sides, doors at one end, blank panel for the word "IMPORTS"), `donald/tariff_stamp` (giant rubber stamp: wooden handle + red rubber base, the base's underside reads "TARIFF" mirrored), `donald/office_desk` (big dark-wood executive desk ~2.4 × 1.2 m), `donald/us_flag` (flag on a pole, child `Cloth`) | — | todo |
| O2c | **Jensen** props: `jensen/leather_jacket` (black leather jacket as a separate prop, open, sleeves out, for the tornado super) | — | todo |
| O2d | **Zuckerbot** props: `zuckerbot/vr_goggles` (chunky VR headset with strap), `zuckerbot/metaverse_kit` (low-poly floating island, cartoon tree, bright pastel colours: 3–4 props) | — | todo |
| O2e | **Sundar** props: `sundar/browser_window` (giant browser window frame ~4 × 3 m: title bar, address bar, close/min buttons, blank page area) | — | todo |
| O3 | NPC models for the stages (contract §3.2), made-up people: `chair` (senior committee chair), `senator_1..3`, `stenographer`, `press_1..2`, `student_1..6`, `cook`, `cashier`, `technician_1..3` (bunny suits), `sysadmin_1..2` | — | todo |
| O4 | AGI phase looks: material/colour variants for phase 2 and 3 (glitch, red), as alt outfits on `algorithm` | — | todo |
| O6 | **Fighting-style animations** (contract §3.6), one fighter at a time when Claude lists the clips. First: `style/tesla_*` (fast, jumpy kicks) and `style/donald_*` (slow, heavy swings, a big shove) | C4 lists clips | blocked |
| O7 | Make the **modelled power-move shots look real**: replace Claude's code-built looks in `scripts/supers/projectile_looks.gd` (search bar, graphics card) with props `sundar/search_bar` and `jensen/gpu_card` (contract §3.1; Claude swaps them in) | — | todo |
| O2f | **Xi** prop: `xi/paper_dragon` (festival paper dragon facing -Z: big red-and-gold head with horns, eyes, whiskers; 7 body segments as children `Segment1`..`Segment7` trailing along +Z so Claude can weave them; ~2.6 m long, ~0.5 m tall; replaces the code look in `scripts/supers/projectile_looks.gd`) | — | todo |
| O5 | **Xi's super helpers** (NPCs, contract §3.2): `helper_qwen`, `helper_alibaba`, `helper_kimi`: three made-up young engineers in T-shirts with the words **Qwen**, **Alibaba** and **Kimi** printed on the chest (owner's request), different builds and hair, sneakers | — | todo |

### Gemini (stages, assets, writing) — branch `gemini/work`

Next, in this order: **G4** (Senate first), **G12** (Foundry + Server Farm), **G8/G9** (sets ready
now), **G10**, **G7b**, then G6 once G4 is in. One task at a time, screenshots for each.

| ID | Task | Depends | Status |
|---|---|---|---|
| G1 | Story scripts for all 11 fighters (`data/story/`) | — | done |
| G2 | CC0 models/textures for the 4 stages (`assets/stage_props/`) | — | done |
| G3 | Realism pass for the 4 stages (props, PBR, reflection probes, fog) | G2 | review (owner) |
| G4 | Stage-life content: `data/stage_life/<stage>.json` (actor placement, shout lines, events) for each stage, Senate first (example: `tests/fixtures/stage_life_example.json`). Stand-in people appear until O3's NPCs exist | C9 | todo |
| G5 | Stage sounds for the 4 stages (`assets/audio/stage/`) | — | done |
| G6 | Voices for the stage shout lines (contract §3.3 naming): an offline TTS with a licence that allows use in a game (e.g. Piper with a permissively licensed voice; note the licence in `assets/CREDITS.md`), several different voices per stage (chair, students, press...), OGG, normalised, short | G4 | blocked |
| G8 | **Dress the super-scene sets** (contract §3.5) so they look real, one at a time: `launch_pad` (sunset rocket launch site: real pad, tower, floodlights, distant buildings) and `space` (stars, a real-looking Earth with clouds and atmosphere) are ready now; keep every Marker3D | C7 stand-ins | todo |
| G9 | **Dress the victory-scene sets**: `mars` is ready now (red rocky plain, dusty pink sky, far hills: make it look like real Mars); keep every Marker3D | C7 stand-ins | todo |
| G10 | **Fight look**: lighting, `WorldEnvironment` (glow, tonemap, fog, SSAO/SSR where cheap) per stage so fights look less flat; keep 60 fps on mid hardware | — | todo |
| G7 | Super and victory sounds for tesla, Donald, Jensen, Zuckerbot, Sundar, Xi (`assets/audio/supers/`) | — | done |
| G7b | Sounds for the newly approved moves and scenes, same folder layout: Xi `dragon_drums.wav` (paper dragon dance), Donald `statue_rise.wav` + `fanfare.wav` (golden statues victory), Zuckerbot `metaverse_ambience.wav`, Sundar `page_load.wav`, Jensen `marker_squeak.wav`, Dario/Yann/Geoff/Ram/algorithm one `victory.wav` each (scroll unroll, cat purr, applause, fireworks, digital hum) | — | todo |
| G12 | **Stage realism, round 2** (G3 follow-up): the **Foundry** is washed out (too white, flat): lower the exposure, add contrast, colour and depth (darker machinery, coloured warning lights, glossy floor reflections). The **Server Farm** barely changed: make it read as a real rooftop data centre (rack detail, cable trays, cooling units, wet reflective floor, steam). Compare before/after screenshots | G3 | todo |

## 5. Requests (cross-owner changes)

Add a line: `- [from <agent> to <agent>] what and why`. The owner of the file does it.

- (none yet)

## 6. Open questions for the owner

- (none: 1v1 = Quick Match, one round vs CPU, done; stage shouts = bubbles **and** voices)

## 7. Handoff (Nov 2026): Claude steps back, Opus 4.6 on `gemini/work` continues

Gemini's remaining tasks (G4, G6, G7b, G8–G10, G12) and Claude's tasks (C*) move to
**Opus 4.6 working on `gemini/work`**, which also takes over the
orchestrator role (keep this board, the ROADMAP and the contracts up to date). Start with:
`git fetch origin && git checkout gemini/work && git merge origin/main`.

### State of main (`main`)
Full suite `0 failure(s)` at handoff. Done: per-fighter movesets (C1), engine features
(multi-shot/sky/around shots, barriers, reflect, teleport, meter drain, low shots) (C2), own
movesets for Sundar, Donald, Xi (C3–C5), super- and victory-scene frameworks (C7), stage-life
framework (C9), 1v1 Quick Match (C12), power moves for tesla, Jensen, Sundar, Donald, Xi,
super scenes for tesla and Xi, tesla's Mars victory. Gemini's G1–G3, G5, G7 merged.

### Unfinished work saved on branches (finish, test, render, then merge)
| Branch | What | State |
|---|---|---|
| `wip/donald-scenes` | Donald's super scene `tariff_stamp` (giant Donald, tiny opponent on the desk, TARIFF stamp; set `oval_desk`) + victory `donald` (golden statues, US flags on the stage) | code written; tests and renders not finished |
| `wip/zuckerbot-scenes` | Zuckerbot's super `metaverse_trap` (VR goggles, cartoon metaverse, legs vanish, avatar punches; sets `vr_lobby`, `metaverse`) + victory `zuckerbot` | code written; renders in progress |
| `wip/sundar-jensen-scenes` | Sundar's super `not_found` (browser window, 404, pixelated; set `browser_void`) + Jensen's `jacket_tornado` (set `keynote_stage`), victories | partly written |

Each was written by an agent from the brief in the commit history; read the scene script, run
`godot --headless --path . -s res://tools/build_showdown_roster.gd -- <id>`, the suite, and
`tools/check_trials.gd -- <id>`, render a contact sheet and look at it before merging. Expect
merge conflicts only in `tools/showdown_movesets.gd` and `tests/sim_test.gd` (keep both sides).

### Remaining work, in a sensible order
1. Finish and merge the three WIP branches (above) first: they add the sets `oval_desk`,
   `vr_lobby`, `metaverse`, `browser_void`, `keynote_stage`, which G8 then dresses with the rest. Re-render Xi's squad scene once (helpers
   were just spread out; untested visually).
2. Victory scenes still to build (approved, ROADMAP §2): Sundar, Xi, Jensen, Dario, Yann,
   Geoff, Ram, AGI. Pattern: `scripts/supers/victory/tesla.gd` (own set) or `own_set = false`
   (on the stage).
3. Power moves + super scenes for Dario, Yann, Geoff, Ram, AGI: designs are **proposed**, ask
   the owner to approve each before building.
4. AGI boss: own kit (C6) and phases / mimicry (C10), ROADMAP §4.
5. Story mode screens (C11): scripts are ready in `data/story/`.
6. Per-fighter fighting styles: list the clips each fighter needs for OpenCode's O6.
7. Balance: Geoff is weak (~25% in CPU sims), Jensen a bit strong (~60%).

### Tips and known issues
- Super scenes: copy `scripts/supers/scenes/rocket_launch.gd` / `open_source_squad.gd`; sets
  come from `tools/super_sets/<fighter>.gd` (`tools/build_super_sets.gd` never overwrites).
- Look at renders, not just tests: `xvfb-run ... --fixed-fps 60`, step `_physics_process` once
  per awaited frame (see any `[C8]` commit for the pattern). Put scratch scripts in
  `tools/_tmp_*` (git-ignored).
- **Memory**: the machine holds about two Godot renders or suites at once; more gets processes
  killed.
- Flaky old tests: "Replays: a rematch is saved as a second replay" and "Courtyard: the
  pigeons..." fail now and then; rerun before investigating.

### Update: Gemini's last round merged; Kilo Code continues on `gemini/work`
Gemini finished G4 (crowd content, all 4 stages), G6 (voices), G7b (sounds), G10 and G12
(realism round 2, lighting), merged into main with the suite at `0 failure(s)`. Opus did not
start. **Kilo Code** now works on `gemini/work` and takes everything in "Remaining work" above,
starting with the three `wip/*` branches, then G8 / G9 (dress the sets). New stage screenshots
after G10/G12 were not saved: render fresh ones into `docs/review/kilo/` first.

### Update 2: three agents, three branches (no shared files)
| Agent (model) | Branch | Takes |
|---|---|---|
| Kilo Code (Nemotron 3 Ultra) | `gemini/work` | **Code**: §7 "Remaining work" steps 1–7 (the wip/* branches, victory scenes, AGI boss, story mode, style clip lists, balance). Not the set dressing. |
| Cline (Nemotron 3.5 Super VL) | `cline/work` | **Visuals**: G8 / G9 (make the sets in `scenes/supers/sets/` look real, keep every Marker3D), fresh stage screenshots after G10/G12 and any fixes they show (`scripts/stages/**`, `scenes/stages/**`). Status `docs/status/cline.md`, screenshots `docs/review/cline/`. |
| OpenCode | `opencode/work` | **Only** O2a (tesla props), O2b (Donald props), O5 (Xi's three helpers). The rest of O2/O3/O4/O6/O7 waits. |

Ownership: Cline owns `scenes/supers/sets/**`, `scripts/stages/**`, `scenes/stages/**`, `assets/stage_props/**`,
`docs/status/cline.md`, `docs/review/cline/**`. Kilo owns everything else Claude owned (and must not
edit those set/stage files; new sets it needs: add the builder in `tools/super_sets/` and run
`tools/build_super_sets.gd`, then tell Cline in its status file). Each merges the others' branches
only through main: the owner merges `gemini/work`, `cline/work`, `opencode/work` into
`main` when a task is done.

### Update: Cline joins on `cline/work`; OpenCode keeps only people
- **Cline** takes all prop tasks: **O2a–O2f** and **O7** (contract §3.1), in that order. Props
  swap in automatically: scenes call `prop("<fighter>/<name>", <stand-in>)`, and
  `scripts/supers/projectile_looks.gd` gets a request from Cline (in `docs/status/cline.md`)
  to load `assets/props/supers/<fighter>/<name>.tscn` when it exists (O7).
- **OpenCode** keeps only people: **O5** (Xi's helpers), **O3** (stage NPCs), **O4** (AGI
  phase looks), **O1** on request; **O6** later.

## 8. Status Nov 18 and the next round (Gemini + OpenCode)

**Merged into main** (suite `0 failure(s)`, combo trials pass): super and victory scenes for
tesla, Xi (super), Donald, Zuckerbot, Sundar, Jensen (Kilo finished the wip branches); Cline's
tesla props (`assets/props/supers/tesla/`); dressed `launch_pad`, `space`, `mars` sets; Gemini's
crowds, voices, sounds, realism pass 2. Kilo Code and Cline are done; `cline/work` and the
`wip/*` branches are merged and can be deleted. **The new scenes have not been checked visually
by a person yet.**

### Gemini (`gemini/work`), in order
1. **Look at every super and victory scene** (render contact sheets like the `[C8]` commits, into
   `docs/review/gemini/scenes/`) and fix what reads badly: framing, scale, timing, things hidden.
2. **G8 for the remaining sets**: dress `oval_desk`, `vr_lobby`, `metaverse`, `browser_void`,
   `keynote_stage`, `xi_plaza` (keep every Marker3D; load each in Godot before committing).
3. **Victory scenes** still missing (approved, ROADMAP §2): Xi (lanterns + fireworks), Dario
   (golden scroll), Yann (giant cat), Geoff (worried medal ceremony), Ram ("AGI ACHIEVED"
   banner), AGI (glowing eye on every screen). Pattern: `scripts/supers/victory/donald.gd` (on
   the stage) or `tesla.gd` (own set); add a test each like the existing victory tests.

### OpenCode (`opencode/work`), in order
1. **O5**: Xi's helpers `helper_qwen`, `helper_alibaba`, `helper_kimi` (the squad scene loads
   them automatically from `data/npcs/`).
2. **Props** (Cline only did tesla): **O2b** Donald, **O2c** Jensen, **O2d** Zuckerbot, **O2e** Sundar,
   **O2f** Xi, then **O7**; `tools/build_super_props.gd` already exists: add to it.
3. **O3** stage NPCs (replace the crowd stand-ins), then **O4**.

### Still needs the owner
Power moves and supers for Dario, Yann, Geoff, Ram and AGI (designs **proposed** in ROADMAP §2),
the AGI boss (C6, C10), story mode screens (C11), fighting-style animations (O6), Geoff's balance.

## 9. Status Nov 18 (evening) and the next round (Gemini + OpenCode)

**Merged into main (`main`)**: `gemini/work`
(visual review of all 17 scenes, G8 all sets dressed, G9 victory scenes for Xi, Dario, Yann,
Geoff, Ram, AGI, G13/G14 typography and sets overhaul) and `opencode/work` (O5 Xi's helpers,
O2b–O2f props, O7 search bar and GPU card, O3 stage NPCs, O4 AGI phase looks). Both merged
without conflicts. Start each branch with
`git fetch origin && git merge origin/main`.
Retired branches (all content is on main; delete them, don't work on them): `cline/work`,
`wip/donald-scenes`, `wip/zuckerbot-scenes`, `wip/sundar-jensen-scenes`,
`claude/blissful-meitner-2wmcms`, `claude/brave-rubin-b43he7` (old main, renamed to `main`). Only `main`, `gemini/work` and `opencode/work` are active.

### Gemini (`gemini/work`), in order (code; owns everything Claude owned)
1. **O7 swap**: `scripts/supers/projectile_looks.gd` loads `sundar/search_bar` and
   `jensen/gpu_card` (keep the code looks as fallback; set `Query` text, spin `Fan1`/`Fan2`).
   Do the same for any other `prop()` stand-in that now has a file in `assets/props/supers/`.
2. **C6 AGI kit** (ROADMAP §4): projectile, command grab, reversal, armour, teleport, super
   Engagement Loop, in `tools/showdown_movesets.gd`; tests and `check_trials.gd -- algorithm`.
3. **C10 AGI phases** (ROADMAP §4): 100–60 % Assistant, 60–25 % Agent (faster, armour on
   specials), < 25 % Superintelligence (mimics the player's most used special, meter regen).
   Transition: glitch + red stage lights + `FighterModel.set_look_variant(0 / 1)` (OpenCode's
   O4 palettes). Phase-aware AI in `scripts/ai/ai_controller.gd`. Simulation stays deterministic.
4. **C11 story mode**: screens over the VS style (dialogue boxes with portraits, cut-ins),
   reading `data/story/<id>.json`; intro → 5 fights → rival → AGI → ending. Menu entry, save
   progress, tests.
5. **Balance**: Geoff (~25 % in CPU sims) up, Jensen (~60 %) down, with `tools/balance_sim.gd`;
   target 40–60 % for everyone. Note before/after numbers in the status file.
6. **Wire O6 clips** as OpenCode delivers them (tesla, Donald first), tune frame data.

### OpenCode (`opencode/work`), in order (people, props, animations)
1. **O6 fighting styles** (contract §3.6), unblocked: you write the clip list yourself.
   `tools/build_style_animations.gd` → `assets/animations/style_anims.res`, library `style`.
   - `tesla_*`: fast, jumpy (idle bounce, jab, cross, flying knee, spinning back kick, dash).
   - `donald_*`: slow, heavy (wide stance idle, haymaker, overhead hammer, big shove, walk).
   - Then Sundar, Jensen, Zuckerbot, Xi, in that order.
   For each clip: length and impact time in `docs/status/opencode.md`; render a strip into
   `docs/review/opencode/`.
2. **Prop fixes** from Gemini's contact sheets (`docs/review/gemini/scenes/`): if a prop reads
   badly in a scene (scale, origin, facing), fix it in `tools/build_super_props.gd`.
3. **O1** on request.

### Still needs the owner
Power moves and super scenes for Dario, Yann, Geoff, Ram and AGI (designs proposed in ROADMAP
§2) — approve each before anyone builds them. Look at the 17 scene sheets in
`docs/review/gemini/scenes/` and the NPC sheets in `docs/review/opencode/`.

## 10. Nov 18: OpenCode hands over to Cline (same branch `opencode/work`)

OpenCode delivered O6 for **tesla**, **Donald** and **Sundar** (`style_anims.res`, merged into `main`;
review strips `docs/review/opencode/style_<fighter>.jpg`). OpenCode is out of
quota; **Cline (Nemotron 3.5 Super VL)** continues on `opencode/work` with OpenCode's file
ownership and keeps reporting in `docs/status/opencode.md` (sign entries "Cline").

### Review of the first clips (owner/Claude)
- `donald_walk`: **redo**. He leans far back and stares at the sky; the head and chest must
  stay upright over the hips, slight forward lean, heavy side-to-side sway, arms low in front.
- `donald_overhead`: at impact (0.60 s) the fists end at the knees and read like a crouch;
  keep both fists clearly locked together and the arms straight down in front at hip height.
- `tesla_flying_knee`: at impact (0.18 s) the rear knee is not visible at chest height (leg
  hangs down); lift the knee to chest height, toes pointed down, and pull the hands toward it.
- `sundar_sweep`: at impact (0.26 s) he only crouches; the lead leg must swing out low and
  wide across the front (foot near the floor, clearly away from the body).
- Sundar has **no table yet** in `docs/status/opencode.md` (clips: `sundar_idle` 2.00 s loop,
  `sundar_jab` 0.36 / 0.10, `sundar_cross` 0.44 / 0.14, `sundar_cast` 0.72 / 0.26,
  `sundar_sweep` 0.72 / 0.26, `sundar_walk` 1.57 s loop): add it.
- Everything else reads well: keep it.

### Cline, in order
1. **[O6-fix]** The four fixes and the Sundar table above; re-render `style_tesla.jpg`, `style_donald.jpg` and `style_sundar.jpg`, look
   at them, and update the tables (lengths / impact times) if they change.
2. **[O6]** Style clips for **Jensen** (showman: idle with jacket shrug, hook, uppercut,
   spinning backfist, presenter walk), **Zuckerbot** (stiff, robotic: idle, straight punch,
   front kick, mechanical dash, glitchy hurt), **Xi** (composed, rooted: idle, palm push, low
   stance sweep, two-hand fan strike, slow walk). One fighter per commit, strip + table each.
3. **[O2-fix]** Gemini's scene sheets in `docs/review/gemini/scenes/`: fix props that read
   badly (scale, origin, facing) in `tools/build_super_props.gd`.

## 11. Nov 18: Gemini's round merged; next round (Gemini)

**Merged into `main`**: O7 (projectile props), C6 (AGI kit), C10 (AGI phases), C11 (story
mode), C12b (balance: every regular fighter 40–60 %, AGI 68 %). Review notes:
- C10 **rollback bug**: `boss_phase` is in `SIM_FIELDS`, but `opponent_specials_used`,
  `mimicked_move` and the `_specials` entry it registers are not, so an online rollback can
  pick a different mimicked move on each machine. Also the `health` setter calls
  `update_boss_phase()`, so `load_state()` and resimulation emit `phase_changed` and replay
  the glitch/red-light transition.
- O6 was not wired because `style_anims.res` was not on `gemini/work` yet; it is on `main` now
  (tesla, Donald, Sundar; Cline is fixing four clips and adding Jensen, Zuckerbot, Xi).

**Owner approved (Nov 18)** the power moves and super scenes for **Dario, Yann, Geoff, Ram
and AGI** as written in ROADMAP §2.

### Gemini (`gemini/work`), in order
1. **[C10-fix]** Make the mimicry rollback-safe: snapshot `opponent_specials_used` (as plain
   data, e.g. move ids/inputs with counts, copied not shared) and `mimicked_move`, and rebuild
   the mimicked `_specials` entry in `load_state()`. Keep cosmetic effects out of
   `load_state()`/resimulation: the setter (or `load_state`) must not emit `phase_changed`
   while restoring; the look variant follows `boss_phase` after a load. Add a test: save a
   state in phase 3, run on with different specials, load, and check the mimicked move and
   `_specials` match the saved state exactly.
2. **[O6-wire]** Load `style_anims.res` as library `style` and use the clips for tesla, Donald
   and Sundar (table in `docs/status/opencode.md`): line each move's active frames up with the
   clip's `animation_impact`; idle/walk loops replace the generic ones for that fighter. Keep
   frame data changes small and note them. Cline re-renders four of these clips (`donald_walk`,
   `donald_overhead`, `tesla_flying_knee`, `sundar_sweep`); re-check the timing when that lands
   on `main`. Jensen, Zuckerbot, Xi follow when Cline delivers.
3. **[C8] Power moves + super scenes**, one fighter per commit, in this order: **Dario**
   (rulebook shield that reflects; constitution scroll + "SAFE" stamp), **Yann** (word tokens
   "the" / "next" / "token"; giant text box, autocomplete types "you lose", letters fall),
   **Geoff** (neural-net node zaps; VHS rewind, lecture hall, net zaps, Geoff regretful),
   **Ram** (money bags "Funding Round"; opponent rides the "Scaling Law" curve off the chart),
   **AGI** (feed cards spin round the opponent; giant phone, endless scroll, spat out).
   Pattern: `scripts/supers/scenes/tariff_stamp.gd` / `open_source_squad.gd`, sets via a builder
   in `tools/super_sets/<fighter>.gd` + `tools/build_super_sets.gd`, power moves via
   `MoveData.projectile_look` in `scripts/supers/projectile_looks.gd`. Use `prop()` stand-ins
   and list the real props you want in your status file for Cline. For each: tests, combo
   trials (`tools/check_trials.gd -- <id>`), a contact sheet in `docs/review/gemini/scenes/`
   that you look at before committing.
4. **[C12c]** Re-run `tools/balance_sim.gd` after step 3 and keep everyone in 40–60 %.
