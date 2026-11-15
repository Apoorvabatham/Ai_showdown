# Character Review: Xi Winping (Revised Pass: Buzz Cut, Stance & Eyes)

## 1. Overview & Status
- **Character Name**: Xi Winping
- **ID**: `xi`
- **Archetype**: Fortress (Heavy defensive anchor)
- **Base Kit**: Aelia (`data/kits/aelia.tres`)
- **Voice**: Brutus (`voice = &"brutus"`)
- **Review Status**: **Awaiting owner review** (per project workflow in `docs/HANDOFF.md`)

---

## 2. Visual Pass (Per Feedback: Hairstyle, Stance, Eyes)

![Xi Winping Portrait](assets/ui/portraits/xi.png)

![Xi Winping Model Sheet](docs/screenshots/roster.jpg)

### Detailed Likeness Specifications
- **Hairstyle Change (`Hair_Buzzed`)**:
  - Replaced parted hair with a crisp, tight cropped cadre buzz/crew cut using `Hair_Buzzed` mesh.
  - Scaled with `hair_volume = [Vector3(1.02, 1.05, 1.02), Vector3(0, 0.003, 0.0)]` in dark charcoal `Color(0.06, 0.06, 0.06)` with salt-and-pepper mirror alt `Color(0.35, 0.35, 0.38)`.
  - Creates a rounded, disciplined head profile that fits the round face shape naturally.
- **Refined Eyes & Gaze**:
  - `eye_open = -0.0010` (open, calm, dignified gaze, avoiding excessive narrowing/squint).
  - `eye_tilt = 0.0002` (level, natural eye angle).
  - `eye_fold = 0.85` (soft, authentic epicanthic fold).
  - Rest expression: `squint = 0.08`, `smile = 0.30` for an alert, polite, stoic demeanor.
  - Brows: `Vector3(1.02, 0.88, 1.0)` with DarkBrown irises.
- **Adjusted Stance & Posture**:
  - `posture = {spine_02 = Vector3(-2, 0, 0), spine_03 = Vector3(-3, 0, 0), neck_01 = Vector3(1, 0, 0), Head = Vector3(-1, 0, 0), upperarm = Vector3(18, 0, -15), lowerarm = Vector3(-25, 0, 0), clavicle = Vector3(0, 3, -3)}`.
  - Lowers the arms down to chest/stomach level and broadens the shoulders, establishing a grounded, heavy fortress defensive stance.
- **Round, Heavy Body Build (Non-Muscular)**:
  - Full protruding paunch/belly (`spine_01 = [Vector3(1.52, 1.0, 1.72), Vector3(0, 0, 0.06)]` and `spine_02 = [Vector3(1.38, 1.0, 1.50), Vector3(0, 0, 0.04)]`).
  - Wide pelvis (`1.35, 1.0, 1.40`) and soft, non-athletic chest (`spine_03 = Vector3(1.12, 1.0, 1.18)`), eliminating any muscular V-taper.
  - Soft round cheeks (`fullness = 0.010`, `jaw = 1.08`, `chin_round = 0.015`, `face_length = 0.94`) and fleshy double chin (`double_chin = 0.012`, `jowls = 0.008`).
- **Zhongshan (Mao) Suit**:
  - Custom `_zhongshan_spec` in `tools/build_outfits.gd`:
  - Dark charcoal/black closed tunic jacket (`Color(0.08, 0.08, 0.09)`) buttoned straight up to the throat.
  - Seamless standing mandarin collar wrapping cleanly around the neck.
  - Symmetrical breast pockets and five front lacquer buttons.
  - Tailored trousers draped over black leather dress shoes (`Color(0.05, 0.05, 0.05)`).
  - Alt Suit: Cadre slate-green tunic (`Color(0.18, 0.21, 0.19)`) with brass buttons (`Color(0.75, 0.62, 0.2)`).

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
  - Deterministic combat and physics verified.
