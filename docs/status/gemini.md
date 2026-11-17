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
- **Summary**: Overhauled visual fidelity across all 4 stages in `scripts/stages/stage_retheme.gd`.
- **Details**:
  - **Mensa**: Added `MensaReflectionProbe` for realistic linoleum floor specular highlights. Applied Poly Haven PBR `floor_tiles_06` texture with normal and roughness maps. Replaced box chairs with Kenney dining chairs (`chair.glb`, `chairRounded.glb`). Populated cafeteria tables and service counter with real plates, bowls, coffee cups, and condiment bottles.
  - **Senate**: Added `SenateReflectionProbe` for mahogany and brass reflections. Replaced blocky dais chairs with Kenney executive swivel chairs (`chairDesk.glb`). Added reading lamp (`lampRoundTable.glb`) and witness chair to the witness stand.
  - **Foundry**: Added `FoundryReflectionProbe` for specular cleanroom floor and chamber glass. Placed articulated robotic arms (`robot-arm-a.glb`, `robot-arm-b.glb`) tending the 300mm wafer load port. Added wafer track conveyors, lithography machines on flanks, and overhead cryogenic fluid pipelines.
  - **Server Farm**: Added `ServerFarmReflectionProbe`. Placed overhead high-density cooling pipes, wall structure panels, and real diagnostic monitor terminals (`computer-screen.glb`).
- **Screenshots**:
  - Mensa: `docs/review/gemini/mensa.png`
  - Server Farm: `docs/review/gemini/server_farm.png`
  - Senate: `docs/review/gemini/senate.png`
  - Foundry: `docs/review/gemini/foundry.png`

## G5: Stage interaction and ambient sounds
- **State**: done
- **Summary**: Generated CC0 44.1kHz 16-bit PCM WAV stage audio in `assets/audio/stage/<stage>/`.
- **Details**:
  - `mensa`: `tray_clatter.wav`, `dishes_clink.wav`, `cafeteria_chatter.wav`, `cheer.wav`, `gasp.wav`.
  - `senate`: `gavel.wav` (solid mahogany sound block strike), `camera_shutter.wav` (DSLR press shutter), `flash_pop.wav`, `hearing_chatter.wav`, `cheer.wav`, `gasp.wav`.
  - `server_farm`: `fan_whir.wav` (server blower drone), `alarm.wav` (rack fault siren), `terminal_beep.wav`, `steam_hiss.wav`.
  - `foundry`: `welding.wav` (electrical arc sizzle), `sparks.wav` (plasma ejection pops), `air_shower.wav` (cleanroom entry blast), `euv_laser.wav` (pulsed 13.5nm core discharge), `alarm.wav`.
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
