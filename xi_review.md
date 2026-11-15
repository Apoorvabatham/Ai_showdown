# Character Review: Xi Winping (Revised Pass: Round Build & Zhongshan Suit)

## 1. Overview & Status
- **Character Name**: Xi Winping
- **ID**: `xi`
- **Archetype**: Fortress (Heavy defensive anchor)
- **Base Kit**: Aelia (`data/kits/aelia.tres`)
- **Voice**: Brutus (`voice = &"brutus"`)
- **Review Status**: **Awaiting owner review** (per project workflow in `docs/HANDOFF.md`)

---

## 2. Visual Pass (Per Feedback: Round, Heavy Build & Zhongshan Suit)

![Xi Winping Portrait](assets/ui/portraits/xi.png)

![Xi Winping Model Sheet](docs/screenshots/roster.jpg)

### Detailed Likeness Specifications
- **Round, Heavy Body Build (Non-Muscular)**:
  - Redesigned bone scaling and displacement in `tools/build_showdown_roster.gd` to create an authentic round, stout physique:
    - **Protruding Paunch / Belly**: `spine_01 = [Vector3(1.52, 1.0, 1.72), Vector3(0, 0, 0.06)]` and `spine_02 = [Vector3(1.38, 1.0, 1.50), Vector3(0, 0, 0.04)]` providing a full, rounded protruding belly.
    - **Wide Lower Torso & Pelvis**: `pelvis = [Vector3(1.35, 1.0, 1.40), Vector3(0, 0, 0.02)]`.
    - **Soft, Non-Athletic Chest**: `spine_03 = Vector3(1.12, 1.0, 1.18)` noticeably narrower than the belly, avoiding any athletic or muscular V-shape taper.
    - **Thick Legs & Heavy Stance**: `thigh = Vector3(1.24, 1.0, 1.24)`, `calf = Vector3(1.16, 1.0, 1.16)`.
    - **Posture**: Slight backward lean (`spine_02 = Vector3(-4, 0, 0)`, `spine_03 = Vector3(-5, 0, 0)`) naturally accommodating the round paunch.
    - **Weight & Scale**: `weight = 1.35`, `scale = 0.98` (stout, round stature).
- **Soft Round Facial Sculpting & Double Chin**:
  - `fullness = 0.010`, `jaw = 1.08`, `chin_round = 0.015` (eliminating sharp angular jawlines for a smooth, soft round face).
  - `double_chin = 0.012`, `jowls = 0.008` (full fleshy double chin and mature lower jaw folds).
  - `cheekbones = -0.002` (soft rounded cheeks without chiseled cheekbones).
  - `face_length = 0.94` (compact, round head outline).
  - `eye_open = -0.0022`, `squint = 0.25`, `eye_fold = 1.0` (narrowed, smiling eye crinkles with natural folds).
  - `face_rest = {smile = 0.35, squint = 0.25}` (affable, contented, stoic expression).
- **Retro Cadre Hair**: Voluminous swept retro cadre side-sweep using `Hair_SimpleParted` mesh with `hair_volume = [Vector3(1.06, 1.15, 1.08), Vector3(0, 0.003, -0.004)]` in jet black `Color(0.05, 0.05, 0.05)`.
- **Zhongshan (Mao) Suit**: Replaced Western suit with custom `_zhongshan_spec` in `tools/build_outfits.gd`:
  - Dark charcoal/black tunic jacket (`Color(0.08, 0.08, 0.09)`) buttoned straight up to the throat.
  - Seamless standing mandarin collar wrapping the neck.
  - Symmetrical breast pockets and five front lacquer buttons (`Slot.DETAIL`).
  - Tailored trousers draped over black leather dress shoes (`Color(0.05, 0.05, 0.05)`).
  - Alt Suit: PLA / cadre slate-green tunic (`Color(0.18, 0.21, 0.19)`) with brass buttons (`Color(0.75, 0.62, 0.2)`).

---

## 3. Rendered Visual Assets & Artifact References

| Asset Description | File Path | Format & Resolution |
|-------------------|-----------|---------------------|
| **Full Roster Model Sheet** | `docs/screenshots/roster.jpg` | RGB8 JPEG, full 12-fighter lineup |
| **Character Portrait** | `assets/ui/portraits/xi.png` | RGBA PNG, 512x512 transparent |
| **Super Cut-In (Default)** | `assets/ui/cutins/xi.png` | RGBA PNG, 1024x400 transparent |
| **Super Cut-In (Alt)** | `assets/ui/cutins/xi_alt.png` | RGBA PNG, 1024x400 transparent |
| **Aged Skin Texture** | `assets/characters/aged/T_xi_skin.png` | RGBA PNG, 2048x2048 (VRAM ctex) |
| **Character Resource** | `data/characters/xi.tres` | Godot CharacterData Resource |
| **Baked Outfit Mesh** | `assets/characters/outfits/xi_outfit.res` | 5-surface ArrayMesh |
| **Baked Body Mesh** | `assets/characters/outfits/xi_body.res` | Sculpted base body ArrayMesh |

---

## 4. Moveset & Voice Lines

- **Signature Moves**:
  - `shield_rush` -> **Belt and Road Rush**
  - `rising_gauntlet` -> **Five-Year Plan**
  - `hammerfall` -> **Social Credit Hammer**
  - `gauntlet_drive` -> **State Media Drive**
  - `spur_rake` -> **Censor Sweep**
  - `emerald_oath` -> **Great Firewall**
  - `oath_finish` -> **Great Firewall** (Super Move)
- **Voice Lines & Intros**:
  - Intros:
    - *"This fight has been approved in advance."*
    - *"Search results for your victory: none found."*
    - *"Harmony will be restored."*
  - Wins:
    - *"This match did not happen."*
    - *"Your defeat is trending. Officially."*
    - *"Stability maintained."*
  - Rivalries:
    - Donald Tarrif: *"Your tariffs do not frighten me." / "Trade war: concluded."*

---

## 5. Simulation Verification

- **Command**:
  ```powershell
  godot_console --headless --path . -s res://tests/sim_test.gd
  ```
- **Execution Results**:
  - **All tests passed**: `0 failure(s)`
  - Exit code: `0`
  - Zero GDScript runtime errors
  - Deterministic physics and combat verified.
