# Character Review: Sundar Pickai (Likeness Pass)

## 1. Overview & Status
- **Character Name**: Sundar Pickai
- **ID**: `sundar`
- **Archetype**: Calm Zoner
- **Base Kit**: Kenji (`data/kits/kenji.tres`)
- **Voice**: Kenji (`voice = &"kenji"`)
- **Review Status**: **Awaiting owner review** (per project workflow in `docs/HANDOFF.md`)

---

## 2. Visual Likeness Pass

![Sundar Pickai Portrait](sundar_portrait.png)

![Sundar Pickai Model Sheet](sundar_model_sheet.jpg)

### Detailed Likeness Specifications
- **Age Pass (Age 54)**: Configured at `age = 54` in `tools/build_showdown_roster.gd` with aged skin texture overlay `assets/characters/aged/T_sundar_skin.png` providing subtle forehead character lines, gentle laugh lines, slight eye wrinkles, and neck definition.
- **Hair & Styling**: Neat, side-parted short executive hair utilizing `Hair_SimpleParted` mesh scaled with `hair_volume = [Vector3(0.98, 0.97, 0.98), Vector3(0, 0.001, 0.0)]`, tinted natural dark black/charcoal `Color(0.12, 0.11, 0.11)` with distinguished salt-and-pepper mirror alt `Color(0.38, 0.38, 0.4)`.
- **Facial Sculpting**: Respectful South Asian facial sculpt parameterized via custom shape morphs:
  - `face_length = 1.05`, `jaw = 0.91` (slender, refined oval face structure)
  - `chin = 0.003`, `chin_round = 0.001`, `chin_forward = 0.002` (defined chin)
  - `nose_length = 0.004`, `nose_bridge = 0.002`, `nose_width = 0.96` (straight, elegant nose)
  - `fullness = -0.004`, `cheekbones = 0.002` (lean, elegant cheeks)
  - `eye_open = -0.0006`, `eye_tilt = 0.0004` (calm, observant eyes)
  - `mouth_width = 0.96`, `lips = 0.0`
  - `face_rest = {smile = 0.45}` (calm, courteous resting expression)
  - Brows: `Vector3(0.96, 0.76, 1.0)`, Eyes: `DarkBrown`
- **Signature Accessories**: Sleek dark rectangular wireframe glasses (`accessories = [&"glasses"]`, `accessory_color = Color(0.08, 0.08, 0.1)`).
- **Executive Stance & Silhouette**: Tall, poised executive posture:
  - `posture = {spine_02 = Vector3(1, 0, 0), spine_03 = Vector3(1, 0, 0), neck_01 = Vector3(2, 0, 0), Head = Vector3(-2, 0, 0)}` (upright, calm, composed).
  - Proportions: tall scale `1.02` (180 cm slender build), lean torso `shape = {spine_03 = Vector3(0.88, 1, 0.88), upperarm = Vector3(0.84, 1, 0.84), lowerarm = Vector3(0.88, 1, 0.88), thigh = Vector3(0.88, 1, 0.88), calf = Vector3(0.9, 1, 0.9), neck_01 = Vector3(0.92, 1.05, 0.92)}`.
- **Wardrobe**: Tailored quarter-zip sweater and slacks (`_sweater_spec`):
  - Slot 0 (`Slot.MAIN`): Navy blue knit sweater (`Color(0.1, 0.13, 0.25)`) with ribbed hem and cuffs.
  - Slot 1 (`Slot.TRIM`): Quarter-zip collar detailing with metal pull.
  - Slot 2 (`Slot.ACCENT`): Tailored grey slacks (`Color(0.36, 0.37, 0.4)`).
  - Slot 3 (`Slot.EXTRA`): Black leather shoes (`Color(0.08, 0.08, 0.08)`).
  - Mirror Alt: Burgundy/crimson sweater (`Color(0.42, 0.12, 0.12)`) with charcoal slacks.

---

## 3. Rendered Visual Assets & Artifact References

| Asset Description | File Path | Format & Resolution |
|-------------------|-----------|---------------------|
| **Full Roster Model Sheet** | `docs/screenshots/roster.jpg` | RGB8 JPEG, full 12-fighter lineup |
| **Character Portrait** | `assets/ui/portraits/sundar.png` | RGBA PNG, 512x512 transparent |
| **Super Cut-In (Default)** | `assets/ui/cutins/sundar.png` | RGBA PNG, 1024x400 transparent |
| **Super Cut-In (Alt)** | `assets/ui/cutins/sundar_alt.png` | RGBA PNG, 1024x400 transparent |
| **Aged Skin Texture** | `assets/characters/aged/T_sundar_skin.png` | RGBA PNG, 2048x2048 (VRAM ctex) |
| **Character Resource** | `data/characters/sundar.tres` | Godot CharacterData Resource |
| **Baked Outfit Mesh** | `assets/characters/outfits/sundar_outfit.res` | 4-surface ArrayMesh |
| **Baked Body Mesh** | `assets/characters/outfits/sundar_body.res` | Sculpted base body ArrayMesh |

---

## 4. Moveset & Voice Lines

- **Projectiles & Moves**:
  - `ki_blast` -> **Ten Blue Links** (Projectile Color: Google Blue `Color(0.26, 0.52, 0.96)`)
  - `rising_dragon` -> **Featured Snippet**
  - `snap_kick` -> **Quarterly Kick**
  - `advancing_straight` -> **Sponsored Result**
  - `dragon_barrage` -> **Search Result**
  - `dragon_finish` -> **Search Result** (Super Move)
- **Voice Lines & Intros**:
  - Intros:
    - *"I'm feeling lucky."*
    - *"We're an AI-first fighter now."*
    - *"Let's have a thoughtful, constructive fight."*
  - Wins:
    - *"Did you mean: 'I lose'?"*
    - *"About one million results for 'knockout'."*
    - *"We'll be sunsetting your health bar."*
  - Rivalries:
    - Ram Altman: *"We invented the transformer, you know." / "Code red: resolved."*

---

## 5. Simulation Verification

- **Command**:
  ```powershell
  godot --headless --path . -s res://tests/sim_test.gd
  ```
- **Execution Results**:
  - **All tests passed**: `0 failure(s)`
  - Exit code: `0`
  - Zero GDScript runtime errors
  - Showdown character integrity verified: movesets, animations, portraits, cut-ins, stage interactions, and deterministic combat physics.
