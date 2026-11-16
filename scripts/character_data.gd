class_name CharacterData
extends Resource
## Static definition of a playable character. One .tres per character in res://data/characters/
## (the AI Showdown roster); the original 3D Fighter cast lives in res://data/kits/ and
## provides the movesets, CPU personalities and showcase routines (`kit`).

@export var id: StringName
@export var display_name: String
@export var archetype: String
@export_multiline var description: String
## Position on the character select screen (lowest first).
@export var select_order: int = 0
## Fighting kit this character is built on: the id of an original fighter in
## res://data/kits/ whose CPU personality and select-screen routine it uses. Empty = `id`.
@export var kit: StringName
## Fighter whose special/KO shouts are used when this one has none of its own
## (assets/audio/voice/fighters/<id>_<kind>_N.ogg). Empty = no fallback.
@export var voice_fallback: StringName

@export_group("Visuals")
@export var portrait: Texture2D
## Rigged glTF body (Quaternius UAL skeleton). Null = graybox capsule.
@export var model_scene: PackedScene
## Extra skinned pieces (hair, beard) rigged to the same skeleton.
@export var hair_scenes: Array[PackedScene] = []
## Optional skin texture variant replacing the body's base color.
@export var body_albedo: Texture2D
@export var model_scale: float = 1.0
## Tint for hair/eyebrow materials (the free Quaternius hair textures are greyscale).
@export var hair_color: Color = Color.WHITE
## Alternate look for mirror matches (P2 picks the same character).
@export var alt_body_albedo: Texture2D
@export var alt_hair_color: Color = Color.WHITE
## Mirror matches, for models with their own materials (no generated outfit): material
## name -> colour replacing that material's albedo colour (Aelia's armour).
@export var alt_material_colors: Dictionary = {}
## Generated clothing (tools/build_outfits.gd): a skinned mesh on the body's skeleton with
## one surface per colour slot (main, trim, accent, extra), and the body with the covered
## skin removed so nothing pokes through.
@export var outfit_mesh: Mesh
@export var outfit_body_mesh: Mesh
## Printed outfit slots: slot index -> texture in the body's UV layout (a T-shirt print,
## tools/build_prints.py), replacing that slot's colour and weave (not in mirror matches).
@export var outfit_textures: Dictionary = {}
## Per outfit surface: colour, fabric (&"cotton", &"stretch", &"denim", &"leather").
@export var outfit_colors: PackedColorArray = PackedColorArray()
@export var outfit_fabrics: Array[StringName] = []
## Outfit colours for mirror matches.
@export var alt_outfit_colors: PackedColorArray = PackedColorArray()
## Higher-detail materials: fabric weave in the colour, 2K fabric maps, hem shading and
## stitch lines (vertex colours from build_outfits.gd), and skin pore detail.
@export var detailed_textures: bool = false
## Stylized-realism shading (pilot): subsurface-scattered skin with a soft rim, wet eyes
## and an anisotropic hair highlight. Off on the Low graphics preset.
@export var realistic_shading: bool = false
## Match-win animations ("library/clip"); one is picked at random.
@export var victory_animations: Array[StringName] = []
## Tint used for graybox stand-ins and UI until real models/portraits exist.
@export var placeholder_color: Color = Color.WHITE

@export_group("Build")
## Body proportions (base bodies): bone name without _l/_r ("spine_02", "upperarm",
## "Head"...) -> Vector3 scale in that bone's space (Y runs along the bone, Z faces front),
## or [scale, offset] to also shift its flesh (m, bone space; +Z pushes a belly forward).
## Applied to the skin binds (FighterModel._reshape), so only the mesh changes: bones,
## animations and hitboxes stay the same.
@export var body_shape: Dictionary = {}
## Facial structure baked into the generated body (tools/face_sculpt.gd: jaw, chin,
## chin_forward, cheekbones, fullness, nose_width, nose_length, nose_bridge, brow, eye_fold,
## eye_tilt). Rebuild the outfit (tools/build_outfits.gd) after changing it.
@export var face_shape: Dictionary = {}
## Eyebrow shape: scale of the brows about their middle (x width, y thickness and arch,
## z depth); e.g. (1, 0.6, 1) for slimmer, straighter brows.
@export var brow_scale: Vector3 = Vector3.ONE
## Hair volume: the hair pieces scaled about their middle (x width, y height, z depth),
## e.g. a big swept style. Vector3.ONE = as modelled.
@export var hair_scale: Vector3 = Vector3.ONE
## Shift of the hair pieces (m, head space: +Y up, +Z forward), after hair_scale.
@export var hair_offset: Vector3 = Vector3.ZERO
## Iris texture replacing the base eyes' brown (assets/characters/base/T_Eye_*.png).
@export var eye_texture: Texture2D
## Resting expression: FighterModel.FACE_SHAPES weights (squint, brow_up, smile...) added to
## every expression, so a fighter keeps a characteristic look (a squint, raised brows).
@export var face_rest: Dictionary = {}
## Stance: bone name (without _l/_r for both sides) -> extra rotation in degrees (bone
## space: X bends forward/back, Y twists, Z tilts sideways), on top of every animation
## (PostureModifier).
@export var posture: Dictionary = {}
## Extra pieces on the head (FighterModel._add_accessories): &"glasses", &"curls" (short
## curly hair), &"tousled" (messy tufts), &"swoop" (a big swept-over front), &"receding".
@export var accessories: Array[StringName] = []
## Glasses frame colour.
@export var accessory_color: Color = Color(0.05, 0.05, 0.06)
## Skin colour for the receding hairline cap (accessory &"receding").
@export var receding_color: Color = Color(0.69, 0.52, 0.35)

@export_group("Intro and quotes")
## Pre-fight intro animation ("library/clip"), ending in the guard (FightIntro).
@export var intro_animation: StringName
## FighterModel.EXPRESSIONS preset worn through the intro.
@export var intro_expression: StringName = &"neutral"
## Pre-fight lines; one is picked at random unless a rival line applies.
@export var intro_lines: PackedStringArray = PackedStringArray()
## Match-win quotes; one is picked at random unless a rival quote applies.
@export var win_quotes: PackedStringArray = PackedStringArray()
## Rivalries: opponent id -> [intro line, win quote].
@export var rival_lines: Dictionary = {}

@export_group("Training")
## Combo trials (TrainingMode): each {name, steps, corner, tip}. `steps` are move inputs
## ("LP", "2HP", "236P"...) to land in one combo, plus "WALL" for a wall splat; `corner`
## starts the dummy at the stage edge. From tools/build_movesets.gd TRIALS.
@export var combo_trials: Array[Dictionary] = []

@export_group("Stats")
@export var max_health: int = 1000
## Meters per second.
@export var walk_speed: float = 2.0
@export var back_walk_speed: float = 1.6
@export var dash_speed: float = 6.0
@export var sidestep_distance: float = 0.8
@export var jump_velocity: float = 6.0
## Scales knockback received. Heavier characters get pushed less.
@export var weight: float = 1.0
@export var throw_damage: int = 120
## 0..1 ratings shown as bars on the character select screen.
@export_range(0.0, 1.0) var power_rating := 0.5
@export_range(0.0, 1.0) var speed_rating := 0.5

@export_group("Moves")
@export var moves: Array[MoveData] = []


## True for fighters built on the shared base bodies (assets/characters/base/), which get
## generated outfits, detailed textures and expression shapes; false for an imported model
## that brings its own (Aelia: her own mesh on the game skeleton, tools/build_aelia.gd).
func uses_base_body() -> bool:
	return model_scene != null and model_scene.resource_path.begins_with("res://assets/characters/base/")


## The id used for kit-based lookups (CPU personality, showcase routine).
func kit_id() -> StringName:
	return kit if kit != &"" else id
