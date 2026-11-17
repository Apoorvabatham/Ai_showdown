# Gemini status

Gemini updates this file (branch `gemini/work`). One section per task: id, state
(`in progress` / `review` / `done`), what changed, screenshots in `docs/review/gemini/`,
and any requests for other agents.

## G1: Story scripts for all 11 fighters
- **State**: done
- **Summary**: Created story scripts for all 11 characters in `data/story/<id>.json` (`ram`, `tesla`, `dario`, `zuckerbot`, `jensen`, `yann`, `geoff`, `sundar`, `donald`, `xi`, `algorithm`).
- **Details**:
  - Each character script contains exactly 6 fights (4 regular matches, 5th rival match, 6th boss fight against `algorithm` on `senate`).
  - All text formatted for in-game dialog boxes with line lengths <= 90 characters.
  - Parodic, lighthearted, and non-defamatory tone adhering to project parody guidelines and character lore.
  - Built with validator script `tools/build_story_scripts.py`.

## G2: CC0 stage props and textures
- **State**: done
- **Summary**: Downloaded and imported lightweight CC0 GLB models from Kenney and 1K PBR textures from Poly Haven.
- **Details**:
  - Mensa: CC0 Food Kit (`plate.glb`, `plate-dinner.glb`, `bowl.glb`, `cup-coffee.glb`, `bottle-ketchup.glb`, `bottle-musterd.glb`), CC0 Furniture Kit (`chair.glb`, `chairRounded.glb`, `table.glb`, `tableRound.glb`), and Poly Haven 1K PBR `floor_tiles_06_*` (diffuse, normal, roughness).
  - Server Farm: CC0 Space Station Kit (`computer-screen.glb`, `structure-panel.glb`, `floor-panel.glb`, `pipe.glb`, `pipe-bend.glb`).
  - Senate: CC0 Furniture Kit (`chairDesk.glb`, `desk.glb`, `deskCorner.glb`, `lampRoundTable.glb`).
  - GPU Foundry: CC0 Factory Kit (`robot-arm-a.glb`, `robot-arm-b.glb`, `machine.glb`, `conveyor.glb`, `pipe-large.glb`, `pipe-glass-large.glb`).
  - Added full attribution and links to `assets/CREDITS.md`. Small footprint maintained (< 5 MB per kit).

## G3: Realism pass for the 4 stages (Mensa first, Senate, Foundry, Server Farm)
- **State**: review
- **Summary**: Overhauled visual fidelity across all 4 stages in `scripts/stages/stage_retheme.gd` with PBR materials, real CC0 props, reflection probes, and custom stage atmosphere / fog passes.
- **Details**:
  - **Mensa**: Added `MensaReflectionProbe` for realistic linoleum floor specular highlights. Applied Poly Haven PBR `floor_tiles_06` texture with normal and roughness maps. Replaced box chairs with Kenney dining chairs (`chair.glb`, `chairRounded.glb`). Populated cafeteria tables and service counter with real plates, bowls, coffee cups, and condiment bottles. Configured bright warm indoor fog (`volumetric_fog_albedo = Color(0.95, 0.92, 0.88)`).
  - **Senate**: Added `SenateReflectionProbe` for mahogany and brass reflections. Replaced blocky dais chairs with Kenney executive swivel chairs (`chairDesk.glb`). Added reading lamp (`lampRoundTable.glb`) and witness chair to the witness stand. Configured stately chamber atmosphere fog (`volumetric_fog_albedo = Color(0.9, 0.85, 0.75)`).
  - **Foundry**: Added `FoundryReflectionProbe` for specular cleanroom floor and chamber glass. Placed articulated robotic arms (`robot-arm-a.glb`, `robot-arm-b.glb`) tending the 300mm wafer load port. Added wafer track conveyors, lithography machines on flanks, and overhead cryogenic fluid pipelines. Configured high-tech cleanroom lighting, neutral saturation, and cyan cleanroom haze (`volumetric_fog_albedo = Color(0.7, 0.85, 1.0)`). Eliminated null material errors by properly preserving Jeepney mesh instance overrides.
  - **Server Farm**: Added `ServerFarmReflectionProbe`. Placed overhead high-density cooling pipes, wall structure panels, and real diagnostic monitor terminals (`computer-screen.glb`). Configured cool datacenter airflow haze (`volumetric_fog_albedo = Color(0.6, 0.75, 0.95)`).
- **Screenshots**:
  - Mensa: `docs/review/gemini/mensa.png`
  - Server Farm: `docs/review/gemini/server_farm.png`
  - Senate: `docs/review/gemini/senate.png`
  - Foundry: `docs/review/gemini/foundry.png`

## G5: Stage interaction and ambient sounds
- **State**: done
- **Summary**: Generated CC0 44.1kHz 16-bit PCM WAV stage audio in `assets/audio/stage/<stage>/` for all 4 stages, including interaction effects and crowd reaction sounds (cheers and gasps) per stage.
- **Details**:
  - `mensa`: `tray_clatter.wav`, `dishes_clink.wav`, `cafeteria_chatter.wav`, `cheer.wav`, `gasp.wav`.
  - `senate`: `gavel.wav` (solid mahogany sound block strike), `camera_shutter.wav` (DSLR press shutter), `flash_pop.wav`, `hearing_chatter.wav`, `cheer.wav`, `gasp.wav`.
  - `server_farm`: `fan_whir.wav` (server blower drone), `alarm.wav` (rack fault siren), `terminal_beep.wav`, `steam_hiss.wav`, `cheer.wav`, `gasp.wav`.
  - `foundry`: `welding.wav` (electrical arc sizzle), `sparks.wav` (plasma ejection pops), `air_shower.wav` (cleanroom entry blast), `euv_laser.wav` (pulsed 13.5nm core discharge), `alarm.wav`, `cheer.wav`, `gasp.wav`.
  - Procedural sound generator tool: `tools/build_audio_assets.py`. Credited in `assets/CREDITS.md`.

## G7: Super and victory sounds
- **State**: done
- **Summary**: Generated CC0 44.1kHz 16-bit PCM WAV super move and victory sounds in `assets/audio/supers/<fighter_id>/`.
- **Details**:
  - `tesla`: `truck_engine.wav`, `chain_rattle.wav`, `rocket_launch_roar.wav`, `space_whoosh.wav`, `reentry_burn.wav`, `flag_plant.wav`, `victory.wav`.
  - `donald`: `container_crash.wav`, `stamp_thud.wav`, `paper_flutter.wav`, `usa_chant.wav`, `victory.wav`.
  - `jensen`: `whoosh.wav`, `tornado.wav`, `gpu_sparks.wav`, `victory.wav`.
  - `zuckerbot`: `vr_powerup.wav`, `digital_glitch.wav`, `teleport.wav`, `victory.wav`.
  - `sundar`: `keyboard_typing.wav`, `error_beep.wav`, `search_query.wav`, `victory.wav`.
  - `xi`: `footsteps_sprint.wav`, `punch_flurry.wav`, `gong_strike.wav`, `victory.wav`.
  - Credited in `assets/CREDITS.md`.

## G7b: Newly approved super and victory sounds
- **State**: done
- **Summary**: Added sounds for newly approved moves and scenes in `assets/audio/supers/`:
  - `xi/dragon_drums.wav`
  - `donald/statue_rise.wav`, `donald/fanfare.wav`
  - `zuckerbot/metaverse_ambience.wav`
  - `sundar/page_load.wav`
  - `jensen/marker_squeak.wav`
  - `dario/victory.wav` (scroll unroll & stately cadence)
  - `yann/victory.wav` (rhythmic cat purr)
  - `geoff/victory.wav` (academic applause)
  - `ram/victory.wav` (fireworks launch & burst)
  - `algorithm/victory.wav` (quantum calculation digital hum)
  - Credited in `assets/CREDITS.md`.

## G4: Stage-life content (Senate, Mensa, Foundry, Server Farm)
- **State**: done
- **Summary**: Authored `data/stage_life/<stage>.json` content conforming to TASKS.md §3.3 for all 4 stages:
  - `senate.json`: Chair, senators, stenographers, press, spectator gallery; hearing shout lines ("Order!", "Reclaim my time!", "Subpoena!"); camera flashes and gavel strike events.
  - `mensa.json`: Students, dining crowd, cafeteria staff; food/exam shout lines ("Food fight!", "Check the gradients!"); food fight event.
  - `foundry.json`: Cleanroom technicians in bunny suits, wafer engineers; cleanroom shout lines ("Particle detected!", "13.5nm locked!"); EUV spark burst and air shower events.
  - `server_farm.json`: Sysadmins, SREs, monitoring engineers; datacenter shout lines ("OOM Killer!", "RoCE packet drop!"); high-pressure steam burst and rack alarm events.

## G12 & G10: Realism round 2, Fight Lighting & Open-Source CC0 Props / PBR Pass
- **State**: review
- **Summary**: Overhauled visual depth, lighting, tonemapping and replaced code shapes with downloaded open-source CC0 3D models and Poly Haven PBR textures across all 4 stages.
- **Details**:
  - **Server Farm**: Downloaded Kenney CC0 Space Station models (`container-tall.glb`, `container-wide.glb`, `computer-system.glb`, `computer-wide.glb`, `structure-barrier.glb`, `display-wall.glb`) and Poly Haven 1K PBR `anti_skid_tiles_*`. Replaced primitive shapes with real server containers, battery/transformer modules, multi-screen consoles, cluster display walls, and safety barriers. Added ACES tonemapper, screen glow, and reflective wet floor channels.
  - **GPU Foundry**: Fixed washed-out appearance by lowering exposure, increasing contrast, and applying Poly Haven 1K PBR `metal_plate_02_*` for the cleanroom floor. Downloaded Kenney CC0 Factory models (`catwalk-straight.glb`, `catwalk-stairs.glb`, `scanner-high.glb`, `scanner-low.glb`, `screen-hanging-wide.glb`, `screen-panel-wide.glb`, `warning-orange.glb`, `box-large.glb`). Placed elevated maintenance catwalks, stairs, inspection scanners, laser warning beacons, and sub-fab filtration units.
  - **Senate**: Applied Poly Haven 1K PBR `lacquered_cherry_wood_*` (Rob Tuytel, Charlotte Baglioni, Jenelle van Heerden, Rico Cilliers) across the dais, railing, and witness table. Downloaded Kenney CC0 Furniture models (`laptop.glb`, `books.glb`, `bookcaseClosed.glb`, `bookcaseClosedWide.glb`, `bench.glb`, `desk.glb`, `deskCorner.glb`, `speakerSmall.glb`, `plantSmall1.glb`). Placed senator laptops, legal briefing books, public gallery benches, executive dais wing extensions, stately closed bookcases, PA speakers, chamber planters, and a dedicated official stenographer workstation matching `senate.json`.
  - **Mensa**: Downloaded Kenney CC0 Furniture models (`kitchenBar.glb`, `kitchenBarEnd.glb`, `kitchenCoffeeMachine.glb`, `trashcan.glb`, `cardboardBoxClosed.glb`, `pottedPlant.glb`, `stoolBar.glb`, `table.glb`, `tableRound.glb`). Populated service counter line, espresso station, cafeteria waste receptacles, dining stools, round bistro seating tables, and multi-bench dining tables.
  - **Robustness & Compatibility**:
    - Texture import params set to VRAM/lossy compressed mode (`compress/mode=1`, `mipmaps/generate=true`) across all 1K PBR textures in `assets/stage_props/` to comply with project size rules and prevent texture aliasing.
    - Implemented cross-platform case-insensitive path resolver `_resolve_tex_path()` in `stage_retheme.gd` for `textures` vs `Textures` directory paths.
    - Added specific artist credits for all Poly Haven textures and stage audio/voice assets in `assets/CREDITS.md`.
  - All tests passing at 0 failures (`PASS Showdown: Server Farm, Mensa, Senate and Foundry load with their props`).

## G6: Voices for stage shout lines
- **State**: done
- **Summary**: Generated normalised OGG stage crowd voice shouts for all 4 stages conforming to contract §3.3 (`assets/audio/stage/<stage>/voice/<key>_<n>.ogg`).
- **Details**:
  - Synthesized distinct voice profiles per stage using `tools/build_stage_voices.py`:
    - `senate`: Authoritative committee chair, formal senators, brisk stenographer, eager press pool.
    - `mensa`: Energetic college students, cafeteria cook, busy cashier.
    - `foundry`: Intercom radio-filtered cleanroom technicians, lead process architect, QA inspector.
    - `server_farm`: Alert sysadmins, datacenter on-call SREs, cloud infrastructure architects.
  - Trimmed silence, pitch-profiled, normalised, and converted to OGG Vorbis with `.import` configurations for all shout categories (`round_start`, `big_hit`, `super`, `ko`, `throw`, `wall_hit`).
  - Documented and credited in `assets/CREDITS.md`.
