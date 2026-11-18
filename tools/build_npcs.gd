extends SceneTree
## Builds the stage and super-scene NPCs: res://data/npcs/<id>.tres as CharacterData with
## look fields only (no moves, no kit), on the same body/outfit/face pipeline as the
## fighters (docs/TASKS.md §3.2). Generated people only: every NPC is made up.
##
## Run: godot --headless --path . -s res://tools/build_npcs.gd
## (append `-- <id> ...` to rebuild only those NPCs)
##
## Order (HANDOFF §5, without the moves/stats steps):
##   1. python3 tools/build_prints.py (T-shirt prints, if a change touches them)
##   2. godot --headless --path . --import
##   3. this tool
##   4. godot --headless --path . -s res://tools/build_outfits.gd -- <id> ...
##   5. render (tools/render_npcs.gd) into docs/review/opencode/

const OUT_DIR := "res://data/npcs/"
const PORTRAIT_DIR := "res://assets/ui/portraits/"
const MALE_BODY := "res://assets/characters/base/Superhero_Male_FullBody.gltf"
const HAIR_DIR := "res://assets/characters/hair/"
const PRINT_DIR := "res://assets/characters/prints/"
const SKINS := {
	&"light": "res://assets/characters/base/T_Superhero_Male_Light.png",
	&"light_alt": "res://assets/characters/base/T_Superhero_Male_Dark.png",
	&"medium": "res://assets/characters/base/T_Showdown_Male_Medium.png",
	&"brown": "res://assets/characters/jin/T_Jin_Body.png",
	&"tan": "res://assets/characters/base/T_Showdown_Male_Tan.png",
	&"pale": "res://assets/characters/base/T_Showdown_Male_Pale.png",
	&"warm": "res://assets/characters/base/T_Showdown_Male_Warm.png",
}

## Xi's super squad (O5): three made-up young engineers, each with a T-shirt print
## (tools/build_prints.py) reading Qwen, Alibaba and Kimi. Different builds and hair.
const NPCS := [
	{
		id = &"helper_qwen", name = "Qwen Helper", role = "engineer",
		skin = &"tan", hair = ["Hair_SimpleParted"], hair_color = Color(0.10, 0.09, 0.09),
		alt_hair_color = Color(0.32, 0.26, 0.2),
		hair_volume = [Vector3(1.03, 1.07, 1.04), Vector3(0.0, 0.005, -0.003)],
		face = {jaw = 0.94, chin = -0.002, chin_round = 0.006, cheekbones = 0.002, fullness = -0.003,
			nose_width = 0.96, nose_length = 0.003, nose_bridge = 0.001, eye_open = 0.0008,
			eye_tilt = 0.0004, face_length = 1.02, mouth_width = 0.95},
		face_rest = {smile = 0.38, brow_up = 0.16}, brows = Vector3(0.96, 0.82, 1.0), eyes = "DarkBrown",
		scale = 1.02, accessories = [&"glasses"], accessory_color = Color(0.08, 0.08, 0.09),
		prints = {0: "tee"},
		shape = {spine_01 = Vector3(0.9, 1, 0.9), spine_02 = Vector3(0.88, 1, 0.88), spine_03 = Vector3(0.9, 1, 0.9),
			upperarm = Vector3(0.84, 1, 0.84), lowerarm = Vector3(0.87, 1, 0.87),
			thigh = Vector3(0.9, 1, 0.9), calf = Vector3(0.92, 1, 0.92), neck_01 = Vector3(0.94, 1, 0.94)},
		posture = {spine_02 = Vector3(-2, 0, 0), spine_03 = Vector3(-2, 0, 0), neck_01 = Vector3(1, 0, 0), Head = Vector3(-1, 0, 0)},
	},
	{
		id = &"helper_alibaba", name = "Alibaba Helper", role = "engineer",
		skin = &"medium", hair = ["Hair_Buzzed"], hair_color = Color(0.07, 0.06, 0.06),
		alt_hair_color = Color(0.3, 0.28, 0.26),
		hair_volume = [Vector3(1.02, 1.02, 1.02), Vector3(0.0, 0.002, 0.0)],
		face = {jaw = 1.06, chin = 0.002, chin_round = 0.012, fullness = 0.008, cheekbones = -0.001,
			nose_width = 1.04, nose_length = 0.002, eye_open = 0.0004, eye_tilt = 0.0002,
			face_length = 0.97, mouth_width = 1.02, lips = 0.001},
		face_rest = {smile = 0.5, brow_up = 0.12}, brows = Vector3(1.02, 0.9, 1.0), eyes = "Brown",
		scale = 0.93, accessories = [],
		prints = {0: "tee"},
		shape = {spine_01 = [Vector3(1.16, 1, 1.2), Vector3(0, 0, 0.01)], spine_02 = Vector3(1.12, 1, 1.14),
			spine_03 = Vector3(1.02, 1, 1.04), pelvis = Vector3(1.08, 1, 1.1),
			upperarm = Vector3(1.1, 1, 1.1), lowerarm = Vector3(1.04, 1, 1.04),
			thigh = Vector3(1.08, 1, 1.08), calf = Vector3(1.04, 1, 1.04), neck_01 = Vector3(1.04, 1, 1.04)},
		posture = {spine_01 = Vector3(1, 0, 0), spine_02 = Vector3(1, 0, 0), neck_01 = Vector3(2, 0, 0), Head = Vector3(-2, 0, 0)},
	},
	{
		id = &"helper_kimi", name = "Kimi Helper", role = "engineer",
		skin = &"pale", hair = ["Hair_ShortCurls"], hair_color = Color(0.09, 0.08, 0.08),
		alt_hair_color = Color(0.28, 0.22, 0.17),
		hair_volume = [Vector3(1.06, 1.08, 1.06), Vector3(0.0, 0.004, -0.002)],
		face = {jaw = 0.98, chin = -0.001, chin_forward = 0.002, chin_round = 0.004, fullness = -0.001,
			nose_width = 0.98, nose_length = 0.004, nose_bridge = 0.002, brow = 0.001,
			eye_open = 0.0006, eye_tilt = 0.0003, face_length = 1.01, mouth_width = 0.98},
		face_rest = {smile = 0.24, brow_up = 0.22, squint = 0.1}, brows = Vector3(1.0, 0.86, 1.0), eyes = "Grey",
		scale = 1.05, accessories = [],
		prints = {0: "tee"},
		shape = {spine_01 = Vector3(0.98, 1, 0.98), spine_02 = Vector3(0.96, 1, 0.96), spine_03 = Vector3(0.94, 1, 0.94),
			upperarm = Vector3(0.9, 1, 0.9), lowerarm = Vector3(0.92, 1, 0.92),
			thigh = Vector3(0.94, 1, 0.94), calf = Vector3(0.95, 1, 0.95), neck_01 = Vector3(0.96, 1, 0.96)},
		posture = {spine_02 = Vector3(-1, 0, 0), spine_03 = Vector3(-1, 0, 0), neck_01 = Vector3(1, 0, 0), Head = Vector3(-1, 0, 0)},
	},
]


func _initialize() -> void:
	var only := OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for i in NPCS.size():
		var spec: Dictionary = NPCS[i]
		if only.is_empty() or String(spec.id) in only:
			_build(spec, i)
	quit()


func _build(spec: Dictionary, order: int) -> void:
	var path := OUT_DIR + String(spec.id) + ".tres"
	var previous := load(path) as CharacterData if ResourceLoader.exists(path) else null
	var data := CharacterData.new()
	data.id = spec.id
	data.display_name = spec.name
	data.archetype = spec.get("role", "engineer")
	data.select_order = order
	data.placeholder_color = spec.get("color", Color(0.55, 0.55, 0.58))
	data.kit = &""
	data.voice_fallback = &""
	data.moves = [] as Array[MoveData]
	data.combo_trials = []

	# Look: the shared male base body and the generated outfit (tools/build_outfits.gd,
	# specs keyed by the NPC id).
	data.model_scene = load(MALE_BODY)
	data.model_scale = spec.get("scale", 1.0)
	data.body_shape = spec.get("shape", {}).duplicate(true)
	data.face_shape = spec.get("face", {}).duplicate(true)
	data.face_rest = spec.get("face_rest", {}).duplicate(true)
	data.posture = spec.get("posture", {}).duplicate(true)
	var prints := {}
	for slot in spec.get("prints", {}):
		var print_path := PRINT_DIR + "T_%s_%s.png" % [spec.id, spec.prints[slot]]
		if ResourceLoader.exists(print_path):
			prints[slot] = load(print_path)
		else:
			push_warning("%s: no print %s (run tools/build_prints.py and --import first)" % [spec.id, print_path])
	data.outfit_textures = prints
	data.hair_scale = spec.hair_volume[0] if spec.has("hair_volume") else Vector3.ONE
	data.hair_offset = spec.hair_volume[1] if spec.has("hair_volume") else Vector3.ZERO
	data.brow_scale = spec.get("brows", Vector3.ONE)
	data.eye_texture = load("res://assets/characters/base/T_Eye_%s.png" % spec.eyes) if spec.has("eyes") else null
	var accessories: Array[StringName] = []
	accessories.assign(spec.get("accessories", []))
	data.accessories = accessories
	if spec.has("accessory_color"):
		data.accessory_color = spec.accessory_color
	data.body_albedo = load(SKINS[spec.skin])
	data.alt_body_albedo = data.body_albedo
	var hair: Array[PackedScene] = []
	for piece: String in spec.hair:
		hair.append(load(HAIR_DIR + piece + (".tscn" if ResourceLoader.exists(HAIR_DIR + piece + ".tscn") else ".gltf")))
	data.hair_scenes = hair
	data.hair_color = spec.hair_color
	data.alt_hair_color = spec.alt_hair_color
	data.alt_material_colors = {}
	data.realistic_shading = true

	# Keep the generated outfit (tools/build_outfits.gd) on a rebuild.
	data.outfit_mesh = previous.outfit_mesh if previous else null
	data.outfit_body_mesh = previous.outfit_body_mesh if previous else null
	data.outfit_colors = previous.outfit_colors if previous else PackedColorArray()
	data.alt_outfit_colors = previous.alt_outfit_colors if previous else PackedColorArray()
	data.outfit_fabrics = previous.outfit_fabrics if previous else ([] as Array[StringName])
	data.detailed_textures = previous.detailed_textures if previous else false
	var portrait := PORTRAIT_DIR + String(spec.id) + ".png"
	data.portrait = load(portrait) if ResourceLoader.exists(portrait) else null

	var err := ResourceSaver.save(data, path)
	print("%-16s %-18s %s" % [spec.id, spec.name, "ok" if err == OK else "ERROR %d" % err])
