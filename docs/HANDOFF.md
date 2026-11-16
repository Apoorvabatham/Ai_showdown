# AI Showdown: hand-off notes

Status of the work, how to run everything, and the traps that cost time. Read this before
changing anything. Companion docs: [README](../README.md) (overview, controls, credits) and
[CONTRIBUTING](CONTRIBUTING.md) (field-by-field reference for fighters, stages, outfits).

## 1. What this is

A parody 2-player 3D fighting game for an AI-safety student campaign, forked from
[3D Fighter](https://github.com/clintcan/3d-fighter) by Clint Christopher Canada (code MIT,
assets CC BY 4.0: keep `LICENSE`, `LICENSE-ASSETS.md` and the credits). Godot **4.7.2**.

- 12 parody fighters in `data/characters/` (generated, see §4), built on the 8 original
  fighters, which live on as **kits** in `data/kits/` (movesets, CPU personalities,
  showcase routines). `CharacterData.kit` links them.
- 3 stages: Server Farm, Mensa, Senate Hearing Room (`scenes/stages/server_farm.tscn`,
  `mensa.tscn`, `senate.tscn`, inheriting the original rooftop, dojo and ring scenes, plus
  `scripts/stages/stage_retheme.gd`).
- Modes: Vs CPU, Versus, Training, Arcade (final boss: The Algorithm), Demo. Online is
  hidden (`SHOW_ONLINE` in `scripts/ui/main_menu.gd`). Best of 3.
- Disclaimer (title + main menu + splash): "Parody. Not affiliated with or endorsed by any
  real person or company."

## 2. Content rules (agreed with the project owner)

- Satire of public personas and ideas only. Made-up names. **No real logos** (e.g. the
  T-shirt print is an original "OCCUPY MARS" design, not a company logo).
- No humiliating, sexual or ethnic-caricature content. Caricature = exaggerate a person's
  well-known traits (hair, build, expression, posture), never ethnicity.
- Real-person likeness models from the web were investigated but not used (§7).
- The owner reviews **each fighter one at a time** and must approve before the next is
  started. Show front/side/portrait renders (`render_model_sheet.gd`, `render_portraits.gd`).

## 3. Fighter status (likeness pass)

| id | Name | Status | Notes |
|---|---|---|---|
| donald | Donald Tarrif | **Approved** | age 80, round full face, jowls, squint, big swept blond hair (hair_volume), lean-back stance, belly |
| tesla | tesla man | **Approved** | age 55, tall slouch, long jaw, swept-back brown hair, "OCCUPY MARS" tee (tools/build_prints.py) |
| zuckerbot | Mark Zuckerbot | **Approved** | age 42, short, pale, tight curls, wide blue eyes, upright stiff stance. Hoodie collar jagged edge fixed. |
| jensen | Jensen Wong | **Approved** | age 63, voluminous silver swept-back hair (hair_volume), confident keynote posture, black leather jacket with NVIDIA tee (tools/build_prints.py), glasses, aged skin pass, respectful East Asian facial sculpt. |
| sundar | Sundar Pickai | **Approved** | age 54, warm golden skin tone, cropped crew cut hair (Hair_Buzzed), trimmed beard/mustache, Google logo tee (tools/build_prints.py), wireframe glasses, calm upright posture. |
| xi | Xi Winping | **Approved** | age 73, round heavy non-muscular build with paunch, soft facial contour, epicanthic folds, statesman combed-back parted hair (hair_volume), authentic high-collar Zhongshan Mao suit with white collar liner, 5 brass buttons, red delegate badge, symmetrical chest/hip flap pockets. |
| yann | Yann LeCant | **Approved** | age 65, robust barrel-chested academic heavyweight build, square jaw with subtle 5 o'clock stubble shadow, rectangular glasses, wavy salt-and-pepper hair, knowing French smirk, academic charcoal blazer with lapels over light blue open-collar shirt, dark denim jeans, brown leather dress shoes. |
| geoff | Geoff Hintoff | **Review Ready** | age 78, slender tall stooped elder build, long narrow face, age-78 creases and age spots, wispy silver-white thinning hair, arched brows of perpetual concern, knit oatmeal cardigan sweater with contrast button band and 4 horn buttons, pale blue Oxford shirt, charcoal wool trousers, brown walking shoes. |
| ram, dario, demis, algorithm | | To do | earlier generic pass only (face sculpt, eyes, brows, age) |

Suggested order: yann → geoff → ram → dario → demis → algorithm.
Make each one **completely distinct** from the approved ones (silhouette, posture, hair, face
shape, colours); the owner rejected subtle differences.

## 4. Environment setup (Linux / cloud container)

```bash
curl -L -o g.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
```
```bash
unzip g.zip && ln -sf "$PWD/Godot_v4.7.2-stable_linux.x86_64" /usr/local/bin/godot
```
```bash
godot --headless --path . --import
```
```bash
godot --headless --path . -s res://tests/sim_test.gd
```
The last line must print `0 failure(s)` (exit 1 otherwise). Rendering tools need a display:
use `xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --path . -s res://tools/<tool>.gd`.
Python tools need Pillow and numpy. Assets are plain files (no Git LFS).

## 5. Rebuilding a fighter (order matters)

1. Edit the fighter's entry in `ROSTER` in `tools/build_showdown_roster.gd`
   (look, face, age, posture, prints, moves, lines: see CONTRIBUTING for every field).
2. Age skin: `godot --headless --path . -s res://tools/build_aged_skins.gd` then `python3 tools/build_aged_skins.py <id>`.
3. T-shirt print (only if it has one): `python3 tools/build_prints.py`.
4. `godot --headless --path . --import`
5. `godot --headless --path . -s res://tools/build_showdown_roster.gd -- <id>`
6. Body + outfit + sculpted face: `godot --headless --path . -s res://tools/build_outfits.gd -- <id>`
7. Renders (xvfb): `render_model_sheet.gd -- <id>`, `render_portraits.gd -- <id>`, `render_cutins.gd -- <id>`.
8. `godot --headless --path . --import`, then step 5 again (links the new portrait).
9. Tests (`0 failure(s)`), commit, push.

When all fighters are done also re-run `tools/render_key_art.gd` + `python3 tools/build_showdown_art.py`
(splash, logo, wallpaper), `tools/render_stage_thumbs.gd` and `tools/render_screenshots.gd`.

## 6. How the likeness system works (where to look)

| Feature | Data (CharacterData / ROSTER field) | Code |
|---|---|---|
| Body build | `body_shape` / `shape` (per-bone scale via skin binds) | `FighterModel._reshape` |
| Height | `model_scale` / `scale` | |
| Stance | `posture` (bone → degrees, X+ = bend forward) | `scripts/fighter/posture_modifier.gd` |
| Face structure | `face_shape` / `face` (jaw, chin, jowls, double_chin, pout, chin_round, cheekbones, fullness, nose_*, brow, eye_fold, eye_open, eye_tilt, face_length, lips, mouth_width, age) | `tools/face_sculpt.gd`, baked by `build_outfits.gd` |
| Resting expression | `face_rest` (squint, brow_up, smile...) | `FighterModel.set_face` |
| Eyes / brows | `eye_texture` / `eyes`, `brow_scale` / `brows` | `_customize_materials`, `_shape_brows` |
| Hair | `hair_scenes`, `hair_color`, `hair_scale`+`hair_offset` / `hair_volume` | `_rescale_skinned` |
| Head pieces | `accessories`: glasses, curls, tousled, swoop | `_add_accessories` |
| Skin + age | `body_albedo` (aged texture if `age`) | `tools/build_aged_skins.gd/.py` |
| Clothes | outfit specs in `tools/build_outfits.gd` `_showdown_specs()`; 5 slots incl. DETAIL (metal zips/buttons) | `FighterModel._dress` |
| Prints | `outfit_textures` / `prints` | `tools/build_prints.py` |

All of these are visual only: the fight simulation never reads meshes or bones, so they do
not change gameplay or determinism.

## 7. Things tried and their outcome

- **Real likeness 3D models**: Sketchfab has free CC-BY models of Trump, Musk, Zuckerberg,
  Xi and Pichai (none of Altman, Huang, Hinton, LeCun, Hassabis, Amodei), but downloads need
  a Sketchfab API token (the owner declined to provide one). Thingiverse, Free3D and Poly Pizza
  block automated downloads; paid sites were not used. Do not scrape viewer files.
- Procedural hair "blobs" (`swoop` accessory) looked like a hat: scaling the real hair mesh
  (`hair_volume`) works far better.
- Swapping in `Eyebrows_Female` on the male head made the brows vanish (wrong fit): use
  `brow_scale` instead.

## 8. Traps (read these)

- A new `class_name` script (e.g. `FaceSculpt`) is unknown to tools until you run
  `godot --headless --path . --import` once.
- GDScript: `var x := <expression with untyped values>` fails to parse ("cannot infer the
  type"); write `var x: float = ...`.
- Dictionaries in `.tres` written from GDScript dict literals have **StringName** keys
  (`{jaw = 1.0}` → `&"jaw"`); `dict.has("jaw")` is false. Convert keys with `String(key)`
  (see `FaceSculpt.apply`, `FighterModel._reshape`).
- New PNG textures for characters must be imported VRAM-compressed with mipmaps, or the test
  "Download size: no 3D texture is imported lossless" fails. Copy the `[params]` of
  `assets/characters/base/T_Superhero_Male_Light.png.import` (`build_aged_skins.py` does this
  for aged skins; prints use the same pattern).
- `build_showdown_roster.gd` keeps the outfit fields of an existing `.tres`, so run
  `build_outfits.gd` after it whenever the face, body or outfit changes.
- Changing body/face sculpt amounts too much can push neck skin through the shirt collar
  (seen with `chin` on Donald); check the model sheet close-up.
- The engine regression tests run on the kits (`GameState.use_engine_content()`); the AI
  Showdown checks are `showdown_tests()` at the end of `tests/sim_test.gd`.
- `docs/screenshots/roster.jpg` is overwritten by every `render_model_sheet.gd` run (it shows
  only the ids passed). Re-run it without arguments before committing for the full roster.

## 9. Voice drop-ins

Put one file per fighter at `assets/audio/voice/fighters/<id>_super_1.ogg` (or .wav / .mp3),
then `--import`. Optional: `python tools/build_voice_envelopes.py` (needs ffmpeg) for the
talking mouth.
