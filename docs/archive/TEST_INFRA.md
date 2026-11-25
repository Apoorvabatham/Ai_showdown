# Test Infrastructure Specification: AI Showdown

## 1. Overview & Test Philosophy

The testing infrastructure for **AI Showdown** (built on Clint Christopher Canada's 3D Fighter engine under MIT / CC BY 4.0) operates under an **opaque-box, requirement-driven, deterministic 60 Hz simulation methodology**. Every combat mechanic, animation state machine, input sequence parser, rollback resimulation engine, network security layer, and user interface flow is validated headlessly under Godot 4.7.2.

### Core Testing Tenets

1. **Determinism via 60 Hz Fixed-Step Simulation**:
   - The game loop relies on deterministic frame stepping via `Fighter._tick()` and `FightManager._physics_process(1.0 / 60.0)`.
   - In the test harness (`tests/sim_test.gd`), engine physics processing is detached (`m.set_physics_process(false)`) and stepped explicitly using discrete helper functions (`step(n)`, `hold(dir, n)`, `press(button, dir)`, `motion(digits, button)`).
   - Given identical pseudo-random seeds (`GameState.match_seed`) and identical input streams, the physics and combat simulation reproduces byte-for-byte identical state hashes across runs.

2. **Opaque-Box Requirement Verification**:
   - Tests interact with the game through the same public interfaces and input mechanisms available to human players and network peers.
   - Controller injection utilizes `Scripted extends FighterController` for frame-by-frame directional and button pushes, and `DummyController` for deterministic defensive responses (Stand, Crouch, Stand Block, Crouch Block).
   - Assertions evaluate public observable states (fighter state enums, hitstun frames, health pools, combo counters, scene transitions, and packet structures) rather than private implementation details.

3. **Strict Zero-Tolerance Quality Gates**:
   - Verification demands zero assertion failures (`fails == 0`).
   - Zero script errors (`errors.count == 0` tracked by `ScriptErrorCounter extends Logger`).
   - Clean process exit code `0` (`quit(1 if fails else 0)`).

4. **Hermetic Session Isolation**:
   - The user's settings file (`Settings.PATH`) is backed up byte-for-byte in memory before test suites execute and restored upon completion.
   - The replay directory is redirected to a temporary sandboxed directory (`user://replays_test/`) and cleared before and after suite runs.
   - Content modes (`use_engine_content()` vs `load_roster()`) are partitioned so engine base regression tests and parody showdown tests execute in clean environments.

---

## 2. Test Architecture & Execution Lifecycle

### Canonical Test Runner Commands

The test runner is driven headlessly via Godot 4.7.2. The canonical execution commands are:

- **Primary Direct Console Binary**:
  ```powershell
  C:\Users\batha\.local\bin\godot_base_console.exe --headless --path . -s res://tests/sim_test.gd
  ```
- **Project Root Wrapper (`godot.cmd`)**:
  ```powershell
  .\godot.cmd --headless --path . -s res://tests/sim_test.gd
  ```
- **Global Path Shorthand**:
  ```powershell
  godot --headless --path . -s res://tests/sim_test.gd
  ```
- **Asset Import Command** (Required after updating textures, audio files, or meshes):
  ```powershell
  godot --headless --path . --import
  ```

### Test Execution Lifecycle

```
+-------------------------------------------------------------------------------+
|                        Phase 1: Harness Initialization                        |
| - Attach ScriptErrorCounter Logger (OS.add_logger)                            |
| - Filter benign headless dummy material noise                                 |
+-------------------------------------------------------------------------------+
                                      |
                                      v
+-------------------------------------------------------------------------------+
|                       Phase 2: Sandboxing & Environment                       |
| - Backup user Settings (settings.json)                                        |
| - Redirect Replay.directory -> "user://replays_test/"                         |
| - Set Graphics Preset to High (preset 2) for complete VFX evaluation          |
+-------------------------------------------------------------------------------+
                                      |
                                      v
+-------------------------------------------------------------------------------+
|                       Phase 3: Scene Setup & Stepping                         |
| - Instantiate res://scenes/fight.tscn                                         |
| - Disable automatic engine physics: m.set_physics_process(false)               |
| - Initialize fighters with Scripted and DummyController instances             |
+-------------------------------------------------------------------------------+
                                      |
                                      v
+-------------------------------------------------------------------------------+
|                        Phase 4: Domain Test Execution                         |
| - Execute 47 test sub-suites across 582 static assertion call sites           |
| - Advance simulation deterministically with m._physics_process(1.0 / 60.0)    |
| - Evaluate Tier 1, Tier 2, Tier 3, and Tier 4 assertions                      |
+-------------------------------------------------------------------------------+
                                      |
                                      v
+-------------------------------------------------------------------------------+
|                         Phase 5: Teardown & Isolation                         |
| - Restore original Settings bytes to disk                                     |
| - Purge temporary replays in user://replays_test/                             |
| - Verify Settings preservation assertion                                      |
+-------------------------------------------------------------------------------+
                                      |
                                      v
+-------------------------------------------------------------------------------+
|                        Phase 6: Quality Gate Evaluation                       |
| - Assert errors.count == 0 (no script errors)                                 |
| - Output failure count summary: "0 failure(s)"                                |
| - Terminate process with quit(1 if fails else 0)                              |
+-------------------------------------------------------------------------------+
```

---

## 3. The 4-Tier Testing Methodology

The test suite organizes all 582 assertions into a 4-tier verification hierarchy designed to establish complete reliability from isolated primitives to full real-world scenarios.

```
================================================================================
                    TIER 4: REAL-WORLD SCENARIOS (28 Checks)
      Arcade Ladder Runs | Best-of-3 Matches | High Scores | Settings Persistence
================================================================================
                                      ^
================================================================================
                 TIER 3: CROSS-FEATURE COMBINATIONS (74 Checks)
      Rollback Netplay Desync | Mirror Match Palettes | CPU vs CPU Determinism
================================================================================
                                      ^
================================================================================
                 TIER 2: BOUNDARY & CORNER CASES (81 Checks)
      Wall Splats | Tech Throw Breaks | Double KO | Packet Fuzzing | Tamper Proofing
================================================================================
                                      ^
================================================================================
                     TIER 1: FEATURE COVERAGE (399 Checks)
      11 Fighters | Moves | Kits | Hitboxes | Cancels | Shaders | Blendshapes | UI
================================================================================
```

### Tier Definitions & Scope

#### Tier 1: Feature Coverage (Core Functional Mechanics & Systems)
- **Scope**: Verifies that each individual game component, character move, animation state, cancel transition, collision volume, UI screen, audio bus, and graphical asset exists, loads, and behaves as specified in isolation.
- **Coverage**:
  - 8 base engine kits (`kenji`, `rhea`, `brutus`, `valka`, `jin`, `mira`, `lian`, `aelia`).
  - 11 parody fighters (`ram`, `tesla`, `dario`, `zuckerbot`, `jensen`, `yann`, `geoff`, `sundar`, `donald`, `xi`, `algorithm`).
  - Normal moves, command normals, special moves, supers, hit levels (High, Mid, Low, Overhead), blockstun, hitstun, frame advantage.
  - 3D meshes, facial blend shapes (`jaw_open`, `squint`, `smile`), secondary physics (spring bones on hair and clothing tails), outfit skinning.
  - Audio 4-bus architecture (Master, Music, SFX, Voice) with -1.0 dB master limiter ceiling.
  - UI scenes: Title, Main Menu, Character Select, Stage Select, Fight HUD, Training Overlay, Replay Browser.
- **Metrics**: **399 assertions (68.6%)** across 41 sub-suites.

#### Tier 2: Boundary & Corner Cases (Edge Conditions & Fault Tolerance)
- **Scope**: Tests the simulation at physical, temporal, mathematical, or network boundaries where systems are prone to overflow, race conditions, or unhandled exceptions.
- **Coverage**:
  - Physical Arena Limits: Wall splats, corner pushback clamping, ropes elasticity bounce vs wall collision styles.
  - 1-Frame Windows: Throw tech break escape window, startup invulnerability frames, reversal stance catch windows.
  - Match Termination Bounds: Double KO simultaneous lethal hits, time-out health percentage comparisons, sudden death rules.
  - Buffer & Data Stress: 60-frame input ring buffer wraparound, invalid motion sequences, corrupt or truncated replay files.
  - Network Stress & Security: UDP packet fuzzing, payload tampering, token forgery, challenge amplification limits, Diffie-Hellman MITM attacks.
- **Metrics**: **81 assertions (13.9%)** across 12 sub-suites.

#### Tier 3: Cross-Feature Combinations (Subsystem Interoperability & Determinism)
- **Scope**: Verifies the correct interaction between two or more major game subsystems operating concurrently.
- **Coverage**:
  - Deterministic Rollback Resimulation: Synchronizing 60 Hz gameplay simulation across simulated latency, network jitter, and out-of-order packets.
  - Mirror Matches: P2 alternate palette/outfit swap, rival intro quote resolution, independent input buffer processing.
  - Dynamic Stage & Combat Synchrony: Environmental prop animations (pigeons, laundry, train parallax), crowd excitement transitions on heavy hits or knockouts.
  - AI vs AI Determinism: CPU opponents utilizing character archetype personalities (Zoner, Rushdown, Grappler, Footsies) adhering to fixed seed determinism.
  - Server Relay & Hole-Punching Fallback: UDP peer-to-peer connection drops failing over seamlessly to WebSocket relay servers.
- **Metrics**: **74 assertions (12.7%)** across 11 sub-suites.

#### Tier 4: Real-World Scenarios (End-to-End User Journeys)
- **Scope**: Validates end-to-end player experiences from scene entry to match completion and persistent storage.
- **Coverage**:
  - Full Arcade Campaign: Complete progression through an escalating ladder of CPU opponents culminating in the final boss encounter (AGI in the Senate Hearing Room; Shadow AGI if playing as AGI).
  - Best-of-3 Tournament Match to Completion: Complete multi-round matches running to `Phase.MATCH_OVER` across all 11 roster fighters without hanging or state divergence.
  - Replay Recording & Persistent Playback: Complete match recorded, saved to disk, reloaded, scrubbed back and forth, and verified byte-for-byte against recorded state checksums.
  - Session Integrity & Cleanup: Ensuring all user settings are preserved byte-for-byte and zero GDScript errors occur across the entire runtime execution.
- **Metrics**: **28 assertions (4.8%)** across 6 sub-suites.

---

## 4. Comprehensive Feature Inventory Matrix

| System / Feature | Implementation Source | Test Function in `sim_test.gd` | Lines in `sim_test.gd` | Checks | Tier | Verification Focus & Mechanics |
|---|---|---|---:|---:|:---:|---|
| **Core 60 Hz Loop & Physics** | `scripts/fighter/fighter.gd` | `_initialize` | 215–336 | 21 | Tier 1 | Deterministic physics tick, walk speeds, pushbox overlap prevention, jump trajectories. |
| **Hit Levels & Defense** | `scripts/fighter/fighter.gd` | `_initialize`, `milestone4_tests` | 257–290, 159–161 | 9 | Tier 1 | High, mid, low, and overhead attack properties against standing and crouching blocks. |
| **Combo System & Scaling** | `scripts/fighter/fighter.gd` | `_initialize`, `milestone4_tests` | 263, 141 | 3 | Tier 1 | Normal chain cancels, target combos, combo damage scaling decay (2nd hit scaled to 90%). |
| **Throws & Escapes** | `scripts/fighter/fighter.gd` | `milestone4_tests` | 177–196 | 6 | Tier 1 & 2 | Normal grabs piercing block, whiff recovery frames, 1-frame throw break tech window. |
| **Juggles & Knockdown** | `scripts/fighter/fighter.gd` | `_initialize`, `milestone4_tests` | 293–298, 202–204 | 5 | Tier 1 & 2 | Uppercut vertical launches, air hit gravity, landing knockdown, unhittable clamping. |
| **Arena Boundaries** | `scripts/stages/stage.gd` | `wall_tests` | 614–690 | 13 | Tier 2 | EdgeStyle.WALL splats and crumple states; EdgeStyle.ROPES bounceback velocity; corner anti-infinite limits. |
| **Action Camera** | `scripts/fight/fight_camera.gd` | `camera_tests` | 84–122 | 7 | Tier 1 | 16:9 view frustum bounding, victim hit focus, trauma shake suppression in Off mode. |
| **Visual FX & Lighting** | `scripts/fight/hit_sparks.gd` | `fx_tests`, `graphics_tests` | 540–566, 1528–1627 | 22 | Tier 1 | Hit spark particle spawning, rim lighting flash overlay, particle scaling across presets. |
| **Input Buffer & Motions** | `scripts/fighter/input_buffer.gd`| `specials_tests` | 833–924 | 16 | Tier 1 & 2 | 60-frame input ring buffer, 236/623 motion recognition, input priority, projectile limits. |
| **Kenji (Balanced Kit)** | `data/kits/kenji.tres` | `character_tests`, `specials_tests` | 495–539, 925–958 | 13 | Tier 1 | Hadouken-style projectile, Shoryuken uppercut invulnerability, advancing straight punch. |
| **Brutus (Power Kit)** | `data/kits/brutus.tres` | `character_tests`, `specials_tests` | 495–539, 925–958 | 13 | Tier 1 | Bull Charge armored dash, Earthquake low stomp knockdown, command power bomb. |
| **Rhea (Rushdown Kit)** | `data/kits/rhea.tres` | `character_tests`, `specials_tests` | 495–539, 925–958 | 13 | Tier 1 | High walk velocity, Gale Slide low profile ducking high attacks, rapid multi-kick. |
| **Valka (Grappler Kit)** | `data/kits/valka.tres` | `valka_tests` | 1887–1963 | 10 | Tier 1 & 2 | Untechable Valka Slam command grab, Spinning Lariat projectile invulnerability, super grab. |
| **Jin (Footsies Kit)** | `data/kits/jin.tres` | `jin_tests` | 2260–2314 | 7 | Tier 1 | Extended kick reach, Axe Kick overhead property, Tornado Kick invulnerable startup. |
| **Lian (Counter Kit)** | `data/kits/lian.tres` | `lian_tests` | 2315–2421 | 11 | Tier 1 | Still Water reversal stance, catch high/mid strikes, low vulnerability, Willow Step glide. |
| **Aelia (Knight Kit)** | `data/kits/aelia.tres` | `aelia_tests` | 2422–2553 | 16 | Tier 1 & 2 | Startup armor absorption, armor break thresholds, throw armor bypass, custom skinned mesh. |
| **Mira (Brawler Kit)** | `data/kits/mira.tres` | `mira_tests` | 2725–2897 | 22 | Tier 1 | Lakas focus stance meter (max 3), Bagyo Rush multi-hit chain scaling, Lawin Drop dive kick arc. |
| **Facial & Body Anatomy** | `tools/face_sculpt.gd` | `face_tests`, `hair_tests`, `tail_tests` | 2898–3224 | 36 | Tier 1 | Blend shape expressions (`jaw_open`, `smile`), eye tracking, spring bone gravity settling. |
| **3D Outfits & Materials** | `tools/build_outfits.gd` | `outfit_tests`, `polish_tests` | 3225–3399 | 11 | Tier 1 | Mesh slot assignment, vertex bone weights, skin culling under clothes, rim light shaders. |
| **Audio Architecture** | `scripts/autoload/audio.gd` | `polish_tests`, `_crowd_tests` | 1352–1450 | 14 | Tier 1 | 4-bus architecture, -1.0 dB Master limiter, dynamic crowd excitement state machine. |
| **Parody Stages** | `scripts/stages/stage_retheme.gd`| `stage_tests`, `showdown_tests` | 1211–1351, 4837–4856 | 19 | Tier 1 & 3 | Retheme procedural prop generation, stage boundaries, lighting setup, thumbnail paths. |
| **Engine Stages** | `scenes/stages/` | `train_tests` through `temple_tests` | 1451–2165 | 47 | Tier 1 & 3 | Parallax train streaming, night market neon flickering, Kowloon courtyard time-of-day. |
| **Training**| `scenes/training/` | `training_tests` | 691–747 | 25 | Tier 1 | Input history display, frame data advantage readout, dummy recording and playback. |
| **AI Decision Making** | `scripts/ai/` | `ai_tests`, `personality_tests` | 393–434, 1654–1706 | 11 | Tier 1 & 3 | Reaction delays, anti-air responses, archetype spacing profiles, deterministic seeds. |
| **Rollback Netplay Engine** | `scripts/net/` | `rollback_tests`, `net_tests` | 3388–3822 | 56 | Tier 2 & 3 | Full state serialization, frame resimulation, desync detection, packet jitter handling. |
| **Netplay Security & Crypto**| `scripts/net/` | `security_tests`, `crypto_tests` | 3874–4249 | 36 | Tier 2 | Challenge rate limiting, cookie forgery rejection, MITM protection, AES packet encryption. |
| **Lobby & Server Relays** | `scripts/net/` | `server_tests` | 4368–4777 | 50 | Tier 1, 2, 3 | WebSocket room matching, spectator broadcast streams, NAT hole punching with relay fallback. |
| **Replay Subsystem** | `scripts/replay/` | `replay_tests` | 1062–1198 | 24 | Tier 1, 2, 4 | Input stream recording, ZSTD compression, seek/scrub determinism, corrupt file rejection. |
| **Arcade Campaign Mode** | `scripts/arcade/` | `arcade_tests`, `showdown_tests` | 959–1020, 4873–4882 | 14 | Tier 4 | Opponent ladder progression, difficulty scaling, round bonuses, continue flows, AGI boss. |
| **High Scores & Credits** | `scripts/arcade/` | `scores_credits_tests` | 2166–2199 | 6 | Tier 4 | Score saving/loading, leaderboard sorting, credit roll sequence completion. |
| **Controls & Remapping** | `scripts/autoload/controls.gd` | `controls_tests` | 2208–2259 | 6 | Tier 1 | Keyboard and gamepad action remapping, key conflict swapping, binding persistence. |
| **Parody Content & Roster** | `data/characters/` | `showdown_tests` | 4778–4902 | 16 | Tier 1, 3, 4 | 11 parody fighters, custom supers, 4 parody stages, CPU-vs-CPU full match round-robin. |
| **Session & Settings** | `scripts/autoload/settings.gd` | `_initialize` | 388–389 | 2 | Tier 4 | Byte-for-byte user settings restoration, 0 script errors verification. |

---

## 5. Fighter Roster Coverage Matrix

### 11 Parody Fighters (`data/characters/`)

| # | Fighter ID | Display Name | Base Kit | Unique Super Move | Archetype / Playstyle | Special Mechanics Verified in Suite |
|---|------------|--------------|----------|-------------------|-----------------------|-------------------------------------|
| 1 | `ram` | Ram Altman | `mira` | "Scaling Law" | Brawler / Focus Stance | Lakas focus meter accumulation, Bagyo Rush multi-hit cancel, super freeze cut-in. |
| 2 | `tesla` | tesla man | `rhea` | "Rocket Launch" | Rushdown / Speed | High walk velocity, Gale Slide low profile ducking, Rocket Launch super. |
| 3 | `dario` | Dario Amoday | `lian` | "Constitutional Shield" | Counter / Reversals | Still Water reversal stance, catch mid/highs, low vulnerability, super shield. |
| 4 | `zuckerbot` | Mark Zuckerbot | `valka` | "Metaverse Trap" | Heavy Grappler | Untechable command grabs, Spinning Lariat projectile invulnerability, trap super. |
| 5 | `jensen` | Jensen Wong | `kenji` | "GPU Rain" | Balanced Zoner | Hadouken projectile zoning, Shoryuken anti-air, GPU Rain falling projectile super. |
| 6 | `yann` | Yann LeCant | `brutus` | "It's Just Autocomplete" | Power / Heavy | Armored Bull Charge, Earthquake low stomp, power throw damage, super punch. |
| 7 | `geoff` | Geoff Hintoff | `aelia` | "I Regret Nothing… Wait" | Armored Defense | Startup armor absorption, armor break thresholds, throw armor pierce, regret super. |
| 8 | `sundar` | Sundar Pickai | `kenji` (mod) | "Search Result" | Balanced Zoner | Inherits Kenji kit with customized stats (higher Max HP, reduced walk speed). |
| 9 | `donald` | Donald Tarrif | `valka` (mod) | "Shower of Tariffs" | Super-Heavy Grappler | Inherits Valka kit with customized stats (heavier Weight, increased Max HP). |
| 10 | `xi` | Xi Winping | `aelia` | "Great Firewall" | Armored Statesman | Armored startup absorbs, command thrusts, Great Firewall barrier super. |
| 11 | `algorithm` | AGI (Final Boss) | `rhea` | "Engagement Loop" | Boss / Hard AI | Arcade ladder climax in Senate, full meter round start, Shadow AGI mirror boss. |

### 8 Engine Base Kits (`data/kits/`)

- `kenji`: Classic balanced shoto archetype with fireball, rising dragon punch, and advancing straight.
- `brutus`: Power brawler with armored Bull Charge, ground-shaking Earthquake, and high throw damage.
- `rhea`: High-speed rushdown striker with rapid dash, Gale Slide low profile, and rapid kicks.
- `valka`: Command grappler with untechable Valka Slam, projectile-invulnerable Spinning Lariat, and suplex supers.
- `jin`: Long-range footsies specialist featuring long-range pokes, Axe Kick overheads, and Tornado Kick invulnerability.
- `mira`: Stance brawler utilizing Lakas focus accumulation (up to 3 levels), multi-hit Bagyo Rush, and Lawin Drop dive kick.
- `lian`: Counter specialist with Still Water reversal stance catching mid/high attacks and Willow Step evasion.
- `aelia`: Armored knight with startup hit absorption, armor break counters, and custom 3D model skinning.

---

## 6. Stage Retheme & Environment Coverage Matrix

### Parody Stages (`scenes/stages/`)

| Stage ID | Scene Path | Retheme Look | Edge Style | Thumbnail Path | Environmental Props & Test Invariants |
|----------|------------|--------------|:----------:|----------------|---------------------------------------|
| `server_farm` | `res://scenes/stages/server_farm.tscn` | `Look.SERVER_FARM` | `WALL` | `res://assets/ui/stages/server_farm.png` | Rethemes Rooftop: Server racks, LED blinkers, liquid cooling pipes. Min 10 props. |
| `mensa` | `res://scenes/stages/mensa.tscn` | `Look.MENSA` | `WALL` | `res://assets/ui/stages/mensa.png` | Rethemes Dojo: University cafeteria tables, alignment soup counter, trays. Min 10 props. |
| `senate` | `res://scenes/stages/senate.tscn` | `Look.SENATE` | `WALL` | `res://assets/ui/stages/senate.png` | Rethemes Boxing Ring: Strips ropes (`Rope_*`), forces WALL edges, adds hearing dais and camera flashes. |
| `foundry` | `res://scenes/stages/foundry.tscn` | `Look.FOUNDRY` | `WALL` | `res://assets/ui/stages/foundry.png` | Rethemes Market: Cleanroom airflow floor, EUV scanner, wafer pods, bunny-suit technicians. Min 10 props. |

### Engine Base Stages (`scenes/stages/`)

| Stage ID | Scene Path | Edge Style | Thumbnail Path | Environmental Invariants Tested |
|----------|------------|:----------:|----------------|---------------------------------|
| `ring` | `res://scenes/stages/ring.tscn` | `ROPES` | `res://assets/ui/stages/ring.png` | Elastic rope bounce physics, corner bounceback velocity. |
| `dojo` | `res://scenes/stages/dojo.tscn` | `WALL` | `res://assets/ui/stages/dojo.png` | Solid tatami boundary walls, wall splat animations. |
| `rooftop` | `res://scenes/stages/rooftop.tscn` | `WALL` | `res://assets/ui/stages/rooftop.png` | Helipad edge boundaries, city skybox, dynamic camera bounds. |
| `temple` | `res://scenes/stages/temple.tscn` | `WALL` | `res://assets/ui/stages/temple.png` | Courtyard stone boundaries, falling blossom particle systems. |
| `beach` | `res://scenes/stages/beach.tscn` | `WALL` | `res://assets/ui/stages/beach.png` | Sand surface shaders, ocean sound bus routing. |
| `market` | `res://scenes/stages/market.tscn` | `WALL` | `res://assets/ui/stages/market.png` | Manila market night lighting, neon light flicker, ambient chatter. |
| `train` | `res://scenes/stages/train.tscn` | `WALL` | `res://assets/ui/stages/train.png` | Parallax scenery scrolling, speed sensation, tunnel lighting. |
| `courtyard`| `res://scenes/stages/courtyard.tscn`| `WALL` | `res://assets/ui/stages/courtyard.png` | Kowloon courtyard lighting progression (Dawn to Morning), laundry, pigeons. |

---

## 7. Quality Gates and Failure Triage Matrix

### Quality Gates

Every code change and test execution must satisfy three mandatory criteria:
1. **0 Failures**: `fails == 0` printed in summary.
2. **0 Script Errors**: `no script errors during the run [0, first: ]` reported by logger.
3. **Exit Code 0**: Process terminates with clean exit code 0.

### Failure Triage Matrix

| Failure Signature | Architectural Root Cause | Immediate Diagnostic Action | Corrective Action |
|---|---|---|---|
| `FAIL Replays: a rematch is saved as a second replay` | File collision in `user://replays_test/` due to multiple concurrent Godot instances or sub-second timestamp matching | Check for concurrent `godot_base` processes via `Get-Process godot*`. | Run test suite sequentially on a single runner; ensure unique timestamps in `Replay.save()`. |
| `FAIL Showdown: all 11 fighters load, in select order` | Missing character `.tres` file, mismatched ID, or invalid `select_order` index | Inspect `data/characters/` directory and compare against `SHOWDOWN_IDS`. | Restore missing character resource or correct `select_order` sequence. |
| `FAIL Showdown: four stages with thumbnails` | Stage count mismatch (e.g. a 5th stage added in `GameState.STAGES` but test not updated) | Check `gs.STAGES.size()` vs `sim_test.gd:4839`. | Synchronize test assertion count with `GameState.STAGES` definition. |
| `FAIL voice fallback for specials, none for supers` | Super voice drop-in missing or unlinked in audio subsystem | Check `assets/audio/voice/fighters/<id>_super_1.ogg`. | Provide valid `.ogg`/`.wav` super voice file and verify `Audio.voice()` loading. |
| `FAIL ... not rm.diverged` (Replay/Rollback desync) | Non-deterministic state variable omitted from `save_state()` / `load_state()` | Review variables modified during `_tick()` in `fighter.gd`. | Add missing state fields to dictionary serialization in `save_state()`. |
| `ERROR: Parameter "material" is null` | Benign headless dummy renderer notification for 3D meshes without active GPU | Check `ScriptErrorCounter` filtering logic. | Benign engine noise; ensure logger filters dummy renderer warnings while retaining GDScript errors. |
