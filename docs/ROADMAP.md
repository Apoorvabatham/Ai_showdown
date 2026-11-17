# AI Showdown: roadmap (season 2)

The design for the next big round of work: unique movesets, supers that do what their names
say, living and realistic stages, a real AGI boss, and Story mode. The **task board** that splits
this work between agents is [TASKS.md](TASKS.md). Read [HANDOFF.md](HANDOFF.md) first for setup,
traps and the likeness rules.

AI Showdown is a **fun parody project** with no deadline. Quality beats speed.

## 0. Principles

1. **Keep Godot and the existing game.** It is the engine. We stop *following* the original
   3D Fighter design and build our own content on top of it.
2. **Gameplay stays deterministic.** The fight runs at a fixed 60 Hz and supports rollback
   (`Fighter.save_state` / `load_state`). Anything that changes the fight (damage, positions,
   hitboxes, entities that can hit) lives in the simulation and in the saved state. Effects,
   crowds, cameras and sounds are **cosmetic**: they listen to signals and never feed back.
3. **Generated content stays generated.** `data/characters/` and `data/moves/` are written by
   tools. Change the generator, re-run it, commit the output. Never hand-edit those `.tres`.
4. **The likeness pass is a must.** Fighter looks are approved one by one by the owner
   (HANDOFF §2–§3). Gameplay work never touches looks.
5. **One owner per file** (see TASKS.md §2), so agents can work in parallel without conflicts.

## 1. Unique movesets

Today 11 fighters run on 8 kits, and four pairs play the same. Every fighter gets an identity.
The engine features each design needs are listed in §1.3.

### 1.1 Who plays how

| Fighter | Kit (base) | Style after this pass | Signature |
|---|---|---|---|
| Ram Altman | mira | Brawler who scales | Add More Compute stance stacks power |
| tesla man | rhea | Rushdown with air mobility | New **Rocket Dash** (air dash), Full Self-Sliding |
| Dario Amoday | lian | Counter | Refusal Stance catches strikes |
| Mark Zuckerbot | valka | **Fast** grappler | New **Move Fast** dash; Data Harvest Slam **steals meter** |
| Jensen Wong | kenji | Aggressive shoto | Tensor Blast fires a **3-shot burst**; new **The More You Buy** rush |
| Yann LeCant | brutus | Power | World Model Quake shockwave |
| Geoff Hintoff | aelia | Armoured knight | Super armour on heavy moves |
| **Sundar Pickai** | kenji → **own** | **Zoner / trapper** | Ten Blue Links (spread of small shots), Sponsored Result (slow trap ad), **Algorithm Update** (teleport) |
| **Donald Tarrif** | valka → **own** | **Armoured powerhouse** | Trade War Tackle (armoured charge), **Build the Wall** (stationary wall that eats projectiles), You're Fired (huge slow grab) |
| **Xi Winping** | aelia → **own** | **Fortress / control** | **Censorship** (reflects projectiles), Belt and Road Rush (long wall-carry charge), Five-Year Plan (focus build-up) |
| **AGI** | rhea → **own boss kit** | **Final boss** | Moves "trained on" every kit, phases, mimicry (§4) |

### 1.2 Move lists (specials; numbers are first drafts for balance)

Inputs: 236 = quarter-circle forward, 214 = quarter-circle back, 623 = dragon punch,
63214 = half-circle back, 236236 = super. P / K = any punch / kick.

**Sundar Pickai (Zoner).** HP 1020, slow walk.
- 236P **Ten Blue Links**: fans out 3 small fast shots (low damage each, three heights: the low one catches crouchers).
- 214P **Sponsored Result**: a slow, long-lived "ad" projectile that hangs in the air (trap).
- 623P **I'm Feeling Lucky**: invincible rising anti-air.
- 214K **Algorithm Update**: teleports behind the opponent (slow recovery if guessed).
- 6HP **Pixel Push**, 6LK **Quarterly Kick** (command normals).
- Super **Search Result**: a giant search bar slams down onto the opponent from above (overhead: block standing).

**Donald Tarrif (Armoured powerhouse).** HP 1120, slowest walk, big damage.
- 236P **Trade War Tackle**: armoured charge (absorbs 1 hit), wall-bounce.
- 214P **Build the Wall**: places a short wall in front that blocks projectiles for ~3 s.
- 623P **Executive Order**: armoured overhead slam with a shockwave.
- 63214P **You're Fired**: slow, huge-damage command grab.
- Super **Shower of Tariffs**: tariff papers rain across the screen (multi-hit, chip).

**Mark Zuckerbot (Fast grappler).** HP 1000, fast walk.
- 214K **Move Fast**: low-profile dash that can cancel into a grab.
- 623P **Pivot to Video**: spinning lariat.
- 63214P **Data Harvest Slam**: command grab that **steals 25% super meter**.
- Super **Metaverse Trap**: grab that pulls the opponent into a VR world (cinematic).

**Xi Winping (Fortress).** HP 1080.
- 236P **Belt and Road Rush**: long travelling charge with big wall-carry.
- 214P **Social Credit Hammer**: ground shockwave (must jump it).
- 214K **Censorship**: short stance that **reflects** projectiles back.
- 623P **Five-Year Plan**: focus stance; stacks power into the next special.
- Super **Great Firewall**: a red wall rises; it blocks/reflects projectiles and pushes the
  opponent toward the corner for a few seconds.

**Jensen Wong (Shoto).** Keeps the kenji kit; changes: Tensor Blast fires a 3-shot burst,
new 214P **The More You Buy** (multi-hit rush, more hits with more meter).

**tesla man (Rushdown).** Keeps the rhea kit; adds j.214K **Rocket Dash** (air dive-dash).

**AGI (Boss).** See §4.

### 1.3 Engine features to add (core, Claude)

New `MoveData` fields (all simulation, all in saved state):

| Feature | Field(s) | Used by |
|---|---|---|
| Multi-shot projectiles | `projectile_count`, `projectile_spread` (vertical / time offsets) | Sundar, Jensen |
| Projectile from above | `projectile_origin` (`hand` / `sky`), `projectile_fall` | GPU Rain, Tariffs, Search Result |
| Stationary entity | `projectile_speed = 0` + `entity_blocks_projectiles` | Build the Wall, Great Firewall |
| Reflect stance | `reflect_projectiles` | Xi Censorship, Dario super |
| Teleport | `teleport` (`behind` / distance) | Sundar, AGI |
| Meter drain | `drain_meter` | Zuckerbot |
| Super FX id | `super_fx` (StringName) | every super (cosmetic hook, §2) |

Per-fighter moves: today `tools/build_showdown_roster.gd` copies the kit and only renames.
New: **`tools/showdown_movesets.gd`** holds per-fighter overrides (`replace`, `add`, `remove`,
field tweaks, stats) so a fighter can diverge from its kit. CPU personality
(`AIController.PERSONALITIES`), showcase routines and combo trials get per-fighter entries
that fall back to the kit.

## 2. Supers that do what they say

A super has two halves:
- **Gameplay** (simulation): the move and any entities it spawns (rain of GPUs, a wall).
- **Show** (cosmetic): a `SuperFX` script per super in `scripts/supers/<id>.gd`, started from the
  `super_flash` signal. It owns the camera shot, props, particles, screen effects and sounds.
  Props (3D models) come from `assets/props/supers/<id>/` (built by OpenCode).

| Fighter | Super | Gameplay | Show |
|---|---|---|---|
| Ram | Scaling Law | Focus-scaled rush (exists) | Ram grows bigger with each hit, rising "compute" graph, server hum |
| tesla man | Rocket Launch | Kicks then launcher | Rocket prop strapped on, smoke trail, launch-pad countdown |
| Dario | Constitutional Shield | Reversal that also reflects projectiles | Glowing rulebook shield, pages flying, soft gold light |
| Zuckerbot | Metaverse Trap | Command grab (exists) | Stage swaps to a VR grid world, low-poly avatars, glitch exit |
| Jensen | GPU Rain | GPUs fall from the sky over the opponent | Graphics cards with spinning fans, price tags, sparks |
| Yann | It's Just Autocomplete | Multi-hit rush | Predicted-text tokens fill the screen, "▌" cursor, typing sounds |
| Geoff | I Regret Nothing… Wait | Armoured rush | VHS rewind filter, time runs backwards, then the big hit |
| Sundar | Search Result | Search bar slams from above | Giant search bar, "Did you mean: lose?" text, result cards |
| Donald | Shower of Tariffs | Paper rain across the screen | Tariff papers, stamp "TARIFF 145%", gold confetti |
| Xi | Great Firewall | Wall entity that pushes and reflects | Red brick wall with glowing grid rises from the floor |
| AGI | Engagement Loop | Multi-hit trap | Infinite-scroll feed panels wrap the opponent, notification pings |

## 3. Living, realistic stages

Every stage gets **people who react** and **events**, plus a realism pass (lighting, materials,
real props).

### 3.1 Stage-life framework (core, Claude)

- `StageActor`: an NPC on the real fighter body with an outfit and the UAL clips
  (`Sitting_Idle`, `Sitting_Talking`, `Idle_Talking`, `Yes`, `Idle_No`, `Dance`, `Interact`...).
- `StageCrowd`: places actors from stage markers and drives reactions from fight signals
  (hit, big combo, wall splat, super, KO, round start/end).
- `ShoutBubble`: speech bubbles (Label3D) with per-stage lines, plus crowd sounds.
- `StageEvent`: scripted moments (gavel bang, food fight, camera-flash burst, spark shower).
- Budget: ~10–20 animated actors per stage, cheap instanced crowd further back.

### 3.2 Per stage

| Stage | People | Events | Realism |
|---|---|---|---|
| **Mensa** | Students at tables (eat, chat, stand and cheer, bang trays), a cook behind the counter, a cashier | Trays and food fly on a KO, students stand on tables during supers | Real tables/trays/food models, tiled PBR floor, warm fluorescent lighting, window light |
| **Senate Hearing Room** | Committee chair with gavel, senators on the dais, a stenographer, press with cameras, gallery audience | "Order! Order!" + gavel on KO and big hits, camera-flash bursts on supers, senators stand up | Wood panelling, carpet, flags, nameplates, microphones, chandelier light |
| **GPU Foundry** | Bunny-suit technicians, an engineer at a console | Welding/laser sparks, robot arms move wafers, alarms on supers, AGV carts | Glossy cleanroom floor, yellow litho lighting, real machinery models, haze |
| **Server Farm** | Sysadmins with laptops, a drone | Sparks on wall hits, rack LEDs pulse with combos, steam vents, cooling leak on KO | Blinking racks, night skyline, rain/fog option, cable trays |

Shouts are **speech bubbles and spoken voice lines** (offline TTS, task G6), plus crowd
sounds.

## 4. AGI, the final boss

- **Own kit** "trained on everyone": a projectile (from kenji), a command grab (valka), a
  reversal (lian), armour (aelia), a teleport (Sundar's), plus its super Engagement Loop.
- **Phases** by health:
  1. 100–60 %: *Assistant*. Normal speed, polite lines.
  2. 60–25 %: *Agent*. Faster, armour on specials, colour shift, glitch effects.
  3. < 25 %: *Superintelligence*. **Mimics** the player's most used special, meter regen.
- Phase changes play a short cosmetic transition (screen glitch, stage lights go red).
- AI: phase-aware personality in `scripts/ai/ai_controller.gd`.

## 5. Modes

- **Story mode.** Per fighter: an intro, 5 fights with pre-fight banter, a rival fight, AGI,
  an ending. Presentation: dialogue boxes with the existing portraits and cut-ins over the
  VS screen style (cheap, looks good). Script data in `data/story/<id>.json` (schema in
  TASKS.md, task G1). Engine and screens: Claude.
- **1v1 Quick Match** (done): the player against a random CPU on a random stage, one round,
  no story.

## 6. Animations

- We have ~70 **unused** clips in `assets/animations/UAL1_Standard.glb` and `UAL2_Standard.glb`
  (Shield_Dash, Spell_Simple_Shoot, OverhandThrow, Sword_Heavy_Combo, Slide, NinjaJump,
  Idle_TalkingPhone, Dance, Yes / No, Sitting_*...).
- New fight clips are authored in code with the pose/IK toolkit in
  `tools/build_fight_animations.gd` (output `assets/animations/fight_anims.res`, library `fight/`).
- New clips for movesets and supers: Claude. NPC clips come straight from UAL.
- More CC0 packs (Quaternius) may be added; Mixamo needs a manual download by the owner.

## 7. Order of work

1. Collaboration docs + per-fighter moveset system (C1, C2).
2. Sundar → Donald → Xi → AGI movesets (C3–C6), one at a time, owner tests each.
3. SuperFX framework (C7), then supers one by one (C8), props from OpenCode (O2).
4. Stage-life framework (C9); NPC models (O3); stage realism and dressing (G2–G4).
5. AGI boss phases (C10). Story mode (C11 + G1).
