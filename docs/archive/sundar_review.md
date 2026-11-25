# Character Review: Sundar Pickai (Revised Likeness Pass)

## 1. Overview & Status
- **Character Name**: Sundar Pickai
- **ID**: `sundar`
- **Archetype**: Calm Zoner
- **Base Kit**: Kenji (`data/kits/kenji.tres`)
- **Voice**: Kenji (`voice = &"kenji"`)
- **Review Status**: **Awaiting owner review** (per project workflow in `docs/HANDOFF.md`)

---

## 2. Visual Likeness Pass (Per Feedback)

![Sundar Pickai Portrait](assets/ui/portraits/sundar.png)

![Sundar Pickai Model Sheet](docs/screenshots/roster.jpg)

### Detailed Likeness Specifications
- **Skin Tone**: Updated to `&"warm"` (`T_Showdown_Male_Warm.png`, mean RGB [178, 134, 103]), giving a realistic Indian golden/olive undertone and eliminating previous muddy or pale tones.
- **Facial Hair / Trimmed Beard**: Implemented custom procedural beard mask in `tools/build_aged_skins.py` (`paint_sundar_beard`) applying a neatly trimmed short beard, mustache, soul patch, and jawline contour in fine dark stubble directly on `assets/characters/aged/T_sundar_skin.png`.
- **Hair & Styling**: Swapped comb-over to Sundar's signature cropped crew cut using `Hair_Buzzed` mesh scaled with `hair_volume = [Vector3(1.01, 1.05, 1.02), Vector3(0, 0.003, 0.0)]`, tinted dark black/charcoal `Color(0.11, 0.10, 0.10)` with distinguished salt-and-pepper mirror alt `Color(0.35, 0.35, 0.38)`.
- **Wardrobe & Google Logo**: Switched from sweater to signature keynote T-shirt and slacks (`_tee_spec` in `tools/build_outfits.gd` with `prints = {0: "tee"}`):
  - **Google Chest Print**: Added procedural `google` logo in `tools/build_prints.py` drawing the official 4-color Google circular "G" emblem (Blue, Red, Yellow, Green) and "Google" logotype centered on the chest (`assets/characters/prints/T_sundar_tee.png`).
  - Charcoal black crew tee (`Color(0.12, 0.12, 0.13)`), navy trousers (`Color(0.18, 0.22, 0.28)`), and clean dark sneakers (`Color(0.08, 0.08, 0.08)`).
- **Facial Sculpting & Glasses**:
  - `face_length = 1.06`, `jaw = 0.90` (slender, refined oval face structure)
  - `chin = 0.003`, `chin_forward = 0.002` (defined chin)
  - `nose_length = 0.005`, `nose_bridge = 0.003`, `nose_width = 0.95` (straight, prominent bridge)
  - `fullness = -0.005`, `cheekbones = 0.003` (lean, elegant cheeks)
  - `eye_open = -0.0006`, `eye_tilt = 0.0004` (calm, observant eyes)
  - `mouth_width = 0.96`, `lips = 0.0`
  - `face_rest = {smile = 0.45}` (calm, polite resting demeanor)
  - Brows: `Vector3(0.96, 0.78, 1.0)`, Eyes: `DarkBrown`
  - **Signature Glasses**: Sleek dark rectangular wireframe glasses (`accessories = [&"glasses"]`, `accessory_color = Color(0.08, 0.08, 0.1)`).
- **Executive Stance & Silhouette**: Tall, poised posture:
  - `posture = {spine_02 = Vector3(1, 0, 0), spine_03 = Vector3(1, 0, 0), neck_01 = Vector3(2, 0, 0), Head = Vector3(-2, 0, 0)}`.
  - Proportions: tall scale `1.02` (180 cm slender build), lean torso `shape = {spine_03 = Vector3(0.88, 1, 0.88), upperarm = Vector3(0.84, 1, 0.84), lowerarm = Vector3(0.88, 1, 0.88), thigh = Vector3(0.88, 1, 0.88), calf = Vector3(0.9, 1, 0.9), neck_01 = Vector3(0.92, 1.05, 0.92)}`.

---

## 3. Rendered Visual Assets & Artifact References

| Asset Description | File Path | Format & Resolution |
|-------------------|-----------|---------------------|
| **Full Roster Model Sheet** | `docs/screenshots/roster.jpg` | RGB8 JPEG, full 12-fighter lineup |
| **Character Portrait** | `assets/ui/portraits/sundar.png` | RGBA PNG, 512x512 transparent |
| **Super Cut-In (Default)** | `assets/ui/cutins/sundar.png` | RGBA PNG, 1024x400 transparent |
| **Super Cut-In (Alt)** | `assets/ui/cutins/sundar_alt.png` | RGBA PNG, 1024x400 transparent |
| **Google Tee Texture** | `assets/characters/prints/T_sundar_tee.png` | RGBA PNG, 2048x2048 |
| **Aged & Bearded Skin Texture** | `assets/characters/aged/T_sundar_skin.png` | RGBA PNG, 2048x2048 (VRAM ctex) |
| **Character Resource** | `data/characters/sundar.tres` | Godot CharacterData Resource |
| **Baked Outfit Mesh** | `assets/characters/outfits/sundar_outfit.res` | 4-surface ArrayMesh |
| **Baked Body Mesh** | `assets/characters/outfits/sundar_body.res` | Sculpted base body ArrayMesh |

---

## 4. Moveset & Parody Voice Lines

- **Projectiles & Moves**:
  - `ki_blast` -> **Ten Blue Links** (Google Blue projectile: `Color(0.26, 0.52, 0.96)`)
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
