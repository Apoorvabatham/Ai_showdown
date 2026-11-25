# Character Review: Xi Winping (Revised Pass: Combed-Back Hair & High-Collar Mao Suit)

## 1. Overview & Status
- **Character Name**: Xi Winping
- **ID**: `xi`
- **Archetype**: Fortress (Heavy defensive anchor)
- **Base Kit**: Aelia (`data/kits/aelia.tres`)
- **Voice**: Brutus (`voice = &"brutus"`)
- **Review Status**: **Awaiting owner review** (per project workflow in `docs/HANDOFF.md`)

---

## 2. Visual Pass (Per Feedback: Hair & Clothing Overhaul)

![Xi Winping Portrait](assets/ui/portraits/xi.png)

![Xi Winping Model Sheet](docs/screenshots/roster.jpg)

### Detailed Likeness Specifications
- **Statesman Combed-Back Side-Parted Hairstyle (`Hair_SimpleParted`)**:
  - Full, voluminous combed-back statesman coif with zero scalp clipping or thinning.
  - Scaled with `hair_volume = [Vector3(1.14, 1.15, 1.12), Vector3(0.002, 0.009, -0.005)]` in lustrous dyed jet-black `Color(0.08, 0.08, 0.09)` with salt-and-pepper mirror alt `Color(0.38, 0.38, 0.40)`.
  - Provides a generous 4.8 cm of clearance over the widened skull (`Head = Vector3(1.08, 1.02, 1.08)`), neatly covering the crown, temples, and nape.
- **Authentic Zhongshan (Mao) Suit (`_zhongshan_spec`)**:
  - **High Standing Mandarin Collar**: Fully closes around the neck up to $y = 1.57$ ($L.neck + 0.048$), covering the throat and collarbones completely right below the jawline, eliminating previous scoop neck cutouts.
  - **White Inner Collar Liner**: A crisp white band (`Color(0.95, 0.95, 0.93)`) neatly peeking along the rim of the standing collar (`Slot.EXTRA`).
  - **Center Placket & 5 Gold/Brass Buttons**: Full-length front placket band with 5 distinct buttons (`Color(0.88, 0.74, 0.22)`, `Slot.DETAIL`) running from the throat closure to the hem.
  - **Four External Flap Pockets**: Symmetrical breast flap pockets on the chest and symmetrical lower flap pockets on the hips (`Slot.MAIN`).
  - **Red Delegate Badge**: Vermilion red badge (`Color(0.88, 0.10, 0.10)`, `Slot.ACCENT`) pinned above the left chest pocket.
  - **Cloth Color**: Deep charcoal-slate navy (`Color(0.12, 0.13, 0.16)`); mirror alt is military cadre sage green (`Color(0.18, 0.22, 0.19)`).
  - **Tailored Trousers & Leather Shoes**: Trousers drape cleanly over flat-soled black dress shoes (`Color(0.05, 0.05, 0.05)`).
- **Facial Sculpt & Dignified Gaze**:
  - `eye_open = -0.0010` with `eye_tilt = 0.0002` and `eye_fold = 0.85` for a calm, authoritative gaze with natural epicanthic folds.
  - Rest expression: `smile = 0.28`, `squint = 0.08` for a poised, diplomatic expression.
  - Soft, full round cheeks (`fullness = 0.010`, `jaw = 1.08`, `chin_round = 0.015`, `face_length = 0.94`) and fleshy double chin (`double_chin = 0.012`, `jowls = 0.008`).
- **Round, Heavy Body Build (Non-Muscular)**:
  - Heavy protruding paunch/belly (`spine_01 = [Vector3(1.52, 1.0, 1.72), Vector3(0, 0, 0.06)]`, `spine_02 = [Vector3(1.38, 1.0, 1.50), Vector3(0, 0, 0.04)]`).
  - Wide pelvis (`1.35, 1.0, 1.40`) and soft, non-athletic chest (`spine_03 = Vector3(1.12, 1.0, 1.18)`), eliminating athletic V-taper.
  - Lowered fortress defensive guard posture (`posture = {spine_02 = Vector3(-2, 0, 0), spine_03 = Vector3(-3, 0, 0), neck_01 = Vector3(1, 0, 0), Head = Vector3(-1, 0, 0), upperarm = Vector3(18, 0, -15), lowerarm = Vector3(-25, 0, 0), clavicle = Vector3(0, 3, -3)}`).

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
  - Rivals:
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
  - Deterministic combat, netplay, physics, and CPU matches verified.
