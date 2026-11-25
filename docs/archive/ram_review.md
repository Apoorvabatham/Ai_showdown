# Character Review: Ram Altman (Likeness Pass)

## 1. Overview & Status

- **Character Name**: Ram Altman
- **ID**: `ram`
- **Archetype**: Hype Brawler
- **Base Kit**: Mira (`data/kits/mira.tres`)
- **Voice**: Kenji (`voice_fallback = &"kenji"`)
- **Review Status**: **Awaiting owner review**

![Ram Altman portrait](assets/ui/portraits/ram.png)

---

## 2. Visual Pass

### Face & Hair

- Age 41 with a youthful oval jaw (`jaw = 0.92`), soft rounded chin (`chin = -0.002`,
  `chin_round = 0.004`) and lean cheeks (`fullness = -0.003`).
- Slightly narrow nose (`nose_width = 0.92`, `nose_bridge = 0.002`) and wide, alert blue
  eyes (`eye_open = 0.0012`, `eye_tilt = 0.0003`).
- Resting expression is an eager, half-smiling challenge: `brow_up = 0.52`,
  `smile = 0.24`; brows scaled `Vector3(0.95, 0.80, 1.0)`.
- Close-cropped buzz cut (`Hair_Buzzed`) in dark brown `Color(0.28, 0.20, 0.14)`, scaled
  `Vector3(1.02, 1.05, 1.03)` with a 3 mm lift for a clean hairline. Mirror palette is
  near-black `Color(0.12, 0.10, 0.09)`.
- No accessories: the face and buzz cut carry the read.

### Build & Posture

- Trim athletic build at `model_scale = 0.98`: torso `0.90–0.92`, arms `0.88–0.90`,
  legs `0.90–0.92` on the base skeleton.
- Upright, ready posture (`spine_01/02 = 1°`, `neck_01 = 2°`, `Head = -2°`) with a level,
  direct gaze.
- Intro animation `fight/intro_power` with the `grin` expression.

### Outfit

- Fitted charcoal tee `Color(0.12, 0.12, 0.13)` with the OpenAI emblem and wordmark print
  (`tools/build_prints.py` → `T_ram_tee.png`).
- Dark-wash denim `Color(0.14, 0.18, 0.28)` and white sneakers `Color(0.08, 0.08, 0.09)`.
- Mirror palette: white tee `Color(0.85, 0.85, 0.88)`, black denim
  `Color(0.10, 0.10, 0.12)`, off-white sneakers `Color(0.12, 0.12, 0.14)`.

### Alternate Palette

![Ram Altman alt cut-in](assets/ui/cutins/ram_alt.png)

---

## 3. Rendered Assets

| Asset | Path | Format |
|---|---|---|
| Portrait | `assets/ui/portraits/ram.png` | RGBA PNG, 512×512 |
| Super cut-in | `assets/ui/cutins/ram.png` | RGBA PNG, 1024×400 |
| Alt super cut-in | `assets/ui/cutins/ram_alt.png` | RGBA PNG, 1024×400 |
| Full roster sheet | `docs/screenshots/roster.jpg` | RGB JPEG (Ram is first on the left) |
| Aged/young skin | `assets/characters/aged/T_ram_skin.png` | RGBA PNG, 2048×2048 |
| Tee print | `assets/characters/prints/T_ram_tee.png` | RGBA PNG |
| Character resource | `data/characters/ram.tres` | Godot `CharacterData` |
| Baked outfit | `assets/characters/outfits/ram_outfit.res` | 5-surface `ArrayMesh` |
| Baked body | `assets/characters/outfits/ram_body.res` | Sculpted `ArrayMesh` |

![Full roster model sheet](docs/screenshots/roster.jpg)

---

## 4. Moveset & Voice Lines

- **Signature moves**:
  - `lakas_stance` → **Add More Compute**
  - `bagyo_rush` → **Funding Round Rush**
  - `lawin_rise` → **Hype Cycle**
  - `lawin_drop` → **Product Drop**
  - `sipa_flip` → **Pivot Flip**
  - `tapik` → **Teaser Tweet**
  - `huling_hagupit` / `hagupit_finish` / `hagupit_max` → **Scaling Law** (super)
- **Training trials**: Teaser Tweet String, Sipa Launcher, Bagyo Confirm.
- **Intros**:
  - *"Honestly? I think this is going to be a really good fight."*
  - *"We're going to need a lot more compute for this."*
  - *"AGI is close. So is my fist."*
- **Wins**:
  - *"That felt like a pretty big deal, honestly."*
  - *"Scaling works. It's kind of wild."*
  - *"I'll need about seven trillion dollars for the rematch."*
- **Rivals**:
  - tesla: *"Still upset you left the board?" / "See you in court. Again."*
  - dario: *"You used to work for me, you know." / "Safety is great. Shipping is better."*

---

## 5. Simulation Verification

- **Command**: `godot_console --headless --path . -s res://tests/sim_test.gd`
- **Result**: `0 failure(s)`, exit code `0`; the suite's "no script errors during the run"
  check passed. The headless dummy renderer prints benign `material is null` warnings on
  teardown; they do not fail the run.

---

## 6. Review Checklist

- [ ] Silhouette reads as the youngest, leanest fighter next to the rest of the roster.
- [ ] Buzz cut hairline is clean from front and profile; no scalp clipping.
- [ ] Face reads age 41 — not a veteran, not a teenager.
- [ ] Tee print is legible and correctly placed at gameplay distance.
- [ ] Stance feels alert and forward-leaning without looking hunched.
- [ ] Alt palette (white tee / black denim) is distinct in the mirror match.

**Approve as-is, or send notes and I will revise before moving to Dario.**
