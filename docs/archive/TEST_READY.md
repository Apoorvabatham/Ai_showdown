# TEST_READY: AI Showdown Test Infrastructure & Verification Contract

## 1. Overview & Verification Readiness

This document defines the authoritative test verification contract for **AI Showdown** under Godot 4.7.2. The game simulation is verified headlessly using a deterministic 60 Hz fixed-step harness exercising combat physics, character kits, network security, rollback resimulation, and user interface workflows.

### Engine & Execution Environment
- **Engine Version**: Godot 4.7.2 (`Godot_v4.7.2-stable_win64.exe` / `godot_base_console.exe`).
- **Target Test Suite**: `res://tests/sim_test.gd` (4,902 lines, 47 test sub-suites, 582 static assertion call sites).
- **Execution Mode**: Headless (`--headless`), disabling GPU windowing and running physics deterministically.

### Pass/Fail Acceptance Criteria
1. **Zero Assertion Failures**: Output must conclude with `0 failure(s)`.
2. **Zero Script Errors**: Engine log monitor must assert `PASS  no script errors during the run  [0, first: ]`.
3. **Hermetic State Preservation**: Player settings must assert `PASS  the player's settings file is left as it was`.
4. **Exit Code**: The test runner terminates with process exit code `0` (`quit(1 if fails else 0)`).

---

## 2. Canonical Test Runner Commands

### Primary Direct Console Command
Executes Godot console executable directly in headless mode:
```powershell
C:\Users\batha\.local\bin\godot_base_console.exe --headless --path . -s res://tests/sim_test.gd
```

### Workspace Shorthand Wrapper
Utilizes project-root `godot.cmd` wrapper forwarding arguments and exit codes:
```powershell
.\godot.cmd --headless --path . -s res://tests/sim_test.gd
```
Or via system PATH:
```powershell
godot --headless --path . -s res://tests/sim_test.gd
```

### Asset Import Pre-Pass
Required before test execution whenever textures, audio files, or 3D models are added or modified:
```powershell
godot --headless --path . --import
```

---

## 3. Coverage Summary Table by Tier

The 582 assertion call sites in `tests/sim_test.gd` map comprehensively across the 4-tier testing hierarchy:

| Tier | Category | Focus Areas | Key Test Functions | Assertions | Coverage % |
|:---:|---|---|---|---:|---:|
| **Tier 1** | **Feature Coverage** | Core combat mechanics, hitboxes, frame data, 8 engine kits, 11 parody fighters, blend shapes, outfits, shaders, audio buses, and UI navigation in isolation. | `_initialize`, `character_tests`, `specials_tests`, `face_tests`, `mira_tests`, `aelia_tests`, `loading_tests`, `graphics_tests`, `showdown_tests` | 399 | 68.6% |
| **Tier 2** | **Boundary & Corner Cases** | Arena boundary wall splats, ropes elasticity, 1-frame throw break tech windows, double KO draws, timeout health evaluations, ring buffer limits, packet fuzzing, and cryptographic anti-tamper defenses. | `wall_tests`, `milestone4_tests`, `security_tests`, `crypto_tests`, `replay_tests`, `round_tests`, `server_tests` | 81 | 13.9% |
| **Tier 3** | **Cross-Feature Combinations** | Subsystem interoperability: 60 Hz deterministic rollback resimulation under latency/jitter, mirror match palette swapping, AI vs AI match determinism, stage crowd reactions, and server relay failover. | `rollback_tests`, `net_tests`, `server_tests`, `versus_tests`, `ai_tests`, `courtyard_tests` | 74 | 12.7% |
| **Tier 4** | **Real-World Scenarios** | Complete end-to-end player journeys: full arcade ladder progression to final boss AGI, best-of-3 tournament matches to completion across all 11 fighters, replay disk persistence, and settings restoration. | `arcade_tests`, `showdown_tests`, `scores_credits_tests`, `demo_tests`, `round_tests`, `_initialize` | 28 | 4.8% |
| **TOTAL** | **Full Regression Suite** | **Exhaustive Combat, Systems, Netplay, Stages & Parody Roster Verification** | **47 Sub-Suites / Functions** | **582** | **100.0%** |

*(Note: Including the `check()` function signature definition at line 14 brings total string matches to 583. Runtime loop iterations across characters and stages evaluate 672 dynamic assertions per test run).*

---

## 4. Complete Feature Checklist Across All Subsystems

### Parody Roster (11 Fighters)
- [x] **Ram Altman** (`ram`): Kit `mira`, Focus stance brawler, Super: *"Scaling Law"*.
- [x] **tesla man** (`tesla`): Kit `rhea`, High-speed rushdown striker, Super: *"Rocket Launch"*.
- [x] **Dario Amoday** (`dario`): Kit `lian`, Counter/reversal specialist, Super: *"Constitutional Shield"*.
- [x] **Mark Zuckerbot** (`zuckerbot`): Kit `valka`, Command grappler, Super: *"Metaverse Trap"*.
- [x] **Jensen Wong** (`jensen`): Kit `kenji`, Balanced projectile zoner, Super: *"GPU Rain"*.
- [x] **Yann LeCant** (`yann`): Kit `brutus`, Heavy power brawler, Super: *"It's Just Autocomplete"*.
- [x] **Geoff Hintoff** (`geoff`): Kit `aelia`, Armored defense knight, Super: *"I Regret Nothing… Wait"*.
- [x] **Sundar Pickai** (`sundar`): Kit `kenji` (mod), High HP zoner, Super: *"Search Result"*.
- [x] **Donald Tarrif** (`donald`): Kit `valka` (mod), Heavyweight command grappler, Super: *"Shower of Tariffs"*.
- [x] **Xi Winping** (`xi`): Kit `aelia`, Armored statesman, Super: *"Great Firewall"*.
- [x] **AGI** (`algorithm`): Kit `rhea`, Final Boss in Senate / Shadow AGI mirror boss, Super: *"Engagement Loop"*.

### Parody Stages (4 Current)
- [x] **Server Farm** (`res://scenes/stages/server_farm.tscn`): Rooftop base, WALL edges, humming GPU racks, liquid cooling pipes, LED blinkers.
- [x] **Mensa** (`res://scenes/stages/mensa.tscn`): Dojo base, WALL edges, university cafeteria tables, alignment soup counter.
- [x] **Senate Hearing Room** (`res://scenes/stages/senate.tscn`): Boxing ring base, ropes stripped, WALL edges forced, committee hearing dais.
- [x] **GPU Foundry** (`res://scenes/stages/foundry.tscn`): Market base, WALL edges, cleanroom airflow floor, EUV scanner, FOUP monorail, bunny-suit technicians.

### Core Combat & Physics
- [x] 60 Hz deterministic physics tick (`Fighter._tick()`, `FightManager._physics_process()`).
- [x] Pushbox collision solver preventing fighter model overlap.
- [x] High, Mid, Low, and Overhead attack hit level validation.
- [x] Stand Block and Crouch Block defensive rules.
- [x] Normal-to-normal chain cancels and special cancels.
- [x] Combo damage scaling decay (2nd hit scaled to 90%).
- [x] Uppercut launchers, air hit physics, ground knockdown, and wakeup invulnerability.
- [x] Normal throws piercing guard, throw whiff recovery, and 1-frame throw break tech window.
- [x] EdgeStyle.WALL splats and crumple states with anti-infinite limiters.
- [x] EdgeStyle.ROPES elasticity and bounceback physics.
- [x] Super freeze, screen darken, cinematic camera focus, and trauma shake effects.

### Audio, UI & Presentation
- [x] 4-bus audio layout (Master, Music, SFX, Voice) with -1.0 dB limiter ceiling.
- [x] Parody voice fallback architecture with custom super voice drop-in support (`<id>_super_1.ogg`).
- [x] Title screen legal parody disclaimer label.
- [x] Main menu navigation: Vs CPU, Versus, Training, and Arcade enabled; Online hidden.
- [x] Character select screen with 3D character preview, portraits, and kit showcases.
- [x] Stage select screen with 16:9 thumbnail previews.
- [x] Fight HUD with Health bars, Super Meter, Round Timer, and Move List overlay.
- [x] Best-of-3 round rules (`ROUNDS_TO_WIN = 2`) and results transition screens.

### Netplay, Rollback & Replays
- [x] Full state snapshot serialization and 60 Hz rollback resimulation.
- [x] NetPeer UDP packet protocol with frame packing and checksums.
- [x] Security layer: packet fuzzing defense, challenge rate limiting, and MITM tamper protection.
- [x] WebSocket LobbyClient protocol for room matchmaking and spectator streams.
- [x] Deterministic replay recording to compressed ZSTD `.rpl` files.
- [x] Replay playback, pause, frame-advance, and bidirectional scrub/seek verification.

---

## 5. Operational Constraints & Execution Guidelines

1. **Single-Runner Sequential Execution**:
   - Godot's `user://` directory on Windows resolves to `%APPDATA%\Godot\app_userdata\AI Showdown\`.
   - Replay tests write temporary test files into `user://replays_test/`.
   - Running multiple test processes concurrently on the same machine can cause file timestamp collisions and intermittent failures in `replay_tests()`. Always run tests sequentially.

2. **Headless Dummy Renderer Messages**:
   - In Godot 4.7.2 headless execution, `servers/rendering/dummy` outputs recurring messages: `ERROR: Parameter "material" is null. at: material_get_instance_shader_parameters`.
   - These are expected engine messages caused by instantiating 3D shaders without a physical GPU display. `ScriptErrorCounter` explicitly ignores these benign messages and flags only true GDScript runtime errors.

3. **Settings Restoration Guarantee**:
   - The test suite backs up `user://settings.json` in memory prior to running tests and writes it back byte-for-byte upon teardown, ensuring developer settings remain untouched.
