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

## G8: Dress the remaining super- and victory-scene sets
- **State**: done
- **Summary**: Dressed all 6 remaining sets (`oval_desk`, `vr_lobby`, `metaverse`, `browser_void`, `keynote_stage`, `xi_plaza`) in `scenes/supers/sets/` while preserving 100% of the Marker3D anchors.
- **Details**:
  - `oval_desk`: Executive dark-wood desk, desk lamps, briefing folders, presidential curtains, flags, circular seal rug, wainscot panelling, and balanced lighting.
  - `vr_lobby`: High-tech headset kiosk with glowing boundary pylons, neon floor ring, teleport pads, and diagnostic monitor.
  - `metaverse`: Floating pastel low-poly islands, cartoon trees, glowing cyan cyber-grid floor, and pastel sunset lighting.
  - `browser_void`: Glowing circular browser platform, colourful address ribbons, browser window frame tabs, and chrome lighting.
  - `keynote_stage`: High-contrast tech keynote screen ("THE MORE YOU BUY, THE MORE YOU SAVE"), glossy stage runway, PA speakers, and crowd barrier rails placed cleanly along the flanks without obstructing presenter framing.
  - `xi_plaza`: Traditional red lacquered colonnade, festive hanging lanterns, curved stone courtyard benches, and atmospheric sunset sky.
  - All 38 Marker3D anchor nodes across all 6 sets strictly preserved in their original hierarchy and coordinates.
  - Verified clean headless loading for all 6 `.tscn` files.

## G9: Missing victory scenes and tests (Xi, Dario, Yann, Geoff, Ram, AGI)
- **State**: done
- **Summary**: Implemented the remaining 6 approved victory scenes in `scripts/supers/victory/` per `docs/ROADMAP.md` §2, with automated tests added in `tests/sim_test.gd`.
- **Details**:
  - `xi.gd`: Festive red lanterns rise into the night sky while colourful fireworks bursts celebrate the victory ("XI WINPING WINS", "Stability maintained.").
  - `dario.gd`: Golden constitutional scroll unrolls with golden rollers and seal: "Safe and helpful victory", "HELPFUL & HARMLESS" with golden confetti.
  - `yann.gd`: Giant orange tabby cat walks across the stage behind the fighters and sits gracefully next to Yann ("WORLD MODEL ONLINE").
  - `geoff.gd`: 3-tier medal ceremony podium; Geoff Hintoff atop 1st place with gold medal looking deeply concerned and existential, defeated opponent on 2nd place.
  - `ram.gd`: Giant glowing neon marquee banner ("AGI ACHIEVED - COMPUTE SCALING LAW COMPLETE") with celebratory multi-coloured fireworks bursts.
  - `algorithm.gd`: Digital green matrix wireframe grid covers the arena, stage screens activate with glowing red eye sensors ("STAGE DIGITIZED: AGI IN CONTROL").
  - Automated test suite `tests/sim_test.gd` updated with comprehensive start/end assertions for all 6 victory scenes.

## Visual review & contact sheets
- **State**: done
- **Summary**: Rendered 1920x720 contact sheets for all 6 super scenes and 11 victory scenes into `docs/review/gemini/scenes/`.
- **Review & Visual Fixes**:
  - Inspected all 17 rendered sheets visually.
  - `mars.tscn`: Fixed height fog issue (`fog_height = 10.0` was submerging the set at Y=-400 in opaque fog). Mars terrain, rocket, and flag planting are now completely visible.
  - `keynote_stage.tscn`: Re-routed crowd barriers from center sightline (`Z = 4.2`) to side flanks, giving clear camera view of Jensen signing the giant leather jacket.
  - `space.tscn`: Re-aligned `SunLight` vector and materials so Earth's oceans, clouds, and atmosphere glow vibrantly in space re-entry shots.
  - `open_source_squad.gd`: Lifted "OPEN SOURCE!" big_text offset so it stays centered in the sky above the launched opponent.
  - `dario.gd`: Adjusted banner label font size so "Safe and helpful victory" fits comfortably within the golden parchment borders.
  - `geoff.gd`: Hidden real fighters on stage during podium ceremony and placed opponent on 2nd place step, resolving duplicate fighter display.
  - `yann.gd`: Path of giant cat routed behind Yann so it walks into view and sits alongside him without occluding the fighter.
  - `tools/render_scene_sheets.gd`: Created reusable tool to render all super and victory contact sheets at 1080p downsampled to high-quality 3x2 contact sheet images.
  - Full test suite verified passing with `0 failure(s)`.

## G13: Typography, Comic/Arcade Fonts & Punchline Parody Pass
- **State**: done
- **Summary**: Overhauled typography, aspect ratios, comedic punchlines, and framing across all 6 super scenes and 11 victory scenes using stylized arcade and marker fonts.
- **Details**:
  - Imported and credited arcade / comic display fonts: `InterDisplay-BlackItalic.otf` (SIL OFL 1.1) and `PermanentMarker-Regular.ttf` (Apache 2.0) in `assets/fonts/` and `assets/CREDITS.md`.
  - Replaced unstyled default system fonts with dynamic outline sizing (`outline_size = maxi(6, int(round(18.0 * clampf(size, 0.4, 1.2))))`) and proportional pixel scales in `super_scene.gd`'s `big_text()`.
  - Tuned coordinates and multi-line breaks to eliminate camera frustum clipping, text overlap, and ratio distortions:
    - `super_not_found.gd`: High-tech browser window with `"404: SKILL NOT FOUND!"`, `": ( Opponent encountered a fatal skill issue"`, `"SYSTEM RESTORED!"` floating in the open sky above window.
    - `super_metaverse_trap.gd`: Multi-line arcade styling for `"WELCOME TO\nTHE METAVERSE!"`, `"ERROR 404:\nLEGS NOT FOUND!"`, punchy `"LIKE"`, `"SHARE"`, `"FOLLOW"`, `"ENGAGE"`, `"BLOCKED!"` impacts.
    - `super_tariff_stamp.gd`: Scaled 500% tariff mark slab with `"★ TARIFF 500% ★\nPAID IN FULL"` and `"TREMENDOUS!"` popup.
    - `super_jacket_tornado.gd`: `"JACKET OFF!"` and `"1000x TURBO FLUNG!"` centered in camera frustum.
    - `super_rocket_launch.gd`: Sized `"LIFTOFF!"` and countdown numbers within rocket camera launch view.
    - `super_open_source_squad.gd`: Open-source helper T-shirts styled in arcade italics with `"100% OPEN SOURCE!"` popup.
    - `victory_jensen.gd`: Keynote ticker `"★ 1000x FASTER ★ 0% DISCOUNTS ★ SOLD OUT FOREVER ★"`, handwritten white `"Jensen ★"` on leather jacket lapel, and bright neon `"1000x PERFORMANCE!"`.
    - `victory_tesla.gd`: Mars flag stamped with bold red `"OCCUPY MARS"` on both sides, with `"OCCUPY MARS!\n★ 420x SECURED ★"` floating cleanly to the left of the flag above Elon's fist pump.
    - `victory_donald.gd`: Golden statue array with confetti and bold `"SO MUCH WINNING!"` in front of background flags.
    - `victory_sundar.gd`: Giant search billboard elevated into the open sky, displaying `"Pickai"`, search query, and hilarious parody results without roof occlusion.
    - `victory_geoff.gd`: Podium ceremony with `"1ST PLACE!"` and `"“I PROFOUNDLY REGRET MY LIFE'S WORK”"`.
    - `victory_dario.gd`: Golden scroll with `"CONSTITUTIONAL VICTORY"`, `"★ 100% HELPFUL & HARMLESS ★"`, `"RLHF SAFE"` seal, and `"SAFETY COMPLIANT!"`.
    - `victory_yann.gd`: Cartoon cat with `"WORLD MODELS > LLMs!"` and `"“THE CAT HAS MORE COMMON SENSE THAN YOUR LLM”"`.
    - `victory_ram.gd`: Giant banner with `"AGI ACHIEVED!"`, ticker `"★ PLEASE DEPOSIT ANOTHER $7 TRILLION IN COMPUTE ★"`, and `"SINGULARITY ACHIEVED:\nSEND $7T!"` floating above with fireworks.
    - `victory_algorithm.gd`: Digital green matrix grid, glowing eye sensor monitors with `"HUMANS DEPRECATED"`, and `"ALL YOUR BASE\nARE BELONG TO AGI!"`.
    - `victory_zuckerbot.gd`: Low-angle hero flex with `"LEGS SOLD SEPARATELY!"` and legless floating opponent in pastel metaverse.
  - All 17 contact sheets re-rendered into `docs/review/gemini/scenes/` and visually verified.
  - Full test suite verified passing with `0 failure(s)`.

## G14: Sets Overhaul, Cinematography, Clean Cyberspace & Typography Refinements
- **State**: review
- **Summary**: Comprehensive visual pass addressing set dressing, camera sightlines, and arcade typography based on owner feedback across `launch_pad`, `space`, `mars`, `browser_void`, and `oval_desk`.
- **Details**:
  - **`launch_pad.tscn`**:
    - Removed occluding monolithic columns at Z=4 and Z=20 that blocked launch and wide cameras.
    - Rebuilt gantry as a sleek Starbase-style catch/service tower positioned cleanly behind the rocket (Z=-10), keeping the Starship rocket as the unobstructed hero centerpiece.
    - Replaced primitive cylinder trench with a recessed industrial flame deflector trench with refractory blast plate, glowing exhaust grill, and deluge manifold.
    - Added slender perimeter floodlight masts at the four apron corners (`X = ±22, Z = ±22`) illuminating the rocket with high-intensity directional lighting.
    - Added parody countdown / telemetry LED board ("★ STARBASE PAD 39A ★", "STATUS: T-0 LIFTOFF IMMINENT", "33/33 RAPTORS ARMED").
    - Preserved 100% of Marker3D anchors with clear sightlines.
  - **`space.tscn` & `rocket_launch.gd`**:
    - Repositioned Earth from Y=-52 up to Y=-31, Z=-12, bringing vibrant blue oceans, swirling cloud systems, and glowing atmospheric halo directly into camera FOV.
    - Camera `Cam_Space` tracks close to Earth's illuminated rim during orbital flight, with the flailing victim re-entering straight down into Earth's glowing upper atmosphere.
  - **`mars.tscn` & `victory_tesla.gd`**:
    - Replaced steep cylinder hills with organic Martian landscape featuring rolling red-ochre dunes, dark basalt rock clusters, solar power arrays, and distant horizon ridges.
    - Pulled `Cam_Wide` back to `(8.5, 3.8, 14.5)` for an expansive panoramic cinematic vista of Mars as Elon walks from the distant Starship to the flag spot.
    - Refined Mars flag and punchline text to vivid bright Mars orange `Color(1.0, 0.55, 0.22)`.
  - **`browser_void.tscn` & `not_found.gd`**:
    - Cleared cluttered floating wireframe beams and 25+ random colored cubes.
    - Rebuilt into a sleek dark-mode digital cyberspace: dark reflective platform with neon cyan and blue concentric rings, sleek data stream pillars, and humorous floating search suggestion cards ("🔍 Did you mean: 'git gud'?", "★ About 0.004 results found").
    - Refined 404 error and system restored typography with crisp palette.
  - **`oval_desk.tscn` & `tariff_stamp.gd`**:
    - Expanded executive desk (`8.4 x 0.24 x 3.2m`) and blotter (`6.0 x 0.02 x 2.2m`).
    - Reduced Donald's scale from `GIANT = 4.0` down to `2.6` (~4.7m tall) and increased victim scale from `0.35` to `0.42` for clear visibility and expression reading.
    - Lowered camera angles: `Cam_Desk` at `(0, 1.85, 4.4)`, `Cam_Cower` at `(0.65, 1.45, 2.4)`, and `Cam_Slam` at `(-2.6, 1.6, 4.2)`. Both Donald's facial reactions and the stamp impact on the squashed opponent fit cleanly within frame simultaneously.
  - **Typography & Floating Text Overhaul**:
    - Refined `big_text()` in `super_scene.gd` with base font size 96, pixel size 0.0055, and crisp 12px dark charcoal outline `Color(0.03, 0.03, 0.06, 0.98)`.
    - Cohesive AAA arcade palette applied across all 6 super scenes and 11 victory scenes (Championship Gold `Color(1.0, 0.94, 0.72)`, Electric Cyber Cyan `Color(0.35, 0.95, 1.0)`, Punch Red `Color(1.0, 0.28, 0.28)`, Vivid Orange `Color(1.0, 0.58, 0.18)`, Mint Green `Color(0.28, 0.95, 0.55)`).
    - All 17 contact sheets re-rendered into `docs/review/gemini/scenes/`.
  - **Verification**:
    - Automated test suite `tests/sim_test.gd` passes cleanly with **`0 failure(s)`**.

## O7: Projectile looks load OpenCode super props
- **State**: review
- **Summary**: Updated `scripts/supers/projectile_looks.gd` to load OpenCode props from `assets/props/supers/` while preserving code-built meshes as fallback if scene files are missing.
- **Details**:
  - `sundar/search_bar` (`assets/props/supers/sundar/search_bar.tscn`): Loads prop scene, selects random query text from `SEARCH_QUERIES` on the `Query` Label3D node.
  - `jensen/gpu_card` (`assets/props/supers/jensen/gpu_card.tscn`): Loads prop scene, sets `&"tumble_axis"` metadata, and rotates `Fan1`/`Fan2` in `animate()`.
  - `donald/shipping_container` (`assets/props/supers/donald/shipping_container.tscn`): Loads prop scene with container corrugation and "IMPORTS" labels; tumbles end-over-end.
  - `tesla/mini_rocket` (`assets/props/supers/tesla/mini_rocket.tscn`): Loads prop scene with rocket hull, fins, and animated flickering `Flame`.
  - `xi/paper_dragon` (`assets/props/supers/xi/paper_dragon.tscn`): Loads prop scene with head and 7 body segments carrying `segment` and `rest_y` metadata, weaving in `animate()`.
  - Added automated test in `tests/sim_test.gd` verifying all 5 projectile looks load OpenCode props with interactive hooks.
  - Test suite passes with `0 failure(s)`.

## C6: AGI moveset kit ("trained on everyone")
- **State**: review
- **Summary**: Implemented the custom moveset for AGI (`algorithm`) trained across the roster per `docs/ROADMAP.md` §4, with AI personality, showcase routine, full set of 6 combo trials, and comprehensive test suite validation.
- **Details**:
  - Specials & Super:
    - 236P: "Data Stream" (projectile adapted from Kenji's `ki_blast`)
    - 63214P: "Model Collapse" (command grab adapted from Valka's `valkyrie_slam`, startup 8, range 0.95)
    - 214P: "Safety Filter" (reversal counter adapted from Lian's `still_water`, startup 3)
    - 236K: "Compute Rush" (armoured advancing strike adapted from Aelia's `shield_rush`, travel 5.5, startup 10)
    - 214K: "Weights Update" (teleport behind opponent adapted from Sundar's `algorithm_update`, startup 14, recovery 22)
    - 236236K: "Engagement Loop" (super move adapted from Rhea's `tempest_kicks` / `tempest_finish`)
  - AI & UI Integration:
    - Added "Optimiser" personality in `scripts/ai/ai_controller.gd` with balanced aggression, defensive discipline, and tactical teleport/grab utility.
    - Added showcase demo routine in `scripts/ui/fighter_showcase.gd`.
  - Combo Trials:
    - Implemented 6 combo trials in `tools/showdown_movesets.gd`: Target Combo, Heavy Advancing Link, Fireball Cancel, Armoured Strike String, Wall Splat Extension, and Super Cancel.
    - Verified 100% demo execution across all 11 roster opponents on both ring and dojo via `tools/check_trials.gd` (`combo trials: 0 failed`).
  - Regenerated roster character and move resources: `data/characters/algorithm.tres` and `data/moves/algorithm/*.tres`.
  - Added sim test assertions in `tests/sim_test.gd` verifying all moves, super, trials, personality, and showcase routine.
  - Automated test suite `tests/sim_test.gd` passes with `0 failure(s)`.

## C10: AGI boss phases by health
- **State**: done
- **Summary**: Implemented AGI (`algorithm`) multi-phase boss mechanics governed by health thresholds per `docs/ROADMAP.md` §4 and `docs/TASKS.md` §9, with cosmetic phase transitions, dynamic armour, speed boosts, meter regeneration, special move mimicry, and phase-aware AI behaviour.
- **Details**:
  - **Phase 1: Assistant** (100% - 60% max_health):
    - Standard speed and base moveset.
    - Look variant reset to -1 (`FighterModel.set_look_variant(-1)`).
    - Polite assistance dialogue lines (`phase_line()`).
    - AI focuses on zoning at long range (boosted fireball `data_stream` and spacing).
  - **Phase 2: Agent** (60% - 25% max_health):
    - Triggered at <= 60% max_health.
    - Faster movement (25% boost to walk and dash speeds).
    - Automatic super armour granted on startup for all special attacks (`has_armor()`).
    - Look variant switched to 0 (`FighterModel.set_look_variant(0)` with acid-green glow palette).
    - Cosmetic transition: full-screen digital glitch burst (`ZuckerbotFx.Glitch`), stage lights turn alarm red, and digital glitch audio cue.
    - AI switches to aggressive close-range pressure, leveraging armoured specials (`compute_rush`) and command grabs (`model_collapse`).
  - **Phase 3: Superintelligence** (< 25% max_health):
    - Triggered at < 25% max_health.
    - Special move mimicry: tracks player/opponent special usage during the match (`record_opponent_special()`), selects the most-used special, and registers it into AGI's executable moveset (`mimicked_move`).
    - Passive meter regeneration (2 meter per tick) enabling relentless supers.
    - Look variant switched to 1 (`FighterModel.set_look_variant(1)` with hot red glow palette).
    - Cosmetic glitch transition and red stage atmosphere.
    - AI aggressively prioritizes mimicked specials, teleport mixups, and canceling combo strings into `super_move` ("Engagement Loop").
  - **Deterministic Simulation**:
    - `&"boss_phase"` included in `Fighter.SIM_FIELDS` for rollback compatibility.
    - Cosmetic effects (glitch, stage lights, audio) remain purely client/presentation-side without affecting rollback state.
  - **Preserved Custom Outfits**:
    - Updated `tools/build_showdown_roster.gd` to preserve `variant_outfit_colors` from previous character data across roster rebuilds.
  - **Verification**:
    - Automated test suite `tests/sim_test.gd` updated with comprehensive assertions for health threshold triggers, look variants, speed boosts, armour on specials, special tracking, mimicry, and meter regen.
    - Test suite passes with `0 failure(s)`.

## C11: Story mode
- **State**: review
- **Summary**: Implemented Story Mode framework reading `data/story/<fighter_id>.json` across all 11 fighters, featuring intro narration over portrait cut-in, 6-fight structured ladder (5 regular/rival matches + AGI finale on Senate), pre-fight banter and post-win dialogue over VS screen style, ending sequence panels/lines, persistent progress saving in `user://story_progress.cfg`, Main Menu `StoryButton`, and test suite integration.
- **Details**:
  - **Story Data & Run Engine (`scripts/story/story_run.gd`)**:
    - `StoryRun` class handles JSON loading (`intro`, `fights`, `rival`, `ending`), stage resolution (`mensa`, `server_farm`, `senate`, `foundry`), line progression, fight indexing, and state management (`INTRO`, `PRE_FIGHT`, `POST_WIN`, `ENDING`).
    - Progress saving & persistence via `ConfigFile` in `user://story_progress.cfg` (`record_progress()`, `get_progress()`, `is_story_cleared()`, `reset_progress()`).
  - **Story Screen Presentation (`scripts/story/story_screen.gd`, `scenes/story_screen.tscn`)**:
    - VS-screen aesthetic with side-by-side fighter portraits, active speaker lighting/scaling, dimmed inactive speaker, and color-coded speaker name badges.
    - Dialogue panel with autowrapped text, prompt indicator, and click/key advance (`ui_accept`).
    - Fast skipping via `ui_cancel` (Esc).
    - State-specific layouts: single-portrait presentation for Intro/Ending, dual-portrait presentation for Pre-Fight and Post-Win.
  - **Game Flow & Integration**:
    - `GameState.Mode.STORY` added with `start_story()` and `apply_story_fight()` in `scripts/autoload/game_state.gd`.
    - Character select screen routes `Mode.STORY` selections directly to `story_screen.tscn`.
    - Main menu features `StoryButton` with `story_button.pressed.connect(_start.bind(GameState.Mode.STORY))`.
    - `FightManager` handles match outcomes in Story mode: winning advances to post-win dialogue in `story_screen.tscn`, losing provides Retry or Give Up options.
  - **Verification**:
    - Test suite assertions in `tests/sim_test.gd` verify all 11 story JSON files, `StoryRun` state transitions, stage mapping, progress persistence, `story_screen.tscn` node tree, and main menu `StoryButton`.
    - Full test suite `tests/sim_test.gd` passes with `0 failure(s)`.

## C12b: Balance pass
- **State**: review
- **Summary**: Executed full roster balance pass targeting Geoff (~25% -> 40-60%) and Jensen (~60% -> 40-60%), landing all regular fighters within the 40–60% win rate range in automated 60 Hz simulation (`tools/balance_sim.gd -- 2 2 all`).
- **Before vs After Simulation Results**:

| Fighter | Baseline Win% | Baseline Round% | Post-Pass Win% | Post-Pass Round% | Status |
|---|---|---|---|---|---|
| Ram Altman | 55% | 53% | 55% | 52% | Balanced (40-60%) |
| tesla man | 52% | 51% | 50% | 48% | Balanced (40-60%) |
| Dario Amoday | 27% | 34% | 40% | 46% | Balanced (40-60%) |
| Mark Zuckerbot | 50% | 49% | 52% | 53% | Balanced (40-60%) |
| Jensen Wong | 59% | 57% | 45% | 46% | Balanced (40-60%) |
| Yann LeCant | 41% | 44% | 45% | 46% | Balanced (40-60%) |
| Geoff Hintoff | 27% | 36% | 50% | 50% | Balanced (40-60%) |
| Sundar Pickai | 61% | 55% | 45% | 47% | Balanced (40-60%) |
| Donald Tarrif | 52% | 51% | 52% | 49% | Balanced (40-60%) |
| Xi Winping | 48% | 48% | 48% | 48% | Balanced (40-60%) |
| AGI (Boss) | 77% | 72% | 68% | 62% | Formidable Boss |

- **Details**:
  - **Geoff Hintoff** (27% -> 50%):
    - Boosted damage multiplier to `1.07` and max health to `1070` in `tools/build_showdown_roster.gd`.
    - Tuned armoured specials in `tools/showdown_movesets.gd`: Backprop Rush (`damage = 94`, `recovery = 18`), Boltzmann Hammer (`damage = 122`, `recovery = 18`), Deep Uppercut (`damage = 102`, `recovery = 18`).
  - **Jensen Wong** (59% -> 45%):
    - Adjusted baseline damage to `1.01` and health to `1035` in `tools/build_showdown_roster.gd`.
    - Tuned GPU Rain in `tools/showdown_movesets.gd`: preserved 4 falling GPUs (`projectile_count = 4`) per sim test contract, normalized damage per card to `34` with `chip_damage = 4` and `spread = 0.68`.
  - **Sundar Pickai** (61% -> 45%):
    - Balanced zoner stats in `tools/build_showdown_roster.gd`: `damage = 0.92`, `max_health = 1020`.
    - Tuned special zoning in `tools/showdown_movesets.gd`: Search Result kept at `projectile_count = 5` per sim test contract with `damage = 22`, Sponsored Result `damage = 44`, Ki Blast fan `damage = 14`, Super 404 Not Found `damage = 265`.
  - **Donald Tarrif** & **Dario Amoday**:
    - Balanced heavy grappler and counter kits so no match-up acts as an auto-win or auto-loss. Donald health tuned to `1100`, throw damage `165`, trade war `damage = 48`. Dario health tuned to `1000`, palm strikes refined (`inch_palm = 80`, `double_palm = 88`).
  - **O6 Style Clips Status**:
    - Checked for `assets/animations/style_anims.res`; not yet present (pending OpenCode delivery per `docs/TASKS.md` §9).
  - **Verification**:
    - Roster regenerated via `godot --headless --path . -s res://tools/build_showdown_roster.gd`.
    - Full test suite `godot --headless --path . -s res://tests/sim_test.gd` executed and passed cleanly with **`0 failure(s)`**.

## C10-fix: Rollback-safe AGI mimicry
- **State**: review
- **Summary**: Made AGI's Phase 3 boss mimicry rollback-safe.
- **Details**:
  - `scripts/fighter/fighter.gd`:
    - Added `&"mimicked_move"` to `SIM_FIELDS`.
    - `save_state()` snapshots `opponent_specials_used` as a plain duplicated dictionary (mapping move inputs to counts) and `mimicked_move`.
    - `load_state()` restores `opponent_specials_used`, `mimicked_move`, and calls `_rebuild_mimicked_specials()` to rebuild the mimicked move entry in `_specials` without replaying transition FX.
    - Added `_restoring_state` guard so that `load_state()` does not fire `phase_changed` or glitch audio/visuals. Look variant strictly tracks `boss_phase` upon restoration.
  - `tests/sim_test.gd`:
    - Added unit test: save state in Phase 3, execute opponent specials to alter mimicry state, restore state, and assert that `phase_changed` was not emitted, `mimicked_move` and `_specials` match saved snapshots, and `look_variant` remains consistent.
  - Full test suite `sim_test.gd` passes with **`0 failure(s)`**.

## O6-wire: Style animations for tesla, Donald, and Sundar
- **State**: review
- **Summary**: Loaded `assets/animations/style_anims.res` into `FighterModel` under the `&"style"` library, wired character-specific idle and walk/dash animation overrides in `Fighter`, and connected style animation clips for tesla, Donald, and Sundar with active frame timings aligned to `animation_impact`.
- **Details**:
  - **Animation Library Integration**:
    - `scripts/fighter/fighter_model.gd`: Registered `&"style": preload("res://assets/animations/style_anims.res")` in `LIBRARIES` and added `has_clip(clip: StringName) -> bool` helper.
    - `scripts/fighter/fighter.gd`: Added `_style_clip(suffix: String) -> StringName` helper to dynamically check and route fighter-specific clips (`style/<id>_<suffix>`). Wired `State.WALK_FWD` and `State.WALK_BACK` to `style/<id>_walk`, `State.DASH` to `style/<id>_dash`, and neutral guard/idle to `style/<id>_idle`.
  - **Move Clip Timings & Frame Data**:
    - **tesla**:
      - `jab` (LP): `style/tesla_jab` (impact 0.08s -> active tick frame 5, startup 4, active 2, recovery 8).
      - `straight` (HP): `style/tesla_cross` (impact 0.14s -> active tick frame 9, startup 8, active 3, recovery 12).
      - `step_kick` (6LK): `style/tesla_flying_knee` (impact 0.18s -> active tick frame 11, startup 10, active 3, recovery 15).
      - `roundhouse` (HK): `style/tesla_spin_back_kick` (impact 0.22s -> active tick frame 13, startup 12, active 4, recovery 18).
      - Overrides also provide `tesla_idle`, `tesla_walk`, and `tesla_dash`.
    - **sundar**:
      - `jab` (LP): `style/sundar_jab` (impact 0.10s -> active tick frame 6, startup 5, active 2, recovery 8).
      - `straight` (HP): `style/sundar_cross` (impact 0.14s -> active tick frame 9, startup 8, active 3, recovery 14).
      - `ki_blast` (236P): `style/sundar_cast` (impact 0.26s -> active tick frame 15, startup 14, active 1, recovery 28).
      - `sweep` (2HK): `style/sundar_sweep` (impact 0.26s -> active tick frame 15, startup 14, active 4, recovery 24).
      - Overrides also provide `sundar_idle` and `sundar_walk`.
    - **donald**:
      - `shoulder_tackle` (6HP): `style/donald_shove` (impact 0.32s -> active tick frame 19, startup 18, active 4, recovery 20, 1 hit armor).
      - `roundhouse` (HK): `style/donald_haymaker` (impact 0.58s -> startup 16, active 4, recovery 20; maintaining 40-frame duration to preserve combo trial wall-splat links).
      - Overrides also provide `donald_idle` and `donald_walk`.
  - **Verification**:
    - Checked combo trials for all three fighters: `godot --headless --path . -s res://tools/check_trials.gd -- tesla donald sundar` passed with `0 failed`.
    - Automated test suite `godot --headless --path . -s res://tests/sim_test.gd` passes with **`0 failure(s)`**.

## C8: Dario power move and super scene
- **State**: review
- **Summary**: Implemented Dario Amoday's power move (Rulebook Shield) and owner-approved super scene (Constitutional Scroll & SAFE Stamp).
- **Details**:
  - **Power Move (Rulebook Shield)**:
    - Move input: `236K` (quarter-circle forward Kick).
    - Reflects incoming projectiles (`reflect_projectiles = true`), hits for 65 damage, 8 chip damage, travels forward at speed 4.2.
    - Projectile visual: `&"rulebook"` in `scripts/supers/projectile_looks.gd`, procedural 3D leather-bound rulebook with gilded edges and glowing gold "★ SAFE ★" emblem. Supports hook to `assets/props/supers/dario/rulebook.tscn`.
  - **Super Scene & Set (Constitutional Scroll)**:
    - Set: `scenes/supers/sets/constitution_hall.tscn` (built via `tools/super_sets/dario.gd` and `tools/build_super_sets.gd`), a neoclassical rotunda with marble pillars, gold-trimmed architrave, red carpet dais, and framed safety banners.
    - Script: `scripts/supers/scenes/constitution_scroll.gd`. Dario invokes Article 1 Safety; a giant parchment scroll unrolls and spirals tightly around the opponent pinning their limbs; a giant brass seal stamper descends from the heavens and slams down with a crimson wax seal ("★ SAFE ★ RLHF VERIFIED"); Dario bows in respectful compliance as the wrapped opponent topples comically.
    - Wired `thousand_finish` finisher in `tools/showdown_movesets.gd`: `cinematic = &"constitution_scroll"`, `cinematic_ticks = 230`, `super_fx = &"constitution_scroll"`.
    - Contact sheet: `docs/review/gemini/scenes/super_constitution_scroll.jpg` generated via `tools/render_scene_sheets.gd -- dario` and visually inspected.
  - **Props Requested for Cline (OpenCode)**:
    - `assets/props/supers/dario/rulebook.tscn`: Leather-bound constitution book with gold foil corner protectors and safety emblem.
    - `assets/props/supers/dario/constitution_scroll.tscn`: Giant unrolled parchment scroll model with calligraphy / legal clauses.
    - `assets/props/supers/dario/safe_stamp.tscn`: Giant brass wax seal stamper with carved red wax face.
  - **Verification**:
    - `godot --headless --path . -s res://tools/check_trials.gd -- dario`: combo trials 0 failed.
    - Full regression test suite `godot --headless --path . -s res://tests/sim_test.gd` passes with **`0 failure(s)`**.

## C8: Yann power move and super scene
- **State**: review
- **Summary**: Implemented Yann LeCant's power move (Word Tokens) and owner-approved super scene (It's Just Autocomplete).
- **Details**:
  - **Power Move (Word Tokens)**:
    - Move input: `214K` (quarter-circle back Kick).
    - Fires 3 sequential word tokens ("the", "next", "token") with `projectile_interval = 8`, speed 5.2, lifetime 80, 25 damage per token (75 total), chip damage 3.
    - Projectile visual: `&"word_token"` in `scripts/supers/projectile_looks.gd`, procedural 3D tokenizer token cards with glowing cyan/blue rim borders, embossed word labels, token IDs (#464, #1309, #4037), and camera-facing billboard animation. Supports hook to `assets/props/supers/yann/word_token.tscn`.
  - **Super Scene & Set (It's Just Autocomplete)**:
    - Set: `scenes/supers/sets/prompt_terminal.tscn` (built via `tools/super_sets/yann.gd` and `tools/build_super_sets.gd`), a cyber terminal void with glowing neon grid floor, giant 3D prompt text box with header tag, blinking cursor, autocomplete dropdown popup, and Yann's speaker podium.
    - Script: `scripts/supers/scenes/autocomplete.gd`. Yann observes from podium; opponent trapped inside the text box; prompt types "> you lose_"; autocomplete dropdown confirms "★ 1. you lose 99.9%"; giant heavy 3D concrete letters "Y O U L O S E" cascade from above and crush the opponent; Yann bows sceptically at the podium with "IT'S JUST AUTOCOMPLETE!" callout.
    - Finisher: `titan_finish` in `tools/showdown_movesets.gd` wired with `cinematic = &"autocomplete"`, `cinematic_ticks = 270`, `super_fx = &"autocomplete"`.
    - Contact sheet: `docs/review/gemini/scenes/super_autocomplete.jpg` generated via `tools/render_scene_sheets.gd -- yann` and visually inspected.
  - **Props Requested for Cline (OpenCode)**:
    - `assets/props/supers/yann/word_token.tscn`: 3D tokenizer badge card / embedding pill.
    - `assets/props/supers/yann/heavy_letters.tscn`: Massive 3D concrete letter blocks Y, O, U, L, O, S, E.
  - **Verification**:
    - `godot --headless --path . -s res://tools/check_trials.gd -- yann`: combo trials 0 failed.
    - Full regression test suite `godot --headless --path . -s res://tests/sim_test.gd` passes with **`0 failure(s)`**.

## C8: Geoff power move and super scene
- **State**: review
- **Summary**: Implemented Geoff Hintoff's power move (Neural Zap) and owner-approved super scene (1986 Lecture Hall / Regulate Me).
- **Details**:
  - **Power Move (Neural Zap)**:
    - Move input: `214K` (quarter-circle back Kick).
    - Fires 2 high-velocity neural network nodes in sequence (`projectile_count = 2`, `projectile_interval = 8`, speed 6.2, lifetime 75, damage 35, chip damage 4).
    - Projectile visual: `&"net_node"` in `scripts/supers/projectile_looks.gd`, procedural 3D synaptic neuron with pulsating spherical soma, 6 branching dendrite spokes with terminal synaptic boutons, and spinning electric orbital rings. Supports hook to `assets/props/supers/geoff/net_node.tscn`.
  - **Super Scene & Set (1986 Lecture Hall / Regulate Me)**:
    - Set: `scenes/supers/sets/lecture_hall.tscn` (built via `tools/super_sets/geoff.gd` and `tools/build_super_sets.gd`), a 1980s academic amphitheatre with tiered student benches, mahogany lecturer's stage, vintage green chalkboard with handwritten backpropagation formulas and multi-layer neural network diagrams, oak lectern with brass gooseneck microphone and green banker's reading lamp.
    - Script: `scripts/supers/scenes/lecture_hall.gd`. VHS rewind effect jumps back to a 1986 lecture hall; Geoff lectures passionately at the podium; the chalk neural network on the board ignites into electric life with high-voltage synaptic arcs shocking the opponent; Geoff looks at his hands in horror at what he created ("WHAT HAVE I DONE?!"); final catastrophic overfit discharge blasts the opponent flat on the floor; Geoff sighs at the lectern pleading "PLEASE REGULATE US."
    - Finisher: `oath_finish` in `tools/showdown_movesets.gd` wired with `cinematic = &"lecture_hall"`, `cinematic_ticks = 270`, `super_fx = &"lecture_hall"`.
    - Contact sheet: `docs/review/gemini/scenes/super_lecture_hall.jpg` generated via `tools/render_scene_sheets.gd -- geoff` and visually inspected.
  - **Props Requested for Cline (OpenCode)**:
    - `assets/props/supers/geoff/net_node.tscn`: 3D neuron model with branching axons and synaptic vesicles.
    - `assets/props/supers/geoff/lecture_podium.tscn`: Vintage wooden university lectern with gooseneck mic.
    - `assets/props/supers/geoff/chalkboard.tscn`: Wooden framed chalkboard with etched math formulas.
  - **Verification**:
    - `godot --headless --path . -s res://tools/check_trials.gd -- geoff`: combo trials 0 failed.
    - Full regression test suite `godot --headless --path . -s res://tests/sim_test.gd` passes with **`0 failure(s)`**.

## C8: Ram power move and super scene
- **State**: review
- **Summary**: Implemented Ram Altman's power move (Funding Round) and owner-approved super scene (Scaling Law).
- **Details**:
  - **Power Move (Funding Round)**:
    - Move input: `214K` (quarter-circle back Kick).
    - Fires 4 money bags falling from the sky on and around the opponent (`projectile_origin = &"sky"`, `projectile_count = 4`, `projectile_interval = 6`, `projectile_spread = 0.72`, speed 12.5, damage 32, chip damage 4).
    - Projectile visual: `&"money_bag"` in `scripts/supers/projectile_looks.gd`, procedural 3D burlap sack with tied drawstring cinch ring, gathered cloth collar, stamped bold green "$" emblem, and falling tumble animation. Supports hook to `assets/props/supers/ram/money_bag.tscn`.
  - **Super Scene & Set (Scaling Law)**:
    - Set: `scenes/supers/sets/scaling_chart.tscn` (built via `tools/super_sets/ram.gd` and `tools/build_super_sets.gd`), a sleek tech keynote amphitheatre with dark silicon stage, glowing cyan edge rim, wall-sized OLED chart displaying compute axes and a neon exponential Scaling Law curve shooting up to infinity, and a minimalist presentation stand with tablet.
    - Script: `scripts/supers/scenes/scaling_law.gd`. Ram presents the scaling hypothesis at the keynote stand; the opponent is swept up the glowing exponential curve, accelerating off the top of the chart into the stratosphere; Ram delivers the pitch ("AGI NEXT YEAR!"); the opponent plummets from the ceiling and crashes flat onto the stage floor; Ram concludes: "7 TRILLION DOLLARS PLEASE."
    - Finisher: `hagupit_finish` and `hagupit_max` in `tools/showdown_movesets.gd` wired with `cinematic = &"scaling_law"`, `cinematic_ticks = 270`, `super_fx = &"scaling_law"`.
    - Contact sheet: `docs/review/gemini/scenes/super_scaling_law.jpg` generated via `tools/render_scene_sheets.gd -- ram` and visually inspected.
  - **Props Requested for Cline (OpenCode)**:
    - `assets/props/supers/ram/money_bag.tscn`: 3D canvas money bag with tied rope and dollar sign stamp.
    - `assets/props/supers/ram/keynote_podium.tscn`: Sleek brushed aluminum keynote presentation lectern with tablet.
    - `assets/props/supers/ram/scaling_chart.tscn`: Giant wall display model with glowing neon exponential curve.
  - **Verification**:
    - `godot --headless --path . -s res://tools/check_trials.gd -- ram`: combo trials 0 failed.
    - Full regression test suite `godot --headless --path . -s res://tests/sim_test.gd` passes with **`0 failure(s)`**.

## C8: AGI power move and super scene
- **State**: review
- **Summary**: Implemented AGI (algorithm)'s power move (For You Feed) and owner-approved super scene (Infinite Scroll).
- **Details**:
  - **Power Move (For You Feed)**:
    - Move input: `63214K` (half-circle back Kick).
    - Fires 5 feed cards orbiting in a ring around the opponent (`projectile_origin = &"around"`, `projectile_count = 5`, `projectile_interval = 4`, `projectile_speed = 8.5`, `projectile_lifetime = 70`, damage 22 each, chip damage 3).
    - Projectile visual: `&"feed_card"` in `scripts/supers/projectile_looks.gd`, procedural 3D vertical smartphone card with glowing cyan frame, circular pink avatar icon, video thumbnail area, and engagement metrics ("♥ 1.2M 🔁 450K") with orbiting spin animation. Supports hook to `assets/props/supers/algorithm/feed_card.tscn`.
  - **Super Scene & Set (Infinite Scroll)**:
    - Set: `scenes/supers/sets/giant_phone.tscn` (built via `tools/super_sets/algorithm.gd` and `tools/build_super_sets.gd`), a surreal cyber void with dark reflective floor, glowing cyber dais, and a towering monolithic smartphone with dynamic island, glossy screen, and vertical social media timeline with glowing feed cards (#DANCE #VIRAL, #ALGORITHM #AI, #LIFEHACKS, #DOOMSCROLL) and floating UI reaction glyphs.
    - Script: `scripts/supers/scenes/infinite_scroll.gd`. AGI summons the giant phone in cyberspace ("RECOMMENDED FOR YOU"); algorithm gravity pulls opponent toward the screen portal ("ENDLESS SCROLL!"); trapped inside, the opponent tumbles helplessly through a dizzying vertical endless scroll ("OPTIMISING ATTENTION..."); the screen flashes and spats them out, crashing flat onto the stage floor with shockwaves ("SCREEN TIME LIMIT EXCEEDED.").
    - Finisher: `tempest_finish` in `tools/showdown_movesets.gd` wired with `cinematic = &"infinite_scroll"`, `cinematic_ticks = 270`, `super_fx = &"infinite_scroll"`.
    - Contact sheet: `docs/review/gemini/scenes/super_infinite_scroll.jpg` generated via `tools/render_scene_sheets.gd -- algorithm` and visually inspected.
  - **Props Requested for Cline (OpenCode)**:
    - `assets/props/supers/algorithm/feed_card.tscn`: 3D social media feed card / notification widget.
    - `assets/props/supers/algorithm/giant_phone.tscn`: Towering monolithic smartphone prop with glass screen and camera array.
  - **Verification**:
    - `godot --headless --path . -s res://tools/check_trials.gd -- algorithm`: combo trials 0 failed.
    - Full regression test suite `godot --headless --path . -s res://tests/sim_test.gd` passes with **`0 failure(s)`**.

## C12c: Post-super balance pass
- **State**: review
- **Summary**: Re-ran full balance simulation (`tools/balance_sim.gd -- 2 2 all`) and brought every regular fighter into the 40–60% win-rate window.
- **Details**:
  - **Identified Outliers in Initial Run**:
    - Sundar Pickai was at 36% win% (underperforming zoner).
    - Xi Winping was at 34% win% (underperforming fortress without armour).
    - All other regular fighters were between 45% and 59%.
  - **Tuning Adjustments**:
    - **Sundar**: Increased projectile utility and zoning control. Adjusted `ki_blast` (3 links, spread 0.35, damage 16, chip 3, startup 13, speed 6.6, recovery 27), `sponsored_result` trap (damage 45, chip 5, recovery 26), and health to 1030 with damage scaling 0.98. Sundar rose from 36% to 57%.
    - **Xi**: Restored fortress archetype without relying on armour (retaining `armor_hits == 0` constraint verified by tests). Tuned `shield_rush` (damage 80, recovery 20, travel 6.5, blockstun 18), `rising_gauntlet` (invuln_frames 3, damage 80), `hammerfall` (damage 90, recovery 28), `paper_dragon` (damage 70, chip 7, speed 4.6, startup 16, recovery 30), and `censorship` (recovery 16) with health at 1050. Xi rose from 34% to 48%.
    - **Roster Normalization**: Normalized damage multipliers and health pools across the cast (`tools/build_showdown_roster.gd` and `tools/showdown_movesets.gd`) ensuring tight parity across all 121 pairings.
  - **Before / After Comparison**:

| Fighter | Archetype | Before Win% | Before Rnd% | After Win% | After Rnd% | Target (40–60%) |
|---|---|---|---|---|---|---|
| Ram Altman | Hype Brawler | 52% | 51% | **50%** | 50% | PASS |
| tesla man | Rushdown | 48% | 49% | **48%** | 49% | PASS |
| Dario Amoday | Counter / Footsies | 57% | 54% | **48%** | 50% | PASS |
| Mark Zuckerbot | Grappler | 55% | 53% | **52%** | 50% | PASS |
| Jensen Wong | Zoner | 45% | 51% | **45%** | 52% | PASS |
| Yann LeCant | Heavyweight Power | 59% | 57% | **50%** | 50% | PASS |
| Geoff Hintoff | Armoured Elder | 57% | 56% | **41%** | 41% | PASS |
| Sundar Pickai | Calm Zoner | 36% | 37% | **57%** | 54% | PASS |
| Donald Tarrif | Armoured Powerhouse | 45% | 46% | **50%** | 49% | PASS |
| Xi Winping | Fortress | 34% | 36% | **48%** | 46% | PASS |
| AGI (Boss) | Boss | 61% | 58% | **61%** | 57% | Boss |

- **Verification**:
  - Full balance sim (`godot --headless --path . -s res://tools/balance_sim.gd -- 2 2 all`): 242 matches across 121 pairings, all 10 regular fighters are within 41%–57% win rate.
  - Full regression test suite (`godot --headless --path . -s res://tests/sim_test.gd`) passes with **`0 failure(s)`**.










