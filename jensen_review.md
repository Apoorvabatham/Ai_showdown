# Character Review: Jensen Wong (Likeness Pass)

## 1. Overview & Status
- **Character Name**: Jensen Wong
- **ID**: `jensen`
- **Archetype**: Zoner
- **Base Kit**: Kenji (`data/kits/kenji.tres`)
- **Voice**: Kenji (`voice = &"kenji"`)
- **Review Status**: **Awaiting owner review** (per project workflow in `docs/HANDOFF.md`)

---

## 2. Likeness Pass Summary

Jensen Wong's likeness pass has been executed and integrated across the full character definition, outfit modeling, texture generation, and rendering pipeline:

- **Age Pass (Age 63)**: Configured at `age = 63` in `tools/build_showdown_roster.gd` with aged skin texture overlay `assets/characters/aged/T_jensen_skin.png` providing subtle nasolabial folds, fine crow's feet, forehead character lines, and neck definition.
- **Hair Volume & Silver Finish**: Voluminous silver swept-back hair utilizing `Hair_SimpleParted` mesh scaled and translated via `hair_volume = [Vector3(1.1, 1.22, 1.12), Vector3(0, 0.008, -0.008)]` and tinted silver-grey `Color(0.72, 0.72, 0.74)` (mirror-match alt costume: dark grey `Color(0.18, 0.18, 0.2)`).
- **Facial Sculpting**: Respectful East Asian facial sculpt parameterized via custom shape morphs:
  - `eye_fold = 1.0`, `nose_bridge = -0.005`, `nose_width = 1.12`, `cheekbones = 0.004`
  - `fullness = 0.002`, `brow = -0.003`, `jaw = 1.02`, `eye_tilt = 0.0012`, `eye_open = -0.001`
  - `chin_round = 0.002`, `mouth_width = 1.02`, `face_rest = {smile = 0.45, squint = 0.15}`
  - Brows: `Vector3(1.0, 0.72, 1.0)`, Eyes: `DarkBrown`
- **Signature Accessories**: Wireframe glasses attached via `accessories = [&"glasses"]`.
- **Keynote Stance & Posture**: Signature leaning, confident keynote posture defined in skeleton rest overrides:
  - `posture = {spine_02 = Vector3(-3, 0, 0), spine_03 = Vector3(-4, 0, 0), neck_01 = Vector3(-3, 0, 0), Head = Vector3(-3, 0, 0), clavicle = Vector3(0, 3, 0)}`
  - Proportional adjustments: `shape = {spine_03 = Vector3(0.96, 1, 0.96), upperarm = Vector3(0.94, 1, 0.94), lowerarm = Vector3(0.95, 1, 0.95), spine_01 = Vector3(1.02, 1, 1.04)}`, overall scale: `0.97`.
- **Wardrobe**: Iconic black leather motorcycle jacket (`_leather_jacket_spec`):
  - Slot 0 (`Slot.MAIN`): Black leather jacket (`black_leather`) with collar, waistband, and cuff details.
  - Slot 1 (`Slot.TRIM`): Black crew-neck t-shirt (`Color(0.12, 0.12, 0.13)`).
  - Slot 2 (`Slot.ACCENT`): Dark jeans (`Color(0.08, 0.08, 0.09)`).
  - Slot 3 (`Slot.EXTRA`): Black boots (`Color(0.06, 0.05, 0.05)`).
  - Slot 4 (`Slot.DETAIL`): Metal zip hardware (`Color(0.75, 0.75, 0.78)`).
- **NVIDIA T-Shirt Logo (Slot 1 TRIM)**: Authentic NVIDIA logo with exact "NVIDIA" spelling procedurally generated in `tools/build_prints.py` via `def nvidia()`:
  - Green spiral/claw emblem using official palette: primary green `(118, 185, 0)`, highlight green `(150, 215, 20)`, white iris `(248, 248, 248)`.
  - Typeset with "NVIDIA" in `InterDisplay-BlackItalic.otf`, dynamically centered beneath the emblem.
  - Chest mapped via 10-term cubic polynomial fit at `(0.0, 1.365)` m.
  - Linked to Slot 1 TRIM in `tools/build_showdown_roster.gd` (`prints = {1: "tee"}`), cleanly displaying the logo on the t-shirt beneath the unzipped leather jacket.

---

## 3. Rendered Visual Assets & Artifact References

All visual renders and baked assets have been generated, imported with VRAM compression, and linked into the game resources:

| Asset Description | File Path | Format & Resolution |
|-------------------|-----------|---------------------|
| **Full Roster Model Sheet** | `docs/screenshots/roster.jpg` | RGB8 JPEG, full 12-fighter lineup |
| **Character Portrait** | `assets/ui/portraits/jensen.png` | RGBA PNG, 512x512 transparent |
| **Super Cut-In (Default)** | `assets/ui/cutins/jensen.png` | RGBA PNG, 1024x400 transparent |
| **Super Cut-In (Alt)** | `assets/ui/cutins/jensen_alt.png` | RGBA PNG, 1024x400 transparent |
| **T-Shirt Print Texture** | `assets/characters/prints/T_jensen_tee.png` | RGBA PNG, 2048x2048 (VRAM ctex) |
| **T-Shirt Texture Import Config** | `assets/characters/prints/T_jensen_tee.png.import` | Godot Import Config (`compress/mode=1`) |
| **Aged Skin Texture** | `assets/characters/aged/T_jensen_skin.png` | RGBA PNG, 2048x2048 (VRAM ctex) |
| **Character Resource** | `data/characters/jensen.tres` | Godot CharacterData Resource |
| **Baked Outfit Mesh** | `assets/characters/outfits/jensen_outfit.res` | 5-surface ArrayMesh |
| **Baked Body Mesh** | `assets/characters/outfits/jensen_body.res` | Sculpted base body ArrayMesh |

---

## 4. Moveset & Voice Lines

- **Projectiles & Moves**:
  - `ki_blast` -> **Tensor Blast** (Projectile Color: `Color(0.46, 0.8, 0.0)`)
  - `rising_dragon` -> **Leather Uppercut**
  - `snap_kick` -> **Keynote Kick**
  - `advancing_straight` -> **The More You Buy**
  - `dragon_barrage` -> **GPU Rain**
  - `dragon_finish` -> **GPU Rain** (Super Move)
- **Voice Lines & Intros**:
  - Intros:
    - *"The more you buy, the more you save."*
    - *"Let me show you our next-generation fist."*
    - *"Every fight is a data-center-scale fight."*
  - Wins:
    - *"Thirty times faster than last year's beatdown."*
    - *"The leather jacket remains undefeated."*
    - *"Thank you, thank you. Now, about pricing..."*
  - Rivalries:
    - Sundar: *"Your data centres run on my chips. / Please, order more."*
    - The Algorithm: *"Who do you think trains you? / Running on my hardware, losing on my hardware."*

---

## 5. Simulation Verification

- **Command**:
  ```powershell
  godot --headless --path . -s res://tests/sim_test.gd
  ```
- **Execution Environment**:
  - Engine: Godot 4.7.2.stable.official.ed1daf0bf
  - Mode: Headless simulation harness
- **Verification Results**:
  - **All tests passed**: `0 failure(s)`
  - Exit code: `0`
  - Zero GDScript runtime errors (`errors.count == 0`)
  - Showdown character integrity verified: movesets, animations, portraits, cut-ins, stage interactions, and deterministic combat physics.
