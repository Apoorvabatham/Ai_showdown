# Task board

Three agents work on this repo in parallel. The design is in [ROADMAP.md](ROADMAP.md); setup
and traps are in [HANDOFF.md](HANDOFF.md). **Read both before your first task.**

| Agent | Strength | Owns |
|---|---|---|
| **Claude** (Claude Code) | Fast; orchestrator | Core code: fight engine, moves, supers, AI, stage-life framework, modes, tests, this board |
| **OpenCode** (DeepSeek) | Character design | Fighter looks (likeness pass), NPC character models, super props |
| **Gemini** | Steady, thorough | Stage realism and dressing, CC0 asset sourcing, stage sounds, story writing, docs |

The owner (the human) approves fighter looks, movesets and anything visual, and decides
what is next.

## 1. Workflow (everyone)

### Branches
| Branch | Who works there |
|---|---|
| `claude/brave-rubin-b43he7` | **Main branch** (integration). Claude works here and merges the others in. |
| `opencode/work` | OpenCode (DeepSeek) only |
| `gemini/work` | Gemini only |

1. Work **only on your own branch**: `git fetch origin && git checkout <your branch>`.
   Never push to another agent's branch or to the main branch.
2. Stay up to date: at the start of every task run
   `git fetch origin && git merge origin/claude/brave-rubin-b43he7` (the main branch).
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
| `tools/build_npcs.gd`, `data/npcs/**`, `tools/build_super_props.gd`, `assets/props/**` | OpenCode |
| `scripts/stages/**` (incl. `stage_retheme.gd`), `scenes/stages/**` | Gemini |
| `assets/stage_props/**`, `assets/audio/stage/**`, `data/stage_life/**`, `data/story/**` | Gemini |
| `assets/CREDITS.md`, `LICENSE-ASSETS.md` | anyone adding assets (append only) |
| `README.md`, `docs/**` (except this board, ROADMAP and status files) | Gemini for prose; anyone may fix facts |
| `docs/status/opencode.md`, `docs/review/opencode/**` | OpenCode |
| `docs/status/gemini.md`, `docs/review/gemini/**` | Gemini |
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
`stand_up`, `bang_table`, `gavel`, `photo`. Events are implemented by Claude (list in C9).
Coordinates: stage space, fight area is about x ∈ [-6, 6], z ∈ [-2, 2]; keep actors outside
it and out of the camera's way.

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
| C4 | Donald moveset | C2 | todo |
| C5 | Xi moveset; Zuckerbot, Jensen and tesla changes | C2 | todo |
| C6 | AGI boss kit | C2 | todo |
| C7 | Super-scene framework: on a super hit, freeze the fight and play a cosmetic scene in its own set (own camera, puppets of both fighters, props); victory-scene framework; modelled shot looks (`scripts/supers/projectile_looks.gd`, started) | — | in progress (claude) |
| C8 | Per fighter: power move + super scene + victory scene (ROADMAP §2), owner approves each design first | C7, O2 per prop | todo |
| C9 | Stage-life framework: StageActor, StageCrowd, ShoutBubble, events (food_fight, camera_flashes, gavel, sparks, spark_shower, steam_burst, alarm) + `data/stage_life` loader | — | todo |
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
| O5 | **Xi's super helpers** (NPCs, contract §3.2): `helper_qwen`, `helper_alibaba`, `helper_kimi`: three made-up young engineers in T-shirts with the words **Qwen**, **Alibaba** and **Kimi** printed on the chest (owner's request), different builds and hair, sneakers | — | todo |

### Gemini (stages, assets, writing) — branch `gemini/work`

Start with G1 and G2 now; G3 after G2. G4 and G6 wait for Claude's stage-life framework (C9).

| ID | Task | Depends | Status |
|---|---|---|---|
| G1 | Story scripts for all 11 fighters (contract §3.4). Start with `ram`, then the rest | — | todo |
| G2 | Find CC0 models/textures for the 4 stages (Kenney, Quaternius, Poly Haven, ambientCG); put them in `assets/stage_props/<pack>/`, credit them in `assets/CREDITS.md`, keep the download small (models < 5 MB, textures ≤ 2K) | — | todo |
| G3 | Realism pass per stage in `scripts/stages/stage_retheme.gd`: replace box props with real models, PBR materials, lighting, fog, reflection probes. One stage at a time (Mensa first), screenshots for the owner | G2 | todo |
| G4 | Stage-life content: `data/stage_life/<stage>.json` (actor placement, shout lines, events) for each stage | C9, O3 | blocked |
| G5 | Stage sounds (CC0): gavel, camera shutter, tray clatter, welding, sparks, alarms, crowd cheers/gasps per stage, in `assets/audio/stage/<stage>/` | — | todo |
| G6 | Voices for the stage shout lines (contract §3.3 naming): an offline TTS with a licence that allows use in a game (e.g. Piper with a permissively licensed voice; note the licence in `assets/CREDITS.md`), several different voices per stage (chair, students, press...), OGG, normalised, short | G4 | blocked |
| G7 | Super and victory sounds (CC0), in `assets/audio/supers/<fighter_id>/`: tesla (truck engine, chain rattle, rocket launch roar, space whoosh, re-entry burn, flag plant), Donald (container crash, giant stamp thud, paper flutter, crowd "USA" chant), Jensen (whoosh / wind tornado), Zuckerbot (VR power-up, digital glitch), Sundar (keyboard typing, error beep), Xi (running footsteps, punch flurry) | — | todo |

## 5. Requests (cross-owner changes)

Add a line: `- [from <agent> to <agent>] what and why`. The owner of the file does it.

- (none yet)

## 6. Open questions for the owner

- (none: 1v1 = Quick Match, one round vs CPU, done; stage shouts = bubbles **and** voices)
